///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// Generates the report spreadsheet document.
//
// Parameters:
//  ReportTable - SpreadsheetDocument - a document, in which data is output.
//  Survey  - DocumentRef.SurveysPurpose - a survey, on which the report is generated.
//  ReportKind - String - it can take the AnswersAnalysis and RespondersAnalysis values.
//
Procedure GenerateReport(ReportTable,Survey,ReportKind) Export
	
	ReportTable.Clear();
	
	If ReportKind ="ResponsesAnalysis" Then
		
		GenerateAnswersAnalysisReport(ReportTable,Survey);
		
	ElsIf ReportKind = "RespondersAnalysis" Then
		
		GenerateRespondersAnalysisReport(ReportTable,Survey);
		
	Else
		
		Return;
		
	EndIf;
	
EndProcedure

#Region AnswersAnalysis

Procedure GenerateAnswersAnalysisReport(ReportTable,Survey)
	
	AttributesSurvey = Common.ObjectAttributesValues(Survey,"QuestionnaireTemplate,StartDate,EndDate,Presentation");
	QuestionnaireTemplate = AttributesSurvey.QuestionnaireTemplate;
	QuestionsPresentations = Survey.GetPresentationsOfElementaryQuestionsOfTabularQuestion(QuestionnaireTemplate);
	
	QueryResult = ExecuteQueryOnQuestionnaireTemplatesQuestions(Survey,QuestionnaireTemplate);
	If QueryResult.IsEmpty() Then
		Return;	
	EndIf;
	
	Template = GetTemplate("AnswersTemplate");
	
	Area = Template.GetArea("Title");
	Area.Parameters.Title = QuestionnaireTemplate.Title;
	Area.Parameters.Survey     = GetSurveyPresentationForHeader(AttributesSurvey);
	ReportTable.Put(Area,1);
	
	Area = Template.GetArea("BlankRow");
	ReportTable.Put(Area,1);
	ReportTable.StartRowGroup("Annotation");
	
	Area = Template.GetArea("Annotation");
	ReportTable.Put(Area,2);
	ReportTable.EndRowGroup();
	
	Area = Template.GetArea("BlankRow");
	ReportTable.Put(Area,1);
	
	QuestionnaireTree = QueryResult.Unload(QueryResultIteration.ByGroupsWithHierarchy);
	If QuestionnaireTree.Rows.Count() > 0 Then
		OutputToSpreadsheetDocument(QuestionnaireTree.Rows,ReportTable,Template,1,New Array, QuestionsPresentations);
	EndIf;
	
EndProcedure 

// It is called recursively, generates full code and calls procedures for outputting questions and sections.
//
// Parameters:
//  TreeRows    - ValueTreeRows - tree rows, for which the action is executed.
//  ReportTable   - SpreadsheetDocument - a document, in which the data is output.
//  Template           - Template             - a template used to output the data.
//  RecursionLevel - Number - the current recursion level.
//  ArrayFullCode - Array - used to generate a full code of a row being processed.
// 
Procedure OutputToSpreadsheetDocument(TreeRows,ReportTable,Template,RecursionLevel,ArrayFullCode, QuestionsPresentations)
	
	If ArrayFullCode.Count() < RecursionLevel Then
		ArrayFullCode.Add(0);
	EndIf;
	
	For each TreeRow In TreeRows Do
		
		ArrayFullCode[RecursionLevel-1] = ArrayFullCode[RecursionLevel-1] + 1;
		For ind = RecursionLevel To ArrayFullCode.Count()-1 Do
			ArrayFullCode[ind] = 0;
		EndDo;
		
		FullCode = StrConcat(ArrayFullCode,".");
		FullCode = QuestioningClientServer.DeleteLastCharsFromString(FullCode,"0.",".");
		
		If TreeRow.IsSection Then
			OutputSection(ReportTable,TreeRow,Template,FullCode);
			If TreeRow.Rows.Count() > 0 Then
				OutputToSpreadsheetDocument(TreeRow.Rows,ReportTable,Template,RecursionLevel + 1,ArrayFullCode,QuestionsPresentations);
			EndIf
		Else
			OutputQuestion(ReportTable,TreeRow,Template,FullCode, QuestionsPresentations);
		EndIf;
		ReportTable.EndRowGroup();
		
	EndDo;
	
EndProcedure

// Outputs section in the report table.
//
// Parameters:
//  ReportTable - SpreadsheetDocument - a document, in which information is output.
//  TreeRow - ValueTreeRow - a current row with data.
//  Template         - Template - a template used to output information.
//  FullCode     - String - a full code of a row to be output in the report.
// 
Procedure OutputSection(ReportTable,TreeRow,Template,FullCode)
	
	Area = Template.GetArea("Section");
	Area.Parameters.SectionName = FullCode + " " + TreeRow.Description;
	ReportTable.Put(Area);
	ReportTable.StartRowGroup("FullCode_" + TreeRow.Description);
	
EndProcedure

// Outputs a question to the report table and calls the procedures depending on the questions type.
//
// Parameters:
//  ReportTable - SpreadsheetDocument - a document, in which information is output.
//  TreeRow - ValueTreeRow - a current row with data.
//  Template         - Template - a template used to output information.
//  FullCode    - String - a full code of a row to be output in the report.
//
Procedure OutputQuestion(ReportTable,TreeRow,Template,FullCode, QuestionsPresentations)
	
	Area = Template.GetArea("Question");
	Area.Parameters.QuestionWording = FullCode + " " + TreeRow.Description;
	ReportTable.Put(Area);
	ReportTable.StartRowGroup("FullCode_" + TreeRow.Description);
	
	If TreeRow.Rows.Count() > 0 Then		
		
		If TreeRow.QuestionsType = Enums.QuestionnaireTemplateQuestionTypes.Tabular Then
			
			OutputAnswerTabularQuestion(ReportTable,TreeRow,Template,FullCode,QuestionsPresentations);
			
		Else	
			
			OutputAnswerSimpleQuestion(ReportTable,TreeRow,Template,FullCode);
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Calls the procedures depending on the tabular questions type.
//
// Parameters:
//  ReportTable         - SpreadsheetDocument - a document, in which information is output.
//  TreeRow - ValueTreeRow - a current row with data.
//  Template                 - Template - a template used to output information.
//  FullCode             - String - a full code of a row to be output in the report.
//  QuestionsPresentations - Map - contains information on the formulation and the Aggregate in reports flag.
// 
Procedure OutputAnswerTabularQuestion(ReportTable, TreeRow, Template, FullCode, QuestionsPresentations)
	
	If TreeRow.TabularQuestionType = Enums.TabularQuestionTypes.Composite Then
		
		OutputAnswerCompositeTabularQuestion(ReportTable,TreeRow.Rows[0],Template,FullCode, QuestionsPresentations);
		
	ElsIf TreeRow.TabularQuestionType = Enums.TabularQuestionTypes.PredefinedAnswersInColumns Then
		
		OutputAnswerPredefinedAnswersInColumnsTabularQuestion(ReportTable,TreeRow,Template,FullCode,QuestionsPresentations);
		
	ElsIf TreeRow.TabularQuestionType = Enums.TabularQuestionTypes.PredefinedAnswersInRows Then
		
		OutputAnswerPredefinedAnswersInRowsTabularQuestion(ReportTable,TreeRow,Template,FullCode,QuestionsPresentations);
		
	ElsIf TreeRow.TabularQuestionType = Enums.TabularQuestionTypes.PredefinedAnswersInRowsAndColumns Then
		
		OutputAnswerPredefinedAnswersInRowsAndColumnsTabularQuestion(ReportTable,TreeRow,Template,FullCode, QuestionsPresentations);
		
	EndIf;
	
EndProcedure

// Outputs tabular questions answers with predefined answers in columns to the report table.
//
// Parameters:
//  ReportTable         - SpreadsheetDocument - a document, in which information is output.
//  TreeRow - ValueTreeRow - a current row with data.
//  Template                 - Template - a template used to output information.
//  FullCode             - String - a full code of a row to be output in the report.
//  QuestionsPresentations - Map - contains information on the formulation and the Aggregate in reports flag.
//
Procedure OutputAnswerPredefinedAnswersInColumnsTabularQuestion(ReportTable, TreeRow, Template, FullCode, QuestionsPresentations)
	
	TreeRowDetails = TreeRow.Rows[0];
	
	Area = Template.GetArea("Indent");
	ReportTable.Put(Area);
	
	Area = Template.GetArea("TableQuestionHeaderItem");
	ReportTable.Join(Area);
	
	TreeRowDetails.PredefinedAnswers.Sort("LineNumber Asc");
	TreeRowDetails.TabularQuestionComposition.Sort("LineNumber Asc");
	For Each Answer In TreeRowDetails.PredefinedAnswers Do
		
		Area = Template.GetArea("TableQuestionHeaderItem");
		Area.Parameters.Value = Answer.Response;
		ReportTable.Join(Area);
		
	EndDo;
	
	For RowsIndex = 2 To TreeRowDetails.TabularQuestionComposition.Count() Do
		
		Area = Template.GetArea("Indent");
		ReportTable.Put(Area);
		
		Area = Template.GetArea("TableQuestionHeaderItem");
		Area.Parameters.Value = QuestionsPresentations.Get(TreeRowDetails.TabularQuestionComposition[RowsIndex - 1].ElementaryQuestion).Wording;
		ReportTable.Join(Area);
		
		For ColumnsIndex = 1 To TreeRowDetails.PredefinedAnswers.Count() Do
			
			FilterStructure = New Structure;
			FilterStructure.Insert("ElementaryQuestionRegister",TreeRowDetails.TabularQuestionComposition[RowsIndex-1].ElementaryQuestion);
			FilterStructure.Insert("CellNumber",ColumnsIndex);
			FoundRows = TreeRow.Rows.FindRows(FilterStructure);
			
			Area = Template.GetArea("TableQuestionCell");
			If FoundRows.Count() > 0 Then
				If TypeOf(FoundRows[0].AnswerOption) <> Type("Boolean") Then
					Area.Parameters.Value = AggregateValuesToString(FoundRows[0],QuestionsPresentations.Get(TreeRowDetails.TabularQuestionComposition[RowsIndex-1].ElementaryQuestion).ShowAggregatedValuesInReports);
					Area.Parameters.Details = New Structure("TemplateQuestion,QuestionsType,FullCode",TreeRow.TemplateQuestion,TreeRow.QuestionsType,FullCode);
				Else
					For each FoundRow In FoundRows Do
						If FoundRow.AnswerOption = True Then
							Area.Parameters.Value = FoundRow.Count;
							Area.Parameters.Details = New Structure("TemplateQuestion,QuestionsType,FullCode",TreeRow.TemplateQuestion,TreeRow.QuestionsType,FullCode);
						EndIf;
					EndDo;
				EndIf;
			EndIf;
			ReportTable.Join(Area);
			
		EndDo;
		
	EndDo;
		
EndProcedure

// Outputs tabular questions answers with predefined answers in rows to the report table.
//
// Parameters:
//  ReportTable - SpreadsheetDocument - a document, in which information is output.
//  TreeRow - ValueTreeRow - a current row with data.
//  Template                 - Template - a template used to output information.
//  FullCode             - String - a full code of a row to be output in the report.
//  QuestionsPresentations - Map - contains information on the formulation and the Aggregate in reports flag.
//
Procedure OutputAnswerPredefinedAnswersInRowsTabularQuestion(ReportTable, TreeRow, Template, FullCode, QuestionsPresentations)
	
	FirstColumn = True;
	TreeRowDetails = TreeRow.Rows[0];
	TreeRowDetails.PredefinedAnswers.Sort("LineNumber Asc");
	TreeRowDetails.TabularQuestionComposition.Sort("LineNumber Asc");
	
	For each Question In TreeRowDetails.TabularQuestionComposition Do
		
		If FirstColumn Then
			Area = Template.GetArea("Indent");
			ReportTable.Put(Area);
			FirstColumn = False;
		EndIf;
		
		Area = Template.GetArea("TableQuestionHeaderItem");
		Area.Parameters.Value = QuestionsPresentations.Get(Question.ElementaryQuestion).Wording;
		ReportTable.Join(Area); 
		
	EndDo;
	
	For RowsIndex = 1 To TreeRowDetails.PredefinedAnswers.Count() Do
		
		FirstColumn = True;
		
		For ColumnsIndex = 1 To TreeRowDetails.TabularQuestionComposition.Count() Do
			
			If FirstColumn Then
				
				Area = Template.GetArea("Indent");
				ReportTable.Put(Area);
				FirstColumn = False;
				
				Area = Template.GetArea("TableQuestionCellItemPredefinedAnswer");
				Area.Parameters.Value = TreeRowDetails.PredefinedAnswers[RowsIndex -1].Response;
				ReportTable.Join(Area);
				
			Else
				
				FilterStructure = New Structure;
				FilterStructure.Insert("ElementaryQuestionRegister",TreeRowDetails.TabularQuestionComposition[ColumnsIndex-1].ElementaryQuestion);
				FilterStructure.Insert("CellNumber",RowsIndex);
				FoundRows = TreeRow.Rows.FindRows(FilterStructure);
				
				Area = Template.GetArea("TableQuestionCell");
				If FoundRows.Count() > 0 Then
					If TypeOf(FoundRows[0].AnswerOption) <> Type("Boolean") Then
						Area.Parameters.Value = AggregateValuesToString(FoundRows[0],QuestionsPresentations.Get(TreeRowDetails.TabularQuestionComposition[ColumnsIndex-1].ElementaryQuestion).ShowAggregatedValuesInReports);
						Area.Parameters.Details = New Structure("TemplateQuestion,QuestionsType,FullCode",TreeRowDetails.TemplateQuestion,TreeRowDetails.QuestionsType,FullCode);
					Else
						For each FoundRow In FoundRows Do
							If FoundRow.AnswerOption = True Then
								Area.Parameters.Value = FoundRow.Count;
								Area.Parameters.Details = New Structure("TemplateQuestion,QuestionsType,FullCode",TreeRowDetails.TemplateQuestion,TreeRowDetails.QuestionsType,FullCode);
							EndIf;
						EndDo;
					EndIf;
				EndIf;
				ReportTable.Join(Area);
				
			EndIf;
			
		EndDo;
	EndDo;
	
EndProcedure

// Outputs tabular questions answers with predefined answers in rows and columns to the report table.
//
// Parameters:
//  ReportTable         - SpreadsheetDocument - a document, in which information is output.
//  TreeRow - ValueTreeRow - a current row with data.
//  Template                 - Template - a template used to output information.
//  FullCode             - String - a full code of a row to be output in the report.
//  QuestionsPresentations - Map - contains information on the formulation and the Aggregate in reports flag.
//
Procedure OutputAnswerPredefinedAnswersInRowsAndColumnsTabularQuestion(ReportTable, TreeRow, Template, FullCode, QuestionsPresentations)
	
	TreeRowDetails = TreeRow.Rows[0];
	
	TreeRowDetails.PredefinedAnswers.Sort("LineNumber Asc");
	TreeRowDetails.TabularQuestionComposition.Sort("LineNumber Asc");

	If TreeRowDetails.TabularQuestionComposition.Count() <> 3 Then
		Return;
	EndIf;
	
	ShowAggregatedValuesInReports = QuestionsPresentations.Get(TreeRowDetails.TabularQuestionComposition[2].ElementaryQuestion).ShowAggregatedValuesInReports;
	
	ColumnsAnswers = TreeRowDetails.PredefinedAnswers.FindRows(New Structure("ElementaryQuestionAnswer",TreeRowDetails.TabularQuestionComposition[1].ElementaryQuestion));
	RowsAnswers = TreeRowDetails.PredefinedAnswers.FindRows(New Structure("ElementaryQuestionAnswer",TreeRowDetails.TabularQuestionComposition[0].ElementaryQuestion));
	
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
			FilterStructure.Insert("ElementaryQuestionRegister",TreeRowDetails.TabularQuestionComposition[2].ElementaryQuestion);
			FoundRows = TreeRow.Rows.FindRows(FilterStructure);
			
			Area = Template.GetArea("TableQuestionCell");
			If FoundRows.Count() > 0 Then
				If TypeOf(FoundRows[0].AnswerOption) <> Type("Boolean") Then
					Area.Parameters.Value = AggregateValuesToString(FoundRows[0],ShowAggregatedValuesInReports);
					Area.Parameters.Details = New Structure("TemplateQuestion,QuestionsType,FullCode",TreeRow.TemplateQuestion,TreeRow.QuestionsType,FullCode);
				Else
					For each FoundRow In FoundRows Do
						If FoundRow.AnswerOption = True Then
							Area.Parameters.Value = FoundRow.Count;
							Area.Parameters.Details = New Structure("TemplateQuestion,QuestionsType",TreeRow.TemplateQuestion,TreeRow.QuestionsType,FullCode);
						EndIf;
					EndDo;
				EndIf;
			EndIf;
			ReportTable.Join(Area);
		EndDo;
		
	EndDo;
	
EndProcedure

// Outputs answers to the composite tabular question in the report table.
//
// Parameters:
//  ReportTable         - SpreadsheetDocument - a document, in which information is output.
//  TreeRow - ValueTreeRow - a current row with data.
//  Template                 - Template - a template used to output information.
//  FullCode             - String - a full code of a row to be output in the report.
//  QuestionsPresentations - Map - contains information on the formulation and the Aggregate in reports flag.
//
Procedure OutputAnswerCompositeTabularQuestion(ReportTable, TreeRow, Template, FullCode, QuestionsPresentations)
	
	FirstColumn = True;
	
	TreeRow.TabularQuestionComposition.Sort("LineNumber Asc");
	For each Question In TreeRow.TabularQuestionComposition Do
		
		If FirstColumn Then
			Area = Template.GetArea("Indent");
			ReportTable.Put(Area);
			FirstColumn = False;
		EndIf;
		
		Area = Template.GetArea("TableQuestionHeaderItem");
		Area.Parameters.Value = QuestionsPresentations.Get(Question.ElementaryQuestion).Wording;
		ReportTable.Join(Area); 
		
	EndDo;
	
	For RowsIndex = 1 To 3 Do
		
		FirstColumn = True;
		
		For ColumnsIndex = 1 To TreeRow.TabularQuestionComposition.Count() Do
			
			If FirstColumn Then
				Area = Template.GetArea("Indent");
				ReportTable.Put(Area);
				FirstColumn = False;
			EndIf;
			
			Area = Template.GetArea("TableQuestionCell");
			Area.Parameters.Details = New Structure("TemplateQuestion,QuestionsType,FullCode",TreeRow.TemplateQuestion,TreeRow.QuestionsType,FullCode);
			ReportTable.Join(Area);
			
		EndDo;
	EndDo;
	
EndProcedure

// Outputs a simple question answer to the report table.
//
// Parameters:
//  ReportTable         - SpreadsheetDocument - a document, in which information is output.
//  TreeRow - ValueTreeRow - a current row with data.
//  Template                 - Template - a template used to output information.
//  FullCode             - String - a full code of a row to be output in the report.
//
Procedure OutputAnswerSimpleQuestion(ReportTable, TreeRow, Template, FullCode)
	
	TreeRowDetails = TreeRow.Rows[0];
	
	If TreeRowDetails.ReplyType = Enums.QuestionAnswerTypes.Boolean
		OR TreeRowDetails.ReplyType = Enums.QuestionAnswerTypes.OneVariantOf
		OR TreeRowDetails.ReplyType = Enums.QuestionAnswerTypes.MultipleOptionsFor Then
		
		OutputAnswerAnswersOptions(ReportTable,TreeRow,Template,FullCode);
		
	Else
		
		Area = Template.GetArea("AnswerToSimpleQuestion");
		Area.Parameters.Value = AggregateValuesToString(TreeRowDetails);
		Area.Parameters.Details = New Structure("TemplateQuestion,QuestionsType,FullCode",TreeRow.TemplateQuestion,TreeRow.QuestionsType,FullCode);
		ReportTable.Put(Area);
		
	EndIf;
	
EndProcedure

// Outputs answer options for questions with the Boolean, OneOptionFrom and SeveralOptionsFrom type to the report table.
//
// Parameters:
// Parameters:
//  ReportTable         - SpreadsheetDocument - a document, in which information is output.
//  TreeRow          - ValueTreeRow - the current row with data.
//  Template                 - Template - a template used to output information.
//  FullCode             - String - a full code of a row to be output in the report.
//
Procedure OutputAnswerAnswersOptions(ReportTable,TreeRow,Template,FullCode)
	
	If TreeRow.Rows[0].ReplyType = Enums.QuestionAnswerTypes.Boolean Then
		
		Area = Template.GetArea("AnswersOptions");
		Area.Parameters.AnswerOption = NStr("ru='Да'; en = 'Yes'; pl = 'Yes';de = 'Yes';ro = 'Yes';tr = 'Yes'; es_ES = 'Yes'");
		FoundRow = TreeRow.Rows.Find(True,"AnswerOption");
		If FoundRow <> Undefined Then
			Area.Parameters.Value = FoundRow.Count;
			Area.Parameters.Details =New Structure("TemplateQuestion,QuestionsType,FullCode",TreeRow.TemplateQuestion,TreeRow.QuestionsType,FullCode);
		EndIf;
		ReportTable.Put(Area);
		
		Area = Template.GetArea("AnswersOptions");
		Area.Parameters.AnswerOption = NStr("ru='Нет'; en = 'No'; pl = 'No';de = 'No';ro = 'No';tr = 'No'; es_ES = 'No'");
		FoundRow = TreeRow.Rows.Find(FALSE,"AnswerOption");
		If FoundRow <> Undefined Then
			Area.Parameters.Value = FoundRow.Count;
			Area.Parameters.Details = New Structure("TemplateQuestion,QuestionsType,FullCode",TreeRow.TemplateQuestion,TreeRow.QuestionsType,FullCode);
		EndIf;
		ReportTable.Put(Area);
		
	Else	
		
		For each DetailsRow In TreeRow.Rows Do
			
			Area = Template.GetArea("AnswersOptions");
			Area.Parameters.AnswerOption = DetailsRow.AnswerOption;
			Area.Parameters.Value = DetailsRow.Count;
			Area.Parameters.Details = New Structure("TemplateQuestion,QuestionsType,FullCode",TreeRow.TemplateQuestion,TreeRow.QuestionsType,FullCode);
			ReportTable.Put(Area);
			
		EndDo;
	EndIf;
	
EndProcedure

