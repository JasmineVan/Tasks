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
	
	// To prevent the Questionnaire document from being opened by other external users.
	If Users.IsExternalUserSession() Then
		If NOT Object.Ref.IsEmpty() Then
			If Object.Respondent <> ExternalUsers.GetExternalUserAuthorizationObject() Then
				Cancel = True;
			EndIf;
		EndIf;
	Else
		IsCommonUserSession = True;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Object.SurveyMode = Enums.SurveyModes.Interview Then
		
		If NOT Object.QuestionnaireTemplate.IsEmpty() Then
			AttributesSurvey = QuestionnaireTemplateAttributesValues(Object.QuestionnaireTemplate);
			SetAttributesValuesBySurvey(AttributesSurvey);
		EndIf;
		
		If Parameters.Property("AllowSavingQuestionnaireDraft") Then
			AllowSavingQuestionnaireDraft = Parameters.AllowSavingQuestionnaireDraft;
		EndIf;
		
	EndIf;
		
	If NOT Object.Survey.IsEmpty() Then
		AttributesSurvey = GetAttributesValuesSurveyPurpose(Object.Survey);
		SetAttributesValuesBySurvey(AttributesSurvey);
		Object.QuestionnaireTemplate = QuestionnaireTemplate;
	EndIf;
		
	If NOT QuestionnaireTemplate.IsEmpty() Then
		
		If Parameters.Property("FillingFormOnly") Then
			AutoTitle = False;
			SetLabelHeader(AttributesSurvey);
		EndIf;
		
		Survey.SetQuestionnaireSectionsTreeItemIntroductionConclusion(SectionsTree,"Introduction");
		Survey.FillSectionsTree(ThisObject,SectionsTree);
		Survey.SetQuestionnaireSectionsTreeItemIntroductionConclusion(SectionsTree,"Conclusion");
		QuestioningClientServer.GenerateTreeNumbering(SectionsTree,True);
		
		If (NOT Object.Posted) AND ValueIsFilled(Object.SectionToEdit) Then
			
			If TypeOf(Object.SectionToEdit) = Type("CatalogRef.QuestionnaireTemplateQuestions") Then
				
				CurrentSectionNumber = QuestioningClientServer.FindStringInTreeFormData(SectionsTree,Object.SectionToEdit,"Ref",True);
				
			Else
				
				CurrentSectionNumber = QuestioningClientServer.FindStringInTreeFormData(SectionsTree,Object.SectionToEdit,"RowType",True);
			
			EndIf;
		
		EndIf;
		
		If CurrentSectionNumber >= 0 Then
			
			Items.SectionsTree.CurrentRow = CurrentSectionNumber;
			CreateFormAccordingToSection();
			
		EndIf;
		
	Else
		
		Cancel = True;
		Return;
		
	EndIf;
		
	
	Items.FooterPreviousSection.Visible = False;
	Items.FooterNextSection.Visible  = False;
	
	ActionsDependingOnFormKind();
	
	Items.SectionsTreeGroup.Visible         = False;
	TitleSectionsCommand = NStr("ru = 'Показать разделы'; en = 'Show sections'; pl = 'Show sections';de = 'Show sections';ro = 'Show sections';tr = 'Show sections'; es_ES = 'Show sections'");
	Items.HideShowSectionsTreeDocument.Title = TitleSectionsCommand;
	
	ChangeFormItemsVisibility(ThisObject);
		
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
		
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	Items.SectionsTree.CurrentRow = CurrentSectionNumber;
	SectionsNavigationButtonAvailabilityControl();
	
	If (Not ThisObject.ReadOnly) Then
		AvailabilityControlSubordinateQuestions(False);
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Items.QuestionnaireBodyGroup.ReadOnly Then
		Modified = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure RespondentStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	FilterArray = New Array;
	If RespondentsFilter.Count() > 0 Then
		FilterArray.Add(QuestioningClient.CreateFilterParameterStructure(Type("DataCompositionFilterItem"),"Ref",DataCompositionComparisonType.InListByHierarchy,RespondentsFilter));
	EndIf;

	OpenForm(RespondentMetadataName + ".ChoiceForm",New Structure("FilterArray",FilterArray),Item);
	
EndProcedure

// OnChange event handler for questions with condition.
&AtClient
Procedure Attachable_OnChangeQuestionsWithConditions(Item)

	AvailabilityControlSubordinateQuestions();

EndProcedure

// On change event handler for simple and tabular questions.
&AtClient
Procedure Attachable_OnChangeQuestion(Item)

	Modified = True;

EndProcedure

// Handler start choice of table questions text cells. 
&AtClient
Procedure Attachable_StartChoiceOfTableQuestionsTextCells(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	AdditionalParameters = New Structure("Item", Item);
	NotificationHandler = New NotifyDescription("EditMultilineTextOnEnd", ThisObject, AdditionalParameters); 
	CommonClient.ShowMultilineTextEditingForm(NotificationHandler,
		Item.EditText);
	
EndProcedure

&AtClient
Procedure SectionsTreeChoice(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.SectionsTree.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
		
	ExecuteFillingFormCreation();
	SectionsNavigationButtonAvailabilityControl();
	
EndProcedure

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(Item.EditText, ThisObject);
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure FillingFormWrite(Command)
	
	Cancel = EndEditFillingForm(DocumentWriteMode.Write);
	
	If NOT Cancel Then
		
		ShowUserNotification(NStr("ru = 'Изменение'; en = 'Update'; pl = 'Update';de = 'Update';ro = 'Update';tr = 'Update'; es_ES = 'Update'"),
		,
		String(Object.Ref),
		PictureLib.Information32);
		
		Notify("Write_Questionnaire",New Structure,Object.Ref);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillingFormPostClose(Command)
	
	OnCloseNotifyHandler = New NotifyDescription("PromptForAcceptingQuestionnaireAfterCompletion", ThisObject);
	ShowQueryBox(OnCloseNotifyHandler,
	                 NStr("ru='Ваша анкета будет принята. 
	                 |Дальнейшее заполнение анкеты будет невозможно
	                 |Продолжить?'; 
	                 |en = 'Your questionnaire will be accepted.
	                 | You will not be able to make any changes to the questionnaire.
	                 |Continue?'; 
	                 |pl = 'Your questionnaire will be accepted.
	                 | You will not be able to make any changes to the questionnaire.
	                 |Continue?';
	                 |de = 'Your questionnaire will be accepted.
	                 | You will not be able to make any changes to the questionnaire.
	                 |Continue?';
	                 |ro = 'Your questionnaire will be accepted.
	                 | You will not be able to make any changes to the questionnaire.
	                 |Continue?';
	                 |tr = 'Your questionnaire will be accepted.
	                 | You will not be able to make any changes to the questionnaire.
	                 |Continue?'; 
	                 |es_ES = 'Your questionnaire will be accepted.
	                 | You will not be able to make any changes to the questionnaire.
	                 |Continue?'")
	                 ,QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure HideShowSectionsTree(Command)

	ChangeSectionsTreeVisibility();

EndProcedure 

&AtClient
Procedure NextSection(Command)
	
	ChangeSection("Forward");
	
EndProcedure

&AtClient
Procedure PreviousSection(Command)
	
	ChangeSection("Back");
	
EndProcedure

&AtClient
Procedure SectionChoice(Command)
	
	ExecuteFillingFormCreation();
	SectionsNavigationButtonAvailabilityControl();
	
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Setting form attributes values.

// Sets values of filling form attributes according to previously given answers.
//
&AtServer
Procedure SetSectionFillingFormAttributesValues()
	
	SectionQuestionsTable.Unload().UnloadColumn("TemplateQuestion");
	
	Query = New Query;
	Query.Text = "SELECT
	               |	ExternalSource.Question AS Question,
	               |	CAST(ExternalSource.ElementaryQuestion AS ChartOfCharacteristicTypes.QuestionsForSurvey) AS ElementaryQuestion,
	               |	ExternalSource.CellNumber AS CellNumber,
	               |	ExternalSource.Response AS Response,
	               |	ExternalSource.OpenAnswer AS OpenAnswer
	               |INTO AnswersTable
	               |FROM
	               |	&ExternalSource AS ExternalSource
	               |WHERE
	               |	ExternalSource.Question IN(&SectionQuestions)
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	AnswersTable.Question AS Question,
	               |	AnswersTable.ElementaryQuestion AS ElementaryQuestion,
	               |	AnswersTable.CellNumber AS CellNumber,
	               |	AnswersTable.Response AS Response,
	               |	AnswersTable.OpenAnswer AS OpenAnswer,
	               |	AnswersTable.ElementaryQuestion.CommentRequired AS OpenEndedQuestion
	               |FROM
	               |	AnswersTable AS AnswersTable
	               |TOTALS BY
	               |	Question";
	
	Query.SetParameter("ExternalSource",Object.Content.Unload());
	Query.SetParameter("SectionQuestions",SectionQuestionsTable.Unload().UnloadColumn("TemplateQuestion"));
	
	Result = Query.Execute();
	If NOT Result.IsEmpty() Then
		
		Selection = Result.Select(QueryResultIteration.ByGroups);
		While Selection.Next() Do
			
			SelectionQuestion = Selection.Select();
			SetAttributeValue(Selection.Question,SelectionQuestion);
			
		EndDo;
		
	EndIf;
		
EndProcedure

// Analyzes a question type and calls procedures to set attribute values.
//
// Parameters:
//  TemplateQuestion - CatalogRef.QuestionnaireTemplateQuestions - a questionnaire template question, 
//                 for which attributes values are set.
//  SelectionQuestion  - QueryResultSelection - a selection containing values of answers to the 
//                 questionnaire template question.
//  QuestionnaireTreeServer - ValueTree - a value tree containing the questionnaire template.
&AtServer
Procedure SetAttributeValue(TemplateQuestion,SelectionQuestion)
	
	FoundRows = SectionQuestionsTable.FindRows(New Structure("TemplateQuestion",TemplateQuestion));
	
	If FoundRows.Count() > 0 Then
		FoundRow = FoundRows[0];
		If FoundRow.QuestionsType = Enums.QuestionnaireTemplateQuestionTypes.Tabular Then
			SetTabularQuestionAttributeValue(TemplateQuestion,SelectionQuestion,FoundRow);
			SetAttributeValuesComplexQuestion(TemplateQuestion,SelectionQuestion,FoundRow);
		ElsIf FoundRow.QuestionsType = Enums.QuestionnaireTemplateQuestionTypes.Complex Then
			SetAttributeValuesComplexQuestion(TemplateQuestion,SelectionQuestion,FoundRow);
		Else
			SetSimpleQuestionAttributeValue(TemplateQuestion,SelectionQuestion,FoundRow);
		EndIf;
	EndIf;

EndProcedure

// Sets attributes values of a simple question.
//
// Parameters:
//  Question  - CatalogRef.QuestionnaireTemplateQuestions - a questionnaire template question, for 
//                 which attributes values are set.
//  SelectionQuestion  - QueryResultSelection - a selection containing values of answers to the 
//                 questionnaire template question.
//  TreeRow  - ValueTreeRow - a value tree row containing the questionnaire template question data.
&AtServer
Procedure SetSimpleQuestionAttributeValue(Question,SelectionQuestion,TreeRow)
	
	QuestionName = QuestioningClientServer.GetQuestionName(TreeRow.RowKey);
	
	If TreeRow.ReplyType = Enums.QuestionAnswerTypes.MultipleOptionsFor Then
		
		OptionsOfAnswersToQuestion = Survey.GetOptionsOfAnswersToQuestion(TreeRow.ElementaryQuestion,ThisObject);
		
		While SelectionQuestion.Next() Do
			
			AnswerParameters = FindAnswerInArray(SelectionQuestion.Response,OptionsOfAnswersToQuestion);
			
			If AnswerParameters <> Undefined Then
				ThisObject[QuestionName + "_Attribute_" + AnswerParameters.AttributeSequenceNumber] = True; 
				If AnswerParameters.OpenEndedQuestion Then
					
					ThisObject[QuestionName + "_Comment_" + AnswerParameters.AttributeSequenceNumber] = SelectionQuestion.OpenAnswer;
					
				EndIf;
			EndIf; 
			
		EndDo;
		
	Else
		
		If SelectionQuestion.Next() Then
					
			If TreeRow.ReplyType = Enums.QuestionAnswerTypes.Text Then
				
				ThisObject[QuestionName] = SelectionQuestion.OpenAnswer;
				
			Else
				
				ThisObject[QuestionName] = SelectionQuestion.Response;
				
				If (TreeRow.CommentRequired) Then
					ThisObject[QuestionName + "_Comment"] = SelectionQuestion.OpenAnswer;
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Analyzes the type of the tabular question and calls procedures to set attributes values.
//
// Parameters:
//  Question  - CatalogRef.QuestionnaireTemplateQuestions - a questionnaire template question, for 
//                 which attributes values are set.
//  SelectionQuestion  - QueryResultSelection - a selection containing values of answers to the 
//                 questionnaire template question.
//  TreeRow  - ValueTreeRow - a value tree row containing the questionnaire template question data.
&AtServer
Procedure SetTabularQuestionAttributeValue(Question,SelectionQuestion,TreeRow)
	
	If TreeRow.TabularQuestionType = Enums.TabularQuestionTypes.Composite Then
		
		SetAttributeValuesCompositeTabularQuestion(Question,SelectionQuestion,TreeRow);
		
	ElsIf TreeRow.TabularQuestionType = Enums.TabularQuestionTypes.PredefinedAnswersInRows Then
		
		SetAttributeValuesTabularQuestionAnswersInRows(Question,SelectionQuestion,TreeRow);
		
	ElsIf TreeRow.TabularQuestionType = Enums.TabularQuestionTypes.PredefinedAnswersInColumns Then
		
		SetAttributeValuesTabularQuestionAnswersInColumns(Question,SelectionQuestion,TreeRow);
		
	ElsIf TreeRow.TabularQuestionType = Enums.TabularQuestionTypes.PredefinedAnswersInRowsAndColumns Then
		
		SetAttributeValuesTabularQuestionAnswersInRowsAndColumns(Question,SelectionQuestion,TreeRow);
		
	EndIf;
	
EndProcedure

// Sets attributes values of composite tabular questions.
//
// Parameters:
//  Question  - CatalogRef.QuestionnaireTemplateQuestions - a questionnaire template question, for 
//                 which attributes values are set.
//  SelectionQuestion  - QueryResultSelection - a selection containing values of answers to the 
//                 questionnaire template question.
//  TreeRow  - ValueTreeRow - a value tree row containing the questionnaire template question data.
&AtServer
Procedure SetAttributeValuesCompositeTabularQuestion(Question,SelectionQuestion,TreeRow);

	QuestionName = QuestioningClientServer.GetQuestionName(TreeRow.RowKey);
	TableName = QuestionName + "_Table";
	Table    = FormAttributeToValue(TableName);
	
	QuestionsArray = TreeRow.TabularQuestionComposition.Unload().UnloadColumn("ElementaryQuestion");
	
	While SelectionQuestion.Next() Do
		
		If QuestionsArray.Find(SelectionQuestion.ElementaryQuestion) = Undefined Then
			Continue;
		EndIf;
		
		If SelectionQuestion.CellNumber > Table.Count() Then
			AddRowsToTable(Table,SelectionQuestion.CellNumber - Table.Count());
		EndIf;
		
		QuestionNumberInArray = QuestionsArray.Find(SelectionQuestion.ElementaryQuestion);
		If QuestionNumberInArray <> Undefined Then
			Table[SelectionQuestion.CellNumber - 1][QuestionNumberInArray] = SelectionQuestion.Response;
		EndIf;
		
	EndDo;
	
	ValueToFormAttribute(Table,TableName);

EndProcedure

// Sets attributes values of a tabular question with predefined answers in rows.
//
// Parameters:
//  Question  - CatalogRef.QuestionnaireTemplateQuestions - a questionnaire template question, for 
//                 which attributes values are set.
//  SelectionQuestion  - QueryResultSelection - a selection containing values of answers to the 
//                 questionnaire template question.
//  TreeRow  - ValueTreeRow - a value tree row containing the questionnaire template question data.
&AtServer
Procedure SetAttributeValuesTabularQuestionAnswersInRows(Question,SelectionQuestion,TreeRow);
	
	QuestionName          = QuestioningClientServer.GetQuestionName(TreeRow.RowKey);
	TableName          = QuestionName + "_Table";
	NameOfColumnWithoutNumber = TableName + "_Column_";
	Table             = FormAttributeToValue(TableName);
	
	QuestionsArray = TreeRow.TabularQuestionComposition.Unload().UnloadColumn("ElementaryQuestion");
	
	While SelectionQuestion.Next() Do
		
		QuestionNumberInArray = QuestionsArray.Find(SelectionQuestion.ElementaryQuestion);
		If (QuestionNumberInArray <> Undefined) AND (SelectionQuestion.CellNumber <= Table.Count()) Then
			Table[SelectionQuestion.CellNumber - 1][NameOfColumnWithoutNumber + String(QuestionNumberInArray+1)] = SelectionQuestion.Response;
		EndIf;
		
	EndDo;
	
	ValueToFormAttribute(Table,TableName);
	
EndProcedure

// Sets attributes values of a tabular question with predefined answers in columns.
//
// Parameters:
//  Question  - CatalogRef.QuestionnaireTemplateQuestions - a questionnaire template question, for 
//                 which attributes values are set.
//  SelectionQuestion  - QueryResultSelection - a selection containing values of answers to the 
//                 questionnaire template question.
//  TreeRow  - ValueTreeRow - a value tree row containing the questionnaire template question data.
&AtServer
Procedure SetAttributeValuesTabularQuestionAnswersInColumns(Question,SelectionQuestion,TreeRow);
	
	QuestionName          = QuestioningClientServer.GetQuestionName(TreeRow.RowKey);
	TableName          = QuestionName + "_Table";
	NameOfColumnWithoutNumber = TableName + "_Column_";
	Table             = FormAttributeToValue(TableName);
	
	QuestionsArray = TreeRow.TabularQuestionComposition.Unload().UnloadColumn("ElementaryQuestion");
	QuestionsArray.Delete(0);
	
	While SelectionQuestion.Next() Do
		
		QuestionNumberInArray = QuestionsArray.Find(SelectionQuestion.ElementaryQuestion);
		If (QuestionNumberInArray <> Undefined) Then
			If (QuestionNumberInArray <= Table.Count()) AND (SelectionQuestion.CellNumber <= Table.Columns.Count()) Then
				Table[QuestionNumberInArray][NameOfColumnWithoutNumber + String(SelectionQuestion.CellNumber + 1)] = SelectionQuestion.Response;
			EndIf;
		EndIf;
		
	EndDo;
	
	ValueToFormAttribute(Table,TableName);
	
EndProcedure

// Sets attributes values of a tabular question with predefined answers in rows and columns.
//
// Parameters:
//  Question  - CatalogRef.QuestionnaireTemplateQuestions - a questionnaire template question, for 
//            which attributes values are set.
//  SelectionQuestion  - QueryResultSelection - a selection containing values of answers to the 
//                  questionnaire template question.
//  TreeRow  - ValueTreeRow - a value tree row containing the questionnaire template question data.
&AtServer
Procedure SetAttributeValuesTabularQuestionAnswersInRowsAndColumns(Question,SelectionQuestion,TreeRow)
	
	QuestionName = QuestioningClientServer.GetQuestionName(TreeRow.RowKey);
	TableName = QuestionName + "_Table";
	NameOfColumnWithoutNumber = TableName + "_Column_";
	Table = FormAttributeToValue(TableName);
	ColumnsNumber = Table.Columns.Count();
	
	QuestionCell = TreeRow.TabularQuestionComposition[2].ElementaryQuestion;
	
	While SelectionQuestion.Next() Do
		If SelectionQuestion.ElementaryQuestion = QuestionCell Then
			ColumnNumber = ?(SelectionQuestion.CellNumber%(ColumnsNumber - 1)=0,ColumnsNumber - 1,SelectionQuestion.CellNumber%(ColumnsNumber - 1));
			RowNumber  = Int((SelectionQuestion.CellNumber + Int(SelectionQuestion.CellNumber/ColumnsNumber))/ColumnsNumber);
			Table[RowNumber ][NameOfColumnWithoutNumber + String(ColumnNumber+1)] = SelectionQuestion.Response;
		EndIf;
	EndDo;
	
	ValueToFormAttribute(Table,TableName);
	
EndProcedure

// Sets attributes values of complex questions.
//
// Parameters:
//  Question  - CatalogRef.QuestionnaireTemplateQuestions - a questionnaire template question, for 
//                 which attributes values are set.
//  SelectionQuestion  - QueryResultSelection - a selection containing values of answers to the 
//                 questionnaire template question.
//  TreeRow  - ValueTreeRow - a value tree row containing the questionnaire template question data.
&AtServer
Procedure SetAttributeValuesComplexQuestion(Question,SelectionQuestion,TreeRow);
	
	QuestionName = QuestioningClientServer.GetQuestionName(TreeRow.RowKey);
	
	QuestionsArray = TreeRow.ComplexQuestionComposition.Unload().UnloadColumn("ElementaryQuestion");
	
	SelectionQuestion.Reset();
	While SelectionQuestion.Next() Do
		
		If QuestionsArray.Find(SelectionQuestion.ElementaryQuestion) = Undefined Then
			Continue;
		EndIf;
		
		QuestionRows = TreeRow.ComplexQuestionComposition.FindRows(New Structure("ElementaryQuestion", SelectionQuestion.ElementaryQuestion));
		CurRowNumber = QuestionRows[0].LineNumber;
		
		AttributeName =  QuestionName + "_Response_" + Format(CurRowNumber, "NG=");
		
		If SelectionQuestion.ElementaryQuestion.ReplyType = Enums.QuestionAnswerTypes.MultipleOptionsFor Then
		
			OptionsOfAnswersToQuestion = Survey.GetOptionsOfAnswersToQuestion(SelectionQuestion.ElementaryQuestion,ThisObject);
			
			AnswerParameters = FindAnswerInArray(SelectionQuestion.Response,OptionsOfAnswersToQuestion);
				
			If AnswerParameters <> Undefined Then
				ThisObject[AttributeName + "_Attribute_" + AnswerParameters.AttributeSequenceNumber] = True; 
				If AnswerParameters.OpenEndedQuestion Then
						
					ThisObject[AttributeName + "_Comment_" + AnswerParameters.AttributeSequenceNumber] = SelectionQuestion.OpenAnswer;
						
				EndIf;
			EndIf; 
				
		Else
			
			If SelectionQuestion.ElementaryQuestion.ReplyType = Enums.QuestionAnswerTypes.Text Then
				
				ThisObject[AttributeName] = SelectionQuestion.OpenAnswer;
				
			Else
				
				ThisObject[AttributeName] = SelectionQuestion.Response;
				
				If (SelectionQuestion.OpenEndedQuestion) Then
					ThisObject[QuestionName + "_Comment_" + Format(CurRowNumber, "NG=")] = SelectionQuestion.OpenAnswer;
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Converting questionnaire filling results to the tabular section of the document.

&AtServer
Function EndEditFillingForm(WriteMode)
	
	ConvertSectionFillingResultsToTabularSection();
	If WriteMode = DocumentWriteMode.Posting Then
		If CheckQuestionnaireFilling()  Then
			Return True;
		EndIf;
	EndIf;
	
	DocumentObject = FormAttributeToValue("Object");
	DocumentObject.ModificationDate = CurrentSessionDate();
	If WriteMode = DocumentWriteMode.Posting Then
		If Not DocumentObject.CheckFilling() Then
			Return True;
		EndIf;
	EndIf;
	DocumentObject.Write(WriteMode);
		
	If WriteMode = DocumentWriteMode.Write Then
		ValueToFormAttribute(DocumentObject,"Object");
		Modified = False;
	EndIf;
	
	Return False;
	
EndFunction

// Converts answers given in the filling form to the data of the tabular section.
//
&AtServer
Procedure ConvertSectionFillingResultsToTabularSection()
	
	CurrentSection = SectionsTree.FindByID(Items.SectionsTree.CurrentRow);
	If CurrentSection <> Undefined Then
		 If CurrentSection.RowType = "Section" Then
			Object.SectionToEdit = CurrentSection.Ref;
		Else
			Object.SectionToEdit = CurrentSection.RowType;
		 EndIf;
	EndIf;
	
	PreviousSectionWithoutQuestions = (SectionQuestionsTable.Count() = 0);
	
	For each TableRow In SectionQuestionsTable Do
		
		// Deleting previous information from the tabular section.
		FoundRows = Object.Content.FindRows(New Structure("Question",TableRow.TemplateQuestion));
		For each FoundRow In FoundRows Do
			Object.Content.Delete(FoundRow);
		EndDo;
		
		If ValueIsFilled(TableRow.ParentQuestion) Then
			FoundRows = SectionQuestionsTable.FindRows(New Structure("TemplateQuestion",TableRow.ParentQuestion));
			If FoundRows.Count() > 0 Then
				ParentRow = FoundRows[0];
				If (NOT ThisObject[QuestioningClientServer.GetQuestionName(ParentRow.RowKey)] = True) Then
					Continue;
				EndIf;
			EndIf;
		EndIf;
		
		If TableRow.QuestionsType = Enums.QuestionnaireTemplateQuestionTypes.Tabular Then
			FillAnswersTableTabularQuestion(TableRow);
		ElsIf TableRow.QuestionsType = Enums.QuestionnaireTemplateQuestionTypes.Complex Then
			FillAnswersComplexQuestion(TableRow);
		Else
			FillAnswerSimpleQuestion(TableRow);
		EndIf;
		
	EndDo;
	
EndProcedure

// Analyzes the type of the tabular question and calls the procedure to get answers to the tabular 
// question given by the respondent.
//
// Parameters:
//   TreeRow - ValueTreeRow - a row of the questionnaire template tree.
//
&AtServer
Procedure FillAnswersTableTabularQuestion(TreeRow)
	
	QuestionName = QuestioningClientServer.GetQuestionName(TreeRow.RowKey);
	TableName = QuestionName + "_Table";
	Table = FormAttributeToValue(TableName);
	
	If Table.Count() = 0 Then
		Return;
	EndIf;
	
	If TreeRow.TabularQuestionType = Enums.TabularQuestionTypes.Composite Then
		
		FillAnswersCompositeTabularQuestion(TreeRow,Table);
		
	ElsIf TreeRow.TabularQuestionType = Enums.TabularQuestionTypes.PredefinedAnswersInRows Then	
		
		FillAnswersTabularQuestionAnswersInRows(TreeRow,Table);
		
	ElsIf TreeRow.TabularQuestionType = Enums.TabularQuestionTypes.PredefinedAnswersInColumns Then
		
		FillAnswersTabularQuestionAnswersInColumns(TreeRow,Table);
		
	ElsIf TreeRow.TabularQuestionType = Enums.TabularQuestionTypes.PredefinedAnswersInRowsAndColumns Then
		
		FillAnswersTabularQuestionAnswersInRowsAndColumns(TreeRow,Table);
		
	EndIf;
	
EndProcedure

// Gets answers given by the respondent to a composite tabular question and accumulates them in the 
//  general answers table.
//
// Parameters:
//  TreeRow - ValueTreeRow - a row of the questionnaire template tree.
//  Table      - ValueTable - a table of a tabular question.
//
&AtServer
Procedure FillAnswersCompositeTabularQuestion(TreeRow,Table)
	
	For ColumnIndex = 0 To TreeRow.TabularQuestionComposition.Count()-1 Do
		
		For RowIndex = 0 To Table.Count() - 1 Do
			
			Answer = Table[RowIndex][ColumnIndex];
			If ValueIsFilled(Answer) Then
				
				NewRow = Object.Content.Add();
				NewRow.Question             = TreeRow.TemplateQuestion;
				NewRow.ElementaryQuestion = TreeRow.TabularQuestionComposition[ColumnIndex].ElementaryQuestion;
				NewRow.Response              = Answer;
				NewRow.CellNumber        = RowIndex + 1;
				
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure

// Gets answers given by the respondent to a tabular question with predefined answers in rows and 
// accumulates them in the general answers table.
//
// Parameters:
//  TreeRow - ValueTreeRow - a row of the questionnaire template tree.
//  Table      - ValueTable - a table of a tabular question.
//
&AtServer
Procedure FillAnswersTabularQuestionAnswersInRows(TreeRow,Table)
	
	QuestionFirstColumn = TreeRow.TabularQuestionComposition[0].ElementaryQuestion;
	NameOfColumnWithoutNumber = QuestioningClientServer.GetQuestionName(TreeRow.RowKey) + "_Table_Column_";
	
	For RowIndex = 0 To Table.Count() - 1 Do
		
		HasAtLeastOneAnswerSpecifiedByRespondent = FALSE;
		
		For ColumnIndex = 1 To TreeRow.TabularQuestionComposition.Count()-1 Do
		
			Answer = Table[RowIndex][NameOfColumnWithoutNumber + String(ColumnIndex+1)];
			If ValueIsFilled(Answer) Then
				
				HasAtLeastOneAnswerSpecifiedByRespondent = True;
				
				NewRow                    = Object.Content.Add();
				NewRow.Question             = TreeRow.TemplateQuestion;
				NewRow.ElementaryQuestion = TreeRow.TabularQuestionComposition[ColumnIndex].ElementaryQuestion;
				NewRow.Response              = Answer;
				NewRow.CellNumber        = RowIndex + 1;
				
			EndIf;
		
		EndDo;
		
		If HasAtLeastOneAnswerSpecifiedByRespondent Then
			
			Answer = Table[RowIndex][NameOfColumnWithoutNumber + "1"];
			If ValueIsFilled(Answer) Then
				
				NewRow = Object.Content.Add();
				NewRow.Question             = TreeRow.TemplateQuestion;
				NewRow.ElementaryQuestion = QuestionFirstColumn;
				NewRow.Response              = Answer;
				NewRow.CellNumber        = RowIndex + 1;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Gets answers given by the respondent to a tabular question with predefined answers in rows and 
// columns and accumulates them in the general answers table.
//
// Parameters:
//  TreeRow - ValueTreeRow - a row of the questionnaire template tree.
//  Table      - ValueTable - a table of a tabular question.
//
&AtServer
Procedure FillAnswersTabularQuestionAnswersInRowsAndColumns(TreeRow,Table)
	
	QuestionForRows   = TreeRow.TabularQuestionComposition[0].ElementaryQuestion;
	QuestionForColumns = TreeRow.TabularQuestionComposition[1].ElementaryQuestion;
	QuestionForCells   = TreeRow.TabularQuestionComposition[2].ElementaryQuestion;
	
	AnswersRows  = TreeRow.PredefinedAnswers.FindRows(New Structure("ElementaryQuestion",QuestionForRows));
	AnswersColumns = TreeRow.PredefinedAnswers.FindRows(New Structure("ElementaryQuestion",QuestionForColumns));
	
	NameOfColumnWithoutNumber = QuestioningClientServer.GetQuestionName(TreeRow.RowKey) + "_Table_Column_";
	
	For RowIndex = 0 To Table.Count() - 1 Do
		For ColumnIndex = 1 To Table.Columns.Count() - 1 Do
			
			Answer = Table[RowIndex][NameOfColumnWithoutNumber + String(ColumnIndex+1)];
			If ValueIsFilled(Answer) Then
				
				CellNumber = ColumnIndex + RowIndex * (Table.Columns.Count() - 1);
				
				NewRow = Object.Content.Add();
				NewRow.Question             = TreeRow.TemplateQuestion;
				NewRow.ElementaryQuestion = QuestionForRows;
				NewRow.Response              = AnswersRows[RowIndex].Response;
				NewRow.CellNumber        = CellNumber;
				
				NewRow = Object.Content.Add();
				NewRow.Question             = TreeRow.TemplateQuestion;
				NewRow.ElementaryQuestion = QuestionForColumns;
				NewRow.Response              = AnswersColumns[ColumnIndex - 1].Response;
				NewRow.CellNumber        = CellNumber;
				
				NewRow = Object.Content.Add();
				NewRow.Question             = TreeRow.TemplateQuestion;
				NewRow.ElementaryQuestion = QuestionForCells;
				NewRow.Response              = Answer;
				NewRow.CellNumber        = CellNumber;
				
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure

// Gets answers given by the respondent to a tabular question with predefined answers in columns and 
// accumulates them in the general answers table.
//
// Parameters:
//  TreeRow - ValueTreeRow - a row of the questionnaire template tree.
//  Table      - ValueTable - a table of a tabular question.
//
&AtServer
Procedure FillAnswersTabularQuestionAnswersInColumns(TreeRow,Table)
	
	QuestionForColumns = TreeRow.TabularQuestionComposition[0].ElementaryQuestion;
	NameOfColumnWithoutNumber = QuestioningClientServer.GetQuestionName(TreeRow.RowKey) + "_Table_Column_";
	
	For ColumnIndex = 1 To Table.Columns.Count() - 1 Do
		
		HasAtLeastOneAnswerSpecifiedByRespondent = FALSE;
		
		For RowIndex = 0 To Table.Count() - 1 Do
			
			Response = Table[RowIndex][NameOfColumnWithoutNumber + String(ColumnIndex + 1)];
			If ValueIsFilled(Response) Then
				
				HasAtLeastOneAnswerSpecifiedByRespondent = True;
				
				NewRow = Object.Content.Add();
				NewRow.Question             = TreeRow.TemplateQuestion;
				NewRow.ElementaryQuestion = TreeRow.TabularQuestionComposition[RowIndex+1].ElementaryQuestion;
				NewRow.Response              = Response;
				NewRow.CellNumber        = ColumnIndex;
				
			EndIf;
			
		EndDo;
		
		 If  HasAtLeastOneAnswerSpecifiedByRespondent Then
			
			NewRow = Object.Content.Add();
			NewRow.Question             = TreeRow.TemplateQuestion;
			NewRow.ElementaryQuestion = QuestionForColumns;
			NewRow.Response              = TreeRow.PredefinedAnswers[ColumnIndex - 1].Response;
			NewRow.CellNumber        = ColumnIndex;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Gets answers given by the respondent to a simple question and accumulates them in the general 
// answers table.
//
// Parameters:
//  TreeRow - ValueTreeRow - a row of the questionnaire template tree.
//
&AtServer
Procedure FillAnswerSimpleQuestion(TreeRow)
	
	QuestionName = QuestioningClientServer.GetQuestionName(TreeRow.RowKey);
	
	If TreeRow.ReplyType <> Enums.QuestionAnswerTypes.MultipleOptionsFor Then
		
		Answer = ThisObject[QuestionName];
		If ValueIsFilled(Answer) Then
			
			NewRow = Object.Content.Add();
			NewRow.Question             = TreeRow.TemplateQuestion;
			NewRow.ElementaryQuestion = TreeRow.ElementaryQuestion;
			If TreeRow.ReplyType = Enums.QuestionAnswerTypes.Text Then
				NewRow.OpenAnswer = Answer;
			Else
				NewRow.Response = Answer;
				If TreeRow.CommentRequired Then
					NewRow.OpenAnswer = ThisObject[QuestionName + "_Comment"];
				EndIf;
			EndIf;
			
		EndIf;
		
	Else
		
		OptionsOfAnswersToQuestion = Survey.GetOptionsOfAnswersToQuestion(TreeRow.ElementaryQuestion,ThisObject);
		
		Counter = 0;
		For each AnswerOption In OptionsOfAnswersToQuestion Do
			
			Counter = Counter + 1;
			AttributeName =  QuestionName + "_Attribute_" + Counter;
			
			If ThisObject[AttributeName] Then
				
				NewRow = Object.Content.Add();
				NewRow.Question             = TreeRow.TemplateQuestion;
				NewRow.ElementaryQuestion = TreeRow.ElementaryQuestion;
				NewRow.Response              = AnswerOption.Response;
				NewRow.CellNumber        = Counter;
				If AnswerOption.OpenEndedQuestion Then
					NewRow.OpenAnswer	= ThisObject[QuestionName + "_Comment_" + Counter];
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillAnswersComplexQuestion(TreeRow)
	
	QuestionName = QuestioningClientServer.GetQuestionName(TreeRow.RowKey);
	
	For each ComplexQuestionRow In TreeRow.ComplexQuestionComposition Do
		
		AttributeName =  QuestionName + "_Response_" + Format(ComplexQuestionRow.LineNumber, "NG=");
		
		If ComplexQuestionRow.ElementaryQuestion.ReplyType <> Enums.QuestionAnswerTypes.MultipleOptionsFor Then
		
			NewRow = Object.Content.Add();
			NewRow.Question             = TreeRow.TemplateQuestion;
			NewRow.ElementaryQuestion = ComplexQuestionRow.ElementaryQuestion;
			If ComplexQuestionRow.ElementaryQuestion.ReplyType = Enums.QuestionAnswerTypes.Text Then
				NewRow.OpenAnswer = ThisObject[AttributeName];
			Else
				NewRow.Response              = ThisObject[AttributeName];
				If ComplexQuestionRow.CommentRequired Then
					NewRow.OpenAnswer	= ThisObject[QuestionName + "_Comment_" + Format(ComplexQuestionRow.LineNumber, "NG=")];
				EndIf;
			EndIf;	
			
		Else
			
			OptionsOfAnswersToQuestion = Survey.GetOptionsOfAnswersToQuestion(ComplexQuestionRow.ElementaryQuestion,ThisObject);
		
			Counter = 0;
			For each AnswerOption In OptionsOfAnswersToQuestion Do
				
				Counter = Counter + 1;
				CurAttributeName =  AttributeName + "_Attribute_" + Counter;
				
				If ThisObject[CurAttributeName] Then
					
					NewRow = Object.Content.Add();
					NewRow.Question             = TreeRow.TemplateQuestion;
					NewRow.ElementaryQuestion = ComplexQuestionRow.ElementaryQuestion;
					NewRow.Response              = AnswerOption.Response;
					NewRow.CellNumber        = Counter;
					If AnswerOption.OpenEndedQuestion Then
						NewRow.OpenAnswer	= ThisObject[AttributeName + "_Comment_" + Counter];
					EndIf;
					
				EndIf;
				
			EndDo;
			
		EndIf;
			
	EndDo;
		
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Other procedures and functions

// Used for creating a filling form.
&AtServer
Procedure CreateFormAccordingToSection()
	
	// Determine the selected section.
	CurrentDataSectionsTree = SectionsTree.FindByID(Items.SectionsTree.CurrentRow);
	If CurrentDataSectionsTree = Undefined Then
		Return;
	EndIf;
	
	If NOT Items.QuestionnaireBodyGroup.ReadOnly Then
		ConvertSectionFillingResultsToTabularSection();
	EndIf;
	CurrentSectionNumber = Items.SectionsTree.CurrentRow;
	Survey.CreateFillingFormBySection(ThisObject,CurrentDataSectionsTree);
	SetSectionFillingFormAttributesValues();
	Survey.GenerateQuestionsSubordinationTable(ThisObject);
	SetOnChangeEventHandlerForQuestions();
	
	Items.FooterPreviousSection.Visible = (SectionQuestionsTable.Count() > 0);
	Items.FooterNextSection.Visible  = (SectionQuestionsTable.Count() > 0);
	
	QuestioningClientServer.SwitchQuestionnaireBodyGroupsVisibility(ThisObject, True);
	
EndProcedure

// Adds blank items to Collection.
//
// Parameters:
//  Table    - Collection - a collection, to which rows are added.
//  RowsCount - Number - a number of rows to be added.
//
&AtServerNoContext
Procedure AddRowsToTable(Collection,RowsCount);

	For ind = 1 To RowsCount Do
		Collection.Add();
	EndDo;

EndProcedure

// Checks whether answers to required questions are given.
//
// Returns:
//   Boolean   - True if the check of filling required answers is failed,
//              otherwise, False.
&AtServer
Function CheckQuestionnaireFilling()
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	AnswerComposition.Question,
	|	AnswerComposition.ElementaryQuestion,
	|	AnswerComposition.CellNumber,
	|	AnswerComposition.Response,
	|	AnswerComposition.OpenAnswer
	|INTO AnswerComposition
	|FROM
	|	&ExternalSource AS AnswerComposition
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	QuestionsWithoutAnswers.Ref
	|INTO MandatoryQuestionsWithoutAnswers
	|FROM
	|	(SELECT
	|		QuestionnaireTemplateQuestions.Ref AS Ref,
	|		SUM(CASE
	|				WHEN AnswerComposition.Response IS NULL 
	|					THEN 0
	|				ELSE 1
	|			END) AS AnswerCount
	|	FROM
	|		Catalog.QuestionnaireTemplateQuestions AS QuestionnaireTemplateQuestions
	|			LEFT JOIN AnswerComposition AS AnswerComposition
	|			ON (AnswerComposition.Question = QuestionnaireTemplateQuestions.Ref)
	|	WHERE
	|		QuestionnaireTemplateQuestions.Required
	|		AND (NOT QuestionnaireTemplateQuestions.DeletionMark)
	|		AND (NOT QuestionnaireTemplateQuestions.IsFolder)
	|		AND QuestionnaireTemplateQuestions.Owner = &QuestionnaireTemplate
	|		AND QuestionnaireTemplateQuestions.ParentQuestion = VALUE(Catalog.QuestionnaireTemplateQuestions.EmptyRef)
	|	
	|	GROUP BY
	|		QuestionnaireTemplateQuestions.Ref
	|	
	|	HAVING
	|		SUM(CASE
	|				WHEN AnswerComposition.Response IS NULL 
	|					THEN 0
	|				ELSE 1
	|			END) = 0
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		QuestionnaireTemplateQuestions.Ref,
	|		SUM(CASE
	|				WHEN AnswerComposition.Response IS NULL 
	|					THEN 0
	|				ELSE 1
	|			END)
	|	FROM
	|		Catalog.QuestionnaireTemplateQuestions AS QuestionnaireTemplateQuestions
	|			LEFT JOIN AnswerComposition AS AnswerComposition
	|			ON QuestionnaireTemplateQuestions.Ref = AnswerComposition.Question
	|	WHERE
	|		QuestionnaireTemplateQuestions.Owner = &QuestionnaireTemplate
	|		AND (NOT QuestionnaireTemplateQuestions.DeletionMark)
	|		AND (NOT QuestionnaireTemplateQuestions.IsFolder)
	|		AND QuestionnaireTemplateQuestions.ParentQuestion <> VALUE(Catalog.QuestionnaireTemplateQuestions.EmptyRef)
	|		AND QuestionnaireTemplateQuestions.ParentQuestion IN
	|				(SELECT DISTINCT
	|					NestedQuery.Ref
	|				FROM
	|					(SELECT
	|						QuestionnaireTemplateQuestions.Ref AS Ref,
	|						ISNULL(AnswerComposition.Response, FALSE) AS Response
	|					FROM
	|						Catalog.QuestionnaireTemplateQuestions AS QuestionnaireTemplateQuestions LEFT JOIN AnswerComposition AS AnswerComposition
	|							ON
	|								QuestionnaireTemplateQuestions.Ref = AnswerComposition.Question
	|					WHERE
	|						QuestionnaireTemplateQuestions.QuestionsType = VALUE(Enum.QuestionnaireTemplateQuestionTypes.QuestionWithCondition)
	|						AND (NOT QuestionnaireTemplateQuestions.DeletionMark)
	|						AND (NOT QuestionnaireTemplateQuestions.IsFolder)
	|						AND QuestionnaireTemplateQuestions.Owner = &QuestionnaireTemplate
	|						AND ISNULL(AnswerComposition.Response, FALSE) = TRUE
	|					) AS NestedQuery)
	|		AND QuestionnaireTemplateQuestions.Required
	|	
	|	GROUP BY
	|		QuestionnaireTemplateQuestions.Ref
	|	
	|	HAVING
	|		SUM(CASE
	|				WHEN AnswerComposition.Response IS NULL 
	|					THEN 0
	|				ELSE 1
	|			END) = 0) AS QuestionsWithoutAnswers
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	QuestionnaireTemplateQuestions.Ref,
	|	QuestionnaireTemplateQuestions.Wording
	|FROM
	|	Catalog.QuestionnaireTemplateQuestions AS QuestionnaireTemplateQuestions
	|WHERE
	|	QuestionnaireTemplateQuestions.Ref IN
	|			(SELECT
	|				MandatoryQuestionsWithoutAnswers.Ref
	|			FROM
	|				MandatoryQuestionsWithoutAnswers AS MandatoryQuestionsWithoutAnswers)
	|
	|ORDER BY
	|	QuestionnaireTemplateQuestions.Ref";
	
	Query.SetParameter("ExternalSource",Object.Content.Unload());
	Query.SetParameter("QuestionnaireTemplate",Object.QuestionnaireTemplate);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return False;
	EndIf;
	
	Selection = Result.Select();
	While Selection.Next() Do
		Common.MessageToUser(NStr("ru='Не указан ответ на вопрос'; en = 'The response to the question is not specified.'; pl = 'The response to the question is not specified.';de = 'The response to the question is not specified.';ro = 'The response to the question is not specified.';tr = 'The response to the question is not specified.'; es_ES = 'The response to the question is not specified.'") + "- "+ StrReplace(Selection.Ref.FullCode(),"/",".") + " " + Selection.Wording);
	EndDo;
	
	Return True;
	
EndFunction

// Finds an answer in the array containing value table rows.
//
// Parameters:
//  Answer         - Characteristic.QuestionsForSurvey - an answer we are looking for.
//  AnswersArray - Array - an array of  value table rows.
//
// Returns:
//   Structure   - a structure contains the attribute number and the flag indicating whether an open answer is to be given.
//
&AtServerNoContext
Function FindAnswerInArray(Answer,AnswersArray)
	
	ReturnStructure = New Structure;
	
	For ind = 1 To AnswersArray.Count() Do
		
		If AnswersArray[ind - 1].Response = Answer Then
			
			ReturnStructure.Insert("AttributeSequenceNumber",ind);
			ReturnStructure.Insert("OpenEndedQuestion",AnswersArray[ind - 1].OpenEndedQuestion);
			Return ReturnStructure;
		EndIf;
		
	EndDo;
	
	Return Undefined;
	
EndFunction

&AtServer
Procedure SetAttributesValuesBySurvey(AttributesSurvey)
	
	AllowSavingQuestionnaireDraft = AttributesSurvey.AllowSavingQuestionnaireDraft;
	QuestionnaireTemplate = AttributesSurvey.QuestionnaireTemplate;
	Introduction                            = ?(IsBlankString(AttributesSurvey.Introduction),
	                                         NStr("ru = 'Нажмите далее для заполнения анкеты.'; en = 'Click Next to fill in the questionnaire.'; pl = 'Click Next to fill in the questionnaire.';de = 'Click Next to fill in the questionnaire.';ro = 'Click Next to fill in the questionnaire.';tr = 'Click Next to fill in the questionnaire.'; es_ES = 'Click Next to fill in the questionnaire.'"),
	                                         AttributesSurvey.Introduction);
	Conclusion                            = ?(IsBlankString(AttributesSurvey.Conclusion),
	                                         NStr("ru = 'Спасибо за то, что заполнили анкету.'; en = 'Thank you for filling out the questionnaire.'; pl = 'Thank you for filling out the questionnaire.';de = 'Thank you for filling out the questionnaire.';ro = 'Thank you for filling out the questionnaire.';tr = 'Thank you for filling out the questionnaire.'; es_ES = 'Thank you for filling out the questionnaire.'"),
	                                         AttributesSurvey.Conclusion);
	
EndProcedure 

// Gets attribute values according to the selected survey.
&AtServer
Function GetAttributesValuesSurveyPurpose(Survey)
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	PollPurpose.QuestionnaireTemplate,
	|	PollPurpose.RespondentsType,
	|	PollPurpose.AllowSavingQuestionnaireDraft,
	|	PollPurpose.Respondents.(
	|		Ref,
	|		LineNumber,
	|		Respondent
	|	),
	|	QuestionnaireTemplates.Title,
	|	QuestionnaireTemplates.Introduction,
	|	QuestionnaireTemplates.Conclusion
	|FROM
	|	Document.PollPurpose AS PollPurpose
	|		LEFT JOIN Catalog.QuestionnaireTemplates AS QuestionnaireTemplates
	|		ON PollPurpose.QuestionnaireTemplate = QuestionnaireTemplates.Ref
	|WHERE
	|	PollPurpose.Ref = &Survey";
	
	Query.SetParameter("Survey",Survey);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	Return Selection;
	
EndFunction

// Gets attribute values according to the questionnaire template.
&AtServerNoContext
Function QuestionnaireTemplateAttributesValues(QuestionnaireTemplate)
	
	Query = New Query;
	Query.Text = "SELECT
	               |	QuestionnaireTemplates.Ref AS QuestionnaireTemplate,
	               |	FALSE AS AllowSavingQuestionnaireDraft,
	               |	QuestionnaireTemplates.Title,
	               |	QuestionnaireTemplates.Introduction,
	               |	QuestionnaireTemplates.Conclusion
	               |FROM
	               |	Catalog.QuestionnaireTemplates AS QuestionnaireTemplates
	               |WHERE
	               |	QuestionnaireTemplates.Ref = &QuestionnaireTemplate";
	
	Query.SetParameter("QuestionnaireTemplate", QuestionnaireTemplate);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	Return Selection;
	
EndFunction

// Sets headers and labels values.
&AtServer
Procedure SetLabelHeader(AttributesSurvey)
	
	Title                            = AttributesSurvey.Title;
	Items.IntroductionLabel.Title = AttributesSurvey.Introduction;
	Introduction                           = AttributesSurvey.Introduction;
	
EndProcedure

// Controls form items availability.
&AtClient
Procedure AvailabilityControlSubordinateQuestions(SetModification = True)
	
	For each CollectionItem In DependentQuestions Do
		
		QuestionName = QuestioningClientServer.GetQuestionName(CollectionItem.Question);
		
		For each SubordinateQuestion In CollectionItem.Dependent Do
			
			Items[SubordinateQuestion.SubordinateQuestionItemName].ReadOnly           = (NOT ThisObject[QuestionName]);
			If StrOccurrenceCount(SubordinateQuestion.SubordinateQuestionItemName,"Attribute") = 0 Then
				
				Try
					Items[SubordinateQuestion.SubordinateQuestionItemName].AutoMarkIncomplete = (ThisObject[QuestionName] AND SubordinateQuestion.Required);
				Except
					// The check box and radio buttons do not have the AutoMarkIncomplete property.
				EndTry;
				
			EndIf;
		EndDo;
	EndDo;
	
	If AllowSavingQuestionnaireDraft AND SetModification Then
		Modified = True;
	EndIf;
	
	ClearMarkIncomplete();
	
EndProcedure

// Sets attributes availability and visibility depending on the form kind.
&AtServer
Procedure ActionsDependingOnFormKind()
	
	If Parameters.Property("FillingFormOnly") Then
		
		IsInterview = Object.SurveyMode = PredefinedValue("Enum.SurveyModes.Interview");
		
		Items.MainAttributesGroup.Visible              = IsInterview;
		Items.Date.Enabled                               = False;
		Items.FormCommandBarPostAndClose.Visible = False;
		Items.FormCommandBarWrite.Visible         = False;
		Items.Post.Visible                             = False;
		Items.FormCancelPosting.Visible                = False;
		Items.FormRefresh.Visible                      = False;
		Items.QuestionnaireShowInList.Visible                = False;
		Items.FormMarkForDeletion.Visible       = False;
		Items.Comment.Visible                          = False;
		
		Items.SurveyMode.ReadOnly = IsInterview;
		Items.Survey.ReadOnly              = IsInterview;
		Items.QuestionnaireTemplate.ReadOnly       = IsInterview;
		
		If Object.Ref.IsEmpty() Then
			Object.Date = CurrentSessionDate();
		EndIf;
			
		If Parameters.ReadOnly = True Then
			
			Items.QuestionnaireBodyGroup.ReadOnly          = True;
			Items.ResponseFormPostAndClose.Visible = False;
			Items.ResponseFormWrite.Visible        = False;
			
		Else
			
			Items.ResponseFormWrite.Visible = AllowSavingQuestionnaireDraft; 
			
		EndIf;
		
		Modified = False;
		
	Else
		
		Items.ResponseFormPostAndClose.Visible = False;
		Items.ResponseFormWrite.Visible        = False;
		Items.QuestionnaireBodyGroup.ReadOnly          = True;
		Items.MainAttributesGroup.ReadOnly   = True;
	
	EndIf;
	
EndProcedure

// Sets the on change event handler  for simple and tabular questions.
&AtServer
Procedure SetOnChangeEventHandlerForQuestions()
	
	If Not AllowSavingQuestionnaireDraft Then
		Return;
	EndIf;
	
	For each TableRow In SectionQuestionsTable Do
		
		If TableRow.QuestionsType = Enums.QuestionnaireTemplateQuestionTypes.QuestionWithCondition Then
			Continue;
		EndIf;
		
		QuestionName = QuestioningClientServer.GetQuestionName(TableRow.RowKey);
		
		If TableRow.QuestionsType = Enums.QuestionnaireTemplateQuestionTypes.Tabular Then
			Items[QuestionName + "_Table"].SetAction("OnChange","Attachable_OnChangeQuestion");
		ElsIf TableRow.QuestionsType = Enums.QuestionnaireTemplateQuestionTypes.Complex Then
			SetOnChangeEventHandlerForComplexQuestions(TableRow, QuestionName);
		Else
			If TableRow.ReplyType = Enums.QuestionAnswerTypes.MultipleOptionsFor Then
				OptionsOfAnswersToQuestion = Survey.GetOptionsOfAnswersToQuestion(TableRow.ElementaryQuestion,ThisObject);
				For ind = 1  To OptionsOfAnswersToQuestion.Count() Do
					Items[QuestionName + "_Attribute_" + ind].SetAction("OnChange","Attachable_OnChangeQuestion");
					If OptionsOfAnswersToQuestion[ind-1].OpenEndedQuestion Then
						Items[QuestionName + "_Comment_" + ind].SetAction("OnChange","Attachable_OnChangeQuestion");
					EndIf;
				EndDo;
			Else
				Items[QuestionName].SetAction("OnChange","Attachable_OnChangeQuestion");
				If TableRow.CommentRequired Then
					Items[QuestionName + "_Comment"].SetAction("OnChange","Attachable_OnChangeQuestion");
				EndIf;
			EndIf;
		EndIf;
		
	EndDo;
	
EndProcedure

// Sets the on change event handler for complex questions.
&AtServer
Procedure SetOnChangeEventHandlerForComplexQuestions(TableRow, QuestionName)
	
	For each ComplexQuestionRow In TableRow.ComplexQuestionComposition Do
		
		FoundRows = QuestionsPresentationTypes.FindRows(New Structure("Question",ComplexQuestionRow.ElementaryQuestion));
		If FoundRows.Count() > 0 Then
			ElementaryQuestionAttributes = FoundRows[0];
		Else
			Continue;
		EndIf;	
			
		If ElementaryQuestionAttributes.ReplyType = Enums.QuestionAnswerTypes.MultipleOptionsFor Then
			OptionsOfAnswersToQuestion = Survey.GetOptionsOfAnswersToQuestion(ComplexQuestionRow.ElementaryQuestion,ThisObject);
			For ind = 1  To OptionsOfAnswersToQuestion.Count() Do
				QuestionAttributeName = QuestionName + "_Response_" + Format(ComplexQuestionRow.LineNumber, "NG=") + "_Attribute_" + ind;
				Items[QuestionAttributeName].SetAction("OnChange","Attachable_OnChangeQuestion");
				If OptionsOfAnswersToQuestion[ind-1].OpenEndedQuestion Then
					CommentAttributeName = QuestionName + "_Response_" + Format(ComplexQuestionRow.LineNumber, "NG=") + "_Comment_" + ind;
					Items[CommentAttributeName].SetAction("OnChange","Attachable_OnChangeQuestion");
				EndIf;
			EndDo;
		Else
			QuestionAttributeName = QuestionName + "_Response_" + Format(ComplexQuestionRow.LineNumber, "NG=");
			Items[QuestionAttributeName].SetAction("OnChange","Attachable_OnChangeQuestion");
			If ComplexQuestionRow.CommentRequired Then
				CommentAttributeName = QuestionName + "_Comment_" + Format(ComplexQuestionRow.LineNumber, "NG=");
				Items[CommentAttributeName].SetAction("OnChange","Attachable_OnChangeQuestion");
			EndIf;
		EndIf;
		
	EndDo;
	
EndProcedure

// Starts the process of creating a filling form according to sections.
&AtClient
Procedure ExecuteFillingFormCreation()
	
	QuestioningClientServer.SwitchQuestionnaireBodyGroupsVisibility(ThisObject, False);
	AttachIdleHandler("EndBuildFillingForm",0.1,True);
	
EndProcedure

// Finishes generation of a questionnaire filling form.
&AtClient
Procedure EndBuildFillingForm()
	
	CreateFormAccordingToSection();
	AvailabilityControlSubordinateQuestions(PreviousSectionWithoutQuestions = False 
	                                         AND Not IsCommonUserSession
	                                         AND Not ReadOnly);
	SectionsNavigationButtonAvailabilityControl();
	
	ItemForPositioning = Items.Find(PositioningItemName);
	If ItemForPositioning <> Undefined Then
		CurrentItem = ItemForPositioning;
	EndIf;
	
EndProcedure

// Changes sections tree visibility.
&AtClient
Procedure ChangeSectionsTreeVisibility()

	Items.SectionsTreeGroup.Visible         = NOT Items.SectionsTreeGroup.Visible;
	
	TitleSectionsCommand = ?(Items.SectionsTreeGroup.Visible,NStr("ru = 'Скрыть разделы'; en = 'Hide sections'; pl = 'Hide sections';de = 'Hide sections';ro = 'Hide sections';tr = 'Hide sections'; es_ES = 'Hide sections'"),NStr("ru = 'Показать разделы'; en = 'Show sections'; pl = 'Show sections';de = 'Show sections';ro = 'Show sections';tr = 'Show sections'; es_ES = 'Show sections'"));
	Items.HideShowSectionsTreeDocument.Title = TitleSectionsCommand;

EndProcedure

// Manages availability of navigation buttons by sections.
&AtClient
Procedure SectionsNavigationButtonAvailabilityControl()

	AvailabilityPreviousSection = (Items.SectionsTree.CurrentRow > 0);
	AvailabilityNextSection  = (SectionsTree.FindByID(Items.SectionsTree.CurrentRow +  1) <> Undefined);
	
	Items.FooterPreviousSection.Enabled   = AvailabilityPreviousSection;
	Items.PreviousSection.Enabled = AvailabilityPreviousSection;
	Items.FooterNextSection.Enabled    = AvailabilityNextSection;
	Items.NextSection.Enabled  = AvailabilityNextSection;

EndProcedure

// Changes the current section
&AtClient
Procedure ChangeSection(Direction)
	
	Items.SectionsTree.CurrentRow = CurrentSectionNumber + ?(Direction = "Forward",1,-1);
	CurrentSectionNumber = CurrentSectionNumber + ?(Direction = "Forward",1,-1);
	CurrentDataSectionsTree = SectionsTree.FindByID(Items.SectionsTree.CurrentRow);
	If CurrentDataSectionsTree.QuestionsCount = 0 AND CurrentDataSectionsTree.RowType = "Section"  Then
		ChangeSection(Direction);
	EndIf;
	ExecuteFillingFormCreation();
	
EndProcedure

&AtClient
Procedure PromptForAcceptingQuestionnaireAfterCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.No Then
		Return;
	EndIf;
	
	Cancel = EndEditFillingForm(DocumentWriteMode.Posting);
	
	If NOT Cancel Then
		
		ShowUserNotification(NStr("ru = 'Изменение'; en = 'Update'; pl = 'Update';de = 'Update';ro = 'Update';tr = 'Update'; es_ES = 'Update'"),
		,
		String(Object.Ref),
		PictureLib.Information32);
	
		Notify("Posting_Questionnaire",New Structure,Object.Ref);
		Modified = False;
		Close();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure EditMultilineTextOnEnd(ChangedText, AdditionalParameters) Export

	Item = AdditionalParameters.Item;
	
	If TypeOf(Item.Parent) = Type("FormGroup") Then
		If ThisObject[Item.Name] <> ChangedText Then
			ThisObject[Item.Name] = ChangedText;
			Modified = True;
		EndIf;
	Else
		
		FoundRow = ThisObject[Item.Parent.Name].FindByID(Item.Parent.CurrentRow);
		RowIndex    = ThisObject[Item.Parent.Name].IndexOf(FoundRow);
		
		If ThisObject[Item.Parent.Name][RowIndex][Item.Name] <> ChangedText Then
			ThisObject[Item.Parent.Name][RowIndex][Item.Name] = ChangedText;
			Modified = True;
		EndIf;
		
	EndIf;

EndProcedure

&AtClientAtServerNoContext
Procedure ChangeFormItemsVisibility(Form)
	
	IsInterview = Form.Object.SurveyMode = PredefinedValue("Enum.SurveyModes.Interview");
	Form.Items.Survey.Visible = NOT IsInterview;
	Form.Items.QuestionnaireTemplate.Visible = IsInterview;
	Form.Items.Interviewer.Visible = IsInterview;
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Object);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result)
	AttachableCommands.ExecuteCommand(ThisObject, Context, Object, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion
