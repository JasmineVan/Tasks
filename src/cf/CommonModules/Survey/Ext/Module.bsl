///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// Configuration subsystems event handlers.

// See BatchObjectModificationOverridable.OnDetermineObjectsWithEditableAttributes. 
Procedure OnDefineObjectsWithEditableAttributes(Objects) Export
	
	Objects.Insert(Metadata.Documents.Questionnaire.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Documents.PollPurpose.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.ChartsOfCharacteristicTypes.QuestionsForSurvey.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.QuestionnaireAnswersOptions.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.QuestionnaireTemplateQuestions.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.QuestionnaireTemplates.FullName(), "AttributesToEditInBatchProcessing");
	
EndProcedure

// See UsersOverridable.OnDefineRolesAssignment. 
Procedure OnDefineRoleAssignment(RolesAssignment) Export
	
	// BothForUsersAndExternalUsers.
	RolesAssignment.BothForUsersAndExternalUsers.Add(
		Metadata.Roles.AddEditQuestionnaireQuestionsAnswers.Name);
	RolesAssignment.BothForUsersAndExternalUsers.Add(
		Metadata.Roles.ReadQuestionnaireQuestionAnswers.Name);
	
EndProcedure

// See ReportsOptionsOverridable.DefineObjectsWithReportCommands. 
Procedure OnDefineObjectsWithReportCommands(Objects) Export
	
	Objects.Add(Metadata.Documents.PollPurpose);
	
EndProcedure

// See InfobaseUpdateSSL.OnAddUpdateHandlers. 
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Version = "2.1.2.7";
	Handler.Procedure = "Survey.InvertFlagIncludeToQuestionnaireArchive";
	
	Handler = Handlers.Add();
	Handler.Version = "2.3.5.6"; 
	Handler.ID = New UUID("cfda47d2-f61f-4c23-84a6-80c77b52e6e5");
	Handler.Procedure = "Documents.Questionnaire.ProcessDataForMigrationToNewVersion";
	Handler.Comment = NStr("ru = 'Заполнение значения нового реквизита ""Режим анкетирования"" у документов ""Анкета"" прошлых периодов.
		|До завершения обработки ""Режим анкетирования"" данных документов будет отображаться некорректно.'; 
		|en = 'Filling in new attribute ""Survey mode"" of the ""Questionnaire"" documents of previous periods.
		|Until the processing is complete, ""Survey mode"" of these documents will be shown incorrectly.'; 
		|pl = 'Filling in new attribute ""Survey mode"" of the ""Questionnaire"" documents of previous periods.
		|Until the processing is complete, ""Survey mode"" of these documents will be shown incorrectly.';
		|de = 'Filling in new attribute ""Survey mode"" of the ""Questionnaire"" documents of previous periods.
		|Until the processing is complete, ""Survey mode"" of these documents will be shown incorrectly.';
		|ro = 'Filling in new attribute ""Survey mode"" of the ""Questionnaire"" documents of previous periods.
		|Until the processing is complete, ""Survey mode"" of these documents will be shown incorrectly.';
		|tr = 'Filling in new attribute ""Survey mode"" of the ""Questionnaire"" documents of previous periods.
		|Until the processing is complete, ""Survey mode"" of these documents will be shown incorrectly.'; 
		|es_ES = 'Filling in new attribute ""Survey mode"" of the ""Questionnaire"" documents of previous periods.
		|Until the processing is complete, ""Survey mode"" of these documents will be shown incorrectly.'");
	Handler.ExecutionMode = "Deferred";
	Handler.DeferredProcessingQueue = 1;
	Handler.UpdateDataFillingProcedure = "Documents.Questionnaire.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure    = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.ObjectsToBeRead      = "Document.Questionnaire";
	Handler.ObjectsToChange    = "Document.Questionnaire";
	Handler.ObjectsToLock   = "Document.Questionnaire";

	Handler = Handlers.Add();
	Handler.Version = "2.3.5.6"; 
	Handler.ID = New UUID("1fdb0962-f814-463a-b560-48ea3d51be27");
	Handler.Procedure = "Catalogs.QuestionnaireTemplateQuestions.ProcessDataForMigrationToNewVersion";
	Handler.Comment = NStr("ru = 'Заполнение значения нового реквизита ""Способ отображения подсказки"" в справочнике ""Вопросы шаблона анкеты"".
		|До завершения обработки ""Способ отображения подсказки"" в данном справочнике будет отображаться некорректно.'; 
		|en = 'Filling in new attribute ""Hint placement"" of the ""Questionnaire template questions"" catalog.
		|Until the processing is complete, ""Hint placement"" in this catalog will be shown incorrectly.'; 
		|pl = 'Filling in new attribute ""Hint placement"" of the ""Questionnaire template questions"" catalog.
		|Until the processing is complete, ""Hint placement"" in this catalog will be shown incorrectly.';
		|de = 'Filling in new attribute ""Hint placement"" of the ""Questionnaire template questions"" catalog.
		|Until the processing is complete, ""Hint placement"" in this catalog will be shown incorrectly.';
		|ro = 'Filling in new attribute ""Hint placement"" of the ""Questionnaire template questions"" catalog.
		|Until the processing is complete, ""Hint placement"" in this catalog will be shown incorrectly.';
		|tr = 'Filling in new attribute ""Hint placement"" of the ""Questionnaire template questions"" catalog.
		|Until the processing is complete, ""Hint placement"" in this catalog will be shown incorrectly.'; 
		|es_ES = 'Filling in new attribute ""Hint placement"" of the ""Questionnaire template questions"" catalog.
		|Until the processing is complete, ""Hint placement"" in this catalog will be shown incorrectly.'");
	Handler.ExecutionMode = "Deferred";
	Handler.DeferredProcessingQueue = 1;
	Handler.UpdateDataFillingProcedure = "Catalogs.QuestionnaireTemplateQuestions.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure    = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.ObjectsToBeRead      = "Catalog.QuestionnaireTemplateQuestions";
	Handler.ObjectsToChange    = "Catalog.QuestionnaireTemplateQuestions";	
	Handler.ObjectsToLock   = "Catalog.QuestionnaireTemplateQuestions";
	
	Handler = Handlers.Add();
	Handler.Version = "2.4.4.69";
	Handler.ID = New UUID("a1581723-c1f5-4b90-b716-a180a4d5a4ad");
	Handler.Procedure = "ChartsOfCharacteristicTypes.QuestionsForSurvey.ProcessDataForMigrationToNewVersion";
	Handler.Comment = NStr("ru = 'Заполнение значений нового реквизита ""Вид"" в вопросах для анкетирования.
		|До завершения обработки вид вопросов для анкетирования будет отображаться некорректно.'; 
		|en = 'Filling in new attribute ""Kind"" in the survey questions.
		|Until the processing is complete, the kind of the survey questions will be shown incorrectly.'; 
		|pl = 'Filling in new attribute ""Kind"" in the survey questions.
		|Until the processing is complete, the kind of the survey questions will be shown incorrectly.';
		|de = 'Filling in new attribute ""Kind"" in the survey questions.
		|Until the processing is complete, the kind of the survey questions will be shown incorrectly.';
		|ro = 'Filling in new attribute ""Kind"" in the survey questions.
		|Until the processing is complete, the kind of the survey questions will be shown incorrectly.';
		|tr = 'Filling in new attribute ""Kind"" in the survey questions.
		|Until the processing is complete, the kind of the survey questions will be shown incorrectly.'; 
		|es_ES = 'Filling in new attribute ""Kind"" in the survey questions.
		|Until the processing is complete, the kind of the survey questions will be shown incorrectly.'");
	Handler.ExecutionMode = "Deferred";
	Handler.DeferredProcessingQueue = 1;
	Handler.UpdateDataFillingProcedure = "ChartsOfCharacteristicTypes.QuestionsForSurvey.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure    = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.ObjectsToBeRead      = "ChartOfCharacteristicTypes.QuestionsForSurvey";
	Handler.ObjectsToChange    = "ChartOfCharacteristicTypes.QuestionsForSurvey";
	Handler.ObjectsToLock   = "ChartOfCharacteristicTypes.QuestionsForSurvey";
		
EndProcedure

// See ReportsOptionsOverridable.CustomizeReportsOptions. 
Procedure OnSetUpReportsOptions(Settings) Export
	ModuleReportsOptions = Common.CommonModule("ReportsOptions");
	ModuleReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.PollStatistics);
	ModuleReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.AnalyticalReportByQuestioning);
EndProcedure

#EndRegion

#Region Private

// Inverts a value of the DontShowInQuestionnaireArchive attribute in accordance with the new name ShowInQuestionnaireArchive.
Procedure InvertFlagIncludeToQuestionnaireArchive() Export

	Query = New Query;
	Query.Text = "SELECT
	|	PollPurpose.Ref,
	|	PollPurpose.ShowInQuestionnaireArchive
	|FROM
	|	Document.PollPurpose AS PollPurpose
	|WHERE
	|	PollPurpose.Posted";
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = Result.Select();
	While Selection.Next() Do
	
		DocumentObject = Selection.Ref.GetObject();
		DocumentObject.ShowInQuestionnaireArchive = NOT Selection.ShowInQuestionnaireArchive;
		InfobaseUpdate.WriteData(DocumentObject);
	
	EndDo;

EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Filling in the questionnaire tree

// Updates preview of a tabular question.
Procedure UpdateTabularQuestionPreview(Questions,Answers,TabularQuestionType,Form,TableNamePreview,varKey) Export
	
	NameOfColumnWithoutNumber = "PreviewTableColumn_" + StrReplace(String(varKey),"-","_") + "_";
	TypesDetailsString = New TypeDescription("String",,New StringQualifiers(70));
	
	ResultingTableServer = Form.FormAttributeToValue(TableNamePreview);
	ResultingTableServer.Columns.Clear();
	
	AttributesToDelete = New Array;
	FormItemsToDelete = New Array;
	ArrayOfCurrentResultingTableColumns = Form.GetAttributes(TableNamePreview);
	For each ArrayElement In ArrayOfCurrentResultingTableColumns Do
		AttributesToDelete.Add(ArrayElement.Path + "." + ArrayElement.Name);
		FormItemsToDelete.Add(ArrayElement.Name);
	EndDo;
	
	For each ArrayElement In FormItemsToDelete Do
		FoundFormItem = Form.Items.Find(ArrayElement);
		If FoundFormItem <> Undefined  Then
			Form.Items.Delete(FoundFormItem);
		EndIf;
	EndDo;
	
	AttributesToAdd = New Array;
	ColumnsCounter = 0;
	
	QuestionsArray = Questions.UnloadColumn("ElementaryQuestion");
	
	If Questions.Columns.Find("LineNumber") = Undefined Then
		Questions.Columns.Add("LineNumber",New TypeDescription("Number"));
	EndIf;
	
	For ind = 0 To Questions.Count()- 1 Do
		Questions[ind].LineNumber = ind;
	EndDo;
	
	Query = New Query;
	Query.Text = "SELECT
	|	Questions.ElementaryQuestion AS Question,
	|	Questions.LineNumber
	|INTO Questions
	|FROM
	|	&Questions AS Questions
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	QuestionsForSurvey.Wording,
	|	QuestionsForSurvey.ValueType
	|FROM
	|	Questions AS Questions
	|		INNER JOIN ChartOfCharacteristicTypes.QuestionsForSurvey AS QuestionsForSurvey
	|		ON Questions.Question = QuestionsForSurvey.Ref
	|WHERE
	|	QuestionsForSurvey.Ref IN(&Questions)
	|
	|ORDER BY
	|	Questions.LineNumber";
	
	Query.SetParameter("Questions",Questions);

	Result = Query.Execute();
	If  Result.IsEmpty() Then
		Return;
	EndIf;
	
	If TabularQuestionType = Enums.TabularQuestionTypes.Composite Then 
		
		SelectionQuestions = Result.Select();
		While SelectionQuestions.Next() Do
			
			ColumnsCounter = ColumnsCounter + 1;
			ResultingTableServer.Columns.Add(NameOfColumnWithoutNumber + String(ColumnsCounter),SelectionQuestions.ValueType,SelectionQuestions.Wording);
			AttributesToAdd.Add(New FormAttribute(NameOfColumnWithoutNumber + String(ColumnsCounter),SelectionQuestions.ValueType,TableNamePreview));
			
		EndDo;	
		
	ElsIf TabularQuestionType = Enums.TabularQuestionTypes.PredefinedAnswersInRows Then
		
		SelectionQuestions = Result.Select();
		While SelectionQuestions.Next() Do
			
			ColumnsCounter = ColumnsCounter + 1;
			ResultingTableServer.Columns.Add(NameOfColumnWithoutNumber + String(ColumnsCounter),SelectionQuestions.ValueType,SelectionQuestions.Wording);
			AttributesToAdd.Add(New FormAttribute(NameOfColumnWithoutNumber + String(ColumnsCounter),SelectionQuestions.ValueType,TableNamePreview));
			
		EndDo;
		
		For ind = 1 To Answers.Count() Do
			
			NewRow    = ResultingTableServer.Add();
			NewRow[0] = Answers[ind - 1].Response;
			
		EndDo;
		
	ElsIf TabularQuestionType = Enums.TabularQuestionTypes.PredefinedAnswersInColumns Then
		
		SelectionQuestions = Result.Select();
		If SelectionQuestions.Next() Then
			
			ColumnsCounter = ColumnsCounter + 1;
			ResultingTableServer.Columns.Add(NameOfColumnWithoutNumber + "1",TypesDetailsString,SelectionQuestions.Wording);
			AttributesToAdd.Add(New FormAttribute(NameOfColumnWithoutNumber + "1",TypesDetailsString,TableNamePreview));
			
		EndIf;
		
		For ind = 1 To Answers.Count() Do
			
			ResultingTableServer.Columns.Add(NameOfColumnWithoutNumber + String(ind + 1),TypesDetailsString,Answers[ind-1].Response);
			AttributesToAdd.Add(New FormAttribute(NameOfColumnWithoutNumber + String(ind + 1),TypesDetailsString,TableNamePreview));
			
		EndDo;
		
		While SelectionQuestions.Next() Do
			
			NewRow    = ResultingTableServer.Add();
			NewRow[0] = SelectionQuestions.Wording;
			
		EndDo;
		
	ElsIf TabularQuestionType = Enums.TabularQuestionTypes.PredefinedAnswersInRowsAndColumns Then
		
		QuestionsTable = Result.Unload();
		
		ResultingTableServer.Columns.Add(NameOfColumnWithoutNumber + "1",QuestionsTable[0].ValueType,QuestionsTable[0].Wording);
		AttributesToAdd.Add(New FormAttribute(NameOfColumnWithoutNumber + "1",QuestionsTable[0].ValueType,TableNamePreview));
		
		AnswersInColumns = Answers.FindRows(New Structure("ElementaryQuestion",QuestionsArray[1]));
		For ind = 1 To AnswersInColumns.Count() Do
			
			ResultingTableServer.Columns.Add(NameOfColumnWithoutNumber + String(ind + 1),QuestionsTable[2].ValueType,AnswersInColumns[ind-1].Response);
			AttributesToAdd.Add(New FormAttribute(NameOfColumnWithoutNumber + String(ind + 1),QuestionsTable[2].ValueType,TableNamePreview));
			
		EndDo;
		
		AnswersInRows = Answers.FindRows(New Structure("ElementaryQuestion",QuestionsArray[0]));
		For ind = 1 To AnswersInRows.Count() Do
			
			NewRow    = ResultingTableServer.Add();
			NewRow[0] = AnswersInRows[ind - 1].Response;
			
		EndDo;
		
	EndIf;
	
	Form.ChangeAttributes(AttributesToAdd,AttributesToDelete);
	Form.ValueToFormAttribute(ResultingTableServer,TableNamePreview);
	
	For ind = 1 To AttributesToAdd.Count() Do
		
		Item = Form.Items.Add(NameOfColumnWithoutNumber + String(ind),Type("FormField"), Form.Items[TableNamePreview]);
		If AttributesToAdd[ind-1].ValueType = New TypeDescription("Boolean") Then
			Item.Type = FormFieldType.CheckBoxField;
		Else
			Item.Type = FormFieldType.InputField;
		EndIf;
		
		Item.DataPath = TableNamePreview + "." + NameOfColumnWithoutNumber + String(ind);
		If (TabularQuestionType = Enums.TabularQuestionTypes.Composite 
			OR TabularQuestionType = Enums.TabularQuestionTypes.PredefinedAnswersInRows) OR (ind > 1) Then
			Item.Title 	= ResultingTableServer.Columns[ind -1].Title;
		Else
			Item.TitleLocation = FormItemTitleLocation.None;
		EndIf;
		
	EndDo;
	
EndProcedure

// The procedure sets a root item to the questionnaire template tree.
// Called upon creating forms, in which the questionnaire template is reflected.
Procedure SetQuestionnaireTreeRootItem(QuestionnaireTree) Export
	
	TreeItems = QuestionnaireTree.GetItems();
	NewRow    = TreeItems.Add();
	
	NewRow.Wording = NStr("ru = 'Анкета'; en = 'Questionnaire'; pl = 'Questionnaire';de = 'Questionnaire';ro = 'Questionnaire';tr = 'Questionnaire'; es_ES = 'Questionnaire'");
	NewRow.RowType    = "Root";
	NewRow.PictureCode  = QuestioningClientServer.GetQuestionnaireTemplatePictureCode(False);
	
EndProcedure

// Sets introduction and conclusion items for sections tree.
//
// Parameters:
//  QuestionnaireTree  - TreeFormData a tree, to which an introduction or conclusion item is added.
//  Formulation  - String - a type of a tree item: introduction or conclusion.
//
Procedure SetQuestionnaireSectionsTreeItemIntroductionConclusion(QuestionnaireTree,Wording) Export
	
	TreeItems = QuestionnaireTree.GetItems();
	NewRow    = TreeItems.Add();
	
	NewRow.Wording = Wording;
	NewRow.RowType    = Wording;
	NewRow.PictureCode  = QuestioningClientServer.GetQuestionnaireTemplatePictureCode(False);
	
EndProcedure

// Fills in the questionnaire template tree.
//
// Parameters:
//  Form                   - ManagedForm - a form, for which the tree is filled in.
//  QuestionnaireTreeName         - String - a name of the form attribute, which will contain the questionnaire tree.
//  QuestionnaireTemplate            - CatalogRef.QuestionnaireTemplates - a reference to a 
//                                                            questionnaire template, according to which the tree will be filled in.
//  FillPreviewPages - Boolean - a flag indicating whether to generate preview tables of tabular questions.
//
Procedure FillQuestionnaireTemplateTree(Form, QuestionnaireTreeName, QuestionnaireTemplate) Export
	
	If QuestionnaireTemplate = Catalogs.QuestionnaireTemplates.EmptyRef() Then
		Return;
	EndIf;
	
	Result = ExecuteQueryByQuestionnaireTemplateQuestions(QuestionnaireTemplate);
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	QuestionnaireTreeServer = Form.FormAttributeToValue(QuestionnaireTreeName);
	
	Selection = Result.Select(QueryResultIteration.ByGroupsWithHierarchy);
	
	If Selection.Count() > 0 Then
		AddQuestionnaireTreeRows(Selection,QuestionnaireTreeServer.Rows[0],1,Form);
	EndIf;
	
	Form.ValueToFormAttribute(QuestionnaireTreeServer,QuestionnaireTreeName);
	
EndProcedure

// Called recursively and adds rows to the questionnaire tree.
//
// Parameters:
//  Selection        - Selection from query - the current query result selection.
//  ParentRow - Value tree row - a parent row of the value tree.
//
Procedure AddQuestionnaireTreeRows(Selection,ParentRow,RecursionLevel,Form)
	
	While Selection.Next() Do
		
		If Not ValueIsFilled(Selection.ParentQuestion) Then
			NewRow = ParentRow.Rows.Add();
		Else
			ParentRowOfSubordinateQuestion = ParentRow.Rows.Find(Selection.ParentQuestion,"TemplateQuestion");
			If ParentRowOfSubordinateQuestion <> Undefined Then
				NewRow = ParentRowOfSubordinateQuestion.Rows.Add();
			EndIf;
		EndIf;
		
		NewRow.TemplateQuestion              = Selection.TemplateQuestion;
		NewRow.PictureCode                = QuestioningClientServer.GetQuestionnaireTemplatePictureCode(Selection.IsSection,Selection.QuestionsType);
		NewRow.QuestionsType                 = Selection.QuestionsType;
		NewRow.TabularQuestionType       = Selection.TabularQuestionType;
		NewRow.ToolTip                  = Selection.ToolTip;
		NewRow.HintPlacement = Selection.HintPlacement;
		
		NewRow.RowType            = ?(Selection.IsSection,"Section","Question");
		If Form.FormName = "Catalog.QuestionnaireTemplates.Form.ItemForm" Then
			NewRow.ElementaryQuestion = ?(Selection.IsSection,Selection.Description,?(Selection.QuestionsType <> Enums.QuestionnaireTemplateQuestionTypes.Tabular,Selection.ElementaryQuestion,Selection.Wording));
			NewRow.Required       = ?(Selection.IsSection,Undefined,?(Selection.QuestionsType <> Enums.QuestionnaireTemplateQuestionTypes.Tabular,Selection.Required,Undefined)); 
			NewRow.Wording       = ?(Selection.IsSection,Selection.Description,Selection.Wording);
			NewRow.Notes            = Selection.Notes;
			NewRow.HasNotes        = Not IsBlankString(Selection.Notes);
		Else 
			NewRow.Wording       = Selection.Wording;
			NewRow.ElementaryQuestion = Selection.ElementaryQuestion;
			NewRow.Required       = Selection.Required;
		EndIf; 
		
		NewRow.Description                      = Selection.Description;
		NewRow.ReplyType                         = Selection.ReplyType;
		NewRow.TabularQuestionComposition           = Selection.TabularQuestionComposition.Unload();
		NewRow.TabularQuestionComposition.Sort("LineNumber Asc");
		NewRow.PredefinedAnswers            = Selection.PredefinedAnswers.Unload();
		NewRow.PredefinedAnswers.Sort("LineNumber Asc");
		NewRow.ComplexQuestionComposition         = Selection.ComplexQuestionComposition.Unload();
		NewRow.TabularQuestionComposition.Sort("LineNumber Asc");
		NewRow.RowKey                        = New UUID;
		NewRow.Length                             = Selection.Length;
		NewRow.MinValue               = Selection.MinValue;
		NewRow.MaxValue              = Selection.MaxValue;
		NewRow.CommentRequired              = Selection.CommentRequired;
		NewRow.CommentNote              = Selection.CommentNote;
		NewRow.ValueType                       = ?(Selection.ValueType = NULL,Undefined,Selection.ValueType);
		NewRow.Accuracy                          = Selection.Accuracy;
		
		SubordinateSelection = Selection.Select(QueryResultIteration.ByGroupsWithHierarchy);
		If SubordinateSelection.Count() > 0 Then
			AddQuestionnaireTreeRows(SubordinateSelection,NewRow,RecursionLevel + 1,Form);
		EndIf;
		
	EndDo;
	
EndProcedure

// Executes a query by a questionnaire template to generate a questionnaire tree in forms.
//
// Parameters:
//   QuestionnaireTemplate - CatalogRef.QuestionnaireTemplates - a reference to a questionnaire template, according to which the query will be executed.
//
// Returns
//   QueryResult - a result of query by a questionnaire template.
//
Function ExecuteQueryByQuestionnaireTemplateQuestions(QuestionnaireTemplate)
	
	Query = New Query;
	Query.Text = "SELECT
	|	QuestionnaireTemplateQuestions.Ref AS TemplateQuestion,
	|	QuestionnaireTemplateQuestions.Parent AS Parent,
	|	QuestionnaireTemplateQuestions.Description AS Description,
	|	QuestionnaireTemplateQuestions.Required AS Required,
	|	QuestionnaireTemplateQuestions.QuestionsType AS QuestionsType,
	|	QuestionnaireTemplateQuestions.TabularQuestionType AS TabularQuestionType,
	|	QuestionnaireTemplateQuestions.ElementaryQuestion AS ElementaryQuestion,
	|	QuestionnaireTemplateQuestions.IsFolder AS IsSection,
	|	QuestionnaireTemplateQuestions.ParentQuestion AS ParentQuestion,
	|	QuestionnaireTemplateQuestions.ToolTip AS ToolTip,
	|	QuestionnaireTemplateQuestions.HintPlacement AS HintPlacement,
	|	QuestionnaireTemplateQuestions.TabularQuestionComposition.(
	|		LineNumber AS LineNumber,
	|		ElementaryQuestion
	|	),
	|	QuestionnaireTemplateQuestions.PredefinedAnswers.(
	|		LineNumber AS LineNumber,
	|		ElementaryQuestion,
	|		Response
	|	),
	|	QuestionnaireTemplateQuestions.ComplexQuestionComposition.(
	|		LineNumber AS LineNumber,
	|		ElementaryQuestion
	|	),
	|	ISNULL(QuestionsForSurvey.Length, 0) AS Length,
	|	QuestionsForSurvey.ValueType AS ValueType,
	|	ISNULL(QuestionsForSurvey.CommentRequired, FALSE) AS CommentRequired,
	|	ISNULL(QuestionsForSurvey.CommentNote, """") AS CommentNote,
	|	ISNULL(QuestionsForSurvey.MinValue, 0) AS MinValue,
	|	ISNULL(QuestionsForSurvey.MaxValue, 0) AS MaxValue,
	|	ISNULL(QuestionsForSurvey.ReplyType, VALUE(Enum.QuestionAnswerTypes.EmptyRef)) AS ReplyType,
	|	ISNULL(QuestionnaireTemplateQuestions.Wording, """") AS Wording,
	|	ISNULL(QuestionsForSurvey.Accuracy, 0) AS Accuracy,
	|	QuestionnaireTemplateQuestions.Notes
	|FROM
	|	Catalog.QuestionnaireTemplateQuestions AS QuestionnaireTemplateQuestions
	|		LEFT JOIN ChartOfCharacteristicTypes.QuestionsForSurvey AS QuestionsForSurvey
	|		ON QuestionnaireTemplateQuestions.ElementaryQuestion = QuestionsForSurvey.Ref
	|WHERE
	|	(NOT QuestionnaireTemplateQuestions.DeletionMark)
	|	AND QuestionnaireTemplateQuestions.Owner = &Owner
	|
	|ORDER BY
	|	QuestionnaireTemplateQuestions.Ref HIERARCHY";
	
	Query.SetParameter("Owner",QuestionnaireTemplate);
	
	Return Query.Execute();
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Generating a questionnaire filling form.

// Creates a form according to the questionnaire template section.
//
// Parameters:
//  Form                       - ManagedForm - a form, for which information is obtained.
//  CurrentDataSectionsTree - FormDataTreeItem - the current section, for which the filling form is created.
//
Procedure CreateFillingFormBySection(Form,CurrentDataSectionsTree) Export
	
	AttributesToAdd = New Array;
	Form.SectionQuestionsTable.Clear();
	
	If CurrentDataSectionsTree.RowType = "Section" Then
		
		Form.Items.IntroductionLabel.Title  = NStr("ru = 'Раздел'; en = 'Section'; pl = 'Section';de = 'Section';ro = 'Section';tr = 'Section'; es_ES = 'Section'") + " " + CurrentDataSectionsTree.Wording;
		If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
			Form.Items.IntroductionLabel.TextColor = WebColors.Peru;
			Form.Items.IntroductionLabel.Font = New Font(, 8, True, , , );
		Else
			Form.Items.IntroductionLabel.TextColor = New Color(0, 150, 70);
			Form.Items.IntroductionLabel.Font = New Font(, 12, False, , , );
		EndIf;
		
		Section = CurrentDataSectionsTree.Ref;
		FullSectionCode = CurrentDataSectionsTree.FullCode;
		
		// getting section questions
		Form.SectionQuestionsTable.Clear();
		GetInformationOnQuestionnaireQuestions(Form,Form.QuestionnaireTemplate,Section,FullSectionCode);
		GenerateAttributesToAddForSection(AttributesToAdd,Form);
		
	Else
		
		Introduction = ?(IsBlankString(Form.Introduction), NStr("ru = 'Нажмите далее для заполнения анкеты.'; en = 'Click Next to fill in the questionnaire.'; pl = 'Click Next to fill in the questionnaire.';de = 'Click Next to fill in the questionnaire.';ro = 'Click Next to fill in the questionnaire.';tr = 'Click Next to fill in the questionnaire.'; es_ES = 'Click Next to fill in the questionnaire.'"), Form.Introduction);
		Conclusion = ?(IsBlankString(Form.Conclusion), NStr("ru = 'Спасибо за то что заполнили анкету.'; en = 'Thank you for filling out the questionnaire.'; pl = 'Thank you for filling out the questionnaire.';de = 'Thank you for filling out the questionnaire.';ro = 'Thank you for filling out the questionnaire.';tr = 'Thank you for filling out the questionnaire.'; es_ES = 'Thank you for filling out the questionnaire.'"), Form.Conclusion);
		
		Form.Items.IntroductionLabel.Title = ?(CurrentDataSectionsTree.RowType = "Introduction", Introduction, Conclusion);
		Form.Items.IntroductionLabel.TextColor = StyleColors.FieldTextColor;
		Form.Items.IntroductionLabel.Font = New Font(, 8, False, , , );
		
	EndIf;
	
	Form.ChangeAttributes(AttributesToAdd,Form.DynamicallyAddedAttributes.UnloadValues());
	
	// Deleting form items dynamically generated previously.
	DeleteFillingFormItems(Form,Form.DynamicallyAddedAttributes);
	Form.DynamicallyAddedAttributes.Clear();
	For each AddedAttribute In AttributesToAdd Do
		If IsBlankString(AddedAttribute.Path) Then
			Form.DynamicallyAddedAttributes.Add(AddedAttribute.Name);
		EndIf;
	EndDo;
	
	If CurrentDataSectionsTree.RowType = "Section" Then
		// adding form items
		GenerateFormItemsForSection(Form);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Creating attributes of the questionnaire filling form.

// Generates an array of attributes to be added.
//
// Parameters:
//  AttributesToAdd - Array - used to accumulate form attributes to be created.
//  Form                - Managed form - a form, for which an array of attributes is generated.
//
Procedure GenerateAttributesToAddForSection(AttributesToAdd,Form) 
	
	For each Row In Form.SectionQuestionsTable Do
		
		AddAttributesForQuestion(Row,AttributesToAdd,Form);
		
	EndDo;
	
EndProcedure

// Adds form attributes for simple questions.
//
// Parameters:
//  TreeRow         - ValueTreeRow - a row of the questionnaire template tree.
//  AttributesToAdd - Array - used to accumulate form attributes to be added.
//
Procedure AddAttributesForQuestion(TreeRow,AttributesToAdd,Form)
	
	QuestionName = QuestioningClientServer.GetQuestionName(TreeRow.RowKey);
	
	RowTypeDetails = New TypeDescription("String");
	AttributesToAdd.Add(New FormAttribute(QuestionName + "_Wording",RowTypeDetails));
	
	If TreeRow.QuestionsType = Enums.QuestionnaireTemplateQuestionTypes.Tabular Then
		
		AddAttributesTabularQuestion(TreeRow,AttributesToAdd,Form);
				
	ElsIf TreeRow.QuestionsType = Enums.QuestionnaireTemplateQuestionTypes.Complex Then
		
		AddAttributesComplexQuestion(TreeRow, AttributesToAdd, Form);
		
	Else
		
		If TreeRow.ReplyType = Enums.QuestionAnswerTypes.String Then
			
			RowTypeDetails = New TypeDescription("String",,New StringQualifiers(TreeRow.Length));
			AttributesToAdd.Add(New FormAttribute(QuestionName,RowTypeDetails,,TreeRow.Wording));
			
		ElsIf TreeRow.ReplyType = Enums.QuestionAnswerTypes.Text Then
			
			RowTypeDetails = New TypeDescription("String",,New StringQualifiers(TreeRow.Length));
			AttributesToAdd.Add(New FormAttribute(QuestionName,RowTypeDetails,,TreeRow.Wording));
		
		ElsIf TreeRow.ReplyType = Enums.QuestionAnswerTypes.Boolean Then
			
			BooleanTypeDetails = New TypeDescription("Boolean");
			AttributesToAdd.Add(New FormAttribute(QuestionName,BooleanTypeDetails,,TreeRow.Wording));
			
		ElsIf TreeRow.ReplyType = Enums.QuestionAnswerTypes.Date Then
			
			DateTypeDetails = New TypeDescription("Date",New DateQualifiers(DateFractions.Date));
			AttributesToAdd.Add(New FormAttribute(QuestionName,DateTypeDetails,,TreeRow.Wording));
			
		ElsIf TreeRow.ReplyType = Enums.QuestionAnswerTypes.Number Then
			
			TypeDescriptionNumber = New TypeDescription("Number",,,New NumberQualifiers(TreeRow.Length,TreeRow.Accuracy));
			AttributesToAdd.Add(New FormAttribute(QuestionName,TypeDescriptionNumber,,TreeRow.Wording));
			
		ElsIf TreeRow.ReplyType = Enums.QuestionAnswerTypes.InfobaseValue Then
			
			AttributesToAdd.Add(New FormAttribute(QuestionName,TreeRow.ValueType,,TreeRow.Wording));
			
		ElsIf TreeRow.ReplyType = Enums.QuestionAnswerTypes.OneVariantOf Then
			
			AttributesToAdd.Add(New FormAttribute(QuestionName,TreeRow.ValueType,,TreeRow.Wording));
			
		ElsIf TreeRow.ReplyType = Enums.QuestionAnswerTypes.MultipleOptionsFor Then
			
			OptionsOfAnswersToQuestion = GetOptionsOfAnswersToQuestion(TreeRow.ElementaryQuestion,Form);
			
			RowTypeDetails = New TypeDescription("String",,New StringQualifiers(150));
			BooleanTypeDetails = New TypeDescription("Boolean");
			
			Counter = 0;
			
			For each AnswerOption In OptionsOfAnswersToQuestion Do
				Counter = Counter + 1;
				AttributesToAdd.Add(New FormAttribute(QuestionName + "_Attribute_" + Counter,BooleanTypeDetails,,AnswerOption.Presentation));
				If AnswerOption.OpenEndedQuestion Then
					AttributesToAdd.Add(New FormAttribute(QuestionName + "_Comment_" + Counter,RowTypeDetails));
				EndIf;
			EndDo;
			
		EndIf;
		
		If (TreeRow.ReplyType <> Enums.QuestionAnswerTypes.MultipleOptionsFor) AND (TreeRow.CommentRequired) Then
			
			RowTypeDetails = New TypeDescription("String",,New StringQualifiers(150));
			AttributesToAdd.Add(New FormAttribute(QuestionName + "_Comment",RowTypeDetails,,TreeRow.CommentNote));
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Adds form attributes for tabular questions.
//
// Parameters:
//  TreeRow         - ValueTreeRow - a row of the questionnaire template tree.
//  AttributesToAdd - Array - used to accumulate form attributes to be added.
//
Procedure AddAttributesTabularQuestion(TreeRow,AttributesToAdd,Form)
	
	TabularQuestionType = TreeRow.TabularQuestionType;
	QuestionName           = QuestioningClientServer.GetQuestionName(TreeRow.RowKey);
	TableName           = QuestionName + "_Table";
	NameOfColumnWithoutNumber  = TableName + "_Column_";
	CCTTypesDetails     = Metadata.ChartsOfCharacteristicTypes.QuestionsForSurvey.Type;
	
	AttributeTable = New FormAttribute(TableName ,New TypeDescription("ValueTable"),,TreeRow.Wording);
	AttributesToAdd.Add(AttributeTable);
	
	If TabularQuestionType = Enums.TabularQuestionTypes.Composite
		OR TabularQuestionType = Enums.TabularQuestionTypes.PredefinedAnswersInRows Then
		
		For ind = 1 To TreeRow.TabularQuestionComposition.Count() Do
			
			FoundRows = Form.QuestionsPresentationTypes.FindRows(New Structure("Question",TreeRow.TabularQuestionComposition[ind-1].ElementaryQuestion));
			If FoundRows.Count() > 0 Then
				QuestionTypePresentation = FoundRows[0];
			Else
				Continue;
			EndIf;
			
			AttributesToAdd.Add(New FormAttribute(NameOfColumnWithoutNumber + String(ind),QuestionTypePresentation.Type,TableName,QuestionTypePresentation.Wording));
		
		EndDo;
		
	ElsIf TabularQuestionType = Enums.TabularQuestionTypes.PredefinedAnswersInColumns Then
		
		// Question, the answers to which will be displayed in columns.
		QuestionForColumns = TreeRow.TabularQuestionComposition[0].ElementaryQuestion;
		// Adding the first column to the table.
		AttributesToAdd.Add(New FormAttribute(NameOfColumnWithoutNumber + "1",New TypeDescription("ChartOfCharacteristicTypesRef.QuestionsForSurvey"),TableName));
		
		// Adding other columns
		AnswersArray = TreeRow.PredefinedAnswers.FindRows(New Structure("ElementaryQuestion",QuestionForColumns));
		For ind=1 To AnswersArray.Count() Do
			AttributesToAdd.Add(New FormAttribute(NameOfColumnWithoutNumber + String(ind+1),CCTTypesDetails,TableName,AnswersArray[ind-1].Response));
		EndDo;
		
	ElsIf TabularQuestionType = Enums.TabularQuestionTypes.PredefinedAnswersInRowsAndColumns Then
		
		// Question, the answers to which will be displayed in columns.
		QuestionForColumns = TreeRow.TabularQuestionComposition[1].ElementaryQuestion;
		
		// Question that defines the type of cells.
		QuestionForCells  = TreeRow.TabularQuestionComposition[2].ElementaryQuestion;
		FoundRows = Form.QuestionsPresentationTypes.FindRows(New Structure("Question",QuestionForCells));
		If FoundRows.Count() > 0 Then
			QuestionTypePresentationForCells = FoundRows[0];
		Else
			Return;
		EndIf;
		
		// Question, the answers to which will be displayed in rows of the first column.
		QuestionForRows  = TreeRow.TabularQuestionComposition[0].ElementaryQuestion;
		FoundRows = Form.QuestionsPresentationTypes.FindRows(New Structure("Question",QuestionForRows));
		If FoundRows.Count() > 0 Then
			QuestionTypePresentationForRows = FoundRows[0];
		Else
			Return;
		EndIf;
		// Adding the first column to the table.
		AttributesToAdd.Add(New FormAttribute(NameOfColumnWithoutNumber + "1",QuestionTypePresentationForRows.Type,TableName,QuestionTypePresentationForRows.Wording));
		
		// Adding other columns
		AnswersArray = TreeRow.PredefinedAnswers.FindRows(New Structure("ElementaryQuestion",QuestionForColumns));
		For ind=1 To AnswersArray.Count() Do
			AttributesToAdd.Add(New FormAttribute(NameOfColumnWithoutNumber + String(ind+1),QuestionTypePresentationForCells.Type,TableName,AnswersArray[ind-1].Response));
		EndDo;
		
	EndIf;
	
EndProcedure

// Adds form attributes for complex questions.
//
// Parameters:
//  TreeRow         - ValueTreeRow - a row of the questionnaire template tree.
//  AttributesToAdd - Array - used to accumulate form attributes to be added.
//
Procedure AddAttributesComplexQuestion(TreeRow,AttributesToAdd,Form)
	
	QuestionName = QuestioningClientServer.GetQuestionName(TreeRow.RowKey);
	For each ComplexQuestionRow In TreeRow.ComplexQuestionComposition Do
		
		FoundRows = Form.QuestionsPresentationTypes.FindRows(New Structure("Question",ComplexQuestionRow.ElementaryQuestion));
		If FoundRows.Count() > 0 Then
			QuestionTypePresentation = FoundRows[0];
		Else
			Continue;
		EndIf;
		
		If QuestionTypePresentation.ReplyType = Enums.QuestionAnswerTypes.MultipleOptionsFor Then
			
			OptionsOfAnswersToQuestion = GetOptionsOfAnswersToQuestion(ComplexQuestionRow.ElementaryQuestion,Form);
			
			RowTypeDetails = New TypeDescription("String",,New StringQualifiers(150));
			BooleanTypeDetails = New TypeDescription("Boolean");
			
			Counter = 0;
			
			For each AnswerOption In OptionsOfAnswersToQuestion Do
				Counter = Counter + 1;
				AttributesToAdd.Add(New FormAttribute(QuestionName + "_Response_" 
					+ Format(ComplexQuestionRow.LineNumber, "NG=") + "_Attribute_" + Counter,BooleanTypeDetails,,AnswerOption.Presentation));
				If AnswerOption.OpenEndedQuestion Then
					AttributesToAdd.Add(New FormAttribute(QuestionName + "_Response_" 
						+ Format(ComplexQuestionRow.LineNumber, "NG=") + "_Comment_" + Counter,RowTypeDetails));
				EndIf;
			EndDo;
			
		Else
			
			AttributesToAdd.Add(New FormAttribute(QuestionName + "_Response_" 
				+ Format(ComplexQuestionRow.LineNumber, "NG="),QuestionTypePresentation.Type,,QuestionTypePresentation.Wording));
			
		EndIf;
		
		If (QuestionTypePresentation.ReplyType <> Enums.QuestionAnswerTypes.MultipleOptionsFor) AND (ComplexQuestionRow.CommentRequired) Then
			
			RowTypeDetails = New TypeDescription("String",,New StringQualifiers(150));
			AttributesToAdd.Add(New FormAttribute(QuestionName + "_Comment_" 
				+ Format(ComplexQuestionRow.LineNumber, "NG="),RowTypeDetails,,ComplexQuestionRow.CommentNote));
			
		EndIf;
		
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Creating questionnaire filling form items.

// Generates questionnaire filling form items for the selected section.
Procedure GenerateFormItemsForSection(Form) 

	For each TableRow In Form.SectionQuestionsTable Do
	
		AddFormItemsByTableRow(TableRow,Form.Items.QuestionnaireBodyGroup,Form);
	
	EndDo;
	
	PositionOnFirstSectionQuestion(Form);
	
EndProcedure

// Sets focus on the first question of the section that opens.
//
// Parameters:
//  Form - ManagedForm - a form, for which the action is performed.
//
Procedure PositionOnFirstSectionQuestion(Form)
	
	If Form.SectionQuestionsTable.Count() > 0 Then
		
		QuestionName = QuestioningClientServer.GetQuestionName(Form.SectionQuestionsTable[0].RowKey);
		
		FoundItem = Form.Items.Find(QuestionName);
		If FoundItem = Undefined Then
			FoundItem = Form.Items.Find(QuestionName + "_Attribute_1");
		EndIf;
		
		If FoundItem = Undefined Then
			FoundItem = Form.Items.Find(QuestionName + "_Table");
		EndIf;
		
		If FoundItem <> Undefined Then
			Form.CurrentItem = FoundItem;
			FoundItem.DefaultItem = True;
			Form.PositioningItemName = FoundItem.Name;
		EndIf;
		
	EndIf;
	
EndProcedure

// Analyzes the type of a questionnaire tree row and calls the function to add form items.
//
// Parameters:
//  TreeRow    - ValueTreeRow - a row of the questionnaire template tree.
//  GroupItem   - FormGroup - a form group, for which attributes being added are subordinated.
//  RecursionLevel -Number - a procedure call recursion level.
//  Form           - Managed form - a form, for which items are added.
//
// Returns:
//   FormGroup   - a group of created items.
//
Function AddFormItemsByTableRow(TableRow,GroupItem,Form)

	If TableRow.RowType = "Section" Then
		Return AddItemsSection(TableRow,GroupItem,Form);
	ElsIf TableRow.RowType = "Question" Then
		AddQuestionItems(TableRow,GroupItem,Form);
	EndIf;

EndFunction

// Adds form items for sections.
//
// Parameters:
//  TreeRow    - ValueTreeRow - a row of the questionnaire template tree.
//  GroupItem   - FormGroup - a form group, for which attributes being added are subordinated.
//  RecursionLevel - Number - a procedure call recursion level.
//  Form           - Managed form - a form, for which items are added.
//
// Returns:
//   FormGroup   - a group of created items.
//
Function AddItemsSection(TableRow,GroupItem,Form)
	
	SectionName = "Section_" + StrReplace(TableRow.RowKey,"-","_");
	
	SectionItem = Form.Items.Add(SectionName,Type("FormGroup"),GroupItem);
	SectionItem.Type           = FormGroupType.UsualGroup;
	SectionItem.Title     = FullCodeDescription(TableRow);
	SectionItem.Group   = ChildFormItemsGroup.Vertical;
	SectionItem.VerticalStretch = False;
	
	Return SectionItem;
	
EndFunction

// Adds form items for questions.
//
// Parameters:
//  TableRow - CollectionItemFormData - a row of the section questions table.
//  GroupItem - FormGroup - a form group, for which attributes being added are subordinated.
//  Form         - Managed form- - a form, for which items are added.
//
Procedure AddQuestionItems(TableRow,GroupItem,Form)
	
	QuestionName = QuestioningClientServer.GetQuestionName(TableRow.RowKey);
	
	// Setting group item for the question.
	QuestionGroupItem = Form.Items.Add(QuestionName + "_Group" ,Type("FormGroup"),GroupItem);
	QuestionGroupItem.Type                        = FormGroupType.UsualGroup;
	QuestionGroupItem.ShowTitle        = False;
	QuestionGroupItem.Representation                = UsualGroupRepresentation.None;
	QuestionGroupItem.Group                = ChildFormItemsGroup.Vertical;
	QuestionGroupItem.HorizontalStretch   = True;
	QuestionGroupItem.VerticalStretch     = False;
	
	If TableRow.ReplyType = Enums.QuestionAnswerTypes.Boolean Then
		QuestionGroupItemBoolean = Form.Items.Add(QuestionName + "_Group_Boolean" ,Type("FormGroup"),QuestionGroupItem);
		QuestionGroupItemBoolean.Type                        = FormGroupType.UsualGroup;
		QuestionGroupItemBoolean.ShowTitle        = False;
		QuestionGroupItemBoolean.Representation                = UsualGroupRepresentation.None;
		QuestionGroupItemBoolean.Group                = ChildFormItemsGroup.AlwaysHorizontal;
		QuestionGroupItemBoolean.HorizontalStretch   = True;
		QuestionGroupItemBoolean.VerticalStretch     = False;
	EndIf;
	
	Form[QuestionName + "_Wording"] = FullCodeDescription(TableRow);
	
	If TableRow.ReplyType = Enums.QuestionAnswerTypes.Boolean Then
		Item = Form.Items.Add(QuestionName + "_Wording",Type("FormDecoration"),QuestionGroupItemBoolean);
	Else
		Item = Form.Items.Add(QuestionName + "_Wording",Type("FormDecoration"),QuestionGroupItem);
	EndIf;
	Item.Type                      = FormDecorationType.Label;
	Item.VerticalAlign    = ItemVerticalAlign.Top;
	Item.Title                = Form[QuestionName + "_Wording"];
	Item.AutoMaxWidth   = False;
	Item.MaxWidth       = 100;
	Item.HorizontalStretch = False;
	Item.VerticalStretch   = False;
	Item.ToolTip                = TableRow.ToolTip;
	
	If TableRow.HintPlacement = Enums.TooltipDisplayMethods.AsQuestionMark Then
		Item.ToolTipRepresentation = ToolTipRepresentation.Button;
	Else
		Item.ToolTipRepresentation = ToolTipRepresentation.ShowBottom;
	EndIf;
	
	QuestionGroupItemComment = Form.Items.Add(QuestionName + "_Group_Question_Comment",Type("FormGroup"),QuestionGroupItem);
	QuestionGroupItemComment.Type                 = FormGroupType.UsualGroup;
	QuestionGroupItemComment.Representation         = UsualGroupRepresentation.None;
	QuestionGroupItemComment.Group         = ChildFormItemsGroup.Vertical;
	QuestionGroupItemComment.ShowTitle = False;
	
	If TableRow.QuestionsType = Enums.QuestionnaireTemplateQuestionTypes.Tabular Then
		
		AddTabularQuestionItems(TableRow,QuestionGroupItem,Form);
				
	ElsIf TableRow.QuestionsType = Enums.QuestionnaireTemplateQuestionTypes.Complex Then
		
		AddComplexQuestionItems(TableRow,QuestionGroupItem,Form);
		
	Else
		
		If TableRow.ReplyType = Enums.QuestionAnswerTypes.String Then
			
			Item = Form.Items.Add(QuestionName,Type("FormField"),QuestionGroupItemComment);
			Item.Type                        = FormFieldType.InputField;
			Item.TitleLocation         = FormItemTitleLocation.None;
			Item.AutoMarkIncomplete  = TableRow.Required;
			Item.DataPath                = QuestionName;
			Item.AutoMaxWidth     = False;
			Item.HorizontalStretch   = False;
			
		ElsIf TableRow.ReplyType = Enums.QuestionAnswerTypes.Text Then
			
			Item = Form.Items.Add(QuestionName,Type("FormField"),QuestionGroupItemComment);
			Item.Type                       = FormFieldType.InputField;
			Item.TitleLocation        = FormItemTitleLocation.None;
			Item.AutoMarkIncomplete = TableRow.Required;
			Item.DataPath               = QuestionName;
			Item.VerticalStretch    = False;
			Item.AutoMaxWidth    = False;
			SetTextCellItemParameters(Item); 
			
		ElsIf TableRow.ReplyType = Enums.QuestionAnswerTypes.Boolean Then
			
			Item = Form.Items.Add(QuestionName,Type("FormField"),QuestionGroupItemBoolean);
			If TableRow.CheckBoxType = Enums.CheckBoxKindsInQuestionnaires.CheckBox Then
				Item.Type = FormFieldType.CheckBoxField;
			Else
				Item.Type = FormFieldType.InputField;
			EndIf;
			
			Item.TitleLocation = FormItemTitleLocation.None;
			Item.DataPath        = QuestionName;
			
		ElsIf TableRow.ReplyType = Enums.QuestionAnswerTypes.Date Then
			
			Item = Form.Items.Add(QuestionName,Type("FormField"),QuestionGroupItemComment);
			Item.Type                       = FormFieldType.InputField;
			Item.TitleLocation        = FormItemTitleLocation.None;
			Item.AutoMarkIncomplete = TableRow.Required;
			Item.DataPath               = QuestionName;
			Item.AutoMaxWidth    = False;
			
		ElsIf TableRow.ReplyType = Enums.QuestionAnswerTypes.Number Then
			
			Item = Form.Items.Add(QuestionName,Type("FormField"),QuestionGroupItemComment);
			Item.Type                       = FormFieldType.InputField;
			Item.TitleLocation        = FormItemTitleLocation.None;
			Item.AutoMarkIncomplete = TableRow.Required;
			Item.MinValue       = ?(TableRow.MinValue = 0,Undefined,TableRow.MinValue);
			Item.MaxValue      = ?(TableRow.MaxValue = 0,Undefined,TableRow.MaxValue);
			Item.ChoiceButton              = False;
			Item.DataPath               = QuestionName;
			Item.AutoMaxWidth    = False;
			If TableRow.MinValue <> 0 OR TableRow.MaxValue <> 0 Then
				Item.SpinButton = True;
				
				TooltipText = "";
				If TableRow.MinValue <> 0 AND TableRow.MaxValue <> 0 Then
					TooltipText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Допустим ввод значения от %1 до %2'; en = 'You can enter value from %1 to %2'; pl = 'You can enter value from %1 to %2';de = 'You can enter value from %1 to %2';ro = 'You can enter value from %1 to %2';tr = 'You can enter value from %1 to %2'; es_ES = 'You can enter value from %1 to %2'"),
						TableRow.MinValue, TableRow.MaxValue);
				ElsIf TableRow.MinValue = 0 AND TableRow.MaxValue <> 0 Then
					TooltipText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Допустим ввод значения до %1'; en = 'You can enter value to %1'; pl = 'You can enter value to %1';de = 'You can enter value to %1';ro = 'You can enter value to %1';tr = 'You can enter value to %1'; es_ES = 'You can enter value to %1'"), TableRow.MaxValue);
				Else
					TooltipText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Допустим ввод значения от %1'; en = 'You can enter value from %1'; pl = 'You can enter value from %1';de = 'You can enter value from %1';ro = 'You can enter value from %1';tr = 'You can enter value from %1'; es_ES = 'You can enter value from %1'"), TableRow.MinValue);
				EndIf;
				
				Item.ToolTip = TooltipText;
				
			EndIf;
			
		ElsIf TableRow.ReplyType = Enums.QuestionAnswerTypes.InfobaseValue Then
			
			Item = Form.Items.Add(QuestionName,Type("FormField"),QuestionGroupItemComment);
			Item.Type                        = FormFieldType.InputField;
			Item.TitleLocation         = FormItemTitleLocation.None;
			Item.AutoMarkIncomplete  = TableRow.Required;
			Item.DataPath                = QuestionName;
			Item.AutoMaxWidth     = False;
			Item.HorizontalStretch   = False;
			
		ElsIf TableRow.ReplyType = Enums.QuestionAnswerTypes.OneVariantOf Then
			
			OptionsOfAnswersToQuestion = GetOptionsOfAnswersToQuestion(TableRow.ElementaryQuestion,Form);
			
			Item = Form.Items.Add(QuestionName,Type("FormField"),QuestionGroupItemComment);
			Item.Type                     = FormFieldType.RadioButtonField;
			Item.TitleLocation      = FormItemTitleLocation.None;
			Item.DataPath             = QuestionName;
			Item.ColumnsCount       = 1;
			Item.ItemHeight          = 1;
			Item.HorizontalAlign = ItemHorizontalLocation.Left;
			
			If TableRow.RadioButtonType = Enums.RadioButtonTypesInQuestionnaires.Tumbler Then
				Item.RadioButtonType = RadioButtonType.Tumbler;
				Item.ColumnsCount = 0;
				Item.EqualColumnsWidth = False;
			Else
				Item.RadioButtonType = RadioButtonType.RadioButton;
				Item.ColumnsCount = 1;
			EndIf;
			
			For each AnswerOption In OptionsOfAnswersToQuestion Do
				Item.ChoiceList.Add(AnswerOption.Response,AnswerOption.Presentation);
			EndDo;
			
		ElsIf TableRow.ReplyType = Enums.QuestionAnswerTypes.MultipleOptionsFor Then
			
			OptionsOfAnswersToQuestion = GetOptionsOfAnswersToQuestion(TableRow.ElementaryQuestion,Form);
			Counter = 0;
			
			AnswersOptionsGroupItem = Form.Items.Add(QuestionName + "_Group_Options",Type("FormGroup"),QuestionGroupItemComment);
			
			AnswersOptionsGroupItem.Type                 = FormGroupType.UsualGroup;
			AnswersOptionsGroupItem.Representation         = UsualGroupRepresentation.None;
			AnswersOptionsGroupItem.Group         = ChildFormItemsGroup.Vertical;
			AnswersOptionsGroupItem.ShowTitle = False;
			
			For each AnswerOption In OptionsOfAnswersToQuestion Do
				
				Counter = Counter + 1;
				
				AnswerOptionGroupItem = Form.Items.Add(QuestionName + "_Group_ResponseOption_" + String(Counter),Type("FormGroup"),AnswersOptionsGroupItem);
				
				AnswerOptionGroupItem.Type                        = FormGroupType.UsualGroup;
				AnswerOptionGroupItem.Representation                = UsualGroupRepresentation.None;
				AnswerOptionGroupItem.Group                = ChildFormItemsGroup.AlwaysHorizontal;
				AnswerOptionGroupItem.ShowTitle        = False;
				AnswerOptionGroupItem.HorizontalStretch   = True;
				
				QuestionAttributeName = QuestionName + "_Attribute_" + Counter;
				Item = Form.Items.Add(QuestionAttributeName,Type("FormField"),AnswerOptionGroupItem);
				
				Item.Type                = FormFieldType.CheckBoxField;
				Item.TitleLocation = FormItemTitleLocation.Right;
				Item.DataPath        = QuestionAttributeName;
				Item.TitleHeight    = 1;
				
				If AnswerOption.OpenEndedQuestion Then
					CommentAttributeName = QuestionName + "_Comment_" + Counter;
					Item = Form.Items.Add(CommentAttributeName,Type("FormField"),AnswerOptionGroupItem);
					Item.Type 		= FormFieldType.CheckBoxField;
					Item.DataPath	= CommentAttributeName;
					Item.TitleLocation = FormItemTitleLocation.None;
				EndIf;
				
			EndDo;
			
		EndIf;
		
		// Comments to questions
		If (TableRow.ReplyType <> Enums.QuestionAnswerTypes.MultipleOptionsFor) AND (TableRow.CommentRequired) Then
			
			Item                        = Form.Items.Add(QuestionName + "_Comment",Type("FormField"),QuestionGroupItemComment);
			Item.Type                    = FormFieldType.InputField;
			Item.DataPath            = QuestionName + "_Comment";
			Item.AutoMaxWidth = False;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Adds form items for tabular questions.
//
// Parameters:
//  TableRow - FormDataCollectionItem - a row of the section questions table.
//  GroupItem - FormGroup - a form group, for which attributes being added are subordinated.
//  Form         - Managed form.
//
Procedure AddTabularQuestionItems(TableRow,GroupItem,Form)
	
	TabularQuestionType = TableRow.TabularQuestionType;
	QuestionName = QuestioningClientServer.GetQuestionName(TableRow.RowKey);
	TableName = QuestionName + "_Table";
	
	// Creating a table form item.
	ItemTable = Form.Items.Add(TableName,Type("FormTable"),GroupItem);
	
	If TabularQuestionType = Enums.TabularQuestionTypes.Composite Then
		ItemTable.CommandBarLocation = FormItemCommandBarLabelLocation.Top;
	Else
		ItemTable.CommandBarLocation = FormItemCommandBarLabelLocation.None;
		ItemTable.ChangeRowSet  = False;
		ItemTable.ChangeRowOrder = False;
	EndIf;
	ItemTable.TitleLocation       = FormItemTitleLocation.None;
	ItemTable.DataPath              = TableName;
	ItemTable.HorizontalStretch = True;
	ItemTable.VerticalStretch   = False;
	
	// Adding columns to the table form item.
	QuestionTable = Form.FormAttributeToValue(TableName);
	
	If TableRow.TabularQuestionType = Enums.TabularQuestionTypes.PredefinedAnswersInRowsAndColumns 
		AND TableRow.TabularQuestionComposition.Count() = 3 Then
		
		FoundRows = Form.QuestionsPresentationTypes.FindRows(New Structure("Question",TableRow.TabularQuestionComposition[2].ElementaryQuestion));
		If FoundRows.Count() > 0 Then
			ElementaryQuestionAttributes = FoundRows[0];
		Else
			Return;
		EndIf;
		
	ElsIf TableRow.TabularQuestionType = Enums.TabularQuestionTypes.PredefinedAnswersInRowsAndColumns
		AND TableRow.TabularQuestionComposition.Count() > 1 Then

	EndIf;
	
	For ind = 1 To QuestionTable.Columns.Count() Do
		
		ColumnName = TableName + "_Column_" + ind;
		
		If TableRow.TabularQuestionType <> Enums.TabularQuestionTypes.PredefinedAnswersInRowsAndColumns 
			AND TableRow.TabularQuestionType <> Enums.TabularQuestionTypes.PredefinedAnswersInColumns Then
			FoundRows = Form.QuestionsPresentationTypes.FindRows(New Structure("Question",TableRow.TabularQuestionComposition[ind-1].ElementaryQuestion));
			If FoundRows.Count() > 0 Then
				ElementaryQuestionAttributes = FoundRows[0];
			Else
				Continue;
			EndIf;
		EndIf;
		
		Item = Form.Items.Add(ColumnName, Type("FormField"), Form.Items[TableName]);
		Item.EditMode = ColumnEditMode.Directly;
		
		If QuestionTable.Columns[ColumnName].ValueType = New TypeDescription("Boolean") Then
			Item.Type = FormFieldType.CheckBoxField;
		Else
			Item.Type = FormFieldType.InputField;
			
			// Setting the selection list for those columns, whose answer type is "Questionnaire answer options" 
			// and setting restrictions for numerical questions.
			If TableRow.TabularQuestionType = Enums.TabularQuestionTypes.Composite 
				Or TableRow.TabularQuestionType = Enums.TabularQuestionTypes.PredefinedAnswersInRows Then
				
				If QuestionTable.Columns[ColumnName].ValueType = New TypeDescription("CatalogRef.QuestionnaireAnswersOptions") Then
					
					Item.ListChoiceMode = True;
					OptionsOfAnswersToQuestion = GetOptionsOfAnswersToQuestion(TableRow.TabularQuestionComposition[ind-1].ElementaryQuestion,Form);
					For each OptionOfAnswerToQuestion In OptionsOfAnswersToQuestion Do
						Item.ChoiceList.Add(OptionOfAnswerToQuestion.Response);
					EndDo;
					Item.OpenButton = False;
					
				ElsIf ElementaryQuestionAttributes.ReplyType = Enums.QuestionAnswerTypes.Number Then
					
					SetNumberCellItemParameters(Item,ElementaryQuestionAttributes);
					
				ElsIf ElementaryQuestionAttributes.ReplyType = Enums.QuestionAnswerTypes.Text Then
					
					SetTextCellItemParameters(Item);
					
				EndIf;
				
			ElsIf TableRow.TabularQuestionType = Enums.TabularQuestionTypes.PredefinedAnswersInRowsAndColumns Then	
				
				If TableRow.TabularQuestionComposition.Count() = 3 AND ind <> 1 Then
					
					If TableRow.TabularQuestionComposition[2].ElementaryQuestion.ValueType = New TypeDescription("CatalogRef.QuestionnaireAnswersOptions")Then
						
						Item.ListChoiceMode = True;
						OptionsOfAnswersToQuestion = GetOptionsOfAnswersToQuestion(TableRow.TabularQuestionComposition[2].ElementaryQuestion,Form);
						For each OptionOfAnswerToQuestion In OptionsOfAnswersToQuestion Do
							Item.ChoiceList.Add(OptionOfAnswerToQuestion.Response);
						EndDo;
						Item.OpenButton = False;
						
					EndIf;
					
					If ElementaryQuestionAttributes.ReplyType = Enums.QuestionAnswerTypes.Number Then
						
						SetNumberCellItemParameters(Item,ElementaryQuestionAttributes);
						
					ElsIf ElementaryQuestionAttributes.ReplyType = Enums.QuestionAnswerTypes.Text Then
						
						SetTextCellItemParameters(Item);
						
					EndIf;
					
				EndIf;
				
			EndIf;
		EndIf;
		
		Item.DataPath = TableName + "." + ColumnName;
		
		If (TabularQuestionType <> Enums.TabularQuestionTypes.Composite) AND (ind = 1) Then
			Item.Enabled = False;
		EndIf;
		
		If (TabularQuestionType = Enums.TabularQuestionTypes.PredefinedAnswersInColumns)Then
			If ind = 1 Then
				Item.TitleLocation = FormItemTitleLocation.None;
			Else	
				Item.TypeLink = New TypeLink("Items." + TableName + ".CurrentData." + TableName + "_Column_1");
				ChoiceParametersLinks = New Array();
				ChoiceParametersLinks.Add(New ChoiceParameterLink("Filter.Owner","Items." + TableName + ".CurrentData." + TableName + "_Column_1"));
				Item.ChoiceParameterLinks = New FixedArray(ChoiceParametersLinks);
			EndIf;
		EndIf;
		
	EndDo;
	
	// Filling in table rows.
	If TabularQuestionType = Enums.TabularQuestionTypes.PredefinedAnswersInRows Then
		
		AnswersArray = TableRow.PredefinedAnswers.FindRows(New Structure("ElementaryQuestion",TableRow.TabularQuestionComposition[0].ElementaryQuestion));
		
		For each AnswerRow In AnswersArray Do
			
			NewRow = QuestionTable.Add();
			NewRow[TableName + "_Column_1"] = AnswerRow.Response;
		
		EndDo;
		
	ElsIf TabularQuestionType = Enums.TabularQuestionTypes.PredefinedAnswersInColumns Then
		
		For ind = 2 To TableRow.TabularQuestionComposition.Count() Do
		
			NewRow = QuestionTable.Add();
			NewRow[TableName + "_Column_1"] = TableRow.TabularQuestionComposition[ind-1].ElementaryQuestion;
		
		EndDo;
		
	ElsIf TabularQuestionType = Enums.TabularQuestionTypes.PredefinedAnswersInRowsAndColumns Then	
		
		AnswersArray = TableRow.PredefinedAnswers.FindRows(New Structure("ElementaryQuestion",TableRow.TabularQuestionComposition[0].ElementaryQuestion));
		
		For each AnswerRow In AnswersArray Do
			
			NewRow = QuestionTable.Add();
			NewRow[TableName + "_Column_1"] = AnswerRow.Response;
		
		EndDo;
		
	EndIf;
	
	If TabularQuestionType <> Enums.TabularQuestionTypes.Composite Then
		
		ItemTable.HeightInTableRows = QuestionTable.Count() + 1;
		
	EndIf;
	
	Form.ValueToFormAttribute(QuestionTable,TableName);
	
EndProcedure

Procedure AddComplexQuestionItems(TableRow,GroupItem,Form)
	
	QuestionName = QuestioningClientServer.GetQuestionName(TableRow.RowKey);
	For each ComplexQuestionRow In TableRow.ComplexQuestionComposition Do
		
		FoundRows = Form.QuestionsPresentationTypes.FindRows(New Structure("Question",ComplexQuestionRow.ElementaryQuestion));
		If FoundRows.Count() > 0 Then
			ElementaryQuestionAttributes = FoundRows[0];
		Else
			Continue;
		EndIf;
		
		If ElementaryQuestionAttributes.ReplyType = Enums.QuestionAnswerTypes.Boolean Then
			QuestionGroupItemBoolean = Form.Items.Add(QuestionName + "_ElementaryQuestion_" + Format(ComplexQuestionRow.LineNumber, "NG=") + "_GroupBoolean",Type("FormGroup"),GroupItem);
			QuestionGroupItemBoolean.Type                        = FormGroupType.UsualGroup;
			QuestionGroupItemBoolean.ShowTitle        = False;
			QuestionGroupItemBoolean.Representation                = UsualGroupRepresentation.None;
			QuestionGroupItemBoolean.Group                = ChildFormItemsGroup.AlwaysHorizontal;
			QuestionGroupItemBoolean.HorizontalStretch   = True;
			QuestionGroupItemBoolean.VerticalStretch     = False;
		EndIf;
		
		If ElementaryQuestionAttributes.ReplyType = Enums.QuestionAnswerTypes.Boolean Then
			Item = Form.Items.Add(QuestionName + "_ElementaryQuestion_" + Format(ComplexQuestionRow.LineNumber, "NG="),Type("FormDecoration"),QuestionGroupItemBoolean);
		Else
			Item = Form.Items.Add(QuestionName + "_ElementaryQuestion_" + Format(ComplexQuestionRow.LineNumber, "NG="),Type("FormDecoration"),GroupItem);
		EndIf;
		Item.Type                        = FormDecorationType.Label;
		Item.Title                  = ComplexQuestionRow.ElementaryQuestion;
		Item.AutoMaxWidth     = False;
		Item.HorizontalStretch   = (ElementaryQuestionAttributes.ReplyType <> Enums.QuestionAnswerTypes.Boolean);
		Item.Font = New Font(Item.Font, , 8);
		
		If ElementaryQuestionAttributes.ReplyType = Enums.QuestionAnswerTypes.String Then
			
			Item = Form.Items.Add(QuestionName + "_Response_" + Format(ComplexQuestionRow.LineNumber, "NG="),Type("FormField"),GroupItem);
			Item.Type                        = FormFieldType.InputField;
			Item.TitleLocation         = FormItemTitleLocation.None;
			Item.AutoMarkIncomplete  = TableRow.Required;
			Item.DataPath                = QuestionName + "_Response_" + Format(ComplexQuestionRow.LineNumber, "NG=");
			Item.AutoMaxWidth     = False;
			Item.HorizontalStretch   = False;
			
		ElsIf ElementaryQuestionAttributes.ReplyType = Enums.QuestionAnswerTypes.Text Then
			
			Item = Form.Items.Add(QuestionName + "_Response_" + Format(ComplexQuestionRow.LineNumber, "NG="),Type("FormField"),GroupItem);
			Item.Type                       = FormFieldType.InputField;
			Item.TitleLocation        = FormItemTitleLocation.None;
			Item.AutoMarkIncomplete = TableRow.Required;
			Item.DataPath               = QuestionName + "_Response_" + Format(ComplexQuestionRow.LineNumber, "NG=");
			Item.VerticalStretch    = False;
			Item.AutoMaxWidth    = False;
			SetTextCellItemParameters(Item); 
			
		ElsIf ElementaryQuestionAttributes.ReplyType = Enums.QuestionAnswerTypes.Boolean Then
			
			Item = Form.Items.Add(QuestionName + "_Response_" + Format(ComplexQuestionRow.LineNumber, "NG="),Type("FormField"),QuestionGroupItemBoolean);
			If ElementaryQuestionAttributes.CheckBoxType = Enums.CheckBoxKindsInQuestionnaires.CheckBox Then
				Item.Type = FormFieldType.CheckBoxField;
			Else
				Item.Type = FormFieldType.InputField;
			EndIf;
			
			Item.TitleLocation = FormItemTitleLocation.None;
			Item.DataPath        = QuestionName + "_Response_" + Format(ComplexQuestionRow.LineNumber, "NG=");
			
		ElsIf ElementaryQuestionAttributes.ReplyType = Enums.QuestionAnswerTypes.Date Then
			
			Item = Form.Items.Add(QuestionName + "_Response_" + Format(ComplexQuestionRow.LineNumber, "NG="),Type("FormField"),GroupItem);
			Item.Type                       = FormFieldType.InputField;
			Item.TitleLocation        = FormItemTitleLocation.None;
			Item.AutoMarkIncomplete = TableRow.Required;
			Item.DataPath               = QuestionName + "_Response_" + Format(ComplexQuestionRow.LineNumber, "NG=");
			Item.AutoMaxWidth    = False;
			
		ElsIf ElementaryQuestionAttributes.ReplyType = Enums.QuestionAnswerTypes.Number Then
			
			Item = Form.Items.Add(QuestionName + "_Response_" + Format(ComplexQuestionRow.LineNumber, "NG="),Type("FormField"),GroupItem);
			Item.Type                       = FormFieldType.InputField;
			Item.TitleLocation        = FormItemTitleLocation.None;
			Item.AutoMarkIncomplete = TableRow.Required;
			Item.MinValue       = ?(ElementaryQuestionAttributes.MinValue = 0,Undefined,ElementaryQuestionAttributes.MinValue);
			Item.MaxValue      = ?(ElementaryQuestionAttributes.MaxValue = 0,Undefined,ElementaryQuestionAttributes.MaxValue);
			Item.ChoiceButton              = False;
			Item.DataPath               = QuestionName + "_Response_" + Format(ComplexQuestionRow.LineNumber, "NG=");
			Item.AutoMaxWidth    = False;
			If ElementaryQuestionAttributes.MinValue <> 0 OR ElementaryQuestionAttributes.MaxValue <> 0 Then
				Item.SpinButton = True;
				
				TooltipText = "";
				If ElementaryQuestionAttributes.MinValue <> 0 AND ElementaryQuestionAttributes.MaxValue <> 0 Then
					TooltipText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Допустим ввод значения от %1 до %2'; en = 'You can enter value from %1 to %2'; pl = 'You can enter value from %1 to %2';de = 'You can enter value from %1 to %2';ro = 'You can enter value from %1 to %2';tr = 'You can enter value from %1 to %2'; es_ES = 'You can enter value from %1 to %2'"),
						ElementaryQuestionAttributes.MinValue, ElementaryQuestionAttributes.MaxValue);
				ElsIf ElementaryQuestionAttributes.MinValue = 0 AND ElementaryQuestionAttributes.MaxValue <> 0 Then
					TooltipText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Допустим ввод значения до %1'; en = 'You can enter value to %1'; pl = 'You can enter value to %1';de = 'You can enter value to %1';ro = 'You can enter value to %1';tr = 'You can enter value to %1'; es_ES = 'You can enter value to %1'"), ElementaryQuestionAttributes.MaxValue);
				Else
					TooltipText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Допустим ввод значения от %1'; en = 'You can enter value from %1'; pl = 'You can enter value from %1';de = 'You can enter value from %1';ro = 'You can enter value from %1';tr = 'You can enter value from %1'; es_ES = 'You can enter value from %1'"), ElementaryQuestionAttributes.MinValue);
				EndIf;
				
				Item.ToolTip = TooltipText;
				
			EndIf;
			
		ElsIf TableRow.ReplyType = Enums.QuestionAnswerTypes.InfobaseValue Then
			
			Item = Form.Items.Add(QuestionName + "_Response_" + Format(ComplexQuestionRow.LineNumber, "NG="),Type("FormField"),GroupItem);
			Item.Type                       = FormFieldType.InputField;
			Item.TitleLocation        = FormItemTitleLocation.None;
			Item.AutoMarkIncomplete = TableRow.Required;
			Item.DataPath               = QuestionName + "_Response_" + Format(ComplexQuestionRow.LineNumber, "NG=");
			Item.AutoMaxWidth    = False;
			Item.HorizontalStretch  = False;	
			
		ElsIf ElementaryQuestionAttributes.ReplyType = Enums.QuestionAnswerTypes.OneVariantOf Then
				
			OptionsOfAnswersToQuestion = GetOptionsOfAnswersToQuestion(ComplexQuestionRow.ElementaryQuestion,Form);
			
			Item = Form.Items.Add(QuestionName + "_Response_" + Format(ComplexQuestionRow.LineNumber, "NG="),Type("FormField"),GroupItem);
			Item.Type                     = FormFieldType.RadioButtonField;
			Item.TitleLocation      = FormItemTitleLocation.None;
			Item.DataPath             = QuestionName + "_Response_" + Format(ComplexQuestionRow.LineNumber, "NG=");
			Item.ItemHeight          = 1;
			Item.HorizontalAlign = ItemHorizontalLocation.Left;
			
			If ElementaryQuestionAttributes.RadioButtonType = Enums.RadioButtonTypesInQuestionnaires.Tumbler Then
				Item.RadioButtonType = RadioButtonType.Tumbler;
				Item.ColumnsCount = 0;
				Item.EqualColumnsWidth = False;
			Else
				Item.RadioButtonType = RadioButtonType.RadioButton;
				Item.ColumnsCount = 1;
			EndIf;
			
			For each AnswerOption In OptionsOfAnswersToQuestion Do
				Item.ChoiceList.Add(AnswerOption.Response,AnswerOption.Presentation);
			EndDo;
				
		ElsIf ElementaryQuestionAttributes.ReplyType = Enums.QuestionAnswerTypes.MultipleOptionsFor Then
				
			OptionsOfAnswersToQuestion = GetOptionsOfAnswersToQuestion(ComplexQuestionRow.ElementaryQuestion,Form);
			Counter = 0;
			
			AnswersOptionsGroupItem = Form.Items.Add(QuestionName + "_Response_" 
				+ Format(ComplexQuestionRow.LineNumber, "NG=") + "_Group_Options",Type("FormGroup"),GroupItem);
			
			AnswersOptionsGroupItem.Type                 = FormGroupType.UsualGroup;
			AnswersOptionsGroupItem.Representation         = UsualGroupRepresentation.None;
			AnswersOptionsGroupItem.Group         = ChildFormItemsGroup.Vertical;
			AnswersOptionsGroupItem.ShowTitle = False;
			
			For each AnswerOption In OptionsOfAnswersToQuestion Do
				
				Counter = Counter + 1;
				
				AnswerOptionGroupItem = Form.Items.Add(QuestionName + "_Response_" 
					+ Format(ComplexQuestionRow.LineNumber, "NG=") + "_Group_ResponseOption_" + String(Counter),Type("FormGroup"),AnswersOptionsGroupItem);
				
				AnswerOptionGroupItem.Type                        = FormGroupType.UsualGroup;
				AnswerOptionGroupItem.Representation                = UsualGroupRepresentation.None;
				AnswerOptionGroupItem.Group                = ChildFormItemsGroup.AlwaysHorizontal;
				AnswerOptionGroupItem.ShowTitle        = False;
				AnswerOptionGroupItem.HorizontalStretch   = True;
				
				QuestionAttributeName = QuestionName + "_Response_" + Format(ComplexQuestionRow.LineNumber, "NG=") + "_Attribute_" + Counter;
				Item = Form.Items.Add(QuestionAttributeName,Type("FormField"),AnswerOptionGroupItem);
				
				Item.Type                = FormFieldType.CheckBoxField;
				Item.TitleLocation = FormItemTitleLocation.Right;
				Item.DataPath        = QuestionAttributeName;
				Item.TitleHeight    = 1;
				
				If AnswerOption.OpenEndedQuestion Then
					CommentAttributeName = QuestionName + "_Response_" + Format(ComplexQuestionRow.LineNumber, "NG=") + "_Comment_" + Counter;
					Item = Form.Items.Add(CommentAttributeName,Type("FormField"),AnswerOptionGroupItem);
					Item.Type 		= FormFieldType.CheckBoxField;
					Item.DataPath	= CommentAttributeName;
					Item.TitleLocation = FormItemTitleLocation.None;
				EndIf;
				
			EndDo;
							
		EndIf;
		
		// Comments to questions
		If (ElementaryQuestionAttributes.ReplyType <> Enums.QuestionAnswerTypes.MultipleOptionsFor) AND (ComplexQuestionRow.CommentRequired) Then
			
			Item                        = Form.Items.Add(QuestionName + "_Comment_" 
			                                                         + Format(ComplexQuestionRow.LineNumber, "NG="),Type("FormField"),GroupItem);
			Item.Type                    = FormFieldType.InputField;
			Item.DataPath            = QuestionName + "_Comment_" + Format(ComplexQuestionRow.LineNumber, "NG=");
			Item.AutoMaxWidth = False;
			
		EndIf;
		
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Auxiliary procedures of a questionnaire filling form.

// Gets possible options of answers to a question.
//
// Parameters:
//  ElementaryQuestion - ChartOfCharacteristicTypesRef.QuestionsForSurvey - a question, for which answers are obtained.
//  Form              - Managed form - a form, from which the call is made.
//
// Returns:
//   Array - an array of value table rows containing options of answers to a question.
//
Function GetOptionsOfAnswersToQuestion(ElementaryQuestion,Form) Export
	
	Return (Form.QuestionnaireAnswersOptions.FindRows(New Structure("Question",ElementaryQuestion)));
	
EndFunction

// Generates rows from a formulation and full row code.
//
// Parameters:
//  TableRow - CollectionItemFormData - a row of the section questions table.
//
// Returns:
//   Row - a row containing full code and formulation.
//
Function FullCodeDescription(TableRow)

	Return ?(TableRow.RowType = "Section","Section ","") + TableRow.FullCode + " " + ?(TableRow.RowType="Section",TableRow.Description,TableRow.Wording);

EndFunction

// Sets parameters values and the StartChoice event handler for the form field used for text input.
// 
//
// Parameters:
//  Item - FormField - an item, for which parameters are set.
//
Procedure SetTextCellItemParameters(Item)
	
	Item.ChoiceButton = True;
	Item.MultiLine = True;
	Item.SetAction("StartChoice","Attachable_StartTableQuestionTextCellSelection");
	
EndProcedure

// Sets parameters values for the form field used for text input.
//
// Parameters:
//  Item - FormField - an item, for which parameters are set.
//  ElementaryQuestionAttributes - FormDataCollectionItem - contains parameters values.
// 
Procedure SetNumberCellItemParameters(Item,ElementaryQuestionAttributes);

	Item.MinValue  = ?(ElementaryQuestionAttributes.MinValue = 0,Undefined,ElementaryQuestionAttributes.MinValue);
	Item.MaxValue = ?(ElementaryQuestionAttributes.MaxValue = 0,Undefined,ElementaryQuestionAttributes.MaxValue);
	
EndProcedure

// Deletes questionnaire filling form items dynamically generated previously.
//
// Parameters:
//  Form              - Managed form - a form, from which items are deleted.
//  AttributesToDelete - Array - an array of names of form attributes to be deleted, based on which 
//                       form items are deleted.
//
Procedure DeleteFillingFormItems(Form,AttributesToDelete) 
	
	For each AttributeToDelete In AttributesToDelete Do
		
		QuestionName = Left(AttributeToDelete.Value,43);
		
		FoundFormItem = Form.Items.Find(QuestionName + "_Group");
		
		If FoundFormItem <> Undefined  Then
			SubordinateItemsArray = FoundFormItem.ChildItems;
			For each SubordinateItem In SubordinateItemsArray Do
				Form.Items.Delete(SubordinateItem);
			EndDo;
			Form.Items.Delete(FoundFormItem);
		EndIf;
		
	EndDo;
	
EndProcedure

// Fills in the sections tree on the form.
//
// Parameters:
//  Form           - Managed form - a form, for which the operation is executed.
//  SectionsTree - TreeFormData - a tree, for which the data is obtained.
//
Procedure FillSectionsTree(Form,SectionsTree) Export
	
	SectionsSelection = GetSectionsSelectionByQuestionnaireTemplate(Form.QuestionnaireTemplate);
	AddRowsToSectionsTree(SectionsSelection,SectionsTree);
	
EndProcedure

// Gets a hierarchical selection by a questionnaire template.
//
// Parameters:
//  QuestionnaireTemplate - CatalogRef.QuestionnaireTemplates - a questionnaire template used to get a selection.
//
// Returns:
//   QueryResultSelection - a hierarchical selection by questionnaire template sections.
//
Function GetSectionsSelectionByQuestionnaireTemplate(QuestionnaireTemplate)
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	COUNT(DISTINCT QuestionnaireTemplateQuestions.Ref) AS Count,
	|	QuestionnaireTemplateQuestions.Parent AS Parent
	|INTO QuestionsCount
	|FROM
	|	Catalog.QuestionnaireTemplateQuestions AS QuestionnaireTemplateQuestions
	|WHERE
	|	QuestionnaireTemplateQuestions.Owner = &QuestionnaireTemplate
	|	AND NOT QuestionnaireTemplateQuestions.IsFolder
	|
	|GROUP BY
	|	QuestionnaireTemplateQuestions.Parent
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	QuestionnaireTemplateQuestions.Ref AS Ref,
	|	QuestionnaireTemplateQuestions.Wording AS Wording,
	|	QuestionsCount.Count AS Count
	|FROM
	|	Catalog.QuestionnaireTemplateQuestions AS QuestionnaireTemplateQuestions
	|		LEFT JOIN QuestionsCount AS QuestionsCount
	|		ON QuestionnaireTemplateQuestions.Ref = QuestionsCount.Parent
	|WHERE
	|	QuestionnaireTemplateQuestions.IsFolder
	|	AND NOT QuestionnaireTemplateQuestions.DeletionMark
	|	AND QuestionnaireTemplateQuestions.Owner = &QuestionnaireTemplate
	|
	|ORDER BY
	|	Ref HIERARCHY";
	
	Query.SetParameter("QuestionnaireTemplate",QuestionnaireTemplate);
	
	Return Query.Execute().Select(QueryResultIteration.ByGroupsWithHierarchy);
	
EndFunction

// Adds rows to the sections tree.
//
// Parameters:
//  SectionsSelection - QueryResultSelection - a hierarchical selection by questionnaire template sections.
//  Parent       - TreeItemFormData - a parent tree item, for which rows are added.
//
Procedure AddRowsToSectionsTree(SectionsSelection,Parent)

	ParentTreeItems = Parent.GetItems();
	While SectionsSelection.Next() Do
	
		NewTreeItem = ParentTreeItems.Add();
		NewTreeItem.Wording       = SectionsSelection.Wording;
		NewTreeItem.PictureCode        = QuestioningClientServer.GetQuestionnaireTemplatePictureCode(True);
		NewTreeItem.RowType          = "Section";
		NewTreeItem.Ref             = SectionsSelection.Ref;
		NewTreeItem.QuestionsCount = SectionsSelection.Count;
		
		AddRowsToSectionsTree(SectionsSelection.Select(QueryResultIteration.ByGroupsWithHierarchy),NewTreeItem);
	
	EndDo;

EndProcedure

// Gets information on a questionnaire section: section questions, questions attributes, and answers 
// options. Puts received information to form attributes.
// 
//
// Parameters:
//  Form            - ManagedForm - a form, for which information is obtained.
//  QuestionnaireTemplate     - CatalogRef.QuestionnaireTemplate - a questionnaire template used to get the information.
//  Section           - CatalogRef.QuestionnaireTemplateQuestions - a questionnaire section, on which information is obtained.
//  FullSectionCode - String - a full code of the section, on which the information is obtained.
//
Procedure GetInformationOnQuestionnaireQuestions(Form, QuestionnaireTemplate, Section,FullSectionCode)
	
	Query = New Query;
	Query.Text = "SELECT
	               |	QuestionsForSurvey.Ref AS Question,
	               |	QuestionsForSurvey.Wording AS Wording,
	               |	QuestionsForSurvey.ValueType AS Type,
	               |	QuestionsForSurvey.ReplyType AS ReplyType,
	               |	QuestionsForSurvey.RadioButtonType AS RadioButtonType,
	               |	QuestionsForSurvey.CheckBoxType AS CheckBoxType,
	               |	QuestionsForSurvey.MinValue AS MinValue,
	               |	QuestionsForSurvey.MaxValue AS MaxValue
	               |FROM
	               |	ChartOfCharacteristicTypes.QuestionsForSurvey AS QuestionsForSurvey
	               |WHERE
	               |	QuestionsForSurvey.Ref IN
	               |			(SELECT DISTINCT
	               |				QuestionnaireTemplateQuestions.ElementaryQuestion
	               |			FROM
	               |				Catalog.QuestionnaireTemplateQuestions AS QuestionnaireTemplateQuestions
	               |			WHERE
	               |				QuestionnaireTemplateQuestions.Owner = &QuestionnaireTemplate
	               |				AND QuestionnaireTemplateQuestions.Parent = &Section
	               |		
	               |			UNION ALL
	               |		
	               |			SELECT
	               |				QuestionnaireTemplateQuestionsTableQuestionComposition.ElementaryQuestion
	               |			FROM
	               |				Catalog.QuestionnaireTemplateQuestions.TabularQuestionComposition AS QuestionnaireTemplateQuestionsTableQuestionComposition
	               |			WHERE
	               |				QuestionnaireTemplateQuestionsTableQuestionComposition.Ref.Owner = &QuestionnaireTemplate
	               |				AND QuestionnaireTemplateQuestionsTableQuestionComposition.Ref.Parent = &Section
	               |		
	               |			UNION ALL
	               |		
	               |			SELECT
	               |				QuestionnaireTemplateQuestionsComplexQuestionContent.ElementaryQuestion
	               |			FROM
	               |				Catalog.QuestionnaireTemplateQuestions.ComplexQuestionComposition AS QuestionnaireTemplateQuestionsComplexQuestionContent
	               |			WHERE
	               |				QuestionnaireTemplateQuestionsComplexQuestionContent.Ref.Owner = &QuestionnaireTemplate
	               |				AND QuestionnaireTemplateQuestionsComplexQuestionContent.Ref.Parent = &Section)
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	QuestionnaireTemplateQuestions.Ref AS TemplateQuestion,
	               |	QuestionnaireTemplateQuestions.Parent AS Parent,
	               |	QuestionnaireTemplateQuestions.Description AS Description,
	               |	QuestionnaireTemplateQuestions.Required AS Required,
	               |	QuestionnaireTemplateQuestions.QuestionsType AS QuestionsType,
	               |	QuestionnaireTemplateQuestions.TabularQuestionType AS TabularQuestionType,
	               |	QuestionnaireTemplateQuestions.ElementaryQuestion AS ElementaryQuestion,
	               |	""Question"" AS RowType,
	               |	QuestionnaireTemplateQuestions.ParentQuestion AS ParentQuestion,
	               |	QuestionnaireTemplateQuestions.ToolTip AS ToolTip,
	               |	QuestionnaireTemplateQuestions.HintPlacement AS HintPlacement,
	               |	QuestionnaireTemplateQuestions.TabularQuestionComposition.(
	               |		LineNumber,
	               |		ElementaryQuestion
	               |	),
	               |	QuestionnaireTemplateQuestions.PredefinedAnswers.(
	               |		LineNumber,
	               |		ElementaryQuestion,
	               |		Response
	               |	),
	               |	QuestionnaireTemplateQuestions.ComplexQuestionComposition.(
	               |		LineNumber,
	               |		ElementaryQuestion,
	               |		ElementaryQuestion.CommentRequired AS CommentRequired,
	               |		ElementaryQuestion.CommentNote AS CommentNote
	               |	),
	               |	ISNULL(QuestionsForSurvey.Length, 0) AS Length,
	               |	QuestionsForSurvey.ValueType AS ValueType,
	               |	ISNULL(QuestionsForSurvey.CommentRequired, FALSE) AS CommentRequired,
	               |	ISNULL(QuestionsForSurvey.CommentNote, """") AS CommentNote,
	               |	ISNULL(QuestionsForSurvey.MinValue, 0) AS MinValue,
	               |	ISNULL(QuestionsForSurvey.MaxValue, 0) AS MaxValue,
                   |	ISNULL(QuestionsForSurvey.RadioButtonType, VALUE(Enum.RadioButtonTypesInQuestionnaires.EmptyRef)) AS RadioButtonType,
	               |	ISNULL(QuestionsForSurvey.CheckBoxType, VALUE(Enum.CheckBoxKindsInQuestionnaires.EmptyRef)) AS CheckBoxType,
	               |	ISNULL(QuestionsForSurvey.ReplyType, VALUE(Enum.QuestionAnswerTypes.EmptyRef)) AS ReplyType,
	               |	ISNULL(QuestionnaireTemplateQuestions.Wording, """") AS Wording,
	               |	ISNULL(QuestionsForSurvey.Accuracy, 0) AS Accuracy
	               |FROM
	               |	Catalog.QuestionnaireTemplateQuestions AS QuestionnaireTemplateQuestions
	               |		LEFT JOIN ChartOfCharacteristicTypes.QuestionsForSurvey AS QuestionsForSurvey
	               |		ON QuestionnaireTemplateQuestions.ElementaryQuestion = QuestionsForSurvey.Ref
	               |WHERE
	               |	NOT QuestionnaireTemplateQuestions.DeletionMark
	               |	AND QuestionnaireTemplateQuestions.Owner = &QuestionnaireTemplate
	               |	AND QuestionnaireTemplateQuestions.Parent = &Section
	               |	AND NOT QuestionnaireTemplateQuestions.IsFolder
	               |
	               |ORDER BY
	               |	QuestionnaireTemplateQuestions.Code
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	QuestionnaireAnswersOptions.Owner AS Question,
	               |	QuestionnaireAnswersOptions.Ref AS Response,
	               |	QuestionnaireAnswersOptions.Presentation,
	               |	QuestionnaireAnswersOptions.OpenEndedQuestion
	               |FROM
	               |	Catalog.QuestionnaireAnswersOptions AS QuestionnaireAnswersOptions
	               |WHERE
	               |	QuestionnaireAnswersOptions.Owner IN
	               |			(SELECT
	               |				QuestionnaireTemplateQuestions.ElementaryQuestion
	               |			FROM
	               |				Catalog.QuestionnaireTemplateQuestions AS QuestionnaireTemplateQuestions
	               |			WHERE
	               |				QuestionnaireTemplateQuestions.Owner = &QuestionnaireTemplate
	               |				AND QuestionnaireTemplateQuestions.Parent = &Section
	               |				AND NOT QuestionnaireTemplateQuestions.IsFolder
	               |				AND NOT QuestionnaireTemplateQuestions.DeletionMark
	               |		
	               |			UNION ALL
	               |		
	               |			SELECT
	               |				QuestionnaireTemplateQuestionsTableQuestionComposition.ElementaryQuestion
	               |			FROM
	               |				Catalog.QuestionnaireTemplateQuestions.TabularQuestionComposition AS QuestionnaireTemplateQuestionsTableQuestionComposition
	               |			WHERE
	               |				QuestionnaireTemplateQuestionsTableQuestionComposition.Ref.Owner = &QuestionnaireTemplate
	               |				AND QuestionnaireTemplateQuestionsTableQuestionComposition.Ref.Parent = &Section
	               |				AND NOT QuestionnaireTemplateQuestionsTableQuestionComposition.Ref.IsFolder
	               |				AND NOT QuestionnaireTemplateQuestionsTableQuestionComposition.Ref.DeletionMark
	               |		
	               |			UNION ALL
	               |		
	               |			SELECT
	               |				QuestionnaireTemplateQuestionsComplexQuestionContent.ElementaryQuestion
	               |			FROM
	               |				Catalog.QuestionnaireTemplateQuestions.ComplexQuestionComposition AS QuestionnaireTemplateQuestionsComplexQuestionContent
	               |			WHERE
	               |				QuestionnaireTemplateQuestionsComplexQuestionContent.Ref.Owner = &QuestionnaireTemplate
	               |				AND QuestionnaireTemplateQuestionsComplexQuestionContent.Ref.Parent = &Section
	               |				AND NOT QuestionnaireTemplateQuestionsComplexQuestionContent.Ref.IsFolder
	               |				AND NOT QuestionnaireTemplateQuestionsComplexQuestionContent.Ref.DeletionMark)
	               |	AND NOT QuestionnaireAnswersOptions.DeletionMark
	               |
	               |ORDER BY
	               |	QuestionnaireAnswersOptions.AddlOrderingAttribute";
	
	Query.SetParameter("QuestionnaireTemplate",QuestionnaireTemplate);
	Query.SetParameter("Section",Section);
	
	QueryResultsArray = Query.ExecuteBatch();

	// Presentation and questions types.
	Form.QuestionsPresentationTypes.Load(QueryResultsArray[0].Unload());
	
	// Questions of a questionnaire template section.
	QuestionsByQuestionnaireSectionSelection = QueryResultsArray[1].Select();
	QuestionsCounter = 0;
	
	While QuestionsByQuestionnaireSectionSelection.Next() Do
		
		QuestionsCounter = QuestionsCounter + 1;
		NewRow = Form.SectionQuestionsTable.Add();
		FillPropertyValues(NewRow,QuestionsByQuestionnaireSectionSelection,,"TabularQuestionComposition,PredefinedAnswers,ComplexQuestionComposition");
		NewRow.TabularQuestionComposition.Load(QuestionsByQuestionnaireSectionSelection.TabularQuestionComposition.Unload());
		NewRow.TabularQuestionComposition.Sort("LineNumber Asc");
		NewRow.PredefinedAnswers.Load(QuestionsByQuestionnaireSectionSelection.PredefinedAnswers.Unload());
		NewRow.PredefinedAnswers.Sort("LineNumber Asc");
		NewRow.ComplexQuestionComposition.Load(QuestionsByQuestionnaireSectionSelection.ComplexQuestionComposition.Unload());
		NewRow.ComplexQuestionComposition.Sort("LineNumber Asc");
		NewRow.RowKey = New UUID;
		NewRow.FullCode  = FullSectionCode + "." + String(QuestionsCounter);
		
	EndDo;
	
	// Answers options
	Form.QuestionnaireAnswersOptions.Load(QueryResultsArray[2].Unload());

EndProcedure

// Generates a table of questions subordination.
//
// Parameters:
//   Form - Managed form - a form, for which the subordination table is generated.
//
Procedure GenerateQuestionsSubordinationTable(Form) Export
	
	Form.DependentQuestions.Clear();
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	ExternalSource.TemplateQuestion AS TemplateQuestion,
	|	ExternalSource.ParentQuestion AS ParentQuestion,
	|	ExternalSource.QuestionsType,
	|	ExternalSource.KeyString,
	|	ExternalSource.Required,
	|	ExternalSource.CommentRequired,
	|	ExternalSource.ElementaryQuestion,
	|	ExternalSource.ReplyType
	|INTO SectionQuestions
	|FROM
	|	&ExternalSource AS ExternalSource
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SectionQuestions.TemplateQuestion AS TemplateQuestion,
	|	SectionQuestions.KeyString
	|INTO QuestionsWithCondition
	|FROM
	|	SectionQuestions AS SectionQuestions
	|WHERE
	|	SectionQuestions.QuestionsType = VALUE(Enum.QuestionnaireTemplateQuestionTypes.QuestionWithCondition)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SectionQuestions.ParentQuestion AS ParentQuestion,
	|	SectionQuestions.TemplateQuestion,
	|	SectionQuestions.KeyString AS RowKey,
	|	QuestionsWithCondition.KeyString AS ParentSrtingKey,
	|	SectionQuestions.Required,
	|	SectionQuestions.CommentRequired,
	|	SectionQuestions.QuestionsType,
	|	SectionQuestions.ElementaryQuestion,
	|	SectionQuestions.ReplyType
	|FROM
	|	SectionQuestions AS SectionQuestions
	|		INNER JOIN QuestionsWithCondition AS QuestionsWithCondition
	|		ON SectionQuestions.ParentQuestion = QuestionsWithCondition.TemplateQuestion
	|WHERE
	|	SectionQuestions.ParentQuestion IN
	|			(SELECT
	|				QuestionsWithCondition.TemplateQuestion
	|			FROM
	|				QuestionsWithCondition AS QuestionsWithCondition)
	|TOTALS BY
	|	ParentSrtingKey";
	
	ExternalSource = Form.SectionQuestionsTable.Unload();
	ExternalSource.Columns.Add("KeyString", New TypeDescription("String",,New StringQualifiers(50)));
	For each TableRow In ExternalSource Do
		TableRow.KeyString = String(TableRow.RowKey);
	EndDo;
	Query.SetParameter("ExternalSource",ExternalSource);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;  	
	
	Selection = Result.Select(QueryResultIteration.ByGroups);
	While Selection.Next() Do
		
		Form.Items[QuestioningClientServer.GetQuestionName(Selection.ParentSrtingKey)].SetAction("OnChange","Attachable_OnChangeQuestionsWithConditions");
		
		DetailsSelection = Selection.Select();
		
		NewRow = Form.DependentQuestions.Add();
		NewRow.Question = Selection.ParentSrtingKey;
		
		While DetailsSelection.Next() Do
			
			QuestionName = QuestioningClientServer.GetQuestionName(DetailsSelection.RowKey);
			If DetailsSelection.QuestionsType = Enums.QuestionnaireTemplateQuestionTypes.Tabular Then
				
				NewRowSubordinate = NewRow.Dependent.Add();
				NewRowSubordinate.SubordinateQuestionItemName = QuestionName + "_Table";
				NewRowSubordinate.Required = Selection.Required;
				
			ElsIf DetailsSelection.QuestionsType = Enums.QuestionnaireTemplateQuestionTypes.Complex Then
				
				NewRowSubordinate = NewRow.Dependent.Add();
				NewRowSubordinate.SubordinateQuestionItemName = QuestionName + "_Group";
				NewRowSubordinate.Required = Selection.Required;
				
			Else
				
				If DetailsSelection.ReplyType = Enums.QuestionAnswerTypes.MultipleOptionsFor Then
					
					OptionsOfAnswersToQuestion = GetOptionsOfAnswersToQuestion(DetailsSelection.ElementaryQuestion,Form);
					
					Counter = 0;
					For each AnswerOption In OptionsOfAnswersToQuestion Do
						
						Counter = Counter + 1;
						NewRowSubordinate = NewRow.Dependent.Add();
						NewRowSubordinate.SubordinateQuestionItemName = QuestionName + "_Attribute_" + Counter;
						NewRowSubordinate.Required                   = False;
						
						If AnswerOption.OpenEndedQuestion Then
							NewRowSubordinate = NewRow.Dependent.Add();
							NewRowSubordinate.SubordinateQuestionItemName = QuestionName + "_Comment_" + Counter;
							NewRowSubordinate.Required                   = False;
						EndIf;
					EndDo;
					
				Else
					
					NewRowSubordinate = NewRow.Dependent.Add();
					NewRowSubordinate.SubordinateQuestionItemName = QuestionName;
					NewRowSubordinate.Required                   = DetailsSelection.Required;
					
					If DetailsSelection.CommentRequired Then
						NewRowSubordinate = NewRow.Dependent.Add();
						NewRowSubordinate.SubordinateQuestionItemName = QuestionName + "_Comment";
						NewRowSubordinate.Required                   = False;;
					EndIf;
					
				EndIf;
			EndIf;
		EndDo; // details selection
	EndDo; // selection
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Other procedures and functions

// The procedure deletes previous question items of the questionnaire template.
Procedure DeleteQuestionnaireTemplateQuestions(OwnerRef) Export
	
	SetPrivilegedMode(True);
	
	// Deleting the previous template questions.
	Query = New Query;
	Query.Text = "SELECT
	|	QuestionnaireTemplateQuestions.Ref
	|FROM
	|	Catalog.QuestionnaireTemplateQuestions AS QuestionnaireTemplateQuestions
	|WHERE
	|	QuestionnaireTemplateQuestions.Owner = &Owner";
	
	Query.SetParameter("Owner",OwnerRef);
	
	QueryResult = Query.Execute();
	If Not QueryResult.IsEmpty() Then
		
		RefsArray = QueryResult.Unload().UnloadColumn("Ref");
		For each ArrayElement In RefsArray Do
			
			CatalogObject = ArrayElement.GetObject();
			If (NOT CatalogObject = Undefined) Then
				CatalogObject.Delete();
			EndIf;
			
		EndDo;
	EndIf;
	
	SetPrivilegedMode(False);
	
EndProcedure

// Gets presentations of elementary questions of tabular questions and fills in the 
// QuestionsPresentation map from which questions presentations will be obtained during the table 
// questions output.
//
// Parameters:
//   QuestionnaireTemplate - CatalogRef.QuestionnaireTemplates used for survey.
//
// Returns:
//   Map - a reference to the question acts as a key and questions formulation acts as a value.
//
Function GetPresentationsOfElementaryQuestionsOfTabularQuestion(QuestionnaireTemplate) Export
	
	QuestionsPresentations = New Map;
	
	Query = New Query;
	Query.Text = "SELECT
	|	QuestionnaireTemplateQuestions.Ref
	|INTO TemplateQuestions
	|FROM
	|	Catalog.QuestionnaireTemplateQuestions AS QuestionnaireTemplateQuestions
	|WHERE
	|	QuestionnaireTemplateQuestions.Owner = &QuestionnaireTemplate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	QuestionnaireTemplateQuestionsTableQuestionComposition.ElementaryQuestion
	|INTO ElementaryQuestions
	|FROM
	|	Catalog.QuestionnaireTemplateQuestions.TabularQuestionComposition AS QuestionnaireTemplateQuestionsTableQuestionComposition
	|WHERE
	|	QuestionnaireTemplateQuestionsTableQuestionComposition.Ref IN
	|			(SELECT
	|				TemplateQuestions.Ref
	|			FROM
	|				TemplateQuestions AS TemplateQuestions)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	QuestionsForSurvey.Ref,
	|	QuestionsForSurvey.Wording,
	|	QuestionsForSurvey.ShowAggregatedValuesInReports
	|FROM
	|	ChartOfCharacteristicTypes.QuestionsForSurvey AS QuestionsForSurvey
	|WHERE
	|	QuestionsForSurvey.Ref IN
	|			(SELECT
	|				ElementaryQuestions.ElementaryQuestion
	|			FROM
	|				ElementaryQuestions AS ElementaryQuestions)";
	
	Query.SetParameter("QuestionnaireTemplate",QuestionnaireTemplate);
	
	Result = Query.Execute();
	If NOT Result.IsEmpty() Then
		
		Selection = Result.Select();
		While Selection.Next() Do
			QuestionsPresentations.Insert(Selection.Ref,New Structure("Wording,ShowAggregatedValuesInReports", Selection.Wording,Selection.ShowAggregatedValuesInReports));
		EndDo;
		
	EndIf; 
	
	Return QuestionsPresentations;
	
EndFunction

// Gets a table of questionnaires currently available to a respondent.
//
// Parameters:
//  Respondent - CatalogRef - a respondent, for whom the list of questionnaires is obtained.
//
// Returns:
//   ValueTable   - a table containing information on questionnaires available to the respondent.
//   Undefined       - if there are no questionnaires available to the respondent.
//
Function TableOfQuestionnairesAvailableToRespondent(Respondent) Export
	
	If  ValueIsFilled(Respondent) Then
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	PollPurpose.Ref AS Ref,
		|	PollPurpose.FreeSurvey AS FreeSurvey,
		|	PollPurpose.EndDate AS EndDate,
		|	PollPurpose.Description AS Description
		|INTO ActivePolls
		|FROM
		|	Document.PollPurpose AS PollPurpose
		|WHERE
		|	PollPurpose.Posted
		|	AND NOT PollPurpose.DeletionMark
		|	AND PollPurpose.RespondentsType = &RespondentsType
		|	AND (PollPurpose.StartDate = &EmptyDate
		|			OR BEGINOFPERIOD(PollPurpose.StartDate, DAY) < &CurrentDate)
		|	AND (PollPurpose.EndDate = &EmptyDate
		|			OR ENDOFPERIOD(PollPurpose.EndDate, DAY) > &CurrentDate)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ActivePolls.Ref AS Ref,
		|	ActivePolls.EndDate AS EndDate,
		|	ActivePolls.Description AS Description
		|INTO ActivePollsFilterByRespondent
		|FROM
		|	ActivePolls AS ActivePolls
		|WHERE
		|	ActivePolls.FreeSurvey
		|
		|UNION ALL
		|
		|SELECT
		|	PollsPurposeRespondents.Ref,
		|	PollPurpose.EndDate,
		|	PollPurpose.Description
		|FROM
		|	Document.PollPurpose.Respondents AS PollsPurposeRespondents
		|		LEFT JOIN Document.PollPurpose AS PollPurpose
		|		ON PollsPurposeRespondents.Ref = PollPurpose.Ref
		|WHERE
		|	PollsPurposeRespondents.Respondent = &Respondent
		|	AND PollsPurposeRespondents.Ref IN
		|			(SELECT
		|				ActivePolls.Ref
		|			FROM
		|				ActivePolls AS ActivePolls
		|			WHERE
		|				NOT ActivePolls.FreeSurvey)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Questionnaire.Ref AS Ref,
		|	Questionnaire.ModificationDate AS Date,
		|	Questionnaire.Posted AS Posted,
		|	Questionnaire.Survey AS Survey
		|INTO QuestionnairesOnActiveRequests
		|FROM
		|	Document.Questionnaire AS Questionnaire
		|WHERE
		|	Questionnaire.Survey IN
		|			(SELECT
		|				ActivePollsFilterByRespondent.Ref
		|			FROM
		|				ActivePollsFilterByRespondent AS ActivePollsFilterByRespondent)
		|	AND Questionnaire.Respondent = &Respondent
		|	AND NOT Questionnaire.DeletionMark
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CASE
		|		WHEN QuestionnairesOnActiveRequests.Ref IS NULL
		|			THEN ""Surveys""
		|		ELSE ""Questionnaires""
		|	END AS Status,
		|	CASE
		|		WHEN QuestionnairesOnActiveRequests.Ref IS NULL
		|			THEN ActivePollsFilterByRespondent.Ref
		|		ELSE QuestionnairesOnActiveRequests.Ref
		|	END AS QuestionnaireSurvey,
		|	ActivePollsFilterByRespondent.EndDate AS EndDate,
		|	ActivePollsFilterByRespondent.Description AS Description,
		|	QuestionnairesOnActiveRequests.Date AS QuestionnaireDate,
		|	ISNULL(QuestionnairesOnActiveRequests.Posted, FALSE) AS Posted
		|INTO PollsWithoutResponsesSavedQuestionnaires
		|FROM
		|	ActivePollsFilterByRespondent AS ActivePollsFilterByRespondent
		|		LEFT JOIN QuestionnairesOnActiveRequests AS QuestionnairesOnActiveRequests
		|		ON ActivePollsFilterByRespondent.Ref = QuestionnairesOnActiveRequests.Survey
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	PollsWithoutResponsesSavedQuestionnaires.Status AS Status,
		|	PollsWithoutResponsesSavedQuestionnaires.QuestionnaireSurvey AS QuestionnaireSurvey,
		|	PollsWithoutResponsesSavedQuestionnaires.EndDate AS EndDate,
		|	PollsWithoutResponsesSavedQuestionnaires.Description AS Description,
		|	PollsWithoutResponsesSavedQuestionnaires.QuestionnaireDate AS QuestionnaireDate
		|FROM
		|	PollsWithoutResponsesSavedQuestionnaires AS PollsWithoutResponsesSavedQuestionnaires
		|WHERE
		|	NOT PollsWithoutResponsesSavedQuestionnaires.Posted";
		
		Query.SetParameter("Respondent", Respondent);
		Query.SetParameter("CurrentDate", CurrentSessionDate());
		Query.SetParameter("EmptyDate" ,Date(1, 1, 1));
		Query.SetParameter("RespondentsType", Catalogs[Respondent.Metadata().Name].EmptyRef());
		
		Result = Query.Execute();
		
		If NOT Result.IsEmpty() Then
			
			Return Result.Unload();
			
		EndIf;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion
