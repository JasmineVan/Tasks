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
	Result.Add("Required");
	Result.Add("Notes");
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
		|	QuestionnaireTemplateQuestions.Ref
		|FROM
		|	Catalog.QuestionnaireTemplateQuestions AS QuestionnaireTemplateQuestions
		|WHERE
		|	QuestionnaireTemplateQuestions.HintPlacement = &EmptyRef";
	Query.Parameters.Insert("EmptyRef", Enums.TooltipDisplayMethods.EmptyRef());
	
	Result = Query.Execute().Unload();
	RefsArray = Result.UnloadColumn("Ref");
	
	InfobaseUpdate.MarkForProcessing(Parameters, RefsArray);
	
EndProcedure

// Fill in a value of the new TooltipDisplayMethod attribute for the QuestionnaireTemplateQuestions catalog.
// 
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	Selection = InfobaseUpdate.SelectRefsToProcess(Parameters.Queue, "Catalog.QuestionnaireTemplateQuestions");
	
	ObjectsWithIssuesCount = 0;
	ObjectsProcessed = 0;
	
	While Selection.Next() Do
		
		Try
			
			FillTooltipDisplayMethodAttribute(Selection);
			ObjectsProcessed = ObjectsProcessed + 1;
			
		Except
			// If an object cannot be processed, try again.
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось обработать вопрос шаблона анкеты: %1 по причине:
					|%2'; 
					|en = 'Cannot process a questionnaire template question: %1 due to:
					|%2'; 
					|pl = 'Cannot process a questionnaire template question: %1 due to:
					|%2';
					|de = 'Cannot process a questionnaire template question: %1 due to:
					|%2';
					|ro = 'Cannot process a questionnaire template question: %1 due to:
					|%2';
					|tr = 'Cannot process a questionnaire template question: %1 due to:
					|%2'; 
					|es_ES = 'Cannot process a questionnaire template question: %1 due to:
					|%2'"), 
					Selection.Ref, DetailErrorDescription(ErrorInfo()));
			WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Warning,
				Metadata.Catalogs.QuestionnaireTemplateQuestions, Selection.Ref, MessageText);
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, "Catalog.QuestionnaireTemplateQuestions");
	If ObjectsProcessed = 0 AND ObjectsWithIssuesCount <> 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Процедуре ЗаполнитьРеквизитСпособОтображенияПодсказки не удалось обработать некоторые вопросы шаблона анкеты (пропущены): %1'; en = 'The FillTooltipDisplayMethodAttribute procedure cannot process some questionnaire template questions (skipped): %1'; pl = 'The FillTooltipDisplayMethodAttribute procedure cannot process some questionnaire template questions (skipped): %1';de = 'The FillTooltipDisplayMethodAttribute procedure cannot process some questionnaire template questions (skipped): %1';ro = 'The FillTooltipDisplayMethodAttribute procedure cannot process some questionnaire template questions (skipped): %1';tr = 'The FillTooltipDisplayMethodAttribute procedure cannot process some questionnaire template questions (skipped): %1'; es_ES = 'The FillTooltipDisplayMethodAttribute procedure cannot process some questionnaire template questions (skipped): %1'"), 
				ObjectsWithIssuesCount);
		Raise MessageText;
	Else
		WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Information,
			Metadata.Catalogs.QuestionnaireTemplateQuestions,,
				StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Процедура ЗаполнитьРеквизитСпособОтображенияПодсказки обработала очередную порцию вопросов шаблона анкеты: %1'; en = 'The FillTooltipDisplayMethodAttribute procedure has processed questionnaire template questions: %1'; pl = 'The FillTooltipDisplayMethodAttribute procedure has processed questionnaire template questions: %1';de = 'The FillTooltipDisplayMethodAttribute procedure has processed questionnaire template questions: %1';ro = 'The FillTooltipDisplayMethodAttribute procedure has processed questionnaire template questions: %1';tr = 'The FillTooltipDisplayMethodAttribute procedure has processed questionnaire template questions: %1'; es_ES = 'The FillTooltipDisplayMethodAttribute procedure has processed questionnaire template questions: %1'"),
					ObjectsProcessed));
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Fills in a value of the new TooltipDisplayMethod attribute for the passed object.
//
Procedure FillTooltipDisplayMethodAttribute(Selection)
	
	BeginTransaction();
	Try
	
		// Locking the object for changes by other sessions.
		Lock = New DataLock;
		LockItem = Lock.Add("Catalog.QuestionnaireTemplateQuestions");
		LockItem.SetValue("Ref", Selection.Ref);
		Lock.Lock();
		
		CatalogObject = Selection.Ref.GetObject();
		
		// Ignore the object if it was previously deleted or processed by other sessions.
		If CatalogObject = Undefined Then
			RollbackTransaction();
			Return;
		EndIf;
		If CatalogObject.HintPlacement <> Enums.TooltipDisplayMethods.EmptyRef() Then
			RollbackTransaction();
			Return;
		EndIf;
		
		// Object processing.
		CatalogObject.HintPlacement = Enums.TooltipDisplayMethods.AsTooltip;
		
		// Processed object record.
		InfobaseUpdate.WriteData(CatalogObject);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

#EndRegion

#EndIf
