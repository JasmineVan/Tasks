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
	
	If NOT Parameters.Property("QuestionnaireTemplate") Then
		Cancel = True;
		Return;
	Else
		QuestionnaireTemplate = Parameters.QuestionnaireTemplate;
	EndIf;
	
	SetFormAttributesValuesAccordingToQuestionnaireTemplate();
	Survey.SetQuestionnaireSectionsTreeItemIntroductionConclusion(SectionsTree,"Introduction");
	Survey.FillSectionsTree(ThisObject,SectionsTree);
	Survey.SetQuestionnaireSectionsTreeItemIntroductionConclusion(SectionsTree,"Conclusion");
	QuestioningClientServer.GenerateTreeNumbering(SectionsTree,True);
	
	Items.SectionsTree.CurrentRow = 0;
	CreateFormAccordingToSection();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SectionsNavigationButtonAvailabilityControl();
	
EndProcedure 

#EndRegion

#Region FormHeaderItemsEventHandlers

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
Procedure Attachable_OnChangeQuestionsWithConditions(Item)

	AvailabilityControlSubordinateQuestions();

EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure HideShowSectionsTree(Command)

	ChangeSectionsTreeVisibility();
	
EndProcedure

&AtClient
Procedure PreviousSection(Command)
	
	ChangeSection("Back");
	
EndProcedure

&AtClient
Procedure NextSection(Command)
	
	ChangeSection("Forward");
	
EndProcedure

&AtClient
Procedure SectionChoice(Command)
	
	ExecuteFillingFormCreation();
	SectionsNavigationButtonAvailabilityControl();

EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

EndProcedure

// Used for creating a filling form.
&AtServer
Procedure CreateFormAccordingToSection()
	
	// Determine the selected section.
	CurrentDataSectionsTree = SectionsTree.FindByID(Items.SectionsTree.CurrentRow);
	If CurrentDataSectionsTree = Undefined Then
		Return;
	EndIf;
	
	CurrentSectionNumber = Items.SectionsTree.CurrentRow;
	Survey.CreateFillingFormBySection(ThisObject,CurrentDataSectionsTree);
	Survey.GenerateQuestionsSubordinationTable(ThisObject);
	
	Items.FooterPreviousSection.Visible = (SectionQuestionsTable.Count() > 0);
	Items.FooterNextSection.Visible  = (SectionQuestionsTable.Count() > 0);
	
	QuestioningClientServer.SwitchQuestionnaireBodyGroupsVisibility(ThisObject, True);
	
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
	AvailabilityControlSubordinateQuestions();
	SectionsNavigationButtonAvailabilityControl();
	
EndProcedure

// Manages availability of navigation buttons by sections.
&AtClient
Procedure SectionsNavigationButtonAvailabilityControl()
	
	Items.PreviousSection.Visible       = (Items.SectionsTree.CurrentRow <> 0);
	Items.FooterPreviousSection.Visible = (Items.SectionsTree.CurrentRow > 0);
	Items.NextSection.Visible        = (SectionsTree.FindByID(Items.SectionsTree.CurrentRow +  1) <> Undefined);
	Items.FooterNextSection.Visible  = (SectionsTree.FindByID(Items.SectionsTree.CurrentRow +  1) <> Undefined);
	
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

// Changes visibility of the sections tree.
&AtClient
Procedure ChangeSectionsTreeVisibility()

	Items.SectionsTreeGroup.Visible         = NOT Items.SectionsTreeGroup.Visible;
	Items.HideShowSectionsTree.Title = ?(Items.SectionsTreeGroup.Visible,NStr("ru = 'Скрыть разделы'; en = 'Hide sections'; pl = 'Hide sections';de = 'Hide sections';ro = 'Hide sections';tr = 'Hide sections'; es_ES = 'Hide sections'"), NStr("ru = 'Показать разделы'; en = 'Show sections'; pl = 'Show sections';de = 'Show sections';ro = 'Show sections';tr = 'Show sections'; es_ES = 'Show sections'"));

EndProcedure 

// Manages availability of form items.
&AtClient
Procedure AvailabilityControlSubordinateQuestions()
	
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
	
EndProcedure 

// Sets values of form attributes defined in a questionnaire template.
//
&AtServer
Procedure SetFormAttributesValuesAccordingToQuestionnaireTemplate()

	AttributesQuestionnaireTemplate = Common.ObjectAttributesValues(QuestionnaireTemplate,"Title,Introduction,Conclusion");
	FillPropertyValues(ThisObject,AttributesQuestionnaireTemplate);

EndProcedure

#EndRegion
