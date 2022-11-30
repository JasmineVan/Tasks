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
	
	FillPropertyValues(ThisObject, Parameters);
	If TreeRowType = "Section" Then
		
		Items.Required.Visible             = False;
		Items.ElementaryQuestion.Visible       = False;
		Items.HintGroup.Visible          = False;
		Items.Wording.Title             = NStr("ru = 'Имя раздела'; en = 'Section name'; pl = 'Section name';de = 'Section name';ro = 'Section name';tr = 'Section name'; es_ES = 'Section name'");
		Title                                   = NStr("ru = 'Раздел шаблона анкеты'; en = 'Questionnaire template section'; pl = 'Questionnaire template section';de = 'Questionnaire template section';ro = 'Questionnaire template section';tr = 'Questionnaire template section'; es_ES = 'Questionnaire template section'");
		
	EndIf;
	
	If NOT ElementaryQuestion.IsEmpty() Then
		Items.Wording.ChoiceList.Add(Common.ObjectAttributeValue(ElementaryQuestion,"Wording"));
	EndIf;
	
	If QuestionsType = Enums.QuestionnaireTemplateQuestionTypes.QuestionWithCondition Then
		ChoiceParameters = New Array;
		ChoiceParameters.Add(New ChoiceParameter("Filter.ReplyType",PredefinedValue("Enum.QuestionAnswerTypes.Boolean")));
		Items.ElementaryQuestion.ChoiceParameters = New FixedArray(ChoiceParameters);
	EndIf;
	
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
Procedure ElementaryQuestionChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	AttributesQuestion = QuestionAttributes(ValueSelected);
	
	If IsBlankString(Wording)
		Or Wording = PreviousWording Then
		Wording = AttributesQuestion.Wording;
	EndIf;
	
	PreviousWording = AttributesQuestion.Wording;
	
EndProcedure

&AtClient
Procedure NotesChoiceStart(Item, ChoiceData, StandardProcessing)
	
	OnCloseNotify = New NotifyDescription("NoteEditOnClose", ThisObject);
	CommonClient.ShowMultilineTextEditingForm(OnCloseNotify, Item.EditText, NStr("ru = 'Заметки'; en = 'Notes'; pl = 'Notes';de = 'Notes';ro = 'Notes';tr = 'Notes'; es_ES = 'Notes'"));

EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure MoveToTemplate(Command)
	
	Cancel = False;
	
	If Not ValueIsFilled(Wording) Then
		Cancel = True;
		CommonClient.MessageToUser(NStr("ru = 'Не заполнена формулировка'; en = 'Wording not filled in'; pl = 'Wording not filled in';de = 'Wording not filled in';ro = 'Wording not filled in';tr = 'Wording not filled in'; es_ES = 'Wording not filled in'"),,"Wording");
	EndIf;
	
	If TreeRowType = "Question" AND (Not ValueIsFilled(ElementaryQuestion)) Then
		Cancel = True;
		CommonClient.MessageToUser(NStr("ru = 'Не указан элементарный вопрос'; en = 'Basic question is not specified'; pl = 'Basic question is not specified';de = 'Basic question is not specified';ro = 'Basic question is not specified';tr = 'Basic question is not specified'; es_ES = 'Basic question is not specified'"),,"ElementaryQuestion");
	EndIf; 
		
	If Cancel Then
		Return;
	EndIf;
	
	ClosingInProgress = True;
	Notify("EndEditQuestionnaireTemplateLineParameters",GenerateParametersStructureToPassToOwner());
	Close();
	
EndProcedure

#EndRegion

#Region Private

// Generates a parameter structure to pass to the owner form.
&AtClient
Function GenerateParametersStructureToPassToOwner()

	ReturnStructure = New Structure;
	ReturnStructure.Insert("Required", Required);
	ReturnStructure.Insert("Wording", Wording);
	ReturnStructure.Insert("ElementaryQuestion", ElementaryQuestion);
	ReturnStructure.Insert("Notes", Notes);
	ReturnStructure.Insert("IsNewLine", False);
	ReturnStructure.Insert("ToolTip", ToolTip);
	ReturnStructure.Insert("HintPlacement", HintPlacement);
	
	Return ReturnStructure;

EndFunction

&AtServerNoContext
Function QuestionAttributes(Question)
	
	Return Common.ObjectAttributesValues(Question,"IsFolder,ReplyType,Wording");
	
EndFunction

&AtClient
Procedure NoteEditOnClose(ReturnText, AdditionalParameters) Export
	
	If Notes <> ReturnText Then
		Notes = ReturnText;
		Modified = True;
	EndIf;
	
EndProcedure

#EndRegion
