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
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	// Setting the filter by an owner in the dynamic list of the "Questionnaire answers options" catalog.
	CommonClientServer.SetDynamicListFilterItem(AnswersOptions,"Owner", Object.Ref, DataCompositionComparisonType.Equal, ,True);
	
	SetAnswerType();
	
	If ReplyType = Enums.QuestionAnswerTypes.String Then
		StringLength = Object.Length;
	EndIf;
	
	If Object.Ref.IsEmpty() Then
		Object.RadioButtonType = Enums.RadioButtonTypesInQuestionnaires.RadioButton;
		Object.CheckBoxType = Enums.CheckBoxKindsInQuestionnaires.InputField;
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AssignmentParameters = AttachableCommands.PlacementParameters();
	AssignmentParameters.Sources = New TypeDescription("ChartOfCharacteristicTypesRef.QuestionsForSurvey");
	AssignmentParameters.CommandBar = Items.FormCommandBar;
	AttachableCommands.OnCreateAtServer(ThisObject, AssignmentParameters);
	
	AssignmentParameters = AttachableCommands.PlacementParameters();
	AssignmentParameters.Sources = New TypeDescription("CatalogRef.QuestionnaireAnswersOptions");
	AssignmentParameters.CommandBar = Items.AnswersOptionsTableCommandBar;
	AssignmentParameters.GroupsPrefix = "QuestionnaireAnswersOptions";
	AttachableCommands.OnCreateAtServer(ThisObject, AssignmentParameters);
	// End StandardSubsystems.AttachableCommands
	
	DescriptionBeforeEditing = Object.Description;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Object.Ref.IsEmpty() Then
		OnChangeAnswerType();
	EndIf;
	VisibilityManagement();
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If Object.ReplyType = PredefinedValue("Enum.QuestionAnswerTypes.Number") Then
		
		If Object.MinValue > Object.MaxValue Then
			CommonClient.MessageToUser(
				NStr("ru = 'Минимально допустимое значение не может быть больше чем максимальное.'; en = 'The minimum allowed value cannot be greater than the maximum allowed value.'; pl = 'The minimum allowed value cannot be greater than the maximum allowed value.';de = 'The minimum allowed value cannot be greater than the maximum allowed value.';ro = 'The minimum allowed value cannot be greater than the maximum allowed value.';tr = 'The minimum allowed value cannot be greater than the maximum allowed value.'; es_ES = 'The minimum allowed value cannot be greater than the maximum allowed value.'"),,
				"Object.MinValue");
			Cancel = True;
		EndIf;
		
	ElsIf Object.ReplyType = PredefinedValue("Enum.QuestionAnswerTypes.String") Then	
		
		Object.Length = StringLength;
		If StringLength = 0 Then
			CommonClient.MessageToUser(NStr("ru = 'Не заполнено значение длины строки.'; en = 'The string length is not specified.'; pl = 'The string length is not specified.';de = 'The string length is not specified.';ro = 'The string length is not specified.';tr = 'The string length is not specified.'; es_ES = 'The string length is not specified.'"),,"StringLength");
			Cancel = True;
		EndIf;
		
	ElsIf Object.ReplyType = PredefinedValue("Enum.QuestionAnswerTypes.Text") Then
		
		Object.Length = 1024;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	AnswersOptionsTableAvailability(ThisObject);
	CommonClientServer.SetDynamicListFilterItem(AnswersOptions,
	                                                                        "Owner",
	                                                                        Object.Ref,
	                                                                        DataCompositionComparisonType.Equal,
	                                                                        ,
	                                                                        True);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AnswerTypeOnChange(Item)
	
	OnChangeAnswerType();
	
EndProcedure

&AtClient
Procedure AnswersOptionsTableBeforeAdd(Item, Cancel, Clone, Parent, Folder)
	
	Cancel = True;
	OpenQuestionnaireAnswersQuestionsCatalogItemForm(Item,True);
	
EndProcedure

&AtClient
Procedure CommentOnChangeIsRequired(Item)
	
	CommentNoteRequiredAvailable();
	
EndProcedure

&AtClient
Procedure DescriptionOnChange(Item)
	
	If Object.Wording = DescriptionBeforeEditing Then
	
		Object.Wording = Object.Description;
	
	EndIf;
	
	DescriptionBeforeEditing = Object.Description;
	
EndProcedure

&AtClient
Procedure AnswersOptionsTableBeforeChange(Item, Cancel)
	
	Cancel = True;
	OpenQuestionnaireAnswersQuestionsCatalogItemForm(Item,False);
	
EndProcedure

&AtClient
Procedure AnswersOptionsTableChoice(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	OpenQuestionnaireAnswersQuestionsCatalogItemForm(Item,False);
	
EndProcedure

&AtClient
Procedure LengthOnChange(Item)
	
	SetPrecisionBasedOnNumberLength();
	
	ClearMarkIncomplete();
	
EndProcedure

&AtClient
Procedure PrecisionOnChange(Item)
	
	SetPrecisionBasedOnNumberLength();
	
EndProcedure

&AtClient
Procedure PresentationStartChoice(Item, ChoiceData, StandardProcessing)
	
	OnCloseNotify = New NotifyDescription("WordingEditOnClose", ThisObject);
	CommonClient.ShowMultilineTextEditingForm(OnCloseNotify, Item.EditText, NStr("ru = 'Формулировка'; en = 'Wording'; pl = 'Wording';de = 'Wording';ro = 'Wording';tr = 'Wording'; es_ES = 'Wording'"));
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	If StrStartsWith(Command.Name, "QuestionnaireAnswersOptions") Then
		AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.AnswersOptionsTable);
	Else
		AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Object);
	EndIf;
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result)
	If StrStartsWith(Context.CommandNameInForm, "QuestionnaireAnswersOptions") Then
		AttachableCommands.ExecuteCommand(ThisObject, Context, Items.AnswersOptionsTable, Result);
	Else
		AttachableCommands.ExecuteCommand(ThisObject, Context, Object, Result);
	EndIf;
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.AnswersOptionsTable);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Length.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Length");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	FIlterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FIlterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FIlterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ReplyType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.QuestionAnswerTypes.String;

	ItemFilter = FIlterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ReplyType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.QuestionAnswerTypes.Number;

	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReplyType.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ReplyType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.QuestionAnswerTypes.InfobaseValue;

	Item.Appearance.SetParameterValue("MarkIncomplete", True);

EndProcedure

// Controls visibility of pages and form items.
&AtClient
Procedure VisibilityManagement()
	
	CommentPossible = NOT (Object.ReplyType = PredefinedValue("Enum.QuestionAnswerTypes.MultipleOptionsFor") 
	                        OR Object.ReplyType = PredefinedValue("Enum.QuestionAnswerTypes.Text"));
	Items.CommentRequired.Enabled  = CommentPossible;
	Items.Comment.Enabled           = CommentPossible;
	If NOT CommentPossible Then
		Object.CommentRequired = False;
		Object.CommentNote = "";
	EndIf;
	CommentNoteRequiredAvailable();
	
	If Object.ReplyType = PredefinedValue("Enum.QuestionAnswerTypes.String") Then 
		
		Items.DependentParameters.CurrentPage = Items.StringPage;
		
	ElsIf Object.ReplyType = PredefinedValue("Enum.QuestionAnswerTypes.Number") Then
		
		Items.DependentParameters.CurrentPage = Items.NumericAttributesPage;
		
	ElsIf Object.ReplyType = PredefinedValue("Enum.QuestionAnswerTypes.InfobaseValue") Then
		
		Items.DependentParameters.CurrentPage = Items.Empty;
	
	ElsIf Object.ReplyType = PredefinedValue("Enum.QuestionAnswerTypes.OneVariantOf") 
	      OR Object.ReplyType = PredefinedValue("Enum.QuestionAnswerTypes.MultipleOptionsFor") Then
		
		Items.DependentParameters.CurrentPage = Items.AnswersOptions; 
		
		AnswersOptionsTableAvailability(ThisObject);
		
	Else
		
		Items.DependentParameters.CurrentPage = Items.Empty;
		
	EndIf;
	
	If Object.ReplyType = PredefinedValue("Enum.QuestionAnswerTypes.OneVariantOf") Then
		
		Items.RadioButtonTypeGroup.CurrentPage = Items.ShowRadioButtonType;
		
	ElsIf Object.ReplyType = PredefinedValue("Enum.QuestionAnswerTypes.Boolean") Then
		
		Items.RadioButtonTypeGroup.CurrentPage = Items.ShowRadioButtonTypeBooleanTypeGroup;
		
	Else
		
		Items.RadioButtonTypeGroup.CurrentPage = Items.HideRadioButtonTypeGroup;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnChangeAnswerType()

	If TypeOf(ReplyType) = Type("EnumRef.QuestionAnswerTypes") Then
		
		Object.ReplyType = ReplyType;
		
	ElsIf TypeOf(ReplyType) = Type("TypeDescription") Then
		
		Object.ReplyType   = PredefinedValue("Enum.QuestionAnswerTypes.InfobaseValue");
		Object.ValueType = ReplyType;
		
	EndIf;
	
	VisibilityManagement();
	
	If Object.ReplyType = PredefinedValue("Enum.QuestionAnswerTypes.Number") Then
		SetPrecisionBasedOnNumberLength();
	EndIf;

EndProcedure 

&AtClient
Procedure CommentNoteRequiredAvailable()
	
	Items.CommentNote.AutoMarkIncomplete = Object.CommentRequired;
	Items.CommentNote.ReadOnly            = NOT Object.CommentRequired;
	
	ClearMarkIncomplete();
	
EndProcedure

&AtClientAtServerNoContext
Procedure AnswersOptionsTableAvailability(Form)
	
	If Form.Object.Ref.IsEmpty() Then
		Form.Items.AnswersOptionsTable.ReadOnly  = True;
		Form.AnswersOptionsInfo                       = NStr("ru = 'Для редактирования вариантов ответов необходимо записать вопрос для анкетирования'; en = 'To edit the response options, write a survey question.'; pl = 'To edit the response options, write a survey question.';de = 'To edit the response options, write a survey question.';ro = 'To edit the response options, write a survey question.';tr = 'To edit the response options, write a survey question.'; es_ES = 'To edit the response options, write a survey question.'");
	Else
		Form.Items.AnswersOptionsTable.ReadOnly = False;
		Form.AnswersOptionsInfo                      = NStr("ru = 'Варианты ответов на вопрос:'; en = 'Possible responses to questions:'; pl = 'Possible responses to questions:';de = 'Possible responses to questions:';ro = 'Possible responses to questions:';tr = 'Possible responses to questions:'; es_ES = 'Possible responses to questions:'");
	EndIf; 
	
	If Form.ReplyType = PredefinedValue("Enum.QuestionAnswerTypes.OneVariantOf") Then
		Form.Items.OpenEndedQuestion.Visible = False;
	ElsIf Form.ReplyType = PredefinedValue("Enum.QuestionAnswerTypes.MultipleOptionsFor") Then
		Form.Items.OpenEndedQuestion.Visible = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenQuestionnaireAnswersQuestionsCatalogItemForm(Item,InsertMode)
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("Owner",Object.Ref);
	ParametersStructure.Insert("ReplyType",Object.ReplyType);
	ParametersStructure.Insert("Description",Object.ReplyType);
	
	If Not InsertMode Then
		CurrentData = Items.AnswersOptionsTable.CurrentData;
		If CurrentData = Undefined Then
			Return;
		EndIf;
		ParametersStructure.Insert("Key",CurrentData.Ref);
	Else
		CurrentData = Items.AnswersOptionsTable.CurrentData;
		If CurrentData <> Undefined Then
			ParametersStructure.Insert("Description",CurrentData.Description);
		EndIf;
	EndIf;
		
	OpenForm("Catalog.QuestionnaireAnswersOptions.Form.ItemForm",ParametersStructure,Item);
	
EndProcedure

&AtServer
Procedure SetAnswerType()
	
	For each EnumValue In Metadata.Enums.QuestionAnswerTypes.EnumValues Do
		
		If Enums.QuestionAnswerTypes[EnumValue.Name] = Enums.QuestionAnswerTypes.InfobaseValue Then 
			
			For each AvailableType In FormAttributeToValue("Object").Metadata().Type.Types() Do
				
				If AvailableType = Type("String") OR AvailableType = Type("Boolean") OR AvailableType = Type("Number") OR AvailableType = Type("Date") OR AvailableType = Type("CatalogRef.QuestionnaireAnswersOptions") Then
					Continue;
				EndIf;
				
				TypesArray = New Array;
				TypesArray.Add(AvailableType);
				Items.ReplyType.ChoiceList.Add(New TypeDescription(TypesArray));
				
			EndDo;
			
		Else
			Items.ReplyType.ChoiceList.Add(Enums.QuestionAnswerTypes[EnumValue.Name]);
		EndIf;
		
	EndDo;
	
	If Object.ReplyType = Enums.QuestionAnswerTypes.InfobaseValue Then
		
		ReplyType = Object.ValueType;
		
	ElsIf Object.ReplyType = Enums.QuestionAnswerTypes.EmptyRef() Then
		
		ReplyType = Items.ReplyType.ChoiceList[0].Value;
		
	Else
		
		ReplyType = Object.ReplyType;
		
	EndIf;
	
EndProcedure

// Sets precision of a numerical answer based on the selected length.
//
&AtClient
Procedure SetPrecisionBasedOnNumberLength()

	If Object.Length > 15 Then
		Object.Length = 15;
	EndIf;
	
	If Object.Length = 0 Then
		Object.Accuracy = 0;
	ElsIf Object.Length <= Object.Accuracy Then
		Object.Accuracy = Object.Length - 1;
	EndIf;
	
	If Object.Accuracy > 3 Then
		Object.Accuracy = 3;
	EndIf;
	
	If (Object.Length - Object.Accuracy) > 12 Then
		Object.Length = Object.Accuracy + 12;
	EndIf;
	
EndProcedure

&AtClient
Procedure WordingEditOnClose(ReturnText, AdditionalParameters) Export
	
	If Object.Wording <> ReturnText Then
		Object.Wording = ReturnText;
		Modified = True;
	EndIf;
	
EndProcedure

#EndRegion
