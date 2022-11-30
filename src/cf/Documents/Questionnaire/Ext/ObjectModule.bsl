///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	SetPrivilegedMode(True);
	
	RegisterRecords.QuestionnaireQuestionAnswers.Write = True;
	
	Query = New Query;
	Query.Text = "SELECT
	|	TableComposition.Question,
	|	TableComposition.ElementaryQuestion,
	|	TableComposition.CellNumber,
	|	TableComposition.Response,
	|	TableComposition.OpenAnswer,
	|	TableComposition.LineNumber
	|INTO Content
	|FROM
	|	&TableComposition AS TableComposition
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Content.Question,
	|	Content.ElementaryQuestion,
	|	Content.CellNumber,
	|	Content.Response,
	|	Content.OpenAnswer,
	|	TRUE AS Active,
	|	&Ref AS Recorder,
	|	&Ref AS Questionnaire,
	|	Content.LineNumber AS LineNumber
	|FROM
	|	Content AS Content";
	
	Query.SetParameter("TableComposition",Content);
	Query.SetParameter("Ref",Ref);
	
	RegisterRecords.QuestionnaireQuestionAnswers.Load(Query.Execute().Unload());
	
EndProcedure

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	If FillingData <> Undefined Then
		FillPropertyValues(ThisObject,FillingData);
	EndIf;
	
	If SurveyMode = Enums.SurveyModes.Interview Then
		Interviewer = Users.CurrentUser();
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If SurveyMode = Enums.SurveyModes.Interview Then
		CheckedAttributes.Delete(CheckedAttributes.Find("Survey"));
	Else
		CheckedAttributes.Delete(CheckedAttributes.Find("QuestionnaireTemplate"));
	EndIf;
	
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Invalid object call on the client.';de = 'Invalid object call on the client.';ro = 'Invalid object call on the client.';tr = 'Invalid object call on the client.'; es_ES = 'Invalid object call on the client.'");
#EndIf