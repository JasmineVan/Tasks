///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Deletes the last characters from the string if they are equal to the deletion substring as long 
// as the last characters are not equal to the deletion substring.
//
// Parameters:
//  IncomingString    - String - a string to be processed.
//  DeletionSubstring - String - a substring to be deleted from the string end.
//  Separator       - String - if the separator is specified, deletion is performed only if the 
//                        deletion substring is located entirely after the separator.
//
// Returns:
//   String - a string resulted from processing.
//
Function DeleteLastCharsFromString(IncomingString,DeletionSubstring,Separator = Undefined) Export
	
	While Right(IncomingString,StrLen(DeletionSubstring)) = DeletionSubstring Do
		
		If Separator <> Undefined Then
			If Mid(IncomingString,StrLen(IncomingString)-StrLen(DeletionSubstring)-StrLen(Separator),StrLen(Separator)) = Separator Then
				Return IncomingString;
			EndIf;
		EndIf;
		IncomingString = Left(IncomingString,StrLen(IncomingString) - StrLen(DeletionSubstring));
		
	EndDo;
	
	Return IncomingString;
	
EndFunction

// Generates a question name based on the UUID of a questionnaire tree row.
//
// Parameters:
//  Key  - UUID - a key, based on which a question name is generated.
//
// Returns:
//  String - a string resulted from processing.
//
Function GetQuestionName(varKey) Export
	
	Return "Question_" + StrReplace(varKey,"-","_");

EndFunction

// Re-generates questionnaire tree numbering.
Procedure GenerateTreeNumbering(QuestionnaireTree,ConvertFormulation = False) Export

	If QuestionnaireTree.GetItems()[0].RowType = "Root" Then 
		KeyTreeItems = QuestionnaireTree.GetItems()[0].GetItems();
	Else
		KeyTreeItems = QuestionnaireTree.GetItems();
	EndIf;
	
	GenerateTreeItemsNumbering(KeyTreeItems,1,New Array,ConvertFormulation);

EndProcedure 

// Called recursively upon generating the full code of questionnaire tree rows.
Procedure GenerateTreeItemsNumbering(TreeRows, RecursionLevel, ArrayFullCode, ConvertFormulation)
	
	If ArrayFullCode.Count() < RecursionLevel Then
		ArrayFullCode.Add(0);
	EndIf;
	
	For each Item In TreeRows Do
		
		If Item.RowType = "Introduction" OR Item.RowType = "Conclusion" Then
			Continue;
		EndIf;	
		
		ArrayFullCode[RecursionLevel-1] = ArrayFullCode[RecursionLevel-1] + 1;
		For ind = RecursionLevel To ArrayFullCode.Count()-1 Do
			ArrayFullCode[ind] = 0;
		EndDo;
		
		FullCode = StrConcat(ArrayFullCode,".");
		FullCode = DeleteLastCharsFromString(FullCode,".0.",".");
		
		Item.FullCode = FullCode;
		If ConvertFormulation Then
			Item.Wording = Item.FullCode + ". " + Item.Wording;
		EndIf;
		
		SubordinateTreeRowItems = Item.GetItems();
		If SubordinateTreeRowItems.Count() > 0 Then
			GenerateTreeItemsNumbering(SubordinateTreeRowItems,?(Item.RowType ="Question",RecursionLevel,RecursionLevel + 1),ArrayFullCode,ConvertFormulation);
		EndIf;
		
	EndDo;
	
EndProcedure

// Finds the first row in the specified column with the specified value in the TreeFormData collection.
Function FindStringInTreeFormData(WhereToFind,Value,Column,SearchInSubordinateItems) Export
	
	TreeItems = WhereToFind.GetItems();
	
	For each TreeItem In TreeItems Do
		If TreeItem[Column] = Value Then
			Return TreeItem.GetID();
		ElsIf  SearchInSubordinateItems Then
			FoundRowID =  FindStringInTreeFormData(TreeItem,Value,Column,SearchInSubordinateItems);
			If FoundRowID >=0 Then
				Return FoundRowID;
			EndIf;
		EndIf;
		
	EndDo;
	
	Return -1;
	
EndFunction

// Returns a picture code depending on question type and on whether it belongs to the section.
//
// Parameters:
//  IsSection - Boolean -  a section flag.
//  QuestionType - Enumeration.QuestionnaireTemplateQuestionTypes.
//
// Returns:
//   Number   - a picture code to display in the tree.
//
Function GetQuestionnaireTemplatePictureCode(IsSection,QuestionType = Undefined) Export
	
	If IsSection Then
		Return 1;
	ElsIf QuestionType = PredefinedValue("Enum.QuestionnaireTemplateQuestionTypes.Basic") Then
		Return 2;
	ElsIf QuestionType = PredefinedValue("Enum.QuestionnaireTemplateQuestionTypes.QuestionWithCondition") Then
		Return 4;
	ElsIf QuestionType = PredefinedValue("Enum.QuestionnaireTemplateQuestionTypes.Tabular") Then
		Return 3;
	ElsIf QuestionType = PredefinedValue("Enum.QuestionnaireTemplateQuestionTypes.Complex") Then
		Return 5;
	Else
		Return 0;
	EndIf;
	
EndFunction

Procedure SwitchQuestionnaireBodyGroupsVisibility(Form, QuestionnaireBodyVisibility) Export
	
	Form.Items.QuestionnaireBodyGroup.Visible = QuestionnaireBodyVisibility;
	Form.Items.WaitGroup.Visible   = NOT QuestionnaireBodyVisibility;
	
	Form.Items.FooterPreviousSection.Enabled = QuestionnaireBodyVisibility;
	Form.Items.PreviousSection.Enabled       = QuestionnaireBodyVisibility;
	Form.Items.FooterNextSection.Enabled  = QuestionnaireBodyVisibility;
	Form.Items.NextSection.Enabled        = QuestionnaireBodyVisibility;

	
EndProcedure

#EndRegion
