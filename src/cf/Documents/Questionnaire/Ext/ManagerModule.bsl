///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region ForCallsFromOtherSubsystems

// StandardSubsystems.BatchObjectsModification

// Returns object attributes allowed to be edited using batch attribute change data processor.
// 
//
// Returns:
//  Array - a list of object attribute names.
Function AttributesToEditInBatchProcessing() Export
	
	Result = New Array;
	Result.Add("Respondent");
	Result.Add("ModificationDate");
	Result.Add("Comment");
	Return Result;
	
EndFunction

// End StandardSubsystems.BatchObjectsModification

#EndRegion

#EndRegion

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// Update handlers.

// Registers the objects to be updated to the latest version in the InfobaseUpdate exchange plan.
// 
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	Questionnaire.Ref
		|FROM
		|	Document.Questionnaire AS Questionnaire
		|WHERE
		|	Questionnaire.SurveyMode = &EmptyRef
		|
		|ORDER BY
		|	Questionnaire.Date DESC";
	Query.Parameters.Insert("EmptyRef", Enums.SurveyModes.EmptyRef());
	
	Result = Query.Execute().Unload();
	RefsArray = Result.UnloadColumn("Ref");
	
	InfobaseUpdate.MarkForProcessing(Parameters, RefsArray);
	
EndProcedure

// Fill in a value of the new SurveyMode attribute in the Questionnaire document.
// 
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	Selection = InfobaseUpdate.SelectRefsToProcess(Parameters.Queue, "Document.Questionnaire");
	
	ObjectsWithIssuesCount = 0;
	ObjectsProcessed = 0;
	
	While Selection.Next() Do
		
		Try
			
			FillSurveyModeAttribute(Selection);
			ObjectsProcessed = ObjectsProcessed + 1;
			
		Except
			// If the questionnaire cannot be processed, try again.
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось обработать анкету: %1 по причине:
					|%2'; 
					|en = 'Cannot process the questionnaire: %1 due to:
					|%2'; 
					|pl = 'Cannot process the questionnaire: %1 due to:
					|%2';
					|de = 'Cannot process the questionnaire: %1 due to:
					|%2';
					|ro = 'Cannot process the questionnaire: %1 due to:
					|%2';
					|tr = 'Cannot process the questionnaire: %1 due to:
					|%2'; 
					|es_ES = 'Cannot process the questionnaire: %1 due to:
					|%2'"), 
					Selection.Ref, DetailErrorDescription(ErrorInfo()));
			WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Warning,
				Metadata.Documents.Questionnaire, Selection.Ref, MessageText);
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, "Document.Questionnaire");
	If ObjectsProcessed = 0 AND ObjectsWithIssuesCount <> 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Процедуре ЗаполнитьРеквизитРежимАнкетирования не удалось обработать некоторые анкеты (пропущены): %1'; en = 'The FillSurveyModeAttribute procedure cannot process some questionnaires (skipped): %1'; pl = 'The FillSurveyModeAttribute procedure cannot process some questionnaires (skipped): %1';de = 'The FillSurveyModeAttribute procedure cannot process some questionnaires (skipped): %1';ro = 'The FillSurveyModeAttribute procedure cannot process some questionnaires (skipped): %1';tr = 'The FillSurveyModeAttribute procedure cannot process some questionnaires (skipped): %1'; es_ES = 'The FillSurveyModeAttribute procedure cannot process some questionnaires (skipped): %1'"), 
				ObjectsWithIssuesCount);
		Raise MessageText;
	Else
		WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Information,
			Metadata.Documents.Questionnaire,,
				StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Процедура ЗаполнитьРеквизитРежимАнкетирования обработала очередную порцию анкет: %1'; en = 'The FillSurveyModeAttribute procedure has processed questionnaires: %1'; pl = 'The FillSurveyModeAttribute procedure has processed questionnaires: %1';de = 'The FillSurveyModeAttribute procedure has processed questionnaires: %1';ro = 'The FillSurveyModeAttribute procedure has processed questionnaires: %1';tr = 'The FillSurveyModeAttribute procedure has processed questionnaires: %1'; es_ES = 'The FillSurveyModeAttribute procedure has processed questionnaires: %1'"),
					ObjectsProcessed));
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Fills a value of the new SurveyMode attribute in the passed document.
//
Procedure FillSurveyModeAttribute(Selection)
	
	BeginTransaction();
	Try
	
		// Locking the object for changes by other sessions.
		Lock = New DataLock;
		LockItem = Lock.Add("Document.Questionnaire");
		LockItem.SetValue("Ref", Selection.Ref);
		Lock.Lock();
		
		DocumentObject = Selection.Ref.GetObject();
		
		// Ignore the object if it was previously deleted or processed by other sessions.
		If DocumentObject = Undefined Then
			RollbackTransaction();
			Return;
		EndIf;
		If DocumentObject.SurveyMode <> Enums.SurveyModes.EmptyRef() Then
			RollbackTransaction();
			Return;
		EndIf;
		
		// Object processing.
		DocumentObject.SurveyMode = Enums.SurveyModes.Questionnaire;
		
		// Processed object record.
		InfobaseUpdate.WriteData(DocumentObject);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

#EndRegion

#EndIf