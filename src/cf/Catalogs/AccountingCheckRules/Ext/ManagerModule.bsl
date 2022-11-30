///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	Query = New Query(
	"SELECT
	|	AccountingCheckRules.Ref AS Ref
	|FROM
	|	Catalog.AccountingCheckRules AS AccountingCheckRules
	|WHERE
	|	AccountingCheckRules.Use
	|	AND AccountingCheckRules.ID IN(&ChecksIDs)");
	
	AccountingChecks = AccountingAuditInternalCached.AccountingChecks().Validation;
	FilterParameters = New Structure;
	FilterParameters.Insert("Disabled", True);
	DisabledChecks = AccountingChecks.FindRows(FilterParameters);
	
	ChecksIDs = New Array;
	For Each DisabledCheck In DisabledChecks Do
		ChecksIDs.Add(DisabledCheck.ID);
	EndDo;
	
	Query.SetParameter("ChecksIDs", ChecksIDs);
	References = Query.Execute().Unload().UnloadColumn("Ref");
	InfobaseUpdate.MarkForProcessing(Parameters, References);
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	ProcessingCompleted = True;
	
	MetadataObject = Metadata.Catalogs.AccountingCheckRules;
	FullObjectName = MetadataObject.FullName();
	
	ObjectsProcessed = 0;
	ObjectsWithIssuesCount = 0;
	
	CheckToDIsable = InfobaseUpdate.SelectRefsToProcess(Parameters.Queue, FullObjectName);
	While CheckToDIsable.Next() Do
		
		BeginTransaction();
		
		Try
			
			CheckToDisableRef = CheckToDIsable.Ref;
			
			Lock = New DataLock;
			LockItem = Lock.Add(FullObjectName);
			LockItem.SetValue("Ref", CheckToDisableRef);
			
			Lock.Lock();
			
			CheckToDisableObject = CheckToDisableRef.GetObject();
			CheckToDisableObject.Use = False;
			ObjectsProcessed = ObjectsProcessed + 1;
			
			InfobaseUpdate.WriteData(CheckToDisableObject);
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			
			Comment = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось установить источник данных правила проверки %1.
				|Возможно он поврежден и не подлежит восстановлению.
				|
				|Информация для администратора: %2'; 
				|en = 'Cannot determine a data source of the %1 check rule.
				|It might be corrupt and cannot be recovered.
				|
				|Information for administrator:%2'; 
				|pl = 'Cannot determine a data source of the %1 check rule.
				|It might be corrupt and cannot be recovered.
				|
				|Information for administrator:%2';
				|de = 'Cannot determine a data source of the %1 check rule.
				|It might be corrupt and cannot be recovered.
				|
				|Information for administrator:%2';
				|ro = 'Cannot determine a data source of the %1 check rule.
				|It might be corrupt and cannot be recovered.
				|
				|Information for administrator:%2';
				|tr = 'Cannot determine a data source of the %1 check rule.
				|It might be corrupt and cannot be recovered.
				|
				|Information for administrator:%2'; 
				|es_ES = 'Cannot determine a data source of the %1 check rule.
				|It might be corrupt and cannot be recovered.
				|
				|Information for administrator:%2'"), 
				CheckToDisableRef, DetailErrorDescription(ErrorInfo()));
			
			WriteLogEvent(
				InfobaseUpdate.EventLogEvent(),
				EventLogLevel.Warning,
				MetadataObject,
				CheckToDisableRef,
				Comment);
				
			EndTry;
			
	EndDo;
	
	If Not InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName) Then
		ProcessingCompleted = False;
	EndIf;
	
	If ObjectsProcessed = 0 AND ObjectsWithIssuesCount <> 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Процедуре Справочник.ПравилаПроверкиУчета.ОбработатьДанныеДляПереходаНаНовуюВерсию не удалось обработать некоторые записи проблемных объектов (пропущены): %1'; en = 'The Catalog.AccountingCheckRules.ProcessDataForMigrationToNewVersion procedure cannot process some records of objects with issues (skipped): %1'; pl = 'The Catalog.AccountingCheckRules.ProcessDataForMigrationToNewVersion procedure cannot process some records of objects with issues (skipped): %1';de = 'The Catalog.AccountingCheckRules.ProcessDataForMigrationToNewVersion procedure cannot process some records of objects with issues (skipped): %1';ro = 'The Catalog.AccountingCheckRules.ProcessDataForMigrationToNewVersion procedure cannot process some records of objects with issues (skipped): %1';tr = 'The Catalog.AccountingCheckRules.ProcessDataForMigrationToNewVersion procedure cannot process some records of objects with issues (skipped): %1'; es_ES = 'The Catalog.AccountingCheckRules.ProcessDataForMigrationToNewVersion procedure cannot process some records of objects with issues (skipped): %1'"), 
			ObjectsWithIssuesCount);
		Raise MessageText;
	Else
		WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Information,
		, ,
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Процедура Справочник.ПравилаПроверкиУчета.ОбработатьДанныеДляПереходаНаНовуюВерсию обработала очередную порцию проблемных объектов: %1'; en = 'The Catalog.AccountingCheckRules.ProcessDataForMigrationToNewVersion procedure processed the next portion of objects with issues: %1'; pl = 'The Catalog.AccountingCheckRules.ProcessDataForMigrationToNewVersion procedure processed the next portion of objects with issues: %1';de = 'The Catalog.AccountingCheckRules.ProcessDataForMigrationToNewVersion procedure processed the next portion of objects with issues: %1';ro = 'The Catalog.AccountingCheckRules.ProcessDataForMigrationToNewVersion procedure processed the next portion of objects with issues: %1';tr = 'The Catalog.AccountingCheckRules.ProcessDataForMigrationToNewVersion procedure processed the next portion of objects with issues: %1'; es_ES = 'The Catalog.AccountingCheckRules.ProcessDataForMigrationToNewVersion procedure processed the next portion of objects with issues: %1'"),
			ObjectsProcessed));
	EndIf;
	
	Parameters.ProcessingCompleted = ProcessingCompleted;
	
EndProcedure

#EndRegion

#EndIf