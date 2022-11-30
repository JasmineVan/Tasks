///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// Adds a record to the register by the passed structure values.
Procedure AddRecord(RecordStructure, Import = False) Export
	
	DataExchangeServer.AddRecordToInformationRegister(RecordStructure, "SynchronizedObjectPublicIDs", Import);
	
EndProcedure

Function RecordIsInRegister(RecordStructure) Export
	
	Query = New Query(
	"SELECT TOP 1
	|	TRUE AS IsRecord
	|FROM
	|	InformationRegister.SynchronizedObjectPublicIDs AS PIR
	|WHERE
	|	PIR.InfobaseNode = &InfobaseNode
	|	AND PIR.Ref = &Ref");
	Query.SetParameter("InfobaseNode", RecordStructure.InfobaseNode);
	Query.SetParameter("Ref",                 RecordStructure.Ref);
	
	QueryResult = Query.Execute();
	
	Return Not QueryResult.IsEmpty();
	
EndFunction

// Deletes a register record set based on the passed structure values.
Procedure DeleteRecord(RecordStructure, Import = False) Export
	
	DataExchangeServer.DeleteRecordSetFromInformationRegister(RecordStructure, "SynchronizedObjectPublicIDs", Import);
	
EndProcedure

// Converts a reference to the current infobase object to string UUID presentation.
// If the SynchronizedObjectPublicIDs register has such a reference, UID from the register is returned.
// Otherwise UID of the passed reference is returned.
// 
// Parameters:
//  InfobaseNode - a reference to the exchange plan node to which data is exported.
//  ObjectRef - a reference to an infobase object, that requires a XDTO object UUID.
//                   
//
// Returns:
//  String - object UUID.
Function PublicIDByObjectRef(InfobaseNode, ObjectRef) Export
	
	SetPrivilegedMode(True);
	
	// Defining a public reference through an object reference.
	Query = New Query(
	"SELECT
	|	PIR.ID AS ID
	|FROM
	|	InformationRegister.SynchronizedObjectPublicIDs AS PIR
	|WHERE
	|	PIR.InfobaseNode = &InfobaseNode
	|	AND PIR.Ref = &Ref");
	Query.SetParameter("InfobaseNode", InfobaseNode);
	Query.SetParameter("Ref",                 ObjectRef);
	
	Selection = Query.Execute().Select();
	If Selection.Count() = 1 Then
		Selection.Next();
		Return TrimAll(Selection.ID);
	ElsIf Selection.Count() > 1 Then
		RecordStructure = New Structure();
		RecordStructure.Insert("InfobaseNode", InfobaseNode);
		RecordStructure.Insert("Ref",                 ObjectRef);
		DeleteRecord(RecordStructure, True);
	EndIf;
	
	Return TrimAll(ObjectRef.UUID());

EndFunction

#EndRegion

#EndIf