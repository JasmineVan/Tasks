﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

// Form parameters:
//   ComplexQuestionComposition - CollectionFormData - with the following columns:
//    * ElementaryQuestion - ChartOfCharacteristicTypesRef.QuestionsForSurvey
//    * RowNumber - Number
//

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Accepting owner form parameters.
	ProcessOwnerFormParameters();
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Not ClosingInProgress AND IsNewLine Then
		Notify("CancelEnterNewQuestionnaireTemplateLine");
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure QuestionsQuestionChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	
	AttributesQuestion = QuestionAttributes(ValueSelected);
	If AttributesQuestion.IsFolder Then
		Return;
	EndIf;
	
	CurItem = Questions.FindByID(Items.Questions.CurrentRow);
	CurItem.ElementaryQuestion = ValueSelected;
	
	CurItem.Presentation = AttributesQuestion.Presentation;
	CurItem.Wording  = AttributesQuestion.Wording;
	CurItem.ReplyType     = AttributesQuestion.ReplyType;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure OKButton(Command)
	
	ClosingInProgress = True;
	Notify("EndEditComplexQuestionParameters",GenerateParametersStructureToPassToOwner());
	Close();
	
EndProcedure

#EndRegion

#Region Private

// Generates a return structure to pass to the owner form.
&AtClient
Function GenerateParametersStructureToPassToOwner()

	ParametersStructure = New Structure;
	
	QuestionsToReturn = New Array;
	For each TableRow In Questions Do
		QuestionsToReturn.Add(TableRow.ElementaryQuestion);
	EndDo;
	ParametersStructure.Insert("Questions",QuestionsToReturn);
	ParametersStructure.Insert("Wording",Wording);
	ParametersStructure.Insert("ToolTip",ToolTip);
	ParametersStructure.Insert("HintPlacement",HintPlacement);

	Return ParametersStructure;

EndFunction

// Processes owner form parameters.
//
&AtServer
Procedure ProcessOwnerFormParameters()
	
	Wording               = Parameters.Wording;
	ToolTip                  = Parameters.ToolTip;
	HintPlacement = Parameters.HintPlacement;
	IsNewLine             = Parameters.IsNewLine;
	
	Query = New Query;
	Query.Text = "SELECT DISTINCT
	|	Questions.ElementaryQuestion,
	|	Questions.LineNumber
	|INTO ElementaryQuestions
	|FROM
	|	&Questions AS Questions
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ElementaryQuestions.ElementaryQuestion AS ElementaryQuestion,
	|	ISNULL(QuestionsForSurvey.Presentation, """""""") AS Presentation,
	|	ISNULL(QuestionsForSurvey.Wording, """""""") AS Wording,
	|	ISNULL(QuestionsForSurvey.ReplyType, """") AS ReplyType
	|FROM
	|	ElementaryQuestions AS ElementaryQuestions
	|		LEFT JOIN ChartOfCharacteristicTypes.QuestionsForSurvey AS QuestionsForSurvey
	|		ON ElementaryQuestions.ElementaryQuestion = QuestionsForSurvey.Ref
	|
	|ORDER BY
	|	ElementaryQuestions.LineNumber";
	
	Query.SetParameter("Questions", Parameters.ComplexQuestionComposition.Unload());
	
	Result = Query.Execute();
	If NOT Result.IsEmpty() Then;
		Selection = Result.Select();
		While Selection.Next() Do
			
			NewRow = Questions.Add();
			FillPropertyValues(NewRow,Selection);
			
		EndDo;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function QuestionAttributes(Question)
	
	Return Common.ObjectAttributesValues(Question,"Presentation,Wording,IsFolder,ReplyType");
	
EndFunction

#EndRegion
