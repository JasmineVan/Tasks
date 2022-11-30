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
	
	If ValueIsFilled(PerformerRole) Then
		
		Description = String(PerformerRole);
		
		If ValueIsFilled(MainAddressingObject) Then
			Description = Description + ", " + String(MainAddressingObject);
		EndIf;
		
		If ValueIsFilled(AdditionalAddressingObject) Then
			Description = Description + ", " + String(AdditionalAddressingObject);
		EndIf;
	Else
		Description = NStr("ru = 'Без ролевой адресации'; en = 'Without role addressing'; pl = 'Without role addressing';de = 'Without role addressing';ro = 'Without role addressing';tr = 'Without role addressing'; es_ES = 'Without role addressing'");
	EndIf;
	
	// Checking for duplicates.
	Query = New Query(
		"SELECT TOP 1
		|	TaskPerformersGroups.Ref
		|FROM
		|	Catalog.TaskPerformersGroups AS TaskPerformersGroups
		|WHERE
		|	TaskPerformersGroups.PerformerRole = &PerformerRole
		|	AND TaskPerformersGroups.MainAddressingObject = &MainAddressingObject
		|	AND TaskPerformersGroups.AdditionalAddressingObject = &AdditionalAddressingObject
		|	AND TaskPerformersGroups.Ref <> &Ref");
	Query.SetParameter("PerformerRole", PerformerRole);
	Query.SetParameter("MainAddressingObject", MainAddressingObject);
	Query.SetParameter("AdditionalAddressingObject", AdditionalAddressingObject);
	Query.SetParameter("Ref", Ref);
	
	If NOT Query.Execute().IsEmpty() Then
		Raise(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Уже есть группа исполнителей задач, для которой заданы:
			           |роль исполнителя ""%1"",
			           |основной объект адресации ""%2""
			           |и дополнительный объект адресации ""%3""'; 
			           |en = 'There is already the task assignee group for which
			           |assignee role ""%1"",
			           |main addressing object ""%2"",
			           |and additional addressing object ""%3"" are set'; 
			           |pl = 'There is already the task assignee group for which
			           |assignee role ""%1"",
			           |main addressing object ""%2"",
			           |and additional addressing object ""%3"" are set';
			           |de = 'There is already the task assignee group for which
			           |assignee role ""%1"",
			           |main addressing object ""%2"",
			           |and additional addressing object ""%3"" are set';
			           |ro = 'There is already the task assignee group for which
			           |assignee role ""%1"",
			           |main addressing object ""%2"",
			           |and additional addressing object ""%3"" are set';
			           |tr = 'There is already the task assignee group for which
			           |assignee role ""%1"",
			           |main addressing object ""%2"",
			           |and additional addressing object ""%3"" are set'; 
			           |es_ES = 'There is already the task assignee group for which
			           |assignee role ""%1"",
			           |main addressing object ""%2"",
			           |and additional addressing object ""%3"" are set'"),
			String(PerformerRole),
			String(MainAddressingObject),
			String(AdditionalAddressingObject)));
	EndIf;
	
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Invalid object call on the client.';de = 'Invalid object call on the client.';ro = 'Invalid object call on the client.';tr = 'Invalid object call on the client.'; es_ES = 'Invalid object call on the client.'");
#EndIf