///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

Procedure CreateRecord(StatisticsOperation, StatisticsComment) Export
	BeginTransaction();
	Try
		Lock = New DataLock;
		LockItem = Lock.Add("InformationRegister.StatisticsOperationComments");
		LockItem.SetValue("OperationID", StatisticsOperation);
		LockItem.SetValue("CommentID", StatisticsComment);
		Lock.Lock();
		
		If NOT IsRecord(StatisticsOperation, StatisticsComment) Then
			RecordSet = CreateRecordSet();
			NewRecord = RecordSet.Add();
			NewRecord.OperationID = StatisticsOperation; 
			NewRecord.CommentID = StatisticsComment;
			
			RecordSet.DataExchange.Load = True;
			RecordSet.Write(False);
		EndIf;
				
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
EndProcedure

Function IsRecord(StatisticsOperation, StatisticsComment)
	Query = New Query;
	Query.Text = 
		"SELECT
		|	COUNT(*) AS RecordsCount
		|FROM
		|	InformationRegister.StatisticsOperationComments AS StatisticsOperationComments
		|WHERE
		|	StatisticsOperationComments.OperationID = &OperationID
		|	AND StatisticsOperationComments.CommentID = &CommentID
		|";
	
	Query.SetParameter("CommentID", StatisticsComment);
	Query.SetParameter("OperationID", StatisticsOperation);
	
	QueryResult = Query.Execute();
	
	DetailedRecordsSelection = QueryResult.Select();
	DetailedRecordsSelection.Next();
	
	If DetailedRecordsSelection.RecordsCount = 0 Then
		Return False;
	Else
		Return True;
	EndIf;
EndFunction

#EndRegion

#EndIf