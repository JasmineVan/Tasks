﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// For internal use.
//
Procedure MapObjects(Parameters, TempStorageAddress) Export
	
	PutToTempStorage(ObjectMappingResult(Parameters), TempStorageAddress);
	
EndProcedure

// For internal use.
//
Procedure ExecuteAutomaticObjectMapping(Parameters, TempStorageAddress) Export
	
	PutToTempStorage(AutomaticObjectMappingResult(Parameters), TempStorageAddress);
	
EndProcedure

#EndRegion

#Region Private
// For internal use.
//
Function ObjectMappingResult(Parameters)
	
	ObjectMapping = Create();
	DataExchangeServer.ImportObjectContext(Parameters.ObjectContext, ObjectMapping);
	
	Cancel = False;
	
	// Applying the table of unapproved mapping items to the database.
	If Parameters.FormAttributes.UnapprovedRecordTableApplyOnly Then
		
		ObjectMapping.ApplyUnapprovedRecordsTable(Cancel);
		
		If Cancel Then
			Raise NStr("ru = 'Возникли ошибки в процессе сопоставления объектов.'; en = 'Errors occurred during object mapping.'; pl = 'Wystąpiły błędy podczas mapowania obiektów.';de = 'Beim Zuordnen von Objekten sind Fehler aufgetreten.';ro = 'În procesul de confruntare a obiectelor s-au produs erori.';tr = 'Nesneleri eşlerken hatalar oluştu.'; es_ES = 'Errores ocurridos al mapear los objetos.'");
		EndIf;
		
		Return Undefined;
	EndIf;
	
	// Applying automatic object mapping result obtained by the user.
	If Parameters.FormAttributes.ApplyAutomaticMappingResult Then
		
		// Adding rows to the table of unapproved mapping items
		For Each TableRow In Parameters.AutomaticallyMappedObjectsTable Do
			
			FillPropertyValues(ObjectMapping.UnapprovedMappingTable.Add(), TableRow);
			
		EndDo;
		
	EndIf;
	
	// Applying the table of unapproved mapping items to the database.
	If Parameters.FormAttributes.ApplyUnapprovedRecordsTable Then
		
		ObjectMapping.ApplyUnapprovedRecordsTable(Cancel);
		
		If Cancel Then
			Raise NStr("ru = 'Возникли ошибки в процессе сопоставления объектов.'; en = 'Errors occurred during object mapping.'; pl = 'Wystąpiły błędy podczas mapowania obiektów.';de = 'Beim Zuordnen von Objekten sind Fehler aufgetreten.';ro = 'În procesul de confruntare a obiectelor s-au produs erori.';tr = 'Nesneleri eşlerken hatalar oluştu.'; es_ES = 'Errores ocurridos al mapear los objetos.'");
		EndIf;
		
	EndIf;
	
	// Generating mapping table.
	ObjectMapping.MapObjects(Cancel);
	
	If Cancel Then
		Raise NStr("ru = 'Возникли ошибки в процессе сопоставления объектов.'; en = 'Errors occurred during object mapping.'; pl = 'Wystąpiły błędy podczas mapowania obiektów.';de = 'Beim Zuordnen von Objekten sind Fehler aufgetreten.';ro = 'În procesul de confruntare a obiectelor s-au produs erori.';tr = 'Nesneleri eşlerken hatalar oluştu.'; es_ES = 'Errores ocurridos al mapear los objetos.'");
	EndIf;
	
	Result = New Structure;
	Result.Insert("ObjectCountInSource",       ObjectMapping.ObjectCountInSource());
	Result.Insert("ObjectCountInDestination",       ObjectMapping.ObjectCountInDestination());
	Result.Insert("MappedObjectCount",   ObjectMapping.MappedObjectCount());
	Result.Insert("UnmappedObjectCount", ObjectMapping.UnmappedObjectCount());
	Result.Insert("MappedObjectPercentage",       ObjectMapping.MappedObjectPercentage());
	Result.Insert("MappingTable",               ObjectMapping.MappingTable());
	
	Result.Insert("ObjectContext", DataExchangeServer.GetObjectContext(ObjectMapping));
	
	Return Result;
EndFunction

// For internal use.
//
Function AutomaticObjectMappingResult(Parameters)
	
	ObjectMapping = Create();
	DataExchangeServer.ImportObjectContext(Parameters.ObjectContext, ObjectMapping);
	
	// Defining the UsedFieldList property.
	ObjectMapping.UsedFieldsList.Clear();
	CommonClientServer.SupplementTable(Parameters.FormAttributes.UsedFieldsList, ObjectMapping.UsedFieldsList);
	
	// Defining the TableFieldList property
	ObjectMapping.TableFieldsList.Clear();
	CommonClientServer.SupplementTable(Parameters.FormAttributes.TableFieldsList, ObjectMapping.TableFieldsList);
	
	// Loading the table of unapproved mapping items
	ObjectMapping.UnapprovedMappingTable.Load(Parameters.UnapprovedMappingTable);
	
	Cancel = False;
	
	// Receiving the automatic object mapping table.
	ObjectMapping.ExecuteAutomaticObjectMapping(Cancel, Parameters.FormAttributes.MappingFieldsList);
	
	If Cancel Then
		Raise NStr("ru = 'Возникли ошибки в процессе автоматического сопоставления объектов.'; en = 'Errors occurred during automatic object mapping.'; pl = 'Wystąpiły błędy podczas automatycznego mapowania obiektów.';de = 'Beim automatischen Zuordnen von Objekten sind Fehler aufgetreten.';ro = 'În procesul de confruntare automată a obiectelor s-au produs erori.';tr = 'Nesneleri otomatik olarak eşleştirirken hatalar oluştu.'; es_ES = 'Errores ocurridos al mapear los objetos automáticamente.'");
	EndIf;
	
	Result = New Structure;
	Result.Insert("EmptyResult", ObjectMapping.AutomaticallyMappedObjectsTable.Count() = 0);
	Result.Insert("ObjectContext", DataExchangeServer.GetObjectContext(ObjectMapping));
	
	Return Result;
EndFunction

#EndRegion

#EndIf
