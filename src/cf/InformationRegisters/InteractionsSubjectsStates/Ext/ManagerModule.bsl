///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// Deletes one record or all records from the register.
//
// Parameters:
//  Subject - DocumentRef, CatalogRef, Undefined - a subject, for which the record is being deleted.
//                                                              If the Undefined value is specified, 
//                                                              the register will be cleared.
//
Procedure DeleteRecordFromRegister(Topic = Undefined) Export
	
	SetPrivilegedMode(True);
	
	RecordSet = CreateRecordSet();
	If Topic <> Undefined Then
		RecordSet.Filter.Topic.Set(Topic);
	EndIf;
	
	RecordSet.Write();
	
EndProcedure

// Writes to the information register for the specified subject.
//
// Parameters:
//  Subject                       - DocumentRef, CatalogRef - a subject to be recorded.
//  NotReviewedInteractionsCount       - Number - a number of unreviewed interactions for the subject.
//  LastInteractionDate - DateTime - a date of last interaction on the subject.
//  Active                         - Boolean - indicates that the subject is active.
//
Procedure ExecuteRecordToRegister(Topic,
	                              NotReviewedInteractionsCount = Undefined,
	                              LastInteractionDate = Undefined,
	                              Active = Undefined) Export
	
	SetPrivilegedMode(True);
	
	If NotReviewedInteractionsCount = Undefined AND LastInteractionDate = Undefined AND Active = Undefined Then
		
		Return;
		
	ElsIf NotReviewedInteractionsCount = Undefined OR LastInteractionDate = Undefined OR Active = Undefined Then
		
		Query = New Query;
		Query.Text = "
		|SELECT
		|	InteractionsSubjectsStates.Topic,
		|	InteractionsSubjectsStates.NotReviewedInteractionsCount,
		|	InteractionsSubjectsStates.LastInteractionDate,
		|	InteractionsSubjectsStates.IsActive
		|FROM
		|	InformationRegister.InteractionsSubjectsStates AS InteractionsSubjectsStates
		|WHERE
		|	InteractionsSubjectsStates.Topic = &Topic";
		
		Query.SetParameter("Topic",Topic);
		
		Result = Query.Execute();
		If NOT Result.IsEmpty() Then
			
			Selection = Result.Select();
			Selection.Next();
			
			If NotReviewedInteractionsCount = Undefined Then
				NotReviewedInteractionsCount = Selection.NotReviewedInteractionsCount;
			EndIf;
			
			If LastInteractionDate = Undefined Then
				LastInteractionDate = LastInteractionDate.Topic;
			EndIf;
			
			If Active = Undefined Then
				Active = Selection.IsActive;
			EndIf;
			
		EndIf;
	EndIf;

	RecordSet = CreateRecordSet();
	RecordSet.Filter.Topic.Set(Topic);
	
	Record = RecordSet.Add();
	Record.Topic                      = Topic;
	Record.NotReviewedInteractionsCount      = NotReviewedInteractionsCount;
	Record.LastInteractionDate = LastInteractionDate;
	Record.IsActive                      = Active;
	RecordSet.Write();

EndProcedure

#Region UpdateHandlers

// Infobase update procedure for SSL 2.2.
// Performs initial calculations of interaction subject states.
//
//
// Parameters:
//  Parameter - Structure - execution parameters of the current update handler batch.
//
Procedure CalculateInteractionSubjectStatuses_2_2_0_0(Parameters) Export
	
	Query = New Query;
	Query.Text = "
	|SELECT DISTINCT TOP 1000
	|	InteractionsFolderSubjects.Topic
	|INTO SubjectsForCalculation
	|FROM
	|	InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
	|		LEFT JOIN InformationRegister.InteractionsSubjectsStates AS InteractionsSubjectsStates
	|		ON (InteractionsSubjectsStates.Topic = InteractionsFolderSubjects.Topic)
	|WHERE
	|	InteractionsSubjectsStates.Topic IS NULL 
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InteractionsFolderSubjects.Topic,
	|	SUM(CASE
	|			WHEN NOT InteractionsFolderSubjects.Reviewed
	|				THEN 1
	|			ELSE 0
	|		END) AS NotReviewedInteractionsCount,
	|	MAX(Interactions.Date) AS LastInteractionDate,
	|	CASE
	|		WHEN Delete_ActiveInteractionObjects.Topic IS NULL 
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS IsActive
	|FROM
	|	SubjectsForCalculation AS SubjectsForCalculation
	|		INNER JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
	|			INNER JOIN DocumentJournal.Interactions AS Interactions
	|			ON InteractionsFolderSubjects.Interaction = Interactions.Ref
	|			LEFT JOIN InformationRegister.Delete_ActiveInteractionObjects AS Delete_ActiveInteractionObjects
	|			ON InteractionsFolderSubjects.EmailMessageFolder = Delete_ActiveInteractionObjects.Topic
	|		ON SubjectsForCalculation.Topic = InteractionsFolderSubjects.Topic
	|
	|GROUP BY
	|	InteractionsFolderSubjects.Topic,
	|	CASE
	|		WHEN Delete_ActiveInteractionObjects.Topic IS NULL 
	|			THEN FALSE
	|		ELSE TRUE
	|	END";
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = Result.Select();
	While Selection.Next() Do
		
		RecordSet = CreateRecordSet();
		RecordSet.Filter.Topic.Set(Selection.Topic);
		Record = RecordSet.Add();
		Record.Topic = Selection.Topic;
		Record.NotReviewedInteractionsCount = Selection.NotReviewedInteractionsCount;
		Record.LastInteractionDate = Selection.LastInteractionDate;
		Record.IsActive = Selection.IsActive;
		InfobaseUpdate.WriteData(RecordSet);
		
	EndDo;
	
	Parameters.ProcessingCompleted = (Selection.Count() = 0);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf