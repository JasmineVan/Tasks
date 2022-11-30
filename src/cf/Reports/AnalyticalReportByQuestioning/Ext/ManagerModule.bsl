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

// StandardSubsystems.ReportsOptions

// See ReportsOptionsOverridable.CustomizeReportsOptions. 
//
Procedure CustomizeReportOptions(Settings, ReportSettings) Export
	ModuleReportsOptions = Common.CommonModule("ReportsOptions");
	ModuleReportsOptions.SetOutputModeInReportPanes(Settings, ReportSettings, False);
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "ViewAnswersSimpleQuestions");
	OptionSettings.Details = NStr("ru = 'Информация о том, как отвечали респонденты на простые вопросы.'; en = 'Information about how respondents answered simple questions.'; pl = 'Information about how respondents answered simple questions.';de = 'Information about how respondents answered simple questions.';ro = 'Information about how respondents answered simple questions.';tr = 'Information about how respondents answered simple questions.'; es_ES = 'Information about how respondents answered simple questions.'");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "ViewTableQuestionsFlatView");
	OptionSettings.Details = 
		NStr("ru = 'Информация о том, как отвечали респонденты на табличные вопросы.
		|Выводится в виде списка с группировками.'; 
		|en = 'Information about answers the respondents gave to table questions.
		|Displayed as a list with grouping.'; 
		|pl = 'Information about answers the respondents gave to table questions.
		|Displayed as a list with grouping.';
		|de = 'Information about answers the respondents gave to table questions.
		|Displayed as a list with grouping.';
		|ro = 'Information about answers the respondents gave to table questions.
		|Displayed as a list with grouping.';
		|tr = 'Information about answers the respondents gave to table questions.
		|Displayed as a list with grouping.'; 
		|es_ES = 'Information about answers the respondents gave to table questions.
		|Displayed as a list with grouping.'");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "ViewTableQuestionsTableView");
	OptionSettings.Details = 
		NStr("ru = 'Информация о том, как  отвечали респонденты на табличные вопросы.
		|Каждый ответ респондента представлен в виде таблицы.'; 
		|en = 'Information about answers the respondents gave to table questions.
		|Each response is displayed as a table.'; 
		|pl = 'Information about answers the respondents gave to table questions.
		|Each response is displayed as a table.';
		|de = 'Information about answers the respondents gave to table questions.
		|Each response is displayed as a table.';
		|ro = 'Information about answers the respondents gave to table questions.
		|Each response is displayed as a table.';
		|tr = 'Information about answers the respondents gave to table questions.
		|Each response is displayed as a table.'; 
		|es_ES = 'Information about answers the respondents gave to table questions.
		|Each response is displayed as a table.'");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "SimpleQuestionsAnswerCount");
	OptionSettings.Details = NStr("ru = 'Информация о том, сколько раз был дан вариант ответа на простой вопрос.'; en = 'Information on how many times the response option was given for a simple question.'; pl = 'Information on how many times the response option was given for a simple question.';de = 'Information on how many times the response option was given for a simple question.';ro = 'Information on how many times the response option was given for a simple question.';tr = 'Information on how many times the response option was given for a simple question.'; es_ES = 'Information on how many times the response option was given for a simple question.'");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "SimpleQuestionsAggregatedIndicators");
	OptionSettings.Details = 
		NStr("ru = 'Информация о среднем, минимальном, максимальном ответе на простой вопрос,
		|который требует числового ответа.'; 
		|en = 'Information on average, minimum, and maximum response to a simple question
		|that requires a numeric value.'; 
		|pl = 'Information on average, minimum, and maximum response to a simple question
		|that requires a numeric value.';
		|de = 'Information on average, minimum, and maximum response to a simple question
		|that requires a numeric value.';
		|ro = 'Information on average, minimum, and maximum response to a simple question
		|that requires a numeric value.';
		|tr = 'Information on average, minimum, and maximum response to a simple question
		|that requires a numeric value.'; 
		|es_ES = 'Information on average, minimum, and maximum response to a simple question
		|that requires a numeric value.'");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "TableQuestionsAnswerCount");
	OptionSettings.Details = 
		NStr("ru = 'Информация о том, сколько раз был дан варианта ответа для табличных вопросов,
		|который требует указания числового значения.'; 
		|en = 'Information on how many times the response option which requires a numeric value 
		|was given for the table questions.'; 
		|pl = 'Information on how many times the response option which requires a numeric value 
		|was given for the table questions.';
		|de = 'Information on how many times the response option which requires a numeric value 
		|was given for the table questions.';
		|ro = 'Information on how many times the response option which requires a numeric value 
		|was given for the table questions.';
		|tr = 'Information on how many times the response option which requires a numeric value 
		|was given for the table questions.'; 
		|es_ES = 'Information on how many times the response option which requires a numeric value 
		|was given for the table questions.'");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "TableQuestionsAggregatedParameters");
	OptionSettings.Details = 
		NStr("ru = 'Информация о среднем, минимальном, максимальном ответе в ячейке табличного вопроса,
		|который требует указания числового значения.'; 
		|en = 'Information on average, minimum, and maximum response in the cell of a table question 
		|that requires a numeric value.'; 
		|pl = 'Information on average, minimum, and maximum response in the cell of a table question 
		|that requires a numeric value.';
		|de = 'Information on average, minimum, and maximum response in the cell of a table question 
		|that requires a numeric value.';
		|ro = 'Information on average, minimum, and maximum response in the cell of a table question 
		|that requires a numeric value.';
		|tr = 'Information on average, minimum, and maximum response in the cell of a table question 
		|that requires a numeric value.'; 
		|es_ES = 'Information on average, minimum, and maximum response in the cell of a table question 
		|that requires a numeric value.'");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "SimpleQuestionsAnswerCountComparisonBySurveys");
	OptionSettings.Details = 
		NStr("ru = 'Сравнительный анализ количества данных вариантов ответов 
		|на простые вопросы в разных опросах.'; 
		|en = 'Comparative analysis of the number of options of responses
		|to simple questions in different surveys.'; 
		|pl = 'Comparative analysis of the number of options of responses
		|to simple questions in different surveys.';
		|de = 'Comparative analysis of the number of options of responses
		|to simple questions in different surveys.';
		|ro = 'Comparative analysis of the number of options of responses
		|to simple questions in different surveys.';
		|tr = 'Comparative analysis of the number of options of responses
		|to simple questions in different surveys.'; 
		|es_ES = 'Comparative analysis of the number of options of responses
		|to simple questions in different surveys.'");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "TableQuestionsAggregatedParametersComparisonBySurveys");
	OptionSettings.Details = 
		NStr("ru = 'Сравнительный анализ агрегируемых показателей ответов в ячейках
		|табличных вопросов разных опросов.'; 
		|en = 'Comparative analysis of aggregated response indicators 
		|in cells of table questions of different surveys.'; 
		|pl = 'Comparative analysis of aggregated response indicators 
		|in cells of table questions of different surveys.';
		|de = 'Comparative analysis of aggregated response indicators 
		|in cells of table questions of different surveys.';
		|ro = 'Comparative analysis of aggregated response indicators 
		|in cells of table questions of different surveys.';
		|tr = 'Comparative analysis of aggregated response indicators 
		|in cells of table questions of different surveys.'; 
		|es_ES = 'Comparative analysis of aggregated response indicators 
		|in cells of table questions of different surveys.'");
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf