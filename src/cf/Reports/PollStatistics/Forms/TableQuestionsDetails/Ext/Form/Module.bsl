///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	BasicQuestionsFormulations = New Map;
	
	If  ProcessIncomingParameters(BasicQuestionsFormulations) Then
		Cancel = True;
		Return;
	EndIf;
	
	GenerateReport(BasicQuestionsFormulations);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure GenerateReport(BasicQuestionsFormulations)

	ReportTable.Clear();
	
	QueryResult = ExecuteQueryOnQuestionnareQuestion();
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	Template = Reports.PollStatistics.GetTemplate("AnswersTemplate");
	
	Area = Template.GetArea("Question");
	Area.Parameters.QuestionWording = Wording;
	ReportTable.Put(Area,1);
	
	AnswersTree = QueryResult.Unload(QueryResultIteration.ByGroups);
	For each TreeRow In AnswersTree.Rows Do
		OutputToRespondentsDocument(TreeRow,Template,BasicQuestionsFormulations);
	EndDo;

EndProcedure

&AtServer
Procedure OutputToRespondentsDocument(TreeRow,Template, BasicQuestionsFormulations)

	Area = Template.GetArea("Respondent");
	Area.Parameters.Respondent = TreeRow.Respondent;
	ReportTable.Put(Area,1);
	
	ReportTable.StartRowGroup(TreeRow.Respondent);
	OutputTabularAnswer(TreeRow,Template,BasicQuestionsFormulations);
	ReportTable.EndRowGroup();

EndProcedure

&AtServer
Procedure OutputTabularAnswer(TreeRow,Template,BasicQuestionsFormulations)

	If TabularQuestionType = Enums.TabularQuestionTypes.Composite Then
		
		OutputAnswerCompositeTabularQuestion(TreeRow,Template,BasicQuestionsFormulations);
		
	ElsIf TabularQuestionType = Enums.TabularQuestionTypes.PredefinedAnswersInColumns Then
		
		OutputAnswerPredefinedAnswersInColumnsTabularQuestion(TreeRow,Template, BasicQuestionsFormulations);
		
	ElsIf TabularQuestionType = Enums.TabularQuestionTypes.PredefinedAnswersInRows Then
		
		OutputAnswerPredefinedAnswersInRowsTabularQuestion(TreeRow,Template, BasicQuestionsFormulations);
		
	ElsIf TabularQuestionType = Enums.TabularQuestionTypes.PredefinedAnswersInRowsAndColumns Then
		
		OutputAnswerPredefinedAnswersInRowsAndColumnsTabularQuestion(TreeRow,Template);
		
	EndIf;

EndProcedure

&AtServer
Procedure OutputAnswerCompositeTabularQuestion(TreeRow,Template, BasicQuestionsFormulations)
	
	FirstColumn = True;
	
	For each Question In TabularQuestionComposition Do
		
		If FirstColumn Then
			Area = Template.GetArea("Indent");
			ReportTable.Put(Area);
			FirstColumn = False;
		EndIf;
		
		Area = Template.GetArea("TableQuestionHeaderItem");
		Area.Parameters.Value = BasicQuestionsFormulations.Get(Question.ElementaryQuestion);
		ReportTable.Join(Area);
		
	EndDo; 
	
	FirstColumn = True;
	
	For each TreeRowCell In TreeRow.Rows Do
		
		FirstColumn = True;
		
		For each TabularQuestionContentRow In TabularQuestionComposition Do
			
			FoundRow = TreeRowCell.Rows.Find(TabularQuestionContentRow.ElementaryQuestion,"ElementaryQuestion");
			
			If FirstColumn Then
				Area = Template.GetArea("Indent");
				ReportTable.Put(Area);
				FirstColumn = False;
			EndIf;
			
			Area = Template.GetArea("TableQuestionCell");
			Area.Parameters.Value = ?(FoundRow = Undefined,"",FoundRow.Response);
			ReportTable.Join(Area);
			
		EndDo;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure OutputAnswerPredefinedAnswersInColumnsTabularQuestion(TreeRow,Template, BasicQuestionsFormulations)

	Area = Template.GetArea("Indent");
	ReportTable.Put(Area);
	
	Area = Template.GetArea("TableQuestionHeaderItem");
	ReportTable.Join(Area);
	
	For Each Answer In PredefinedAnswers Do
		
		Area = Template.GetArea("TableQuestionHeaderItem");
		Area.Parameters.Value = Answer.Response;
		ReportTable.Join(Area);
		
	EndDo;	
	
	For RowsIndex = 2 To TabularQuestionComposition.Count() Do
		
		Area = Template.GetArea("Indent");
		ReportTable.Put(Area);
		
		Area = Template.GetArea("TableQuestionHeaderItem");
		Area.Parameters.Value = BasicQuestionsFormulations.Get(TabularQuestionComposition[RowsIndex - 1].ElementaryQuestion);
		ReportTable.Join(Area);
		
		For ColumnsIndex = 1 To PredefinedAnswers.Count() Do
			
			FilterStructure = New Structure;
			FilterStructure.Insert("ElementaryQuestion", TabularQuestionComposition[RowsIndex-1].ElementaryQuestion);
			FilterStructure.Insert("CellNumber",ColumnsIndex);
			FoundRows = TreeRow.Rows.FindRows(FilterStructure,True);
			
			Area = Template.GetArea("TableQuestionCell");
			If FoundRows.Count() > 0 Then
				Area.Parameters.Value = FoundRows[0].Response;
			EndIf;
			ReportTable.Join(Area);
			
		EndDo;
	EndDo;
	
EndProcedure

&AtServer
Procedure OutputAnswerPredefinedAnswersInRowsTabularQuestion(TreeRow,Template, BasicQuestionsFormulations)

	FirstColumn = True;
	
	For each Question In TabularQuestionComposition Do
		
		If FirstColumn Then
			Area = Template.GetArea("Indent");
			ReportTable.Put(Area);
			FirstColumn = False;
		EndIf;
		
		Area = Template.GetArea("TableQuestionHeaderItem");
		Area.Parameters.Value = BasicQuestionsFormulations.Get(Question.ElementaryQuestion);
		ReportTable.Join(Area);
		
	EndDo;
	
	For each TreeRowCell In TreeRow.Rows Do
		
		FirstColumn = True;
		
		For ColumnsIndex = 1 To TabularQuestionComposition.Count() Do
			
			If FirstColumn Then
				
				Area = Template.GetArea("Indent");
				ReportTable.Put(Area);
				FirstColumn = False;
				
				Area = Template.GetArea("TableQuestionCellItemPredefinedAnswer");
				Area.Parameters.Value = PredefinedAnswers[TreeRowCell.CellNumber - 1].Response;
				ReportTable.Join(Area);
				
			Else
				
				FoundRow = TreeRowCell.Rows.Find(TabularQuestionComposition[ColumnsIndex - 1].ElementaryQuestion,"ElementaryQuestion");
				
				Area = Template.GetArea("TableQuestionCell");
				Area.Parameters.Value = ?(FoundRow = Undefined,"",FoundRow.Response);

				ReportTable.Join(Area);
				
			EndIf;
			
		EndDo;
	EndDo;
	
EndProcedure

&AtServer
Procedure OutputAnswerPredefinedAnswersInRowsAndColumnsTabularQuestion(TreeRow,Template)
	
	ColumnsAnswers = PredefinedAnswers.FindRows(New Structure("ElementaryQuestion",TabularQuestionComposition[1].ElementaryQuestion));
	RowsAnswers = PredefinedAnswers.FindRows(New Structure("ElementaryQuestion",TabularQuestionComposition[0].ElementaryQuestion));
	
	If ColumnsAnswers.Count() = 0 AND RowsAnswers.Count() = 0 Then
		Return;
	EndIf;
	
	Area = Template.GetArea("Indent");
	ReportTable.Put(Area);
	
	Area = Template.GetArea("TableQuestionHeaderItem");
	ReportTable.Join(Area);
	
	For Each Answer In ColumnsAnswers Do
		
		Area = Template.GetArea("TableQuestionHeaderItem");
		Area.Parameters.Value = Answer.Response;
		ReportTable.Join(Area);
		
	EndDo;
	
	For RowIndex = 1 To RowsAnswers.Count()  Do
		
		Area = Template.GetArea("Indent");
		ReportTable.Put(Area);
		
		Area = Template.GetArea("TableQuestionHeaderItem");
		Area.Parameters.Value = RowsAnswers[RowIndex - 1].Response;
		ReportTable.Join(Area);
		
		For ColumnIndex = 1 To ColumnsAnswers.Count() Do
			
			FilterStructure = New Structure;
			FilterStructure.Insert("CellNumber", ColumnIndex + (RowIndex-1) * ColumnsAnswers.Count());
			FilterStructure.Insert("ElementaryQuestion",TabularQuestionComposition[2].ElementaryQuestion);
			FoundRows = TreeRow.Rows.FindRows(FilterStructure,True);
			
			Area = Template.GetArea("TableQuestionCell");
			If FoundRows.Count() > 0 Then
				Area.Parameters.Value = FoundRows[0].Response;
			EndIf;
			ReportTable.Join(Area);
			
		EndDo;
		
	EndDo;
	
EndProcedure

&AtServer
Function ExecuteQueryOnQuestionnareQuestion()
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	ISNULL(DocumentQuestionnaire.Respondent, UNDEFINED) AS Respondent,
	|	QuestionnaireQuestionAnswers.CellNumber                  AS CellNumber,
	|	QuestionnaireQuestionAnswers.ElementaryQuestion           AS ElementaryQuestion,
	|	QuestionnaireQuestionAnswers.Response
	|FROM
	|	InformationRegister.QuestionnaireQuestionAnswers AS QuestionnaireQuestionAnswers
	|		LEFT JOIN Document.Questionnaire AS DocumentQuestionnaire
	|		ON QuestionnaireQuestionAnswers.Questionnaire = DocumentQuestionnaire.Ref
	|WHERE
	|	QuestionnaireQuestionAnswers.Question = &TemplateQuestion
	|	AND DocumentQuestionnaire.Survey = &Survey
	|
	|ORDER BY
	|	Respondent,
	|	CellNumber
	|TOTALS BY
	|	Respondent,
	|	CellNumber";
	
	Query.SetParameter("TemplateQuestion",QuestionnaireTemplateQuestion);
	Query.SetParameter("Survey",Survey);
	
	Return Query.Execute();
	
EndFunction

&AtServer
Function ProcessIncomingParameters(BasicQuestionsFormulations)

	If Parameters.Property("QuestionnaireTemplateQuestion") Then
		QuestionnaireTemplateQuestion = Parameters.QuestionnaireTemplateQuestion;
	Else
		Return True;
	EndIf;
	
	If Parameters.Property("Survey") Then
		Survey = Parameters.Survey; 
	Else
		Return True;
	EndIf;
	
	If Parameters.Property("FullCode") Then
		FullCode =  Parameters.FullCode;
	EndIf;
	
	If Parameters.Property("SurveyDescription") Then
		SurveyDescription =  Parameters.SurveyDescription;
	Else
		Cancel = True;
	EndIf; 
	
	If Parameters.Property("SurveyDate") Then
		SurveyDate =  Parameters.SurveyDate;
	Else
		Cancel = True;
	EndIf;
	
	TemplateQuestionsAttributes = Common.ObjectAttributesValues(QuestionnaireTemplateQuestion,"TabularQuestionType,TabularQuestionComposition,PredefinedAnswers,Wording");
	Wording           = TemplateQuestionsAttributes.Wording;
	TabularQuestionType   = TemplateQuestionsAttributes.TabularQuestionType;
	TabularQuestionComposition.Load(TemplateQuestionsAttributes.TabularQuestionComposition.Unload());
	PredefinedAnswers.Load(TemplateQuestionsAttributes.PredefinedAnswers.Unload());
	GetBasicQuestionsFormulations(BasicQuestionsFormulations);
	
	Title = NStr("ru='Ответы на вопрос №'; en = 'Responses to question No.'; pl = 'Responses to question No.';de = 'Responses to question No.';ro = 'Responses to question No.';tr = 'Responses to question No.'; es_ES = 'Responses to question No.'") + " " + FullCode + " " + NStr("ru='опроса'; en = 'of survey'; pl = 'of survey';de = 'of survey';ro = 'of survey';tr = 'of survey'; es_ES = 'of survey'") + " " + SurveyDescription + " " + NStr("ru='от'; en = 'dated'; pl = 'dated';de = 'dated';ro = 'dated';tr = 'dated'; es_ES = 'dated'") + " " + Format(SurveyDate,"DLF=D");
	
	Return False;

EndFunction

&AtServer
Procedure GetBasicQuestionsFormulations(BasicQuestionsFormulations)
	
	Query = New Query;
	Query.Text = "SELECT
	|	QuestionsForSurvey.Ref,
	|	QuestionsForSurvey.Wording,
	|	QuestionsForSurvey.ShowAggregatedValuesInReports
	|FROM
	|	ChartOfCharacteristicTypes.QuestionsForSurvey AS QuestionsForSurvey
	|WHERE
	|	QuestionsForSurvey.Ref IN(&QuestionArray)";
	
	Query.SetParameter("QuestionArray",TabularQuestionComposition.Unload().UnloadColumn("ElementaryQuestion"));
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		BasicQuestionsFormulations.Insert(Selection.Ref,Selection.Wording);
	EndDo;
	
EndProcedure

#EndRegion
