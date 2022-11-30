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
//  Folder - Catalog.EmailsFolders, Undefined - a folder, for which the record is being deleted.
//          If the Undefined value is specified, the register will be cleared.
//
Procedure DeleteRecordFromRegister(Folder = Undefined) Export
	
	SetPrivilegedMode(True);
	
	RecordSet = CreateRecordSet();
	If Folder <> Undefined Then
		RecordSet.Filter.Folder.Set(Folder);
	EndIf;
	
	RecordSet.Write();
	
EndProcedure

// Writes to the information register for the specified folder.
//
// Parameters:
//  Folder - Catalog.EmailsFolders - a folder to be recorded.
//  Count  - Number - a number of unreviewed interactions for this folder.
//
Procedure ExecuteRecordToRegister(Folder, Count) Export

	SetPrivilegedMode(True);
	
	Record = CreateRecordManager();
	Record.Folder = Folder;
	Record.NotReviewedInteractionsCount = Count;
	Record.Write(True);

EndProcedure

#Region UpdateHandlers

// Infobase update procedure for SSL 2.2.
// Performs initial calculations of interaction folder states.
//
Procedure CalculateEmailFolderStatuses_2_2_0_0(Parameters) Export
	
	Query = New Query;
	Query.Text = "
	|SELECT DISTINCT
	|	InteractionsFolderSubjects.EmailMessageFolder AS EmailMessageFolder,
	|	SUM(CASE
	|			WHEN InteractionsFolderSubjects.Reviewed
	|				THEN 0
	|			ELSE 1
	|		END) AS NotReviewedInteractionsCount
	|INTO FoldersToUse
	|FROM
	|	InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
	|WHERE
	|	InteractionsFolderSubjects.EmailMessageFolder <> VALUE(Catalog.EmailMessageFolders.EmptyRef)
	|
	|GROUP BY
	|	InteractionsFolderSubjects.EmailMessageFolder
	|
	|INDEX BY
	|	EmailMessageFolder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	EmailMessageFolders.Ref AS EmailMessageFolder,
	|	ISNULL(FoldersToUse.NotReviewedInteractionsCount, 0) AS NotReviewedInteractionsCount
	|FROM
	|	Catalog.EmailMessageFolders AS EmailMessageFolders
	|		LEFT JOIN FoldersToUse AS FoldersToUse
	|		ON (FoldersToUse.EmailMessageFolder = EmailMessageFolders.Ref)";
	
	Selection = Query.Execute().Select();

	While Selection.Next() Do
		
		RecordSet = CreateRecordSet();
		RecordSet.Filter.Folder.Set(Selection.EmailMessageFolder);
		Record = RecordSet.Add();
		Record.Folder = Selection.EmailMessageFolder;
		Record.NotReviewedInteractionsCount = Selection.NotReviewedInteractionsCount;
		InfobaseUpdate.WriteData(RecordSet);
	
	EndDo;
	
	Parameters.ProcessingCompleted = True;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf