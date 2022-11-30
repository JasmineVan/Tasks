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

	List.Parameters.SetParameterValue("User", Users.CurrentUser());
	List.Parameters.SetParameterValue("Topic", "");
	List.Parameters.SetParameterValue("Check", Enums.NoteColors.EmptyRef());
	List.Parameters.SetParameterValue("ShowDeleted", False);
	
	FillInSelectFilterBySubjectList();
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	#If WebClient Then 
	Items.FilterByColor.ChoiceList.Insert(0, PredefinedValue("Enum.NoteColors.EmptyRef")," ");
	#EndIf
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
   	List.Parameters.SetParameterValue("Topic", "%" + SelectedSubject + "%");
	List.Parameters.SetParameterValue("Check", SelectedColor);
	List.Parameters.SetParameterValue("ShowDeleted", ShowDeleted);
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterBySubjectOnChange(Item)
	List.Parameters.SetParameterValue("Topic", "%" + SelectedSubject + "%");
EndProcedure

&AtClient
Procedure FilterByColorOnChange(Item)
	List.Parameters.SetParameterValue("Check", SelectedColor);
EndProcedure

&AtClient
Procedure ShowDeletedItemsOnChange(Item)
	List.Parameters.SetParameterValue("ShowDeleted", ShowDeleted);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillInSelectFilterBySubjectList()
	
	Query = New Query;
	
	QueryText = 
	"SELECT ALLOWED
	|	Notes.SubjectPresentation AS SubjectPresentation
	|FROM
	|	Catalog.Notes AS Notes
	|WHERE
	|	Notes.IsFolder = FALSE
	|	AND Notes.DeletionMark = FALSE
	|	AND Notes.Author = &User
	|
	|GROUP BY
	|	Notes.SubjectPresentation
	|
	|ORDER BY
	|	SubjectPresentation";
	
	Query.SetParameter("User", Users.CurrentUser());
	Query.Text = QueryText;
	Selection = Query.Execute().Select();

	While Selection.Next() Do
		Items.FilterBySubject.ChoiceList.Add(Selection.SubjectPresentation);
	EndDo;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	List.ConditionalAppearance.Items.Clear();
	Item = List.ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ForDesktop");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DeletionMark");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Font", New Font(,,True));
	
EndProcedure

#EndRegion
