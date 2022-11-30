///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

Function SelectChanges(Val Node, Val MessageNumber) Export
	
	If TransactionActive() Then
		Raise NStr("ru = 'Выборка изменений данных запрещена в активной транзакции.'; en = 'Cannot select data changes in an active transaction.'; pl = 'Wybór zmiany danych jest zabroniony dla aktywnej transakcji.';de = 'Die Auswahl der Datenänderung ist in einer aktiven Transaktion verboten.';ro = 'Selectarea modificărilor datelor este interzisă în tranzacție activă.';tr = 'Etkin bir işlemde veri değişikliği seçimi yasaktır.'; es_ES = 'Selección de cambio de datos está prohibida en una transacción activa.'");
	EndIf;
	
	Result = New Array;
	
	BeginTransaction();
	Try
		
		Lock = New DataLock;
		LockItem = Lock.Add("InformationRegister.CommonNodeDataChanges");
		LockItem.SetValue("InfobaseNode", Node);
		Lock.Lock();
		
		QueryText =
		"SELECT
		|	CommonNodeDataChanges.InfobaseNode AS Node,
		|	CommonNodeDataChanges.MessageNo AS MessageNo
		|FROM
		|	InformationRegister.CommonNodeDataChanges AS CommonNodeDataChanges
		|WHERE
		|	CommonNodeDataChanges.InfobaseNode = &Node";
		
		Query = New Query;
		Query.SetParameter("Node", Node);
		Query.Text = QueryText;
		
		Selection = Query.Execute().Select();
		
		If Selection.Next() Then
			
			Result.Add(Selection.Node);
			
			If Selection.MessageNo = 0 Then
				
				RecordStructure = New Structure;
				RecordStructure.Insert("InfobaseNode", Node);
				RecordStructure.Insert("MessageNo", MessageNumber);
				AddRecord(RecordStructure);
				
			EndIf;
			
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Return Result;
EndFunction

Procedure RecordChanges(Val Node) Export
	
	BeginTransaction();
	Try
		
		Lock = New DataLock;
		LockItem = Lock.Add("InformationRegister.CommonNodeDataChanges");
		LockItem.SetValue("InfobaseNode", Node);
		Lock.Lock();
		
		RecordStructure = New Structure;
		RecordStructure.Insert("InfobaseNode", Node);
		RecordStructure.Insert("MessageNo", 0);
		AddRecord(RecordStructure);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

Procedure DeleteChangeRecords(Val Node, Val MessageNumber = Undefined) Export
	
	BeginTransaction();
	Try
		
		Lock = New DataLock;
		LockItem = Lock.Add("InformationRegister.CommonNodeDataChanges");
		LockItem.SetValue("InfobaseNode", Node);
		Lock.Lock();
		
		If MessageNumber = Undefined Then
			
			QueryText =
			"SELECT
			|	1 AS Field1
			|FROM
			|	InformationRegister.CommonNodeDataChanges AS CommonNodeDataChanges
			|WHERE
			|	CommonNodeDataChanges.InfobaseNode = &Node";
			
		Else
			
			QueryText =
			"SELECT
			|	1 AS Field1
			|FROM
			|	InformationRegister.CommonNodeDataChanges AS CommonNodeDataChanges
			|WHERE
			|	CommonNodeDataChanges.InfobaseNode = &Node
			|	AND CommonNodeDataChanges.MessageNo <= &MessageNo
			|	AND CommonNodeDataChanges.MessageNo <> 0";
			
		EndIf;
		
		Query = New Query;
		Query.SetParameter("Node", Node);
		Query.SetParameter("MessageNo", MessageNumber);
		Query.Text = QueryText;
		
		If Not Query.Execute().IsEmpty() Then
			
			RecordStructure = New Structure;
			RecordStructure.Insert("InfobaseNode", Node);
			DeleteRecord(RecordStructure);
			
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Adds a record to the register by the passed structure values.
Procedure AddRecord(RecordStructure)
	
	DataExchangeServer.AddRecordToInformationRegister(RecordStructure, "CommonNodeDataChanges");
	
EndProcedure

// Deletes a register record set based on the passed structure values.
Procedure DeleteRecord(RecordStructure)
	
	DataExchangeServer.DeleteRecordSetFromInformationRegister(RecordStructure, "CommonNodeDataChanges");
	
EndProcedure

#EndRegion

#EndIf