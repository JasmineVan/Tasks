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
	
	SetConditionalAppearance();
	
	If Parameters.Property("Respondent") Then
		Object.Respondent = Parameters.Respondent;
	Else
		SetRespondentAccordingToCurrentExternalUser();
	EndIf;
	SetDynamicListParametersOfQuestionnairesTree();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CompletedSurveysValueChoice(Item, Value, StandardProcessing)
	
	CurrentData = Items.CompletedSurveys.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("Key",CurrentData.Questionnaire);
	ParametersStructure.Insert("FillingFormOnly",True);
	ParametersStructure.Insert("ReadOnly",True);
	
	OpenForm("Document.Questionnaire.Form.DocumentForm",ParametersStructure,Item);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetDynamicListParametersOfQuestionnairesTree()
	
	For each AvailableParameter In CompletedSurveys.Parameters.AvailableParameters.Items Do
		
		If AvailableParameter.Title = "Respondent" Then
			CompletedSurveys.Parameters.SetParameterValue(AvailableParameter.Parameter,Object.Respondent);
		EndIf;
		
	EndDo;
	
EndProcedure 

&AtServer
Procedure SetRespondentAccordingToCurrentExternalUser()
	
	CurrentUser = Users.AuthorizedUser();
	If TypeOf(CurrentUser) <> Type("CatalogRef.ExternalUsers") Then 
		Object.Respondent = CurrentUser;
	Else	
		Object.Respondent = ExternalUsers.GetExternalUserAuthorizationObject(CurrentUser);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "CompletedSurveys.FillingDate", Items.FillingDate.Name);
	
EndProcedure

#EndRegion
