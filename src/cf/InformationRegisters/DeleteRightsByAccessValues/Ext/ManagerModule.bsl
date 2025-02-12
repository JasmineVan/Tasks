﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// The infobase update handler.
Procedure MoveDataToNewRegister() Export
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	TRUE AS TrueValue
	|FROM
	|	InformationRegister.ObjectsRightsSettings AS RightsByAccessValues
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DeleteRightsByAccessValues.AccessValue AS Object,
	|	DeleteRightsByAccessValues.User,
	|	DeleteRightsByAccessValues.Right,
	|	MAX(DeleteRightsByAccessValues.Denied) AS RightIsProhibited,
	|	MAX(DeleteRightsByAccessValues.DistributedByHierarchy) AS InheritanceIsAllowed
	|FROM
	|	InformationRegister.DeleteRightsByAccessValues AS DeleteRightsByAccessValues
	|
	|GROUP BY
	|	DeleteRightsByAccessValues.AccessValue,
	|	DeleteRightsByAccessValues.User,
	|	DeleteRightsByAccessValues.Right";
	
	Lock = New DataLock;
	Lock.Add("InformationRegister.ObjectsRightsSettings");
	Lock.Add("InformationRegister.DeleteRightsByAccessValues");
	
	BeginTransaction();
	Try
		Lock.Lock();
		QueryResults = Query.ExecuteBatch();
		
		If QueryResults[0].IsEmpty()
		   AND NOT QueryResults[1].IsEmpty() Then
			
			RecordSet = InformationRegisters.ObjectsRightsSettings.CreateRecordSet();
			RecordSet.Load(QueryResults[1].Unload());
			RecordSet.Write();
			
			RecordSet = CreateRecordSet();
			RecordSet.Write();
			
			InformationRegisters.ObjectsRightsSettings.UpdateAuxiliaryRegisterData();
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

#EndRegion

#EndIf