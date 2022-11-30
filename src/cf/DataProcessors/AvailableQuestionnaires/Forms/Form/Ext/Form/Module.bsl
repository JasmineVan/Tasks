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
	
	Object.SurveyMode = Enums.SurveyModes.Questionnaire;
	If Parameters.Property("SurveyMode") Then
		Object.SurveyMode = Parameters.SurveyMode;
		Object.Respondent = Parameters.Respondent;
	Else
		CurrentUser = Users.AuthorizedUser();
		If TypeOf(CurrentUser) <> Type("CatalogRef.ExternalUsers") Then 
			Object.Respondent = CurrentUser;
		Else	
			Object.Respondent = ExternalUsers.GetExternalUserAuthorizationObject(CurrentUser);
		EndIf;
	EndIf;
	
	RespondentQuestionnairesTable();
	 
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_Questionnaire" OR EventName = "Posting_Questionnaire" Then
		RespondentQuestionnairesTable();
	EndIf;
	
EndProcedure 

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure QuestionnairesTreeBeforeChange(Item, Cancel)
	
	Cancel = True;
	
	CurrentData = Items.QuestionnairesTable.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If TypeOf(CurrentData.QuestionnaireSurvey) = Type("DocumentRef.Questionnaire") Then
		ParametersStructure = New Structure;
		ParametersStructure.Insert("Key",CurrentData.QuestionnaireSurvey);
		ParametersStructure.Insert("FillingFormOnly",True);
		ParametersStructure.Insert("SurveyMode", Object.SurveyMode);
		OpenForm("Document.Questionnaire.Form.DocumentForm",ParametersStructure,Item);
	ElsIf TypeOf(CurrentData.QuestionnaireSurvey) = Type("DocumentRef.PollPurpose") Then
		ParametersStructure = New Structure;
		FillingValues 	= New Structure;
		FillingValues.Insert("Respondent",Object.Respondent);
		FillingValues.Insert("Survey",CurrentData.QuestionnaireSurvey);
		FillingValues.Insert("SurveyMode", Object.SurveyMode);
		ParametersStructure.Insert("FillingValues",FillingValues);
		ParametersStructure.Insert("FillingFormOnly",True);
		OpenForm("Document.Questionnaire.Form.DocumentForm",ParametersStructure,Item);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure ArchiveQuestionnaire(Command)
	
	OpenForm("DataProcessor.AvailableQuestionnaires.Form.ArchivedQuestionnaire",New Structure("Respondent",Object.Respondent),ThisObject);
	
EndProcedure 

&AtClient
Procedure Update(Command)
	
	RespondentQuestionnairesTable();
	
EndProcedure 

#EndRegion

#Region Private

&AtServer
Procedure RespondentQuestionnairesTable()
	
	QuestionnairesTable.Clear();
	
	ReceivedQuestionnairesTable = Survey.TableOfQuestionnairesAvailableToRespondent(Object.Respondent);
	
	If ReceivedQuestionnairesTable <> Undefined Then
		
		For each TableRow In ReceivedQuestionnairesTable Do
			
			NewRow = QuestionnairesTable.Add();
			If NOT ValueIsFilled(TableRow.QuestionnaireSurvey) Then
				
				NewRow.Presentation = TableRow.Status;
				NewRow.Status        = TableRow.Status;
				
			Else
				
				NewRow.Status        = TableRow.Status;
				NewRow.QuestionnaireSurvey   = TableRow.QuestionnaireSurvey;
				NewRow.Presentation = GetQuestionnaireTreeRowsPresentation(TableRow);
				
			EndIf;
			
		EndDo;
		
		NewRow.PictureCode = ?(TableRow.Status = "Surveys",0,1);
		
	EndIf;
	
EndProcedure

// Generates a row presentation for the questionnaires tree.
//
// Parameters:
//  TreeRow - ValueTreeRow - based on it, a presentation of questionnaires and surveys in the tree 
//                 is generated.
&AtServer
Function GetQuestionnaireTreeRowsPresentation(TreeRow)
	
	ReturnRow = "";
	
	EndDateSpecified = ValueIsFilled(TreeRow.EndDate);
	
	If TypeOf(TreeRow.QuestionnaireSurvey) = Type("DocumentRef.PollPurpose") Then
		ReturnRow = ReturnRow + NStr("ru = 'Анкета'; en = 'Questionnaire'; pl = 'Questionnaire';de = 'Questionnaire';ro = 'Questionnaire';tr = 'Questionnaire'; es_ES = 'Questionnaire'") + " '" + TreeRow.Description + "'";
	ElsIf TypeOf(TreeRow.QuestionnaireSurvey) = Type("DocumentRef.Questionnaire") Then
		ReturnRow = ReturnRow + NStr("ru = 'Анкета'; en = 'Questionnaire'; pl = 'Questionnaire';de = 'Questionnaire';ro = 'Questionnaire';tr = 'Questionnaire'; es_ES = 'Questionnaire'") + " '" + TreeRow.Description 
		+ "', " + NStr("ru = 'последний раз редактировавшаяся'; en = 'last edited'; pl = 'last edited';de = 'last edited';ro = 'last edited';tr = 'last edited'; es_ES = 'last edited'") + " " + Format(TreeRow.QuestionnaireDate, "DLF=D");
	Else	
		Return ReturnRow;
	EndIf;
	
	If EndDateSpecified Then
			ReturnRow = ReturnRow + ", " + NStr("ru = 'к заполнению до'; en = 'to fill out up to'; pl = 'to fill out up to';de = 'to fill out up to';ro = 'to fill out up to';tr = 'to fill out up to'; es_ES = 'to fill out up to'") + " " + Format(BegOfDay(EndOfDay(TreeRow.EndDate) + 1),"DLF=D");
	EndIf;
		
	ReturnRow = ReturnRow + ".";
	
	Return ReturnRow;
	
EndFunction

#EndRegion
