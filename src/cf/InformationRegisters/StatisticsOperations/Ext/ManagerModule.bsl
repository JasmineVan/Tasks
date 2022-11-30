///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

Function GetRef(Description) Export
	DataHashing = New DataHashing(HashFunction.SHA1);
	DataHashing.Append(Description);
	DescriptionHash = StrReplace(String(DataHashing.HashSum), " ", "");
	
	Ref = FindByHash(DescriptionHash);
	If Ref = Undefined Then
		Ref = CreateNew(Description, DescriptionHash);
	EndIf;
	
	Return Ref;
EndFunction

Function FindByHash(Hash)
	Query = New Query;
	Query.Text = "
	|SELECT TOP 1
	|	StatisticsOperations.OperationID
	|FROM
	|	InformationRegister.StatisticsOperations AS StatisticsOperations
	|WHERE
	|	StatisticsOperations.DescriptionHash = &DescriptionHash
	|";
	Query.SetParameter("DescriptionHash", Hash);
    
    SetPrivilegedMode(True);
	Result = Query.Execute();
    SetPrivilegedMode(False);
    
	If Result.IsEmpty() Then
		Ref = Undefined;
	Else
		Selection = Result.Select();
		Selection.Next();
		
		Ref = Selection.OperationID;
	EndIf;
	
	Return Ref;
EndFunction

Function CreateNew(Description, DescriptionHash)
	BeginTransaction();
	
	Try
		Lock = New DataLock;
		LockItem = Lock.Add("InformationRegister.StatisticsOperations");
		LockItem.SetValue("DescriptionHash", DescriptionHash);
		Lock.Lock();
		
		Ref = FindByHash(DescriptionHash);
		
		If Ref = Undefined Then
			Ref = New UUID();
			
			RecordSet = CreateRecordSet();
			RecordSet.DataExchange.Load = True;
			NewRecord = RecordSet.Add();
			NewRecord.DescriptionHash = DescriptionHash;
			NewRecord.OperationID = Ref;
			NewRecord.Description = Description;
            
            SetPrivilegedMode(True);
			RecordSet.Write(False);
            SetPrivilegedMode(False);
            
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Return Ref;
EndFunction

Function NewCommentPossible(RefOperation) Export
	UniqueMaxCount = 100;
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	StatisticsOperations.UniqueCommentsCount AS UniqueValueCount
		|FROM
		|	InformationRegister.StatisticsOperations AS StatisticsOperations
		|WHERE
		|	StatisticsOperations.OperationID = &OperationID";
		
	Query.SetParameter("OperationID", RefOperation);	
	QueryResult = Query.Execute();
	
	DetailedRecordsSelection = QueryResult.Select();
	DetailedRecordsSelection.Next();
	UniqueValueCount = DetailedRecordsSelection.UniqueValueCount;
	
	If UniqueValueCount < UniqueMaxCount Then
		NewCommentPossible = True;
	Else
		NewCommentPossible = False;
	EndIf;
	
	Return NewCommentPossible;
EndFunction

Procedure IncreaseUniqueCommentsCount(RefOperation, RefComment) Export
	RecordSet = CreateRecordSet();
	RecordSet.Filter.OperationID.Set(RefOperation);
	RecordSet.Read();
	For Each CurRecord In RecordSet Do
		CurRecord.UniqueCommentsCount = CurRecord.UniqueCommentsCount + 1;
	EndDo;
	RecordSet.Write(True);
	
	InformationRegisters.StatisticsOperationComments.CreateRecord(RefOperation, RefComment); 
EndProcedure

#EndRegion

#EndIf