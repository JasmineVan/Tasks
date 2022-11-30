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
		|	QuestionsForSurvey.Ref
		|FROM
		|	ChartOfCharacteristicTypes.QuestionsForSurvey AS QuestionsForSurvey
		|WHERE
		|	(QuestionsForSurvey.RadioButtonType = VALUE(Enum.RadioButtonTypesInQuestionnaires.EmptyRef)
		|			OR QuestionsForSurvey.CheckBoxType = VALUE(Enum.CheckBoxKindsInQuestionnaires.EmptyRef))";
	Result = Query.Execute().Unload();
	RefsArray = Result.UnloadColumn("Ref");
	
	InfobaseUpdate.MarkForProcessing(Parameters, RefsArray);
	
EndProcedure

// Fill in a value of the new RadioButtonsType attribute for the the QuestionsForSurvey chart of characteristic types.
// 
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	Selection = InfobaseUpdate.SelectRefsToProcess(Parameters.Queue, "ChartOfCharacteristicTypes.QuestionsForSurvey");
	
	While Selection.Next() Do
		
		Try
			
			FillNewAttributes(Selection.Ref);
			
		Except
			// If an object cannot be processed, try again.
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось обработать вопрос для анкетирования: %1 по причине:
					|%2'; 
					|en = 'Cannot process the question for survey: %1 due to:
					|%2'; 
					|pl = 'Cannot process the question for survey: %1 due to:
					|%2';
					|de = 'Cannot process the question for survey: %1 due to:
					|%2';
					|ro = 'Cannot process the question for survey: %1 due to:
					|%2';
					|tr = 'Cannot process the question for survey: %1 due to:
					|%2'; 
					|es_ES = 'Cannot process the question for survey: %1 due to:
					|%2'"), 
					Selection.Ref, DetailErrorDescription(ErrorInfo()));
			WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Warning,
				Metadata.ChartsOfCharacteristicTypes.QuestionsForSurvey, Selection.Ref, MessageText);
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, "ChartOfCharacteristicTypes.QuestionsForSurvey");
	
EndProcedure

#EndRegion

#Region Private

// Fills in values of the new RadioButtonsType and CheckBoxType attributes for the passed object.
//
Procedure FillNewAttributes(QuestionForSurvey)
	
	BeginTransaction();
	Try
	
		// Locking the object for changes by other sessions.
		Lock = New DataLock;
		LockItem = Lock.Add("ChartOfCharacteristicTypes.QuestionsForSurvey");
		LockItem.SetValue("Ref", QuestionForSurvey);
		Lock.Lock();
		
		Object = QuestionForSurvey.GetObject();
		
		// Ignore the object if it was previously deleted or processed by other sessions.
		If Object = Undefined Then
			RollbackTransaction();
			Return;
		EndIf;
		If Object.RadioButtonType <> Enums.RadioButtonTypesInQuestionnaires.EmptyRef() AND Object.CheckBoxType <> Enums.CheckBoxKindsInQuestionnaires.EmptyRef() Then
			RollbackTransaction();
			Return;
		EndIf;
		
		// Object processing.
		If Object.RadioButtonType = Enums.RadioButtonTypesInQuestionnaires.EmptyRef() Then
			Object.RadioButtonType = Enums.RadioButtonTypesInQuestionnaires.RadioButton;
		EndIf;
		
		If Object.CheckBoxType = Enums.CheckBoxKindsInQuestionnaires.EmptyRef() Then
			Object.CheckBoxType = Enums.CheckBoxKindsInQuestionnaires.CheckBox;
		EndIf;
		
		// Processed object record.
		InfobaseUpdate.WriteData(Object);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

#EndRegion

#EndIf