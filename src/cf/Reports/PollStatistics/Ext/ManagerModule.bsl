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
	ModuleReportsOptions.SetOutputModeInReportPanes(Settings, ReportSettings, True);
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "");
	OptionSettings.Details = 
		NStr("ru = 'Информация о респондентах, заполнивших анкеты по опросу,
		|количестве ответов на вопросы, количестве данных вариантов ответов.'; 
		|en = 'Information on the number of respondents who filled out a questionnaire of the survey,
		|the number of responses to the questions, and the number of given response options.'; 
		|pl = 'Information on the number of respondents who filled out a questionnaire of the survey,
		|the number of responses to the questions, and the number of given response options.';
		|de = 'Information on the number of respondents who filled out a questionnaire of the survey,
		|the number of responses to the questions, and the number of given response options.';
		|ro = 'Information on the number of respondents who filled out a questionnaire of the survey,
		|the number of responses to the questions, and the number of given response options.';
		|tr = 'Information on the number of respondents who filled out a questionnaire of the survey,
		|the number of responses to the questions, and the number of given response options.'; 
		|es_ES = 'Information on the number of respondents who filled out a questionnaire of the survey,
		|the number of responses to the questions, and the number of given response options.'");
	OptionSettings.SearchSettings.FieldDescriptions = 
		NStr("ru = 'Респондент
		|Опрос
		|Вопрос
		|Ответ'; 
		|en = 'Respondent
		|Survey
		|Question
		|Response'; 
		|pl = 'Respondent
		|Survey
		|Question
		|Response';
		|de = 'Respondent
		|Survey
		|Question
		|Response';
		|ro = 'Respondent
		|Survey
		|Question
		|Response';
		|tr = 'Respondent
		|Survey
		|Question
		|Response'; 
		|es_ES = 'Respondent
		|Survey
		|Question
		|Response'");
	OptionSettings.SearchSettings.FilterParameterDescriptions = 
		NStr("ru = 'Опрос
		|Вид отчета'; 
		|en = 'Survey
		|Report kind'; 
		|pl = 'Survey
		|Report kind';
		|de = 'Survey
		|Report kind';
		|ro = 'Survey
		|Report kind';
		|tr = 'Survey
		|Report kind'; 
		|es_ES = 'Survey
		|Report kind'");
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf