///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Returns references to nodes that have a smaller position in queue than the passed one.
//
// Parameters:
//  PositionInQueue	 - Number - the queue position of the data processor.
// 
// Returns:
// 	Array - an array of the following values:
//		* ExchangePlanRef.InfobaseUpdate
//
Function EarlierQueueNodes(Queue) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	InfobaseUpdate.Ref AS Ref
	|FROM
	|	ExchangePlan.InfobaseUpdate AS InfobaseUpdate
	|WHERE
	|	InfobaseUpdate.Queue < &Queue
	|	AND NOT InfobaseUpdate.ThisNode
	|	AND InfobaseUpdate.Queue <> 0";
	
	Query.SetParameter("Queue", Queue);
	
	Return Query.Execute().Unload().UnloadColumn("Ref");
	
EndFunction

// Searches for the exchange plan node by its queue and returns a reference to it.
// If there is no node, it will be created.
//
// Parameters:
//  PositionInQueue	 - Number - the queue position of the data processor.
// 
// Returns:
//  ExchangePlanRef.InfobaseUpdate.
//
Function NodeInQueue(Queue) Export
	
	If TypeOf(Queue) <> Type("Number") Or Queue = 0 Then
		Raise NStr("ru = 'Невозможно получить узел плана обмена ОбновлениеИнформационнойБазы, т.к. не передан номер очереди.'; en = 'Cannot get the node of InfobaseUpdate exchange plan because the position in queue is not provided.'; pl = 'Nie można uzyskać węzła planu wymiany InfobaseUpdate, ponieważ Nr kolejki nie został przekazany.';de = 'Es ist nicht möglich, den Knoten InfoBaseUpdate des Austauschplans zu erhalten, da die Warteschlangennummer nicht übertragen wurde.';ro = 'Nu puteți obține nodul planului de schimb InfobaseUpdate, deoarece nu este transmis numărul rândului de așteptare.';tr = 'Sıra numarası verilmediği için InfobaseUpdate alışveriş planın ünitesi elde edilemez.'; es_ES = 'Es imposible recibir el nodo del plan de cambio InfobaseUpdate, porque no ha sido transmitido el número de cola.'");
	EndIf;
	
	Query = New Query(
		"SELECT
		|	InfobaseUpdate.Ref AS Ref
		|FROM
		|	ExchangePlan.InfobaseUpdate AS InfobaseUpdate
		|WHERE
		|	InfobaseUpdate.Queue = &Queue
		|	AND NOT InfobaseUpdate.ThisNode");
	Query.SetParameter("Queue", Queue);
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		Node = Selection.Ref;
	Else
		BeginTransaction();
		
		Try
			Locks = New DataLock;
			Lock = Locks.Add("ExchangePlan.InfobaseUpdate");
			Lock.SetValue("Queue", Queue);
			Locks.Lock();
			
			Selection = Query.Execute().Select();
			
			If Selection.Next() Then
				Node = Selection.Ref;
			Else
				QueueString = String(Queue);
				ObjectNode = CreateNode();
				ObjectNode.Queue = Queue;
				ObjectNode.SetNewCode(QueueString);
				ObjectNode.Description = QueueString;
				ObjectNode.Write();
				Node = ObjectNode.Ref;
			EndIf;
			
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	EndIf;
	
	Return Node;
	
EndFunction

#EndRegion

#EndIf