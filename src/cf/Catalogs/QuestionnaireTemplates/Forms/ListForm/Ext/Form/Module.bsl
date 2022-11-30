///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
	
	If Clone
		AND Not Folder Then
		
		CurrentData = Items.List.CurrentData;
		If CurrentData <> Undefined Then
			
			Cancel = True;
			NewItemRef = ExecuteItemCopying(CurrentData.Ref);
			If NewItemRef <> Undefined Then
				OpenForm("Catalog.QuestionnaireTemplates.Form.ItemForm",New Structure("Key",NewItemRef));
				Items.List.Refresh();
			EndIf;
			
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function ExecuteItemCopying(CopyingItem)
	
	BeginTransaction();
	Try
	
		QuestionnaireTemplateObject = Catalogs.QuestionnaireTemplates.CreateItem();
		
		FillPropertyValues(QuestionnaireTemplateObject,CopyingItem,"DeletionMark,Description,Title,Introduction,Conclusion");
		QuestionnaireTemplateObject.SetNewObjectRef(Catalogs.QuestionnaireTemplates.GetRef());
		QuestionnaireTemplateObject.TemplateEditCompleted = False;
		QuestionnaireTemplateObject.Write();
		
		Query = New Query;
		Query.Text = "
		|SELECT
		|	QuestionnaireTemplateQuestions.Ref AS Ref,
		|	QuestionnaireTemplateQuestions.DeletionMark,
		|	QuestionnaireTemplateQuestions.Predefined,
		|	QuestionnaireTemplateQuestions.Owner,
		|	QuestionnaireTemplateQuestions.Parent,
		|	QuestionnaireTemplateQuestions.IsFolder,
		|	QuestionnaireTemplateQuestions.Code AS Code,
		|	QuestionnaireTemplateQuestions.Description,
		|	QuestionnaireTemplateQuestions.Required,
		|	QuestionnaireTemplateQuestions.QuestionsType,
		|	QuestionnaireTemplateQuestions.TabularQuestionType,
		|	QuestionnaireTemplateQuestions.ElementaryQuestion,
		|	QuestionnaireTemplateQuestions.ParentQuestion,
		|	QuestionnaireTemplateQuestions.ToolTip AS ToolTip,
		|	QuestionnaireTemplateQuestions.HintPlacement AS HintPlacement,
		|	QuestionnaireTemplateQuestions.TabularQuestionComposition.(
		|		ElementaryQuestion AS ElementaryQuestion,
		|		LineNumber
		|	),
		|	QuestionnaireTemplateQuestions.PredefinedAnswers.(
		|		ElementaryQuestion AS ElementaryQuestion,
		|		Response,
		|		LineNumber
		|	),
		|	QuestionnaireTemplateQuestions.ComplexQuestionComposition.(
		|		ElementaryQuestion AS ElementaryQuestion,
		|		LineNumber
		|	),
		|	QuestionnaireTemplateQuestions.Wording
		|FROM
		|	Catalog.QuestionnaireTemplateQuestions AS QuestionnaireTemplateQuestions
		|WHERE
		|	QuestionnaireTemplateQuestions.Owner = &QuestionnaireTemplate
		|
		|ORDER BY
		|	Ref HIERARCHY,
		|	Code";
		
		Query.SetParameter("QuestionnaireTemplate", CopyingItem);
		
		Result = Query.Execute();
		
		Selection = Result.Select(QueryResultIteration.ByGroupsWithHierarchy);
		AddQuestionnaireTemplateQuestionsCatalogItems(QuestionnaireTemplateObject.Ref, Selection);
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Return Undefined;
		
	EndTry;
	
	Return QuestionnaireTemplateObject.Ref;
	
EndFunction

&AtServer
Procedure AddQuestionnaireTemplateQuestionsCatalogItems(Ref, Selection, Parent = Undefined)
	
	QuestionsWithCondition = New Map;
	
	While Selection.Next() Do
		
		If Selection.IsFolder Then
			
			NewItem = Catalogs.QuestionnaireTemplateQuestions.CreateFolder();
			FillPropertyValues(NewItem,Selection,"Description,Code,Wording");
			
		Else
			
			NewItem = Catalogs.QuestionnaireTemplateQuestions.CreateItem();
			
			NewRef = Catalogs.QuestionnaireTemplateQuestions.GetRef();
			NewItem.SetNewObjectRef(NewRef);
			
			FillPropertyValues(NewItem,Selection,,"Owner,Parent,TabularQuestionComposition,PredefinedAnswers,ComplexQuestionComposition,Code,ParentQuestion");
			TableQuestionComposition = Selection.TabularQuestionComposition.Unload();
			TableQuestionComposition.Sort("LineNumber Asc");
			NewItem.TabularQuestionComposition.Load(TableQuestionComposition);
			PredefinedAnswers = Selection.PredefinedAnswers.Unload();
			PredefinedAnswers.Sort("LineNumber Asc");
			NewItem.PredefinedAnswers.Load(PredefinedAnswers);
			ComplexQuestionComposition = Selection.ComplexQuestionComposition.Unload();
			ComplexQuestionComposition.Sort("LineNumber Asc");
			NewItem.ComplexQuestionComposition.Load(ComplexQuestionComposition);
			
			If Selection.QuestionsType = Enums.QuestionnaireTemplateQuestionTypes.QuestionWithCondition Then
				QuestionsWithCondition.Insert(Selection.Ref,NewRef);
			EndIf;
			
			If NOT Selection.ParentQuestion.IsEmpty() Then
				NewItem.ParentQuestion = QuestionsWithCondition.Get(Selection.ParentQuestion);
			EndIf;
			
		EndIf;
		
		NewItem.Owner = Ref;
		NewItem.Parent = ?(Parent = Undefined,Catalogs.QuestionnaireTemplateQuestions.EmptyRef(),Parent);
		NewItem.Write();
		
		SubordinateSelection = Selection.Select(QueryResultIteration.ByGroupsWithHierarchy);
		If SubordinateSelection.Count() > 0 Then
			AddQuestionnaireTemplateQuestionsCatalogItems(Ref,SubordinateSelection,NewItem.Ref);
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion
