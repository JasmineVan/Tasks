///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

// Form parameters:
//   TableQuestionComposition - CollectionFormData - with the following columns:
//    * ElementaryQuestion - ChartOfCharacteristicTypesRef.QuestionsForSurvey
//    * RowNumber - Number
//

#Region EventHandlers

&AtClient
Procedure OnOpen(Cancel)

	AvailabilityControl();
	SetHelpTexts();
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Setting a selection list for a table question type.
	For each MetadataItem In Metadata.Enums.TabularQuestionTypes.EnumValues Do
		Items.TabularQuestionType.ChoiceList.Add(Enums.TabularQuestionTypes[MetadataItem.Name],MetadataItem.Synonym);
	EndDo;
		
	// Accepting owner form parameters.
	ProcessOwnerFormParameters();
	
	// Setting a page
	If Parameters.TabularQuestionType = Enums.TabularQuestionTypes.EmptyRef() Then
		Items.Pages.CurrentPage = Items.TableQuestionTypePage;
	Else
		GenerateResultingTable();
		Items.Pages.CurrentPage = Items.ResultTablePage;
	EndIf;
	
	StandardSubsystemsServer.SetGroupTitleRepresentation(ThisObject, "MainPagesGroup");
	
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
Procedure TableQuestionTypeOnChange(Item)
	
	AvailabilityControl();
	
EndProcedure

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
	
	AvailabilityControl();
	
EndProcedure

&AtClient
Procedure AnswersRowsAnswersInRowsBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
	
	Cancel = True;
	
	NewRow = AddAnswerInteractively(Item,Clone,0);
	ProcessAnswersPickingItemAfterAdd(Item,NewRow);
	
EndProcedure

&AtClient
Procedure AnswersColumnsAnswersInColumnsBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
	
	Cancel = True;
	
	NewRow = AddAnswerInteractively(Item,Clone,0);
	ProcessAnswersPickingItemAfterAdd(Item,NewRow);
	
EndProcedure

&AtClient
Procedure AnswersColumnsAnswersInRowsAndColumnsAnswerStartChoice(Item, ChoiceData, StandardProcessing)
	
	ListsChoiceStart(Item,StandardProcessing, QuestionValueType(QuestionForColumns));
	
EndProcedure

&AtClient
Procedure AnswersRowsAnswersInRowsAnswerStartChoice(Item, ChoiceData, StandardProcessing)
	
	ListsChoiceStart(Item,StandardProcessing, QuestionValueType(QuestionForRows));
	
EndProcedure

&AtClient
Procedure AnswersRowsAnswersInRowsAndColumnsAnswerStartChoice(Item, ChoiceData, StandardProcessing)
	
	ListsChoiceStart(Item,StandardProcessing, QuestionValueType(QuestionForRows));
	
EndProcedure

&AtClient
Procedure AnswersColumnsAnswersInColumnsAnswerStartChoice(Item, ChoiceData, StandardProcessing)
	
	ListsChoiceStart(Item,StandardProcessing, QuestionValueType(QuestionForColumns));
	
EndProcedure

&AtClient
Procedure AnswersColumnsAnswersInRowsAndColumnsBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
	
	Cancel = True;
	
	NewRow = AddAnswerInteractively(Item,Clone,1);
	ProcessAnswersPickingItemAfterAdd(Item,NewRow);
	
EndProcedure

&AtClient
Procedure AnswersRowsAnswersInRowsAndColumnsBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
	
	Cancel = True;
	
	NewRow = AddAnswerInteractively(Item,Clone,0);
	ProcessAnswersPickingItemAfterAdd(Item,NewRow);
	
EndProcedure

&AtClient
Procedure QuestionsOnChange(Item)
	
	AvailabilityControl();
	
EndProcedure

&AtClient
Procedure AnswersColumnsAnswersInRowsAndColumnsOnChange(Item)
	
	OnChangeAnswers(Item);
	
EndProcedure

&AtClient
Procedure AnswersRowsAnswersInRowsAndColumnsOnChange(Item)
	
	OnChangeAnswers(Item);
	
EndProcedure

&AtClient
Procedure AnswersColumnsAnswersInColumnsOnChange(Item)
	
	OnChangeAnswers(Item);
	
EndProcedure

&AtClient
Procedure AnswersRowsAnswersInRowsOnChange(Item)
	
	OnChangeAnswers(Item);
	
EndProcedure

&AtClient
Procedure FormulationOnChange(Item)
	
	If Items.Pages.CurrentPage = Items.ResultTablePage Then
		
		Items.NextButton.Enabled 	= ValueIsFilled(Wording);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure NextPage(Command)
	
	CurrentPage = Items.Pages.CurrentPage;
	
	If CurrentPage = Items.TableQuestionTypePage Then
		
		Items.Pages.CurrentPage = Items.QuestionsPage;
		
	ElsIf (CurrentPage = Items.QuestionsPage) AND (TabularQuestionType <> PredefinedValue("Enum.TabularQuestionTypes.Composite")) Then
		
		SetAnswersPage();
		
	ElsIf CurrentPage = Items.ResultTablePage Then
		
		EndEditAndClose();
		
	Else
		
		GenerateResultingTable();
		Items.Pages.CurrentPage = Items.ResultTablePage;
		
	EndIf;
	
	AvailabilityControl();
	SetHelpTexts();
	
EndProcedure

&AtClient
Procedure PreviousPage(Command)

	If Items.Pages.CurrentPage = Items.ResultTablePage Then
		
		If TabularQuestionType = PredefinedValue("Enum.TabularQuestionTypes.Composite") Then
			Items.Pages.CurrentPage = Items.QuestionsPage;
		Else
			SetAnswersPage();
		EndIf;
		
		Items.NextButton.Title = NStr("ru = 'Далее'; en = 'Next'; pl = 'Next';de = 'Next';ro = 'Next';tr = 'Next'; es_ES = 'Next'") + ">";
		
	ElsIf Items.Pages.CurrentPage = Items.QuestionsPage Then
		
		Items.Pages.CurrentPage = Items.TableQuestionTypePage;
		
	Else 
		
		Items.Pages.CurrentPage = Items.QuestionsPage;
		
	EndIf;
	
	AvailabilityControl();
	SetHelpTexts();
	
EndProcedure

&AtClient
Procedure FillAnswersOptionsAnswersInRows(Command)
	
	ClearFillAnswersOptions(QuestionForRows);
	SetFilters();
	AvailabilityControl();
	
EndProcedure

&AtClient
Procedure FillAnswersOptionsAnswersInColumns(Command)
	
	ClearFillAnswersOptions(QuestionForColumns);
	SetFilters();
	AvailabilityControl();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function QuestionValueType(Question)
	Return Common.ObjectAttributeValue(Question,"ValueType");
EndFunction

&AtClient
Procedure SetHelpTexts()
	
	CurrentPage = Items.Pages.CurrentPage;
	
	If CurrentPage = Items.ResultTablePage Then
		InformationHeader                 = NStr("ru='Результирующая таблица:'; en = 'Result table:'; pl = 'Result table:';de = 'Result table:';ro = 'Result table:';tr = 'Result table:'; es_ES = 'Result table:'");
		InformationFooter                = NStr("ru='Нажмите Готово для окончания редактирования.'; en = 'Click Finish to finish editing.'; pl = 'Click Finish to finish editing.';de = 'Click Finish to finish editing.';ro = 'Click Finish to finish editing.';tr = 'Click Finish to finish editing.'; es_ES = 'Click Finish to finish editing.'");
		Items.NextButton.Title = NStr("ru='Готово'; en = 'Finish'; pl = 'Finish';de = 'Finish';ro = 'Finish';tr = 'Finish'; es_ES = 'Finish'");
	Else
		Items.NextButton.Title = NStr("ru='Далее>>'; en = 'Next>>'; pl = 'Next>>';de = 'Next>>';ro = 'Next>>';tr = 'Next>>'; es_ES = 'Next>>'");
		If CurrentPage = Items.QuestionsPage Then
			If TabularQuestionType = PredefinedValue("Enum.TabularQuestionTypes.Composite") Then
				InformationHeader  = NStr("ru='Подбор вопросов. Укажите хотя бы один вопрос:'; en = 'Select questions. Specify at least one question:'; pl = 'Select questions. Specify at least one question:';de = 'Select questions. Specify at least one question:';ro = 'Select questions. Specify at least one question:';tr = 'Select questions. Specify at least one question:'; es_ES = 'Select questions. Specify at least one question:'");
				InformationFooter = NStr("ru='Нажмите Далее для просмотра получившейся таблицы.'; en = 'Click Next to view the resulting table.'; pl = 'Click Next to view the resulting table.';de = 'Click Next to view the resulting table.';ro = 'Click Next to view the resulting table.';tr = 'Click Next to view the resulting table.'; es_ES = 'Click Next to view the resulting table.'");
			ElsIf TabularQuestionType = PredefinedValue("Enum.TabularQuestionTypes.PredefinedAnswersInRowsAndColumns") Then
				InformationHeader  =NStr("ru='Подбор вопросов. Укажите три вопроса:'; en = 'Select questions. Specify three questions:'; pl = 'Select questions. Specify three questions:';de = 'Select questions. Specify three questions:';ro = 'Select questions. Specify three questions:';tr = 'Select questions. Specify three questions:'; es_ES = 'Select questions. Specify three questions:'");
				InformationFooter =NStr("ru='Нажмите Далее для подбора предопределенных ответов.'; en = 'Click Next to select predefined replies.'; pl = 'Click Next to select predefined replies.';de = 'Click Next to select predefined replies.';ro = 'Click Next to select predefined replies.';tr = 'Click Next to select predefined replies.'; es_ES = 'Click Next to select predefined replies.'");
			Else
				InformationHeader   =NStr("ru='Подбор вопросов. Укажите как минимум два вопроса:'; en = 'Select questions. Specify at least two questions:'; pl = 'Select questions. Specify at least two questions:';de = 'Select questions. Specify at least two questions:';ro = 'Select questions. Specify at least two questions:';tr = 'Select questions. Specify at least two questions:'; es_ES = 'Select questions. Specify at least two questions:'");
				InformationFooter  =NStr("ru='Нажмите Далее для подбора предопределенных ответов.'; en = 'Click Next to select predefined replies.'; pl = 'Click Next to select predefined replies.';de = 'Click Next to select predefined replies.';ro = 'Click Next to select predefined replies.';tr = 'Click Next to select predefined replies.'; es_ES = 'Click Next to select predefined replies.'");
			EndIf;
		ElsIf CurrentPage = Items.TableQuestionTypePage Then
			InformationHeader       = NStr("ru='Выбор типа табличного вопроса:'; en = 'Select a table question type:'; pl = 'Select a table question type:';de = 'Select a table question type:';ro = 'Select a table question type:';tr = 'Select a table question type:'; es_ES = 'Select a table question type:'");
			InformationFooter      = NStr("ru='Нажмите Далее для подбора вопросов:'; en = 'Click Next to select questions:'; pl = 'Click Next to select questions:';de = 'Click Next to select questions:';ro = 'Click Next to select questions:';tr = 'Click Next to select questions:'; es_ES = 'Click Next to select questions:'");
		Else
			InformationHeader  = NStr("ru='Подбор предопределенных ответов:'; en = 'Predefined response selection:'; pl = 'Predefined response selection:';de = 'Predefined response selection:';ro = 'Predefined response selection:';tr = 'Predefined response selection:'; es_ES = 'Predefined response selection:'");
			InformationFooter = NStr("ru='Нажмите Далее для просмотра получившейся таблицы:'; en = 'Click Next to view the resulting table:'; pl = 'Click Next to view the resulting table:';de = 'Click Next to view the resulting table:';ro = 'Click Next to view the resulting table:';tr = 'Click Next to view the resulting table:'; es_ES = 'Click Next to view the resulting table:'");
		EndIf;
	EndIf;
	
	Items.MainPagesGroup.Title = InformationHeader;
	
EndProcedure

// Controls availability of form attributes.
&AtClient
Procedure AvailabilityControl()

	CurrentPage = Items.Pages.CurrentPage;
	
	Items.BackButton.Enabled 	= (NOT CurrentPage = Items.TableQuestionTypePage);
		
	If CurrentPage = Items.PredefinedAnswersInRowsAndColumnsPage Then
		 		
		If NOT AllAnswersFilled() Then
			Items.NextButton.Enabled = False;
			Return;
		EndIf;			
		
		Items.PopulateAnswerOptionsColumnsAnswersInRowsAndColumns.Enabled = (Questions[1].ReplyType = PredefinedValue("Enum.QuestionAnswerTypes.MultipleOptionsFor") 
		                                                                             Or Questions[1].ReplyType = PredefinedValue("Enum.QuestionAnswerTypes.OneVariantOf"));
		
		Items.PopulateRowsAnswerOptionsAnswersInRowsAndColumns.Enabled    = (Questions[0].ReplyType = PredefinedValue("Enum.QuestionAnswerTypes.MultipleOptionsFor") 
		                                                                             Or Questions[0].ReplyType = PredefinedValue("Enum.QuestionAnswerTypes.OneVariantOf"));
		
		If Answers.FindRows(New Structure("ElementaryQuestion",QuestionForColumns)).Count() > 0 
			AND Answers.FindRows(New Structure("ElementaryQuestion",QuestionForRows)).Count() > 0  Then
			
			Items.NextButton.Enabled = True;
			
		Else
			
			Items.NextButton.Enabled = False;
			
		EndIf;	
		
	ElsIf CurrentPage = Items.PredefinedAnswersInRowsPage Then
		
		Items.PopulateAnswerOptionsAnswersRows.Enabled = (Questions[0].ReplyType = PredefinedValue("Enum.QuestionAnswerTypes.MultipleOptionsFor") 
		                                                             Or Questions[0].ReplyType = PredefinedValue("Enum.QuestionAnswerTypes.OneVariantOf"));
		
		If NOT AllAnswersFilled() Then
			Items.NextButton.Enabled = False;
			Return;
		EndIf;
		
		Items.NextButton.Enabled = (Answers.FindRows(New Structure("ElementaryQuestion",QuestionForRows)).Count() > 0);
		
	ElsIf CurrentPage = Items.PredefinedAnswersInColumnsPage Then
		
		Items.PopulateAnswerOptionsAnswersInColumns.Enabled = (Questions[0].ReplyType = PredefinedValue("Enum.QuestionAnswerTypes.MultipleOptionsFor") 
		                                                             Or Questions[0].ReplyType = PredefinedValue("Enum.QuestionAnswerTypes.OneVariantOf"));
		
		If NOT AllAnswersFilled() Then
			Items.NextButton.Enabled = False;
			Return;
		EndIf;
		
		Items.NextButton.Enabled = (Answers.FindRows(New Structure("ElementaryQuestion",QuestionForColumns)).Count() > 0);
	
	ElsIf CurrentPage = Items.TableQuestionTypePage Then
				
		Items.NextButton.Enabled 	= TabularQuestionType <> PredefinedValue("Enum.TabularQuestionTypes.EmptyRef");
				
		If TabularQuestionType = PredefinedValue("Enum.TabularQuestionTypes.Composite") Then
			
			Items.TableQuestionTypePagesPictures.CurrentPage = Items.CompositeQuestionPicturePage;
			
		ElsIf TabularQuestionType = PredefinedValue("Enum.TabularQuestionTypes.PredefinedAnswersInRows") Then
			
			Items.TableQuestionTypePagesPictures.CurrentPage = Items.AnswersInRowsPicturePage;
	
		ElsIf TabularQuestionType = PredefinedValue("Enum.TabularQuestionTypes.PredefinedAnswersInColumns") Then
			
			Items.TableQuestionTypePagesPictures.CurrentPage = Items.AnswersInColumnsPicturePage;
			
		ElsIf TabularQuestionType = PredefinedValue("Enum.TabularQuestionTypes.PredefinedAnswersInRowsAndColumns") Then
			
			Items.TableQuestionTypePagesPictures.CurrentPage = Items.AnswersInRowsAndColumnsPicturePage;
			
		Else
			
			Items.TableQuestionTypePagesPictures.CurrentPage = Items.BlankPicturePage;
			
		EndIf;
		
	ElsIf CurrentPage = Items.QuestionsPage Then
		
		If Questions.FindRows(New Structure("ElementaryQuestion",PredefinedValue("ChartOfCharacteristicTypes.QuestionsForSurvey.EmptyRef"))).Count() <> 0  Then
			Items.NextButton.Enabled = False;
			Return;
		EndIf;
		
		If TabularQuestionType = PredefinedValue("Enum.TabularQuestionTypes.Composite") Then
			
			Items.NextButton.Enabled = (Questions.Count() > 0); 
			
		ElsIf TabularQuestionType = PredefinedValue("Enum.TabularQuestionTypes.PredefinedAnswersInRows") Then
			
			Items.NextButton.Enabled = (Questions.Count() > 1);
			
		ElsIf TabularQuestionType = PredefinedValue("Enum.TabularQuestionTypes.PredefinedAnswersInColumns") Then
			
			Items.NextButton.Enabled = (Questions.Count() > 1);
			
		ElsIf TabularQuestionType = PredefinedValue("Enum.TabularQuestionTypes.PredefinedAnswersInRowsAndColumns") Then
			
			Items.NextButton.Enabled = (Questions.Count() = 3);
			
		EndIf;
		
	ElsIf CurrentPage = Items.ResultTablePage Then
		
		Items.NextButton.Enabled =  ValueIsFilled(Wording);
		
	EndIf;
	
EndProcedure

// Checks whether all answers are filled in.
//
// Returns:
//   Boolean   - True if all answers are filled in.
//
&AtClient
Function AllAnswersFilled()

	For each Answer In Answers Do
	
		If NOT ValueIsFilled(Answer.Response) Then
			Return  False;
		EndIf;
	
	EndDo;
	
	Return True;

EndFunction

// The procedure processes the start of choice from lists and sets filters in choice forms.
&AtClient
Procedure ListsChoiceStart(Item,StandardProcessing,DetailsOfAvailableTypes)
	
	If TypeOf(ThisObject[Item.TypeLink.DataPath]) = Type("ChartOfCharacteristicTypesRef.QuestionsForSurvey") Then
		
		If DetailsOfAvailableTypes.ContainsType(Type("CatalogRef.QuestionnaireAnswersOptions")) AND (DetailsOfAvailableTypes.Types().Count() = 1 ) Then
			
			StandardProcessing = FALSE;
			
			FilterParameters = New Structure;
			FilterParameters.Insert("Owner", ThisObject[Item.TypeLink.DataPath]);
			FilterParameters.Insert("DeletionMark", False);
			
			OpenForm("Catalog.QuestionnaireAnswersOptions.Form.ChoiceForm",New Structure("Filter",FilterParameters),Item);
			
		EndIf;
		
	EndIf;
	
EndProcedure

// The procedure clears an answers table from answers, whose parent question is not included in the 
// QuestionsArray acting as a parameter.
&AtClient
Procedure ClearAnswersListIfNecessary(QuestionsArray)
	
	AnswersToDelete = New Array;
	
	For each Answer In Answers Do
		
		If QuestionsArray.Find(Answer.ElementaryQuestion) = Undefined Then
			 AnswersToDelete.Add(Answer);
		EndIf;
		
	EndDo;
	
	For each AnswerToDelete In AnswersToDelete Do
		Answers.Delete(AnswerToDelete);
	EndDo;
	
EndProcedure 

// Sets an appropriate page of generating table question structure depending on the selected table 
// question type.
&AtClient
Procedure SetAnswersPage()
	
	ArrayOfQuestionsToAnswer = New Array;
	
	If TabularQuestionType =  PredefinedValue("Enum.TabularQuestionTypes.PredefinedAnswersInRowsAndColumns") Then
		
		Items.Pages.CurrentPage = Items.PredefinedAnswersInRowsAndColumnsPage;
		QuestionForRowsPresentation      = Questions[0].Wording;
		QuestionForRows                    = Questions[0].ElementaryQuestion;
		QuestionForColumnsPresentation    = Questions[1].Wording;
		QuestionForColumns                  = Questions[1].ElementaryQuestion;
		
		ArrayOfQuestionsToAnswer.Add(QuestionForRows);
		ArrayOfQuestionsToAnswer.Add(QuestionForColumns);
		
	ElsIf TabularQuestionType =  PredefinedValue("Enum.TabularQuestionTypes.PredefinedAnswersInRows") Then 
		
		Items.Pages.CurrentPage = Items.PredefinedAnswersInRowsPage;
		QuestionForRowsPresentation      = Questions[0].Wording;
		QuestionForRows                    = Questions[0].ElementaryQuestion;
		
		ArrayOfQuestionsToAnswer.Add(QuestionForRows);
		
	ElsIf TabularQuestionType = PredefinedValue("Enum.TabularQuestionTypes.PredefinedAnswersInColumns") Then 
		
		Items.Pages.CurrentPage = Items.PredefinedAnswersInColumnsPage;
		QuestionForColumnsPresentation    = Questions[0].Wording;
		QuestionForColumns                  = Questions[0].ElementaryQuestion;
		
		ArrayOfQuestionsToAnswer.Add(QuestionForColumns);
		
	EndIf;
	
	ClearAnswersListIfNecessary(ArrayOfQuestionsToAnswer);
	SetFilters();
	
EndProcedure

// Generates a resulting question table.
&AtServer
Procedure GenerateResultingTable()
	
	Survey.UpdateTabularQuestionPreview(FormAttributeToValue("Questions"),Answers,TabularQuestionType,ThisObject,"ResultingTable","");
	Items.NextButton.Title = NStr("ru = 'Готово'; en = 'Finish'; pl = 'Finish';de = 'Finish';ro = 'Finish';tr = 'Finish'; es_ES = 'Finish'");
	
EndProcedure

// Generates a return structure to pass to the owner form.
&AtClient
Function GenerateParametersStructureToPassToOwner()

	ParametersStructure = New Structure;
	ParametersStructure.Insert("TabularQuestionType",TabularQuestionType);
	
	QuestionsToReturn = New Array;
	For each TableRow In Questions Do
		QuestionsToReturn.Add(TableRow.ElementaryQuestion);
	EndDo;
	ParametersStructure.Insert("Questions",QuestionsToReturn);
	ParametersStructure.Insert("Answers" ,Answers);
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
	
	If Parameters.TabularQuestionType.IsEmpty() Then
		TabularQuestionType = Enums.TabularQuestionTypes.Composite;
		Return;
	EndIf;
	
	TabularQuestionType = Parameters.TabularQuestionType;
	
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
	
	Query.SetParameter("Questions", Parameters.TabularQuestionComposition.Unload());
	
	Result = Query.Execute();
	If NOT Result.IsEmpty() Then;
		Selection = Result.Select();
		While Selection.Next() Do
			NewRow = Questions.Add();
			FillPropertyValues(NewRow,Selection);
		EndDo;
	EndIf;
	
	CommonClientServer.SupplementTable(Parameters.PredefinedAnswers, Answers);
	
EndProcedure

// Sets filters in form items used to create a list of predefined answers.
// 
&AtClient
Procedure SetFilters()
	
	If TabularQuestionType = PredefinedValue("Enum.TabularQuestionTypes.PredefinedAnswersInRowsAndColumns") Then
		
		Items.AnswersColumnsAnswersInRowsAndColumns.RowFilter = New FixedStructure("ElementaryQuestion",QuestionForColumns);
		Items.AnswersRowsAnswersInRowsAndColumns.RowFilter  = New FixedStructure("ElementaryQuestion",QuestionForRows);
		SetLinksOfAnswersAndQuestionsChoiceParameters();
		
	ElsIf TabularQuestionType =  PredefinedValue("Enum.TabularQuestionTypes.PredefinedAnswersInRows") Then
		
		Items.AnswersRowsAnswersInRows.RowFilter = New FixedStructure("ElementaryQuestion",QuestionForRows);
		SetLinksOfAnswersAndQuestionsChoiceParameters();
		
	ElsIf TabularQuestionType =  PredefinedValue("Enum.TabularQuestionTypes.PredefinedAnswersInColumns") Then
		
		Items.AnswersColumnsAnswersInColumns.RowFilter = New FixedStructure("ElementaryQuestion",QuestionForColumns);
		SetLinksOfAnswersAndQuestionsChoiceParameters();
		
	EndIf;
	
	
EndProcedure

&AtServer
Procedure SetLinksOfAnswersAndQuestionsChoiceParameters()

	If TabularQuestionType = PredefinedValue("Enum.TabularQuestionTypes.PredefinedAnswersInRowsAndColumns") Then
		
		SetLinkOfAnswersAndQuestionsChoiceParameter("AnswersColumnsAnswersInRowsAndColumnsAnswer", "QuestionForColumns");
		SetLinkOfAnswersAndQuestionsChoiceParameter("AnswersRowsAnswersInRowsAndColumnsAnswer", "QuestionForRows");
		
	ElsIf TabularQuestionType =  PredefinedValue("Enum.TabularQuestionTypes.PredefinedAnswersInRows") Then
		
		SetLinkOfAnswersAndQuestionsChoiceParameter("AnswersRowsAnswersInRowsAnswer", "QuestionForRows");
		
	ElsIf TabularQuestionType =  PredefinedValue("Enum.TabularQuestionTypes.PredefinedAnswersInColumns") Then
		
		SetLinkOfAnswersAndQuestionsChoiceParameter("AnswersColumnsAnswersInColumnsAnswer", "QuestionForColumns");
		
	EndIf;

EndProcedure

&AtServer
Procedure SetLinkOfAnswersAndQuestionsChoiceParameter(AnswerFieldName, QuestionAttributeName)

	FoundQuestions = Questions.FindRows(New Structure("ElementaryQuestion", ThisObject[QuestionAttributeName]));
	If FoundQuestions.Count() > 0 Then
		FoundQuestion = FoundQuestions[0];
		If FoundQuestion.ReplyType = Enums.QuestionAnswerTypes.OneVariantOf
			OR FoundQuestion.ReplyType = Enums.QuestionAnswerTypes.MultipleOptionsFor Then
			ChoiceParametersArray = New Array;
			ChoiceParameterLink = New ChoiceParameterLink("Filter.Owner", QuestionAttributeName, LinkedValueChangeMode.Clear);
			ChoiceParametersArray.Add(ChoiceParameterLink);
			ChoiceParameterLinks = New FixedArray(ChoiceParametersArray);
			Items[AnswerFieldName].ChoiceParameterLinks = ChoiceParameterLinks;
		Else
			Items[AnswerFieldName].ChoiceParameterLinks = New FixedArray(New Array);
		EndIf;
	Else
		Items[AnswerFieldName].ChoiceParameterLinks = New FixedArray(New Array);
	EndIf;

EndProcedure


// Called upon changing form items linked to the answers table.
// Parameters:
//   Item - FormTable - an item that caused the change.
&AtClient
Procedure OnChangeAnswers(Item)
	
	AvailabilityControl();
	SetFilters();
	Item.Refresh();
	
EndProcedure

&AtClient
Procedure ProcessAnswersPickingItemAfterAdd(Item,AddedRow)
	
	SetFilters();
	Item.Refresh();
	AvailabilityControl();
	Item.CurrentRow = AddedRow.GetID();
	Item.ChangeRow();

EndProcedure

&AtClient
Function AddAnswerInteractively(Item,Clone,SupportQuestionNumber)

	If Clone Then
		
		NewRow = Answers.Add();
		FillPropertyValues(NewRow,Item.CurrentData);
		
	Else	
		
		If Questions.Count() >= SupportQuestionNumber+1 Then
			
			NewRow = Answers.Add();
			NewRow.ElementaryQuestion = Questions[SupportQuestionNumber].ElementaryQuestion;
			
		Else
			Return Undefined;
		EndIf;
		
	EndIf;
	
	Return NewRow;
	
EndFunction

&AtClient
Procedure EndEditAndClose()
	
	If TabularQuestionType = PredefinedValue("Enum.TabularQuestionTypes.Composite") Then
		Answers.Clear();
	EndIf;
	
	ClosingInProgress = True;
	Notify("EndEditTableQuestionParameters",GenerateParametersStructureToPassToOwner());
	Close();
	
EndProcedure

// Clears answers and fills them in with answers options.
//
// Parameters:
//  ElementaryQuestion - ChartOfCharacteristicTypes.QuestionsForSurvey - a question, for which its 
//                                                                         answers options will be filled in.
//
&AtServer
Procedure ClearFillAnswersOptions(ElementaryQuestion)
	
	If Not ValueIsFilled(ElementaryQuestion) Then
		Return;	
	EndIf;
	
	FoundRows = Answers.FindRows(New Structure("ElementaryQuestion",ElementaryQuestion));
	For each FoundRow In FoundRows Do
		Answers.Delete(Answers.IndexOf(FoundRow));
	EndDo;
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	QuestionnaireAnswersOptions.Ref AS Response
	|FROM
	|	Catalog.QuestionnaireAnswersOptions AS QuestionnaireAnswersOptions
	|WHERE
	|	QuestionnaireAnswersOptions.Owner = &ElementaryQuestion
	|	AND (NOT QuestionnaireAnswersOptions.DeletionMark)
	|
	|ORDER BY
	|	QuestionnaireAnswersOptions.AddlOrderingAttribute";
	
	Query.SetParameter("ElementaryQuestion",ElementaryQuestion);
	
	Result = Query.Execute();
	If Not Result.IsEmpty() Then
		
		Selection = Result.Select();
		While Selection.Next() Do
			NewRow = Answers.Add();
			NewRow.ElementaryQuestion = ElementaryQuestion;
			NewRow.Response              = Selection.Response;
		EndDo;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function QuestionAttributes(Question)
	
	Return Common.ObjectAttributesValues(Question,"Presentation,Wording,IsFolder,ReplyType");
	
EndFunction

#EndRegion
