///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	CheckPriority(Cancel);
	If Cancel Then
		Return;
	EndIf;
	
	MD5Hash = New DataHashing(HashFunction.MD5);
	MD5Hash.Append(Name);
	NameHashTmp = MD5Hash.HashSum;
	NameHash = StrReplace(String(NameHashTmp), " ", "");
EndProcedure

#EndRegion

#Region Private

Procedure CheckPriority(Cancel)
	
	If AdditionalProperties.Property(PerformanceMonitorClientServer.DoNotCheckPriority()) Or Priority = 0 Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Priority", Priority);
	Query.SetParameter("Ref", Ref);
	Query.Text = 
	"SELECT TOP 1
	|	KeyOperations.Ref AS Ref,
	|	KeyOperations.Description AS Description
	|FROM
	|	Catalog.KeyOperations AS KeyOperations
	|WHERE
	|	KeyOperations.Priority = &Priority
	|	AND KeyOperations.Ref <> &Ref";
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		MessageText = NStr("ru = 'Ключевая операция с приоритетом ""%1"" уже существует (%2).'; en = 'Key operation priority %1 is not unique (%2 has the same priority).'; pl = 'Key operation priority %1 is not unique (%2 has the same priority).';de = 'Key operation priority %1 is not unique (%2 has the same priority).';ro = 'Key operation priority %1 is not unique (%2 has the same priority).';tr = 'Key operation priority %1 is not unique (%2 has the same priority).'; es_ES = 'Key operation priority %1 is not unique (%2 has the same priority).'");
		MessageText = StrReplace(MessageText, "%1", String(Priority));
		MessageText = StrReplace(MessageText, "%2", Selection.Description);
		PerformanceMonitorClientServer.WriteToEventLog(
			"Catalog.KeyOperations.ObjectModule.BeforeWrite",
			EventLogLevel.Error,
			MessageText);
		PerformanceMonitorInternal.MessageToUser(MessageText);
		Cancel = True;
	EndIf;
	
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Invalid object call on the client.';de = 'Invalid object call on the client.';ro = 'Invalid object call on the client.';tr = 'Invalid object call on the client.'; es_ES = 'Invalid object call on the client.'");
#EndIf