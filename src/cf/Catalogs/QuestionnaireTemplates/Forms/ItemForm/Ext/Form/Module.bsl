///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel,StandardProcessing)
	
	SetConditionalAppearance();
	
	Survey.SetQuestionnaireTreeRootItem(QuestionnaireTree);
	Survey.FillQuestionnaireTemplateTree(ThisObject,"QuestionnaireTree",Object.Ref);
	QuestioningClientServer.GenerateTreeNumbering(QuestionnaireTree);
	SetConditionalFormAppearance();
	DetermineIfThereAreQuestionnairesForThisTemplate();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)

	Items.QuestionnaireTreeForm.Expand(QuestionnaireTree.GetItems()[0].GetID(),False);
	
	If Object.TemplateEditCompleted OR TemplateHasQuestionnaires Then
		SetEditingUnavailability();
	Else
		DetermineTemplateTreeAvailability();
	EndIf;
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	Survey.DeleteQuestionnaireTemplateQuestions(Object.Ref);
	QuestionnaireTemplateTree  = FormAttributeToValue("QuestionnaireTree");
	
	WriteQuestionnaireTemplateTree(QuestionnaireTemplateTree.Rows[0],1);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	CurrentData = Items.QuestionnaireTreeForm.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If EventName = "EndEditTableQuestionParameters" Then
		
		ProcessTabularQuestionWizardResult(CurrentData,Parameter,Items.QuestionnaireTreeForm.CurrentRow);
		Modified = True;
		
	ElsIf EventName = "EndEditComplexQuestionParameters" Then
		
		ProcessComplexQuestionsWizardResult(CurrentData,Parameter,Items.QuestionnaireTreeForm.CurrentRow);
		Modified = True;
		
	ElsIf EventName = "EndEditQuestionnaireTemplateLineParameters" Then
		
		FillPropertyValues(CurrentData,Parameter);
		CurrentData.HasNotes = Not IsBlankString(CurrentData.Notes);
		Modified = True;
		
		If CurrentData.RowType <> "Question" Then
			CurrentData.Required = Undefined;
		EndIf;
		
	ElsIf EventName = "CancelEnterNewQuestionnaireTemplateLine" Then
		If CurrentData.IsNewLine Then
			CurrentRow = QuestionnaireTree.FindByID(CurrentData.GetID());
			If CurrentRow <> Undefined Then
				CurrentRow.GetParent().GetItems().Delete(CurrentRow);
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	QuestionnaireTemplateTree  = FormAttributeToValue("QuestionnaireTree");
	
	If QuestionnaireTemplateTree.Rows[0].Rows.Find("","Wording",True) <> Undefined Then
		Common.MessageToUser(NStr("ru = 'Не все формулировки или имена разделов заполнены.'; en = 'Not all wordings or section names are filled in.'; pl = 'Not all wordings or section names are filled in.';de = 'Not all wordings or section names are filled in.';ro = 'Not all wordings or section names are filled in.';tr = 'Not all wordings or section names are filled in.'; es_ES = 'Not all wordings or section names are filled in.'"),,"QuestionnaireTree");
		Cancel = True;
	EndIf;
	
	FilterStructure = New Structure;
	FilterStructure.Insert("ElementaryQuestion",ChartsOfCharacteristicTypes.QuestionsForSurvey.EmptyRef());
	FilterStructure.Insert("RowType","Question");
	
	FoundRows = QuestionnaireTemplateTree.Rows[0].Rows.FindRows(FilterStructure,True);
	If FoundRows.Count() <> 0 Then
		For each FoundRow In FoundRows Do
			If FoundRow.QuestionsType <> Enums.QuestionnaireTemplateQuestionTypes.Tabular
					AND FoundRow.QuestionsType <> Enums.QuestionnaireTemplateQuestionTypes.Complex Then
				
				Common.MessageToUser(NStr("ru = 'Не все вопросы заполнены.'; en = 'Not all questions are filled in.'; pl = 'Not all questions are filled in.';de = 'Not all questions are filled in.';ro = 'Not all questions are filled in.';tr = 'Not all questions are filled in.'; es_ES = 'Not all questions are filled in.'"),,"QuestionnaireTree");
				Cancel = True;
				Break;
				
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	DetermineTemplateTreeAvailability();
	If Object.TemplateEditCompleted Then
		ThisObject.ReadOnly = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region QuestionnaireTreeFormTableItemsEventHandlers

