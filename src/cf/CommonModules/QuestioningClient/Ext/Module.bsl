///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Creates a filter structure for its further transfer to the server and usage as filter parameters 
// in dynamic lists of forms to be called.
//
Function CreateFilterParameterStructure(FilterType,LeftValue,ComparisonType,RightValue) Export

	ReturnStructure = New Structure;
	ReturnStructure.Insert("FilterType",FilterType);
	ReturnStructure.Insert("LeftValue",LeftValue);
	ReturnStructure.Insert("ComparisonType",ComparisonType);
	ReturnStructure.Insert("RightValue",RightValue);
	
	Return ReturnStructure;

EndFunction

// Starts an interview with the selected respondent.
//
// Parameters:
//  Respondent   - DefinedType.Respondent - an interviewee.
//  QuestionnaireTemplate - CatalogRef.QuestionnaireTemplates - a template used for interview.
//               - Undefined - a user selects a template from the catalog.
//
Procedure StartInterview(Respondent, QuestionnaireTemplate=Undefined) Export
	
	If QuestionnaireTemplate=Undefined Then
	
		NotifyDescription = New NotifyDescription("StartInterviewWithTemplateChoiceCompletion", ThisObject, Respondent);
		
		ShowInputValue(NotifyDescription, Undefined, , Type("CatalogRef.QuestionnaireTemplates"));
		
	Else
		
		OpenInterviewForm(Respondent, QuestionnaireTemplate);
		
	EndIf;
		
EndProcedure

// Opens the form of a new questionnaire in interview mode with the selected respondent and questionnaire template.
//
Procedure OpenInterviewForm(Respondent, QuestionnaireTemplate)
	
	FillingValues = New Structure;
	FillingValues.Insert("Respondent", Respondent);
	FillingValues.Insert("QuestionnaireTemplate", QuestionnaireTemplate);
	FillingValues.Insert("SurveyMode", PredefinedValue("Enum.SurveyModes.Interview"));
	
	FormParameters = New Structure;
	FormParameters.Insert("FillingValues", FillingValues);
	FormParameters.Insert("FillingFormOnly", True);
	
	QuestionnaireForm = OpenForm("Document.Questionnaire.ObjectForm", FormParameters);
	
	If QuestionnaireForm <> Undefined Then
		FillPropertyValues(QuestionnaireForm, FillingValues);
	EndIf;
	
EndProcedure

// StartInterviewWithTemplateChoice procedure execution result handler.
//
Procedure StartInterviewWithTemplateChoiceCompletion(SelectedTemplate, Respondent) Export
	
	If SelectedTemplate = Undefined Then
		Return;
	EndIf;
	
	OpenInterviewForm(Respondent, SelectedTemplate);	
	
EndProcedure

#EndRegion