// Executes a query on the questionnaire template and answer registers data.
//
// Parameters:
//  Survey - DocumentRef.SurveyPurpose - a survey on which the query is created.
//  QuestionnaireTemplate - CatalogRef.QuestionnaireTemplates used for the survey.
//
// Returns:
//   QueryResult - an executed query result.
//
Function ExecuteQueryOnQuestionnaireTemplatesQuestions(Survey,QuestionnaireTemplate)
	
	Query = New Query;
	Query.Text = " 
	|SELECT
	|	QuestionnaireQuestionAnswers.Question AS Question,
	|	QuestionnaireQuestionAnswers.ElementaryQuestion AS ElementaryQuestion,
	|	QuestionnaireQuestionAnswers.CellNumber AS CellNumber,
	|	QuestionnaireQuestionAnswers.Response AS AnswerOption,
	|	COUNT(QuestionnaireQuestionAnswers.Response) AS DifferentItemsCount
	|INTO RegisterDataBooleanResponseOptions
	|FROM
	|	InformationRegister.QuestionnaireQuestionAnswers AS QuestionnaireQuestionAnswers
	|WHERE
	|	QuestionnaireQuestionAnswers.Questionnaire.Survey = &Survey
	|	AND VALUETYPE(QuestionnaireQuestionAnswers.Response) IN (TYPE(BOOLEAN), TYPE(Catalog.QuestionnaireAnswersOptions))
	|			
	|GROUP BY
	|	QuestionnaireQuestionAnswers.Question,
	|	QuestionnaireQuestionAnswers.ElementaryQuestion,
	|	QuestionnaireQuestionAnswers.CellNumber,
	|	QuestionnaireQuestionAnswers.Response
	|;
	|////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	QuestionnaireQuestionAnswers.Question AS Question,
	|	QuestionnaireQuestionAnswers.ElementaryQuestion AS ElementaryQuestion,
	|	QuestionnaireQuestionAnswers.CellNumber AS CellNumber,
	|	NULL AS AnswerOption,
	|	MIN(QuestionnaireQuestionAnswers.Response) AS MIN,
	|	MAX(QuestionnaireQuestionAnswers.Response) AS MAX,
	|	AVG(CAST(QuestionnaireQuestionAnswers.Response AS NUMBER)) AS Mean,
	|	SUM(CAST(QuestionnaireQuestionAnswers.Response AS NUMBER)) AS SUM,
	|	COUNT(QuestionnaireQuestionAnswers.Response) AS DifferentItemsCount
	|INTO RegisterData
	|FROM
	|	InformationRegister.QuestionnaireQuestionAnswers AS QuestionnaireQuestionAnswers
	|WHERE
	|	QuestionnaireQuestionAnswers.Questionnaire.Survey = &Survey
	|	AND VALUETYPE(QuestionnaireQuestionAnswers.Response) = TYPE(NUMBER)
	|GROUP BY
	|	QuestionnaireQuestionAnswers.Question,
	|	QuestionnaireQuestionAnswers.ElementaryQuestion,
	|	QuestionnaireQuestionAnswers.CellNumber
	|
	|UNION ALL
	|
	|SELECT
	|	QuestionnaireQuestionAnswers.Question,
	|	QuestionnaireQuestionAnswers.ElementaryQuestion,
	|	QuestionnaireQuestionAnswers.CellNumber,
	|	NULL,
	|	MIN(QuestionnaireQuestionAnswers.Response),
	|	MAX(QuestionnaireQuestionAnswers.Response),
	|	AVG(0),
	|	SUM(0),
	|	COUNT(QuestionnaireQuestionAnswers.Response)
	|FROM
	|	InformationRegister.QuestionnaireQuestionAnswers AS QuestionnaireQuestionAnswers
	|WHERE
	|	QuestionnaireQuestionAnswers.Questionnaire.Survey = &Survey
	|	AND VALUETYPE(QuestionnaireQuestionAnswers.Response) = TYPE(DATE)
	|
	|GROUP BY
	|	QuestionnaireQuestionAnswers.Question,
	|	QuestionnaireQuestionAnswers.ElementaryQuestion,
	|	QuestionnaireQuestionAnswers.CellNumber
	|
	|UNION ALL
	|
	|SELECT
	|	QuestionnaireQuestionAnswers.Question,
	|	QuestionnaireQuestionAnswers.ElementaryQuestion,
	|	QuestionnaireQuestionAnswers.CellNumber,
	|	QuestionnaireQuestionAnswers.Response,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	COUNT(QuestionnaireQuestionAnswers.Response)
	|FROM
	|	InformationRegister.QuestionnaireQuestionAnswers AS QuestionnaireQuestionAnswers
	|WHERE
	|	QuestionnaireQuestionAnswers.Questionnaire.Survey = &Survey
	|	AND VALUETYPE(QuestionnaireQuestionAnswers.Response) = TYPE(BOOLEAN)
	|	
	|GROUP BY
	|	QuestionnaireQuestionAnswers.Question,
	|	QuestionnaireQuestionAnswers.ElementaryQuestion,
	|	QuestionnaireQuestionAnswers.CellNumber,
	|	QuestionnaireQuestionAnswers.Response
	|			
	|UNION ALL
	|
	|SELECT
	|	QuestionnaireQuestionAnswers.Question,
	|	QuestionnaireQuestionAnswers.ElementaryQuestion,
	|	QuestionnaireQuestionAnswers.CellNumber,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	COUNT(QuestionnaireQuestionAnswers.Response)
	|FROM
	|	InformationRegister.QuestionnaireQuestionAnswers AS QuestionnaireQuestionAnswers
	|WHERE
	|	QuestionnaireQuestionAnswers.Questionnaire.Survey = &Survey
	|	AND VALUETYPE(QuestionnaireQuestionAnswers.Response) <> TYPE(BOOLEAN)
	|	AND VALUETYPE(QuestionnaireQuestionAnswers.Response) <> TYPE(DATE)
	|	AND VALUETYPE(QuestionnaireQuestionAnswers.Response) <> TYPE(NUMBER)
	|	AND VALUETYPE(QuestionnaireQuestionAnswers.Response) <> TYPE(Catalog.QuestionnaireAnswersOptions)
	|	
	|GROUP BY
	|	QuestionnaireQuestionAnswers.Question,
	|	QuestionnaireQuestionAnswers.ElementaryQuestion,
	|	QuestionnaireQuestionAnswers.CellNumber
	|;
	|////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	QuestionnaireTemplateQuestions.Presentation AS Wording,
	|	QuestionnaireTemplateQuestions.IsFolder AS IsSection,
	|	ISNULL(QuestionsForSurvey.ReplyType, VALUE(Enum.QuestionAnswerTypes.EmptyRef)) AS ReplyType,
	|	QuestionnaireTemplateQuestions.Ref AS Ref,
	|	ISNULL(QuestionsForSurvey.ShowAggregatedValuesInReports, FALSE) AS ShowAggregatedValuesInReports
	|INTO QuestionnaireTemplateQuestions
	|FROM
	|	Catalog.QuestionnaireTemplateQuestions AS QuestionnaireTemplateQuestions
	|	LEFT JOIN ChartOfCharacteristicTypes.QuestionsForSurvey AS QuestionsForSurvey
	|		ON QuestionnaireTemplateQuestions.ElementaryQuestion = QuestionsForSurvey.Ref
	|WHERE
	|	QuestionnaireTemplateQuestions.Owner = &QuestionnaireTemplate
	|	AND (NOT QuestionnaireTemplateQuestions.IsFolder)
	|;
	|////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	QuestionnaireTemplateQuestions.IsSection AS IsSection,
	|	QuestionnaireTemplateQuestions.ReplyType AS ReplyType,
	|	QuestionnaireTemplateQuestions.Ref AS Ref,
	|	QuestionnaireTemplateQuestions.ShowAggregatedValuesInReports AS ShowAggregatedValuesInReports
	|INTO QuestionnaireTemplateQuestionsOptions
	|FROM 
	|	QuestionnaireTemplateQuestions AS QuestionnaireTemplateQuestions
	|WHERE
	|	QuestionnaireTemplateQuestions.ReplyType <> VALUE(Enum.QuestionAnswerTypes.OneVariantOf)
	|AND QuestionnaireTemplateQuestions.ReplyType <> VALUE(Enum.QuestionAnswerTypes.MultipleOptionsFor)
	|;
	|////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	QuestionnaireTemplateQuestions.Presentation AS Wording,
	|	QuestionnaireTemplateQuestions.IsFolder AS IsSection,
	|	ISNULL(QuestionsForSurvey.ReplyType, VALUE(Enum.QuestionAnswerTypes.EmptyRef)) AS ReplyType,
	|	QuestionnaireTemplateQuestions.Ref AS Ref,
	|	QuestionnaireAnswersOptions.Ref AS AnswerOption,
	|	ISNULL(QuestionsForSurvey.ShowAggregatedValuesInReports, FALSE) AS ShowAggregatedValuesInReports,
	|	QuestionnaireAnswersOptions.AddlOrderingAttribute AS Code,
	|	QuestionnaireTemplateQuestions.ElementaryQuestion AS ElementaryQuestion
	|INTO QuestionnaireTemplateQuestionsQuestions
	|FROM
	|	Catalog.QuestionnaireTemplateQuestions AS QuestionnaireTemplateQuestions
	|	LEFT JOIN ChartOfCharacteristicTypes.QuestionsForSurvey AS QuestionsForSurvey
	|	LEFT JOIN Catalog.QuestionnaireAnswersOptions AS QuestionnaireAnswersOptions
	|		ON QuestionsForSurvey.Ref = QuestionnaireAnswersOptions.Owner
	|		ON QuestionnaireTemplateQuestions.ElementaryQuestion = QuestionsForSurvey.Ref
	|WHERE
	|	QuestionnaireTemplateQuestions.Owner = &QuestionnaireTemplate
	|	AND (NOT QuestionnaireTemplateQuestions.IsFolder)
	|	AND QuestionsForSurvey.ReplyType IN (VALUE(Enum.QuestionAnswerTypes.OneVariantOf), VALUE(Enum.QuestionAnswerTypes.MultipleOptionsFor))
	|;
	|////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	QuestionnaireQuestionAnswers.Question AS Question,
	|	QuestionnaireQuestionAnswers.ElementaryQuestion AS ElementaryQuestion,
	|	QuestionnaireQuestionAnswers.CellNumber AS CellNumber,
	|	QuestionnaireQuestionAnswers.Response AS Response
	|INTO AnswersToTableQuestions
	|FROM
	|	InformationRegister.QuestionnaireQuestionAnswers AS QuestionnaireQuestionAnswers
	|	LEFT JOIN ChartOfCharacteristicTypes.QuestionsForSurvey AS QuestionsForSurvey
	|		ON QuestionnaireQuestionAnswers.ElementaryQuestion = QuestionsForSurvey.Ref
	|	LEFT JOIN Catalog.QuestionnaireTemplateQuestions AS QuestionnaireTemplateQuestions
	|		ON QuestionnaireQuestionAnswers.Question = QuestionnaireTemplateQuestions.Ref
	|WHERE
	|	QuestionnaireQuestionAnswers.Questionnaire.Survey = &Survey
	|	AND (NOT QuestionnaireTemplateQuestions.TabularQuestionType = VALUE(Enum.TabularQuestionTypes.Composite))
	|	AND QuestionnaireTemplateQuestions.QuestionsType = VALUE(Enum.QuestionnaireTemplateQuestionTypes.Tabular)
	|	AND QuestionsForSurvey.ReplyType IN (VALUE(Enum.QuestionAnswerTypes.Boolean), VALUE(Enum.QuestionAnswerTypes.OneVariantOf), VALUE(Enum.QuestionAnswerTypes.MultipleOptionsFor))
	|;
	|////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	QuestionnaireTemplateQuestions.Wording AS Description,
	|	QuestionnaireTemplateQuestions.Ref AS TemplateQuestion,
	|	QuestionnaireTemplateQuestions.IsFolder AS IsSection,
	|	MainQuery.ElementaryQuestionRegister,
	|	MainQuery.CellNumber AS CellNumber,
	|	MainQuery.AnswerOption,
	|	ISNULL(MainQuery.DifferentItemsCount, 0) AS Count,
	|	ISNULL(MainQuery.MIN, 0) AS MIN,
	|	ISNULL(MainQuery.MAX, 0) AS MAX,
	|	ISNULL(MainQuery.Mean, 0) AS Mean,
	|	ISNULL(MainQuery.SUM, 0) AS SUM,
	|	MainQuery.ReplyType,
	|	QuestionnaireTemplateQuestions.QuestionsType,
	|	QuestionnaireTemplateQuestions.TabularQuestionType,
	|	QuestionnaireTemplateQuestions.TabularQuestionComposition.(
	|		LineNumber,
	|		ElementaryQuestion
	|	),
	|	QuestionnaireTemplateQuestions.PredefinedAnswers.(
	|		LineNumber AS LineNumber,
	|		ElementaryQuestion AS ElementaryQuestionAnswer,
	|		Response
	|	),
	|	MainQuery.ShowAggregatedValuesInReports
	|{SELECT
	|	ElementaryQuestion.*}
	|FROM
	|	(SELECT
	|		QuestionnaireTemplateQuestionsOptions.Ref                    AS TemplateQuestion,
	|		QuestionnaireTemplateQuestionsOptions.IsSection                 AS IsSection,
	|		RegisterData.ElementaryQuestion                      AS ElementaryQuestionRegister,
	|		RegisterData.CellNumber                             AS CellNumber,
	|		RegisterData.AnswerOption                           AS AnswerOption,
	|		RegisterData.DifferentItemsCount                     AS DifferentItemsCount,
	|		RegisterData.MIN                                 AS MIN,
	|		RegisterData.MAX                                AS MAX,
	|		RegisterData.Mean                                 AS Mean,
	|		RegisterData.SUM                                   AS SUM,
	|		QuestionnaireTemplateQuestionsOptions.ReplyType                 AS ReplyType,
	|		QuestionnaireTemplateQuestionsOptions.ShowAggregatedValuesInReports AS ShowAggregatedValuesInReports,
	|		0 AS                                                  ResponseOptionCode
	|	FROM
	|		QuestionnaireTemplateQuestionsOptions AS QuestionnaireTemplateQuestionsOptions
	|			LEFT JOIN RegisterData AS RegisterData
	|			ON QuestionnaireTemplateQuestionsOptions.Ref = RegisterData.Question
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		QuestionnaireTemplateQuestionsQuestions.Ref,
	|		QuestionnaireTemplateQuestionsQuestions.IsSection,
	|		ISNULL(RegisterDataBooleanResponseOptions.ElementaryQuestion, QuestionnaireTemplateQuestionsQuestions.ElementaryQuestion),
	|		RegisterDataBooleanResponseOptions.CellNumber,
	|		QuestionnaireTemplateQuestionsQuestions.AnswerOption,
	|		RegisterDataBooleanResponseOptions.DifferentItemsCount,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		QuestionnaireTemplateQuestionsQuestions.ReplyType,
	|		QuestionnaireTemplateQuestionsQuestions.ShowAggregatedValuesInReports,
	|		QuestionnaireTemplateQuestionsQuestions.Code
	|	FROM
	|		QuestionnaireTemplateQuestionsQuestions AS QuestionnaireTemplateQuestionsQuestions
	|			LEFT JOIN RegisterDataBooleanResponseOptions AS RegisterDataBooleanResponseOptions
	|			ON QuestionnaireTemplateQuestionsQuestions.Ref = RegisterDataBooleanResponseOptions.Question
	|				AND QuestionnaireTemplateQuestionsQuestions.AnswerOption = RegisterDataBooleanResponseOptions.AnswerOption
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		QuestionnaireTemplateQuestionsTableQuestionComposition.Ref,
	|		QuestionnaireTemplateQuestions.IsFolder,
	|		QuestionnaireTemplateQuestionsTableQuestionComposition.ElementaryQuestion,
	|		AnswersToTableQuestions.CellNumber,
	|		NULL,
	|		COUNT(DISTINCT AnswersToTableQuestions.Response),
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL
	|	FROM
	|		Catalog.QuestionnaireTemplateQuestions.TabularQuestionComposition AS QuestionnaireTemplateQuestionsTableQuestionComposition
	|			LEFT JOIN ChartOfCharacteristicTypes.QuestionsForSurvey AS QuestionsForSurvey
	|			ON QuestionnaireTemplateQuestionsTableQuestionComposition.ElementaryQuestion = QuestionsForSurvey.Ref
	|			LEFT JOIN AnswersToTableQuestions AS AnswersToTableQuestions
	|			ON QuestionnaireTemplateQuestionsTableQuestionComposition.Ref = AnswersToTableQuestions.Question
	|				AND QuestionnaireTemplateQuestionsTableQuestionComposition.ElementaryQuestion = AnswersToTableQuestions.ElementaryQuestion
	|			LEFT JOIN Catalog.QuestionnaireTemplateQuestions AS QuestionnaireTemplateQuestions
	|			ON QuestionnaireTemplateQuestionsTableQuestionComposition.Ref = QuestionnaireTemplateQuestions.Ref
	|	WHERE
	|		QuestionnaireTemplateQuestionsTableQuestionComposition.Ref IN
	|				(SELECT
	|					QuestionnaireTemplateQuestions.Ref
	|				FROM
	|					Catalog.QuestionnaireTemplateQuestions AS QuestionnaireTemplateQuestions
	|				WHERE
	|					QuestionnaireTemplateQuestions.QuestionsType = VALUE(Enum.QuestionnaireTemplateQuestionTypes.Tabular)
	|					AND QuestionnaireTemplateQuestions.Owner = &QuestionnaireTemplate
	|					AND (NOT QuestionnaireTemplateQuestions.TabularQuestionType = VALUE(Enum.TabularQuestionTypes.Composite)))
	|		AND QuestionsForSurvey.ReplyType IN (VALUE(Enum.QuestionAnswerTypes.Boolean), VALUE(Enum.QuestionAnswerTypes.OneVariantOf), VALUE(Enum.QuestionAnswerTypes.MultipleOptionsFor))
	|	
	|	GROUP BY
	|		QuestionnaireTemplateQuestionsTableQuestionComposition.Ref,
	|		QuestionnaireTemplateQuestions.IsFolder,
	|		QuestionnaireTemplateQuestionsTableQuestionComposition.ElementaryQuestion,
	|		AnswersToTableQuestions.CellNumber) AS MainQuery
	|		LEFT JOIN Catalog.QuestionnaireTemplateQuestions AS QuestionnaireTemplateQuestions
	|		ON MainQuery.TemplateQuestion = QuestionnaireTemplateQuestions.Ref
	|
	|ORDER BY
	|	TemplateQuestion,
	|	MainQuery.ResponseOptionCode,
	|	CellNumber
	|TOTALS BY
	|	TemplateQuestion HIERARCHY";
	
	Query.SetParameter("Survey", Survey);
	Query.SetParameter("QuestionnaireTemplate",QuestionnaireTemplate);
	
	Return Query.Execute();
	
EndFunction

// Converts aggregate query values to a string for further output to a report.
//
// Parameters:
//   TreeRow - value tree row - a tree row whose data will be converted.
//
// Returns - String - a string to be output to a report.
//
Function AggregateValuesToString(TreeRow,ShowAggregatedValuesInReports = Undefined)
	
	If TypeOf(TreeRow.Maximum) = Type("Date") Then
		Max = Format(TreeRow.Maximum, "DLF=D");
	Else
		Max = Format(Round(TreeRow.Maximum,2),"NDS=.");
	EndIf;
	
	If TypeOf(TreeRow.Minimum) = Type("Date") Then
		Min = Format(TreeRow.Minimum, "DLF=D");
	Else
		Min = Format(Round(TreeRow.Minimum,2),"NDS=.");
	EndIf;
	
	Count = Format(TreeRow.Count,"NDS=.");
	Mean    = Format(Round(TreeRow.Mean,2),"NDS=.");
	Sum      = Format(Round(TreeRow.Sum,2),"NDS=.");
	
	SlashString = " / ";
	
	ReturnString = "" + ?(IsBlankString(Count),"",Count) + Chars.LF 
	+ ?(IsBlankString(Min),"",Min + SlashString)+ ?(IsBlankString(Max),"",Max + SlashString) + ?(IsBlankString(Mean),"",Mean)
	+ ?(?(ShowAggregatedValuesInReports = Undefined,TreeRow.ShowAggregatedValuesInReports,ShowAggregatedValuesInReports),Chars.LF + ?(IsBlankString(Sum) = "∑ 0","","∑ " + Sum),"");
	
	QuestioningClientServer.DeleteLastCharsFromString(ReturnString,SlashString);
	
	Return ReturnString;
	
EndFunction

#EndRegion

#Region RespondersAnalysis

// Generates report in the respondents analysis option.
//
// Parameters:
//  ReportTable - SpreadsheetDocument - a spreadsheet document in which report is output.
//  Survey - Document.SurveyPurpose - a survey for which the report is created.
//
Procedure GenerateRespondersAnalysisReport(ReportTable,Survey)

	AttributesSurvey = Common.ObjectAttributesValues(Survey,"QuestionnaireTemplate,RespondentsType,FreeSurvey,StartDate,EndDate,Presentation");
	
	If AttributesSurvey.FreeSurvey Then
		QueryResult = ExecuteQueryOnFreeFormSurveysRespondents(Survey, AttributesSurvey.RespondentsType);
	Else
		QueryResult = ExecuteQueryOnSurveysRespondentsWithSpecificCompositionOfRespondents(Survey);
	EndIf;
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	OutputRespondersQueryResultToSpreadsheetDocument(QueryResult,AttributesSurvey,ReportTable);

EndProcedure

// Processes the query result and outputs to a spreadsheet document.
//
// Parameters:
//  QueryResult - QueryResult - an executed query result.
//  AttributesSurvey   - Structure - contains values of the SurveyPurpose attributes.
//  ReportTable - SpreadsheetDocument - a spreadsheet document in which report is output.
//
Procedure OutputRespondersQueryResultToSpreadsheetDocument(QueryResult,AttributesSurvey,ReportTable)
	
	Template = GetTemplate("AnsweredTemplate");
	
	Area = Template.GetArea("Title");
	Area.Parameters.Title = AttributesSurvey.QuestionnaireTemplate.Title;
	Area.Parameters.Survey 	= GetSurveyPresentationForHeader(AttributesSurvey);
	ReportTable.Put(Area,1);
	
	OverallSelection = QueryResult.Select(QueryResultIteration.ByGroups);
	While OverallSelection.Next() Do
		
		OutputRespondentsRowToSpreadsheetDocument(OverallSelection,Template,ReportTable,"Overall");
		ReportTable.StartRowGroup("Overall");
		
		AnsweredSelection = OverallSelection.Select(QueryResultIteration.ByGroups);
		While AnsweredSelection.Next() Do
			OutputRespondentsRowToSpreadsheetDocument(AnsweredSelection,Template,ReportTable,"TotalResponse");
			ReportTable.StartRowGroup("AnsweredTotal");
			DetailsSelection = AnsweredSelection.Select();
			While DetailsSelection.Next() Do
				OutputRespondentsRowToSpreadsheetDocument(DetailsSelection,Template,ReportTable,"Respondent");
			EndDo;
			ReportTable.EndRowGroup();
		EndDo;
		ReportTable.EndRowGroup();
	EndDo;
	
EndProcedure

// Outputs a string to the spreadsheet document.
//
// Parameters:
//  Selection - QueryResultSelection - a selection containing the data to be displayed in the report.
//  Template - SpreadsheetDocument - a spreadsheet document containing the report template.
//  ReportTable - SpreadsheetDocument - a spreadsheet document in which output is being carried out.
//  AreaName - String - a name of the template area to be used for output.
//
Procedure OutputRespondentsRowToSpreadsheetDocument(Selection,Template,ReportTable,AreaName);
	
	Area = Template.GetArea(AreaName);
	If Selection.RecordType() = QueryRecordType.Overall Then
		Area.Parameters.Count = Selection.Respondent;
	ElsIf Selection.RecordType() = QueryRecordType.GroupTotal Then
		Area.Parameters.Count = Selection.Respondent;
		Area.Parameters.Answered    = Selection.Answered;
	Else
		Area.Parameters.Respondent = Selection.Respondent;
	EndIf;
	ReportTable.Put(Area);
	
EndProcedure

// Generates and executes a query for free-form surveys.
//
// Parameters:
//  Survey - Document.SurveyPurpose - a survey for which the report is created.
// Returns:
//   QueryResult - an executed query result.
//
Function ExecuteQueryOnSurveysRespondentsWithSpecificCompositionOfRespondents(Survey)
	
	Query = New Query;
	Query.Text = "
	|SELECT DISTINCT
	|	Questionnaire.Respondent,
	|	Questionnaire.Posted
	|INTO RespondentsThatAnswered
	|FROM
	|	Document.Questionnaire AS Questionnaire
	|WHERE
	|	Questionnaire.Survey = &Survey
	|	AND (NOT Questionnaire.DeletionMark)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CASE
	|		WHEN RespondentsThatAnswered.Respondent IS NULL 
	|			THEN &NotFilled
	|		ELSE CASE
	|				WHEN RespondentsThatAnswered.Posted
	|					THEN &Filled
	|				ELSE &StartedFilling
	|			END
	|	END AS Answered,
	|	PollsPurposeRespondents.Respondent AS Respondent
	|FROM
	|	Document.PollPurpose.Respondents AS PollsPurposeRespondents
	|		LEFT JOIN RespondentsThatAnswered AS RespondentsThatAnswered
	|		ON (RespondentsThatAnswered.Respondent = PollsPurposeRespondents.Respondent)
	|WHERE
	|	PollsPurposeRespondents.Ref = &Survey
	|
	|ORDER BY
	|	Answered,
	|	Respondent
	|TOTALS
	|	COUNT(DISTINCT Respondent)
	|BY
	|	OVERALL,
	|	Answered";
	
	Query.SetParameter("Survey",Survey);
	Query.SetParameter("Filled",NStr("ru = 'Заполнил'; en = 'Filled'; pl = 'Filled';de = 'Filled';ro = 'Filled';tr = 'Filled'; es_ES = 'Filled'"));
	Query.SetParameter("StartedFilling",NStr("ru = 'Начал заполнять'; en = 'Started filling'; pl = 'Started filling';de = 'Started filling';ro = 'Started filling';tr = 'Started filling'; es_ES = 'Started filling'"));
	Query.SetParameter("NotFilled",NStr("ru = 'Не заполнял'; en = 'Not filled'; pl = 'Not filled';de = 'Not filled';ro = 'Not filled';tr = 'Not filled'; es_ES = 'Not filled'"));
	
	Return Query.Execute();
	
EndFunction

// Generates and executes a query for free-form surveys.
//
// Parameters:
//  Survey - Document.SurveyPurpose - a survey for which the report is created.
//  RespondentType - CatalogRef - an empty reference to the catalog the elements of which are 
//                    respondents for this survey.
// Returns:
//   QueryResult - an executed query result.
//
Function ExecuteQueryOnFreeFormSurveysRespondents(Survey,RespondentType)
	
	RespondentTypeMetadata = RespondentType.Metadata();
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	CatalogTable.Ref
	|INTO CatalogData
	|FROM
	|	" + RespondentTypeMetadata.FullName() + " AS CatalogTable
	|WHERE
	|	(NOT CatalogTable.DeletionMark)
	|	" + ?(RespondentTypeMetadata.Hierarchical AND RespondentTypeMetadata.HierarchyType = Metadata.ObjectProperties.HierarchyType.HierarchyFoldersAndItems,
	         " AND (NOT CatalogTable.IsFolder)","") + "
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Questionnaire.Respondent,
	|	Questionnaire.Posted
	|INTO RespondentsThatAnswered
	|FROM
	|	Document.Questionnaire AS Questionnaire
	|WHERE
	|	(NOT Questionnaire.DeletionMark)
	|	AND Questionnaire.Survey = &Survey
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CASE
	|		WHEN RespondentsThatAnswered.Respondent IS NULL 
	|			THEN &NotFilled
	|		ELSE CASE
	|				WHEN RespondentsThatAnswered.Posted
	|					THEN &Filled
	|				ELSE &StartedFilling
	|			END
	|	END AS Answered,
	|	CatalogData.Ref AS Respondent
	|FROM
	|	CatalogData AS CatalogData
	|		LEFT JOIN RespondentsThatAnswered AS RespondentsThatAnswered
	|		ON CatalogData.Ref = RespondentsThatAnswered.Respondent
	|
	|ORDER BY
	|	Answered,
	|   Respondent
	|TOTALS
	|	COUNT(DISTINCT Respondent)
	|BY
	|	OVERALL,
	|	Answered";
	
	Query.SetParameter("Survey",Survey);
	Query.SetParameter("Filled",NStr("ru = 'Заполнил'; en = 'Filled'; pl = 'Filled';de = 'Filled';ro = 'Filled';tr = 'Filled'; es_ES = 'Filled'"));
	Query.SetParameter("StartedFilling",NStr("ru = 'Начал заполнять'; en = 'Started filling'; pl = 'Started filling';de = 'Started filling';ro = 'Started filling';tr = 'Started filling'; es_ES = 'Started filling'"));
	Query.SetParameter("NotFilled",NStr("ru = 'Не заполнял'; en = 'Not filled'; pl = 'Not filled';de = 'Not filled';ro = 'Not filled';tr = 'Not filled'; es_ES = 'Not filled'"));
	
	Return Query.Execute();
	
EndFunction

#EndRegion

#Region OtherProceduresAndFunctions

// Generates the survey presentation for the report header.
Function GetSurveyPresentationForHeader(AttributesSurvey)
	
	SurveyPresentationForHeader =  NStr("ru='Опрос'; en = 'Survey'; pl = 'Survey';de = 'Survey';ro = 'Survey';tr = 'Survey'; es_ES = 'Survey'") + " ";
	If AttributesSurvey.StartDate <> Date(1,1,1) OR AttributesSurvey.EndDate <> Date(1,1,1) Then
		SurveyPresentationForHeader = SurveyPresentationForHeader + NStr("ru='проводился в период'; en = 'was carried out'; pl = 'was carried out';de = 'was carried out';ro = 'was carried out';tr = 'was carried out'; es_ES = 'was carried out'") + " ";
	EndIf;
	
	If AttributesSurvey.StartDate <> Date(1,1,1) Then
		SurveyPresentationForHeader = SurveyPresentationForHeader + NStr("ru='с'; en = 'from'; pl = 'from';de = 'from';ro = 'from';tr = 'from'; es_ES = 'from'") + " " + Format(AttributesSurvey.StartDate,"DF=dd.MM.yy") + " ";
	EndIf;
	
	If AttributesSurvey.EndDate <> Date(1,1,1) Then
		SurveyPresentationForHeader = SurveyPresentationForHeader + NStr("ru = 'по'; en = 'to'; pl = 'to';de = 'to';ro = 'to';tr = 'to'; es_ES = 'to'") + " " + Format(AttributesSurvey.EndDate,"DF=dd.MM.yy")+ " ";
	EndIf; 
	
	SurveyPresentationForHeader = SurveyPresentationForHeader + NStr("ru = 'на основании документа'; en = 'based on document'; pl = 'based on document';de = 'based on document';ro = 'based on document';tr = 'based on document'; es_ES = 'based on document'") + " " + AttributesSurvey.Presentation + ".";
	
	Return SurveyPresentationForHeader;
	
EndFunction

#EndRegion

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Invalid object call on the client.';de = 'Invalid object call on the client.';ro = 'Invalid object call on the client.';tr = 'Invalid object call on the client.'; es_ES = 'Invalid object call on the client.'");
#EndIf