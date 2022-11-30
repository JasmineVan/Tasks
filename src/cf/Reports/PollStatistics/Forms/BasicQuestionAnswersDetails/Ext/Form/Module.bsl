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
	
	ProcessIncomingParameters(Cancel);
	
	If Cancel Then
		Return;
	EndIf;
	
	CaptionPattern =  NStr("ru = 'Ответы на вопрос № %1 опроса %2 +  от %3.'; en = 'Responses to question No. %1 of survey %2 + dated %3.'; pl = 'Responses to question No. %1 of survey %2 + dated %3.';de = 'Responses to question No. %1 of survey %2 + dated %3.';ro = 'Responses to question No. %1 of survey %2 + dated %3.';tr = 'Responses to question No. %1 of survey %2 + dated %3.'; es_ES = 'Responses to question No. %1 of survey %2 + dated %3.'");
	Title = StringFunctionsClientServer.SubstituteParametersToString(CaptionPattern, FullCode, SurveyDescription, Format(SurveyDate,"DLF=D"));
	
	GenerateReport();
	
EndProcedure

&AtClient
Procedure ReportsOptionOnChange(Item)
	
	GenerateReport();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure GenerateReport()
	
	ReportTable.Clear();
	DCS = Reports.PollStatistics.GetTemplate("SimpleQuestions");
	Settings = DCS.SettingVariants[ReportOption].Settings;
	
	DCS.Parameters.QuestionnaireTemplateQuestion.Value = QuestionnaireTemplateQuestion;
	DCS.Parameters.Survey.Value               = Survey;
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DCS,Settings);
	
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(CompositionTemplate);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ReportTable);
	OutputProcessor.Output(DataCompositionProcessor);
	
	ReportTable.ShowGrid = False;
	ReportTable.ShowHeaders = False;
	
EndProcedure

// Processes incoming form parameters.
//
// Returns:
//   Boolean - cancel the form startup.
//
&AtServer
Procedure ProcessIncomingParameters(Cancel)

	If Parameters.Property("QuestionnaireTemplateQuestion") Then	
		QuestionnaireTemplateQuestion = Parameters.QuestionnaireTemplateQuestion; 
	Else
		Cancel = True;
	EndIf;
	
	If Parameters.Property("Survey") Then
		Survey =  Parameters.Survey; 
	Else
		Cancel = True;
	EndIf;
	
	If Parameters.Property("FullCode") Then
		FullCode =  Parameters.FullCode;
	Else
		Cancel = True;
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
	
	If Parameters.Property("ReportOption") Then
		ReportOption = Parameters.ReportOption;
	Else
		Cancel = True;
	EndIf;

EndProcedure

#EndRegion