&AtClient
Procedure QuestionnaireTreeFormBeforeDelete(Item, Cancel)
	
	CurrentData = Items.QuestionnaireTreeForm.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.RowType = "Root" Then
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure QuestionnaireTreeFormOnActivateRow(Item)
	
	CurrentData = Items.QuestionnaireTreeForm.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure QuestionnaireTreeFormDragCheck(Item, DragParameters, StandardProcessing, Row, Field)
	
	If (Row = Undefined) OR (DragParameters.Value = Undefined) Then
		Return;
	EndIf;
		
	StandardProcessing = False;
	
	If TypeOf(DragParameters.Value) <> Type("Number") Then
		DragParameters.Action = DragAction.Cancel;
		Return;
	EndIf;
	
	AssignmentRow     = QuestionnaireTree.FindByID(Row);
	RowDrag = QuestionnaireTree.FindByID(DragParameters.Value);
	
	If (RowDrag.RowType = "Section") AND (AssignmentRow.RowType = "Question") Then
		DragParameters.Action = DragAction.Cancel;
	ElsIf (RowDrag.RowType = "Question") AND (AssignmentRow.RowType = "Root")	Then
		DragParameters.Action = DragAction.Cancel;
	ElsIf (RowDrag.RowType = "Section") AND (AssignmentRow.RowType = "Section") Then
		If RowDrag.TemplateQuestion = AssignmentRow.TemplateQuestion Then
		      DragParameters.Action = DragAction.Cancel;
			Return;
		EndIf;
		Parent = AssignmentRow.GetParent();
		While Parent.RowType <> "Root" Do
				If Parent = RowDrag Then
					DragParameters.Action = DragAction.Cancel;
					Return;
				Else
					Parent = Parent.GetParent();
				EndIf;
		EndDo;
	EndIf;
	
EndProcedure

&AtClient
Procedure QuestionnaireTreeFormDragStart(Item, DragParameters, StandardProcessing)
	
	If Items.QuestionnaireTreeForm.ReadOnly Then
		StandardProcessing = False;
		DragParameters.Action = DragAction.Cancel;
	EndIf; 
	
	RowDrag = QuestionnaireTree.FindByID(DragParameters.Value);
	If TypeOf(RowDrag) = Type("Undefined") Then
		StandardProcessing = False;
		DragParameters.Action = DragAction.Cancel;
	Else
		If RowDrag.RowType = "Root" Then
			StandardProcessing = False;
			DragParameters.Action = DragAction.Cancel;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure QuestionnaireTreeFormDrag(Item, DragParameters, StandardProcessing, Row, Field)
	
	AssignmentRow     = QuestionnaireTree.FindByID(Row);
	RowDrag = QuestionnaireTree.FindByID(DragParameters.Value);
	
	If (RowDrag.RowType = "Question") AND (AssignmentRow.RowType = "Question") Then
		
		// Dragging a question without condition to a question with condition.
		If RowDrag.QuestionsType <> PredefinedValue("Enum.QuestionnaireTemplateQuestionTypes.QuestionWithCondition")
			AND AssignmentRow.QuestionsType = PredefinedValue("Enum.QuestionnaireTemplateQuestionTypes.QuestionWithCondition") Then
			
			StandardProcessing = False;
			DragTreeItem(AssignmentRow,RowDrag,False);
			
			Modified = True;
			
		ElsIf RowDrag.GetParent() <> AssignmentRow.GetParent() Then
			
			StandardProcessing = False;
			DragTreeItem(AssignmentRow,RowDrag,True);
			
			Modified = True;
			
		EndIf;
		
	ElsIf (RowDrag.RowType = "Question") AND (AssignmentRow.RowType = "Section") Then
		
		If RowDrag.GetParent() <> AssignmentRow Then
			
			StandardProcessing = False;
			DragTreeItem(AssignmentRow,RowDrag,False);
			
			Modified = True;
			
		EndIf;
		
	ElsIf (RowDrag.RowType = "Section") AND (AssignmentRow.RowType = "Section") Then
		
		If RowDrag.GetParent() <> AssignmentRow Then
			
			StandardProcessing = False;
			DragTreeItem(AssignmentRow,RowDrag,False);
			
			Modified = True; 
			
		ElsIf RowDrag.GetParent() <> AssignmentRow.GetParent() Then
			
			StandardProcessing = False;
			DragTreeItem(AssignmentRow,RowDrag,True);
			
			Modified = True;
			
		EndIf;
		
	ElsIf (RowDrag.RowType = "Section") AND (AssignmentRow.RowType = "Question") Then
		
		If (RowDrag.GetParent() <> AssignmentRow.GetParent()) AND (AssignmentRow.GetParent() <> RowDrag)Then
			
			StandardProcessing = False;
			DragTreeItem(AssignmentRow,RowDrag,True);
			
			Modified = True;
			
		EndIf;
		
	ElsIf ((RowDrag.RowType = "Section") OR (RowDrag.RowType = "Question")) AND (AssignmentRow.RowType = "Root") Then
		
		StandardProcessing = False;
		DragTreeItem(AssignmentRow,RowDrag,False);
		
		Modified = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure QuestionnaireTreeFormOnChange(Item)
	
	Modified = True;
	QuestioningClientServer.GenerateTreeNumbering(QuestionnaireTree);
	
EndProcedure

&AtClient
Procedure QuestionnaireTreeFormBeforeChange(Item, Cancel)
	
	Cancel = True;
	
	CurrentData = Item.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.RowType = "Root" Then
		Cancel = True;
		Return;
	ElsIf CurrentData.RowType = "Section" 
		OR (CurrentData.RowType = "Question" 
		                               AND CurrentData.QuestionsType <> PredefinedValue("Enum.QuestionnaireTemplateQuestionTypes.Tabular")
		                               AND CurrentData.QuestionsType <> PredefinedValue("Enum.QuestionnaireTemplateQuestionTypes.Complex")) Then
		
		OpenSimpleQuestionsForm(CurrentData);
		
	ElsIf CurrentData.RowType = "Question" AND CurrentData.QuestionsType = PredefinedValue("Enum.QuestionnaireTemplateQuestionTypes.Complex") Then
		
		OpenComplexQuestionsWizardForm(CurrentData);
		
	ElsIf CurrentData.RowType = "Question" AND CurrentData.QuestionsType = PredefinedValue("Enum.QuestionnaireTemplateQuestionTypes.Tabular") Then
		
		OpenTabularQuestionsWizardForm(CurrentData);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure QuestionnaireTreeFormBeforeAdd(Item, Cancel, Clone, Parent, Folder)
	
	Cancel = True;
	
	ChoiceList = New  ValueList;
	ChoiceList.Add(NStr("ru = 'Раздел'; en = 'Section'; pl = 'Section';de = 'Section';ro = 'Section';tr = 'Section'; es_ES = 'Section'"));
	ChoiceList.Add(NStr("ru = 'Простой вопрос'; en = 'Simple question'; pl = 'Simple question';de = 'Simple question';ro = 'Simple question';tr = 'Simple question'; es_ES = 'Simple question'"));
	ChoiceList.Add(NStr("ru = 'Комплексный вопрос'; en = 'Interview question'; pl = 'Interview question';de = 'Interview question';ro = 'Interview question';tr = 'Interview question'; es_ES = 'Interview question'"));
	ChoiceList.Add(NStr("ru = 'Условный вопрос'; en = 'Conditional question'; pl = 'Conditional question';de = 'Conditional question';ro = 'Conditional question';tr = 'Conditional question'; es_ES = 'Conditional question'"));
	ChoiceList.Add(NStr("ru = 'Табличный вопрос'; en = 'Table question'; pl = 'Table question';de = 'Table question';ro = 'Table question';tr = 'Table question'; es_ES = 'Table question'"));
	
	OnCloseNotifyHandler = New NotifyDescription("SelectAddedItemTypeOnCompletion", ThisObject);
	ChoiceList.ShowChooseItem(OnCloseNotifyHandler, NStr("ru = 'Выберите тип добавляемого элемента.'; en = 'Select a type of the item being added.'; pl = 'Select a type of the item being added.';de = 'Select a type of the item being added.';ro = 'Select a type of the item being added.';tr = 'Select a type of the item being added.'; es_ES = 'Select a type of the item being added.'"),ChoiceList[0]);
	
EndProcedure

&AtClient
Procedure QuestionnaireTreeFormDragEnd(Item, DragParameters, StandardProcessing)
	
	QuestioningClientServer.GenerateTreeNumbering(QuestionnaireTree);
	
EndProcedure

&AtClient
Procedure QuestionnaireTreeFormChoice(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	If Items.QuestionnaireTreeForm.ReadOnly Then
		Return;	
	EndIf;
	
	CurrentData = Item.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.RowType = "Root" Then
		Return;
	ElsIf CurrentData.RowType = "Section" 
		OR (CurrentData.RowType = "Question" AND CurrentData.QuestionsType <> PredefinedValue("Enum.QuestionnaireTemplateQuestionTypes.Tabular")
												AND CurrentData.QuestionsType <> PredefinedValue("Enum.QuestionnaireTemplateQuestionTypes.Complex") ) Then
		
		OpenSimpleQuestionsForm(CurrentData);
		
	ElsIf CurrentData.RowType = "Question" AND CurrentData.QuestionsType = PredefinedValue("Enum.QuestionnaireTemplateQuestionTypes.Complex") Then
		
		OpenComplexQuestionsWizardForm(CurrentData);
		
	ElsIf CurrentData.RowType = "Question" AND CurrentData.QuestionsType = PredefinedValue("Enum.QuestionnaireTemplateQuestionTypes.Tabular") Then
		
		OpenTabularQuestionsWizardForm(CurrentData);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure QuestionnaireTreeNotesOnChange(Item)
	
	CurrentData = Items.QuestionnaireTreeForm.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurrentData.HasNotes = Not IsBlankString(CurrentData.HasNotes);
	
EndProcedure

&AtClient
Procedure QuestionnaireTreeNotesChoiceStart(Item, ChoiceData, StandardProcessing)
	
	OnCloseNotify = New NotifyDescription("NoteEditOnClose", ThisObject);
	CommonClient.ShowMultilineTextEditingForm(OnCloseNotify, Item.EditText, NStr("ru = 'Заметки'; en = 'Notes'; pl = 'Notes';de = 'Notes';ro = 'Notes';tr = 'Notes'; es_ES = 'Notes'"));
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

// Sets the flag indicating that questionnaire template editing is finished and records the 
// questionnaire.
&AtClient
Procedure EndEdit(Command)
	
	Object.TemplateEditCompleted = True;
	Write();
	
	If Modified Then
		Object.TemplateEditCompleted = False;
	Else
		SetEditingUnavailability();
	EndIf;
	
EndProcedure

// Adds a section to the questionnaire template tree.
&AtClient
Procedure AddSection(Command)
	
	If Not WriteIfNewExecutedSuccessfully() Then
		Return;
	EndIf;
	
	CurrentData = Items.QuestionnaireTreeForm.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
		
	Parent = GetParentQuestionnaireTree(CurrentData,True);
	AddQuestionnaireTreeRow(Parent,"Section");
	
EndProcedure

// Adds a simple question to the questionnaire template tree.
&AtClient
Procedure AddSimpleQuestion(Command)
	
	CurrentData = Items.QuestionnaireTreeForm.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	AddQuestion(CurrentData,PredefinedValue("Enum.QuestionnaireTemplateQuestionTypes.Basic"));
	
EndProcedure 

// Adds a complex question to the questionnaire template.
&AtClient
Procedure AddComplexQuestion(Command)
	
	CurrentData = Items.QuestionnaireTreeForm.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	AddQuestion(CurrentData,PredefinedValue("Enum.QuestionnaireTemplateQuestionTypes.Complex"));
	
EndProcedure

// Adds a question with condition to the questionnaire template.
&AtClient
Procedure AddQuestionWithCondition(Command)
	
	CurrentData = Items.QuestionnaireTreeForm.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	AddQuestion(CurrentData,PredefinedValue("Enum.QuestionnaireTemplateQuestionTypes.QuestionWithCondition"));
	
EndProcedure

// Adds a tabular question to the questionnaire template.
&AtClient
Procedure AddTabularQuestion(Command)
	
	CurrentData = Items.QuestionnaireTreeForm.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	AddQuestion(CurrentData,PredefinedValue("Enum.QuestionnaireTemplateQuestionTypes.Tabular"));
	
EndProcedure 

&AtClient
Procedure OpenQuestionnaireFillingForm(Command)
	
	If Not WriteIfNewExecutedSuccessfully() Then
		Return;
	EndIf;
	
	If Modified Then
		OnCloseNotifyHandler = New NotifyDescription("PromptForWriteRequiredAfterCompletion", ThisObject);
		ShowQueryBox(OnCloseNotifyHandler,
		               NStr("ru = 'Шаблон анкеты был модифицирован. 
		                   |Для корректного отображения изменений шаблон необходимо записать.
		                   |Записать?'; 
		                   |en = 'The questionnaire template was modified.  
		                   |To display all the changes correctly, save the template. 
		                   |Do you want to save it?'; 
		                   |pl = 'The questionnaire template was modified.  
		                   |To display all the changes correctly, save the template. 
		                   |Do you want to save it?';
		                   |de = 'The questionnaire template was modified.  
		                   |To display all the changes correctly, save the template. 
		                   |Do you want to save it?';
		                   |ro = 'The questionnaire template was modified.  
		                   |To display all the changes correctly, save the template. 
		                   |Do you want to save it?';
		                   |tr = 'The questionnaire template was modified.  
		                   |To display all the changes correctly, save the template. 
		                   |Do you want to save it?'; 
		                   |es_ES = 'The questionnaire template was modified.  
		                   |To display all the changes correctly, save the template. 
		                   |Do you want to save it?'"),
		               QuestionDialogMode.YesNo,
		               ,
		               DialogReturnCode.Yes,
		               NStr("ru = 'Записать?'; en = 'Do you want to save it?'; pl = 'Do you want to save it?';de = 'Do you want to save it?';ro = 'Do you want to save it?';tr = 'Do you want to save it?'; es_ES = 'Do you want to save it?'"));
	Else
		OpenQuestionnaireWizardFormBySections();
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.QuestionnaireTreeRequired.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("QuestionnaireTree.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = NStr("ru = 'Вопрос'; en = 'Question'; pl = 'Question';de = 'Question';ro = 'Question';tr = 'Question'; es_ES = 'Question'");

	Item.Appearance.SetParameterValue("BackColor", WebColors.Gainsboro);
	Item.Appearance.SetParameterValue("TextColor", WebColors.Gainsboro);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.QuestionnaireTreeRequired.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("QuestionnaireTree.QuestionsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.QuestionnaireTemplateQuestionTypes.Tabular;

	Item.Appearance.SetParameterValue("BackColor", WebColors.Gainsboro);
	Item.Appearance.SetParameterValue("TextColor", WebColors.Gainsboro);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.QuestionnaireTreeWording.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("QuestionnaireTree.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = NStr("ru = 'Корень'; en = 'Root'; pl = 'Root';de = 'Root';ro = 'Root';tr = 'Root'; es_ES = 'Root'");

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("QuestionnaireTree.Wording");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

EndProcedure

// Adds a new row to the form tree.
// Parent   - QuestionnaireTreeRow -  an item of the form values tree, from which a new branch starts.
// RowType  - Row - a type of a tree row.
// Returns:
//   Row     - a new tree row.
//
&AtClient
Function AddQuestionnaireTreeRow(Parent,RowType,QuestionType = Undefined)
	
	TreeItems = Parent.GetItems();
	NewRow    = TreeItems.Add();
	
	NewRow.RowType      = RowType;
	NewRow.Required   = False;
	NewRow.RowKey     = New UUID;
	NewRow.IsNewLine = True;
	
	If RowType = "Question" Then
		
		NewRow.QuestionsType         = QuestionType;
		NewRow.PictureCode        = QuestioningClientServer.GetQuestionnaireTemplatePictureCode(FALSE,QuestionType);
		NewRow.ElementaryQuestion = ?(QuestionType = PredefinedValue("Enum.QuestionnaireTemplateQuestionTypes.Tabular")
		                                   Or QuestionType = PredefinedValue("Enum.QuestionnaireTemplateQuestionTypes.Complex"),
		                                   "",
		                                   PredefinedValue("ChartOfCharacteristicTypes.QuestionsForSurvey.EmptyRef"));
		NewRow.Required       = ?(QuestionType = PredefinedValue("Enum.QuestionnaireTemplateQuestionTypes.Tabular")
		                                   Or QuestionType = PredefinedValue("Enum.QuestionnaireTemplateQuestionTypes.Complex"),"",False);
		
	Else
		
		NewRow.QuestionsType         = PredefinedValue("Enum.QuestionnaireTemplateQuestionTypes.EmptyRef");
		NewRow.PictureCode        = QuestioningClientServer.GetQuestionnaireTemplatePictureCode(TRUE);
		NewRow.ElementaryQuestion = "";
		NewRow.Required       = "";
		
	EndIf;
	
	NewRow.HintPlacement = PredefinedValue("Enum.TooltipDisplayMethods.AsTooltip");
	
	QuestioningClientServer.GenerateTreeNumbering(QuestionnaireTree);
	Items.QuestionnaireTreeForm.CurrentRow = NewRow.GetID();
	
	Modified = True;
	Items.QuestionnaireTreeForm.ChangeRow();
	
	Return NewRow;
	
EndFunction

&AtServer
Procedure WriteQuestionnaireTemplateTree(TreeRowParent,RecursionLevel,CatalogParent = Undefined)
	
	Counter = 0;
	
	// Writing new rows
	For each TreeRow In TreeRowParent.Rows Do
		
		Counter = Counter + 1;
		CatRef = AddQuestionnaireTemplateQuestionCatalogItem(TreeRow,?(RecursionLevel = 1,Counter,Undefined),CatalogParent);
		
		If TreeRow.Rows.Count() > 0 Then
			If TreeRow.RowType = "Section" Then
				WriteQuestionnaireTemplateTree(TreeRow,RecursionLevel+1,CatRef);
			Else
				For each RowSubordinateQuestion In TreeRow.Rows Do
					AddQuestionnaireTemplateQuestionCatalogItem(RowSubordinateQuestion,Undefined,CatalogParent,CatRef);
				EndDo;
			EndIf;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Function AddQuestionnaireTemplateQuestionCatalogItem(TreeRow,Code = Undefined,CatalogParent = Undefined,QuestionParent = Undefined)
	
	If TreeRow.RowType = "Section" Then
		
		CatObject = Catalogs.QuestionnaireTemplateQuestions.CreateFolder();
		
	Else
		
		CatObject = Catalogs.QuestionnaireTemplateQuestions.CreateItem();
		CatObject.QuestionsType                        = TreeRow.QuestionsType;
		CatObject.ElementaryQuestion                = TreeRow.ElementaryQuestion;
		CatObject.TabularQuestionType              = TreeRow.TabularQuestionType;
		CatObject.Required                      = TreeRow.Required;
		CatObject.ToolTip                         = TreeRow.ToolTip;
		CatObject.HintPlacement        = TreeRow.HintPlacement;
		CatObject.ParentQuestion                    = ?(QuestionParent = Undefined, Catalogs.QuestionnaireTemplateQuestions.EmptyRef(),QuestionParent);
		CommonClientServer.SupplementTable(TreeRow.TabularQuestionComposition,CatObject.TabularQuestionComposition);
		CommonClientServer.SupplementTable(TreeRow.PredefinedAnswers,CatObject.PredefinedAnswers);
		CommonClientServer.SupplementTable(TreeRow.ComplexQuestionComposition,CatObject.ComplexQuestionComposition);
		
	EndIf;
	
	If Code <> Undefined Then
		CatObject.Code = Code;
	EndIf;
	CatObject.Description = TreeRow.Wording;
	CatObject.Notes      = TreeRow.Notes;
	CatObject.Wording = TreeRow.Wording;
	CatObject.Parent     = ?(CatalogParent = Undefined,Catalogs.QuestionnaireTemplateQuestions.EmptyRef(),CatalogParent);
	CatObject.Owner    = Object.Ref;
	
	CatObject.Write();
	
	Return CatObject.Ref;
	
EndFunction

// Processes a result of the tabular question wizard.
//
// Parameters:
//  CurrentData - TreeItemFormData - the current data of the template tree.
//  Parameter - Structure - a result of the tabular question wizard.
//
&AtClient
Procedure ProcessTabularQuestionWizardResult(CurrentData,Parameter,CurrentRow)
	
	CurrentData.TabularQuestionComposition.Clear();
	CurrentData.PredefinedAnswers.Clear();
	
	CurrentData.TabularQuestionType       = Parameter.TabularQuestionType;
	CurrentData.Description               = Parameter.Wording;
	CurrentData.Wording               = Parameter.Wording;
	CurrentData.ElementaryQuestion         = Parameter.Wording;
	CurrentData.Required               = "";
	CurrentData.ToolTip                  = Parameter.ToolTip;
	CurrentData.HintPlacement = Parameter.HintPlacement;
	CurrentData.IsNewLine             = False;
	
	RowNumber = 1;
	For each Question In Parameter.Questions Do
	
		NewRow = CurrentData.TabularQuestionComposition.Add();
		NewRow.ElementaryQuestion = Question;
		NewRow.LineNumber        = RowNumber;
		
		RowNumber = RowNumber + 1;
	
	EndDo;
	
	For each Answer In Parameter.Answers Do
		FillPropertyValues(CurrentData.PredefinedAnswers.Add(),Answer);
	EndDo;
	
	SetConditionalFormAppearance();
	
EndProcedure

&AtClient
Procedure ProcessComplexQuestionsWizardResult(CurrentData,Parameter,CurrentRow)
	
	CurrentData.ComplexQuestionComposition.Clear();
	
	CurrentData.Description               = Parameter.Wording;
	CurrentData.Wording               = Parameter.Wording;
	CurrentData.ElementaryQuestion         = Parameter.Wording;
	CurrentData.Required               = "";
	CurrentData.ToolTip                  = Parameter.ToolTip;
	CurrentData.HintPlacement = Parameter.HintPlacement;
	CurrentData.IsNewLine             = False;
	
	RowNumber = 1;
	For each Question In Parameter.Questions Do
	
		NewRow = CurrentData.ComplexQuestionComposition.Add();
		NewRow.ElementaryQuestion = Question;
		NewRow.LineNumber        = RowNumber;
		
		RowNumber = RowNumber + 1;
	
	EndDo;
	
	SetConditionalFormAppearance();
	
EndProcedure

// Sets conditional appearance of the form.
&AtServer
Procedure SetConditionalFormAppearance();
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("QuestionnaireTree.RowType");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.NotEqual;
	DataFilterItem.Use = True;
	DataFilterItem.RightValue = "Question";
	
	AppearanceField = ConditionalAppearanceItem.Fields.Items.Add();
	AppearanceField.Use = True;
	AppearanceField.Field          = New DataCompositionField("QuestionnaireTreeRequired");
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("BackColor",WebColors.Gainsboro);
	
EndProcedure

&AtServer
Procedure DetermineIfThereAreQuestionnairesForThisTemplate()
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = "
	|SELECT TOP 1
	|	Questionnaire.Ref
	|FROM
	|	Document.Questionnaire AS Questionnaire
	|WHERE
	|	(NOT Questionnaire.DeletionMark)
	|	AND Questionnaire.Survey IN
	|			(SELECT
	|				PollPurpose.Ref
	|			FROM
	|				Document.PollPurpose AS PollPurpose
	|			WHERE
	|				PollPurpose.QuestionnaireTemplate = &QuestionnaireTemplate)";
	
	Query.SetParameter("QuestionnaireTemplate",Object.Ref);
	
	If NOT Query.Execute().IsEmpty() Then
		
		TemplateHasQuestionnaires = True;
		
	Else
		
		TemplateHasQuestionnaires = False;
		
	EndIf;
	
	SetPrivilegedMode(False);
	
EndProcedure

&AtClient
Function GetParentQuestionnaireTree(CurrentParent,CanBeRoot,QuestionType = Undefined)
	
	If CanBeRoot Then
		
		While (CurrentParent.RowType <> "Root") AND (CurrentParent.RowType <> "Section") Do
			CurrentParent = CurrentParent.GetParent();
			If CurrentParent = Undefined Then
				Return QuestionnaireTree.GetItems()[0];
			EndIf;
		EndDo;
		
	Else 
		
		While (CurrentParent.RowType <> "Section")
			AND ((CurrentParent.RowType = "Question") AND (NOT CurrentParent.QuestionsType = PredefinedValue("Enum.QuestionnaireTemplateQuestionTypes.QuestionWithCondition"))
			OR (CurrentParent.RowType = "Question" AND  CurrentParent.QuestionsType = PredefinedValue("Enum.QuestionnaireTemplateQuestionTypes.QuestionWithCondition") AND QuestionType = PredefinedValue("Enum.QuestionnaireTemplateQuestionTypes.QuestionWithCondition"))) Do
			
			CurrentParent = CurrentParent.GetParent();
			
		EndDo
		
	EndIf;
	
	Return CurrentParent;
	
EndFunction

// Adds a question to the questionnaire template. 
//
// Parameters:
//  CurrentData - FormDataTreeItem - the data of the current tree row.
//  QuestionType    - Enumerations.QuestionnaireTemplateQuestionTypes - a type of a question to be added.
//
&AtClient
Procedure AddQuestion(CurrentData,QuestionType)

	Parent = GetParentQuestionnaireTree(CurrentData,False,QuestionType);
	If Parent.RowType = "Root" Then
		ShowMessageBox(,NStr("ru = 'Вопросы нельзя добавлять в корень анкеты.'; en = 'Cannot add questions to the questionnaire root.'; pl = 'Cannot add questions to the questionnaire root.';de = 'Cannot add questions to the questionnaire root.';ro = 'Cannot add questions to the questionnaire root.';tr = 'Cannot add questions to the questionnaire root.'; es_ES = 'Cannot add questions to the questionnaire root.'"),15,NStr("ru = 'Ошибка добавления'; en = 'Adding error'; pl = 'Adding error';de = 'Adding error';ro = 'Adding error';tr = 'Adding error'; es_ES = 'Adding error'"));
		Return;
	EndIf;
	AddQuestionnaireTreeRow(Parent,"Question",QuestionType);

EndProcedure

&AtClient
Procedure DetermineTemplateTreeAvailability()
	
	EditingUnavailability   = Object.TemplateEditCompleted OR TemplateHasQuestionnaires;
	
	Items.QuestionnaireTree.ReadOnly                                      = EditingUnavailability;
	Items.QuestionnaireTreeForm.ReadOnly                                 = EditingUnavailability;
	Items.EndEdit.Enabled                              = NOT EditingUnavailability;
	Items.QuestionnaireTreeForm.CommandBar.Enabled                    = NOT EditingUnavailability;
	Items.QuestionnaireTreeForm.ContextMenu.Enabled                    = NOT EditingUnavailability;
	Items.QuestionnaireTreeFormContextMenuAdd.Enabled             = NOT EditingUnavailability;
	Items.QuestionnaireTreeContextMenuAddSection.Enabled            = NOT EditingUnavailability;
	Items.QuestionnaireTreeContextMenuMoveUp.Enabled          = NOT EditingUnavailability;
	Items.QuestionnaireTreeContextMenuMoveDown.Enabled           = NOT EditingUnavailability;
	Items.QuestionnaireTreeContextMenuAddQuestion.Enabled            = NOT EditingUnavailability;
	Items.QuestionnaireTreeContextMenuAddConditionalQuestion.Enabled   = NOT EditingUnavailability;
	Items.QuestionnaireTreeContextMenuAddTableQuestion.Enabled   = NOT EditingUnavailability;
	Items.QuestionnaireTreeContextMenuAddInterviewQuestion.Enabled = NOT EditingUnavailability;
	
EndProcedure

&AtClient
Procedure SetEditingUnavailability()
	
	If Object.TemplateEditCompleted OR TemplateHasQuestionnaires Then
		
		ThisObject.ReadOnly                                                 = True;
		Items.QuestionnaireTree.ReadOnly                                      = True;
		Items.QuestionnaireTreeForm.ReadOnly                                 = True;
		Items.QuestionnaireTreeForm.CommandBar.Enabled                    = False;
		Items.QuestionnaireTreeContextMenuAddSection.Enabled            = False;
		Items.QuestionnaireTreeContextMenuMoveUp.Enabled          = False;
		Items.QuestionnaireTreeContextMenuMoveDown.Enabled           = False;
		Items.QuestionnaireTreeContextMenuAddQuestion.Enabled            = False;
		Items.QuestionnaireTreeContextMenuAddConditionalQuestion.Enabled   = False;
		Items.QuestionnaireTreeContextMenuAddTableQuestion.Enabled   = False;
		Items.QuestionnaireTreeContextMenuAddInterviewQuestion.Enabled = False;
		Items.EndEdit.Enabled                              = False;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenSimpleQuestionsForm(CurrentData)
	
	SimpleQuestion = New Structure;
	SimpleQuestion.Insert("TreeRowType", CurrentData.RowType);
	SimpleQuestion.Insert("ElementaryQuestion", CurrentData.ElementaryQuestion);
	SimpleQuestion.Insert("Required", CurrentData.Required);
	SimpleQuestion.Insert("QuestionsType", CurrentData.QuestionsType);
	SimpleQuestion.Insert("Wording", CurrentData.Wording);
	SimpleQuestion.Insert("CloseOnChoice", True);
	SimpleQuestion.Insert("CloseOnOwnerClose", True);
	SimpleQuestion.Insert("ReadOnly", False);
	SimpleQuestion.Insert("Notes", CurrentData.Notes);
	SimpleQuestion.Insert("IsNewLine", CurrentData.IsNewLine);
	SimpleQuestion.Insert("ToolTip", CurrentData.ToolTip);
	SimpleQuestion.Insert("HintPlacement", CurrentData.HintPlacement);
	
	OpenForm("Catalog.QuestionnaireTemplates.Form.BasicQuestionsForm", SimpleQuestion, ThisObject);
	
EndProcedure

&AtClient
Procedure OpenComplexQuestionsWizardForm(CurrentData)
	
	ComplexQuestion = New Structure;
	ComplexQuestion.Insert("ComplexQuestionComposition", CurrentData.ComplexQuestionComposition);
	ComplexQuestion.Insert("Wording" ,CurrentData.Wording);
	ComplexQuestion.Insert("ToolTip", CurrentData.ToolTip);
	ComplexQuestion.Insert("HintPlacement", CurrentData.HintPlacement);
	ComplexQuestion.Insert("IsNewLine",             CurrentData.IsNewLine);
	
	OpenForm("Catalog.QuestionnaireTemplates.Form.ComplexQuestionsWizardForm", ComplexQuestion, ThisObject);
	
EndProcedure

&AtClient
Procedure OpenTabularQuestionsWizardForm(CurrentData)
	
	TabularQuestion = New Structure;
	TabularQuestion.Insert("TabularQuestionType",       CurrentData.TabularQuestionType);
	TabularQuestion.Insert("TabularQuestionComposition",    CurrentData.TabularQuestionComposition);
	TabularQuestion.Insert("PredefinedAnswers",     CurrentData.PredefinedAnswers);
	TabularQuestion.Insert("Wording",               CurrentData.Wording);
	TabularQuestion.Insert("ToolTip",                  CurrentData.ToolTip);
	TabularQuestion.Insert("HintPlacement", CurrentData.HintPlacement);
	TabularQuestion.Insert("IsNewLine",             CurrentData.IsNewLine);
	
	OpenForm("Catalog.QuestionnaireTemplates.Form.TableQuestionsWizardForm", TabularQuestion, ThisObject);
	
EndProcedure

&AtClient
Procedure DragTreeItem(AssignmentRow,RowDrag,UseAssignmentRowParent = FALSE,DeleteAfterAdd = True);
	
	If UseAssignmentRowParent Then
		NewRow = AssignmentRow.GetParent().GetItems().Add();
	Else
		NewRow = AssignmentRow.GetItems().Add();
	EndIf;
	
	FillPropertyValues(NewRow,RowDrag,,"TabularQuestionComposition,PredefinedAnswers, ComplexQuestionComposition");
	If RowDrag.QuestionsType = PredefinedValue("Enum.QuestionnaireTemplateQuestionTypes.Tabular") Then
		CommonClientServer.SupplementTable(RowDrag.TabularQuestionComposition,NewRow.TabularQuestionComposition);
		CommonClientServer.SupplementTable(RowDrag.PredefinedAnswers,NewRow.PredefinedAnswers);
	EndIf;
	
	If RowDrag.QuestionsType = PredefinedValue("Enum.QuestionnaireTemplateQuestionTypes.Complex") Then
		CommonClientServer.SupplementTable(RowDrag.ComplexQuestionComposition,NewRow.ComplexQuestionComposition);
	EndIf;
	
	For each Item In RowDrag.GetItems() Do
		DragTreeItem(NewRow,Item,False,False);
	EndDo;
	
	If DeleteAfterAdd Then
		RowDrag.GetParent().GetItems().Delete(RowDrag);
	EndIf;
	
	If UseAssignmentRowParent Then
		Items.QuestionnaireTreeForm.Expand(AssignmentRow.GetParent().GetID(),False);
	Else	
		Items.QuestionnaireTreeForm.Expand(AssignmentRow.GetID(),False);
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectAddedItemTypeOnCompletion(SelectedItem, AdditionalParameters) Export
	
	If NOT SelectedItem = Undefined Then
		
		If SelectedItem.Value = NStr("ru = 'Раздел'; en = 'Section'; pl = 'Section';de = 'Section';ro = 'Section';tr = 'Section'; es_ES = 'Section'") Then
			
			AddSection(Commands.AddSection);
			
		ElsIf SelectedItem.Value = NStr("ru = 'Простой вопрос'; en = 'Simple question'; pl = 'Simple question';de = 'Simple question';ro = 'Simple question';tr = 'Simple question'; es_ES = 'Simple question'") Then
			
			AddSimpleQuestion(Commands.AddSimpleQuestion)
			
		ElsIf SelectedItem.Value = NStr("ru = 'Комплексный вопрос'; en = 'Interview question'; pl = 'Interview question';de = 'Interview question';ro = 'Interview question';tr = 'Interview question'; es_ES = 'Interview question'") Then
			
			AddComplexQuestion(Commands.AddSimpleQuestion)
			
		ElsIf SelectedItem.Value = NStr("ru = 'Условный вопрос'; en = 'Conditional question'; pl = 'Conditional question';de = 'Conditional question';ro = 'Conditional question';tr = 'Conditional question'; es_ES = 'Conditional question'") Then
			
			AddQuestionWithCondition(Commands.AddConditionalQuestion)
			
		ElsIf SelectedItem.Value = NStr("ru = 'Табличный вопрос'; en = 'Table question'; pl = 'Table question';de = 'Table question';ro = 'Table question';tr = 'Table question'; es_ES = 'Table question'") Then
			
			AddTabularQuestion(Commands.AddTabularQuestion);
			
		EndIf;
		
	EndIf;

EndProcedure

&AtClient
Procedure PromptForWriteRequiredAfterCompletion(QuestionResult, AdditionalParameters) Export

	If QuestionResult = DialogReturnCode.Yes Then
			Write();
	EndIf;
	
	OpenQuestionnaireWizardFormBySections();
	
EndProcedure

&AtClient
Procedure OpenQuestionnaireWizardFormBySections()

	ParametersStructure = New Structure;
	ParametersStructure.Insert("QuestionnaireTemplate",Object.Ref);
	OpenForm("CommonForm.QuestionnaireBySectionWizard",ParametersStructure,ThisObject);

EndProcedure 

&AtClient
Procedure NoteEditOnClose(ReturnText, AdditionalParameters) Export
	
	CurrentData = Items.QuestionnaireTreeForm.CurrentData;
	If CurrentData <> Undefined Then
		If CurrentData.Notes <> ReturnText Then
			CurrentData.Notes = ReturnText;
			CurrentData.HasNotes = Not IsBlankString(CurrentData.Notes);
			Modified = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Function WriteAtServerExecutedSuccessfully()

	If Not CheckFilling() Then
		Return False;
	Else
		Write();
		Return True;
	EndIf;

EndFunction

&AtClient
Function WriteIfNewExecutedSuccessfully()

	If Object.Ref.IsEmpty() Then
		
		ClearMessages();
		Return WriteAtServerExecutedSuccessfully();
		
	Else
		
		Return True;
		
	EndIf;

EndFunction

#EndRegion
