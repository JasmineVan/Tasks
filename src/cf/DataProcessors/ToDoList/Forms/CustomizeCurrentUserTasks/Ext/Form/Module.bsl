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
	
	ViewSettings = ToDoListInternal.SavedViewSettings();
	FillUserTaskTree(ViewSettings);
	SetSectionOrder(ViewSettings);
	
	AutoRefreshSettings = Common.CommonSettingsStorageLoad("ToDoList", "AutoUpdateSettings");
	If TypeOf(AutoRefreshSettings) = Type("Structure") Then
		AutoRefreshSettings.Property("AutoRefreshEnabled", UseAutoUpdate);
		AutoRefreshSettings.Property("AutoRefreshPeriod", UpdatePeriod);
	Else
		UpdatePeriod = 5;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ShownUserTasksTreeOnChange(Item)
	
	Modified = True;
	If Item.CurrentData.IsSection Then
		For Each ToDoItem In Item.CurrentData.GetItems() Do
			ToDoItem.Check = Item.CurrentData.Check;
		EndDo;
	ElsIf Item.CurrentData.Check Then
		Item.CurrentData.GetParent().Check = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure OKButton(Command)
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	SaveSettings();
	
	If AutoUpdateEnabled Then
		Notify("ToDoList_AutoUpdateEnabled");
	ElsIf AutoUpdateDisabled Then
		Notify("ToDoList_AutoUpdateDisabled");
	EndIf;
	
	Close(Modified);
	
EndProcedure

&AtClient
Procedure CancelButton(Command)
	Close(False);
EndProcedure

&AtClient
Procedure MoveUp(Command)
	
	Modified = True;
	// Move the current row up one position.
	CurrentTreeRow = Items.DisplayedUserTasksTree.CurrentData;
	
	If CurrentTreeRow.IsSection Then
		TreeSections = DisplayedUserTasksTree.GetItems();
	Else
		UserTaskParent = CurrentTreeRow.GetParent();
		TreeSections= UserTaskParent.GetItems();
	EndIf;
	
	CurrentRowIndex = CurrentTreeRow.IndexOf;
	If CurrentRowIndex = 0 Then
		Return; // The current row is at the top of the list. Do not move.
	EndIf;
	TreeSections.Move(CurrentTreeRow.IndexOf, -1);
	CurrentTreeRow.IndexOf = CurrentRowIndex - 1;
	// Change the previous row index.
	PreviousString = TreeSections.Get(CurrentRowIndex);
	PreviousString.IndexOf = CurrentRowIndex;
	If PreviousString.Hidden Then
		MoveUp(Undefined);
	EndIf;
	
EndProcedure

&AtClient
Procedure MoveDown(Command)
	
	Modified = True;
	// Move the current row down one position.
	CurrentTreeRow = Items.DisplayedUserTasksTree.CurrentData;
	
	If CurrentTreeRow.IsSection Then
		TreeSections = DisplayedUserTasksTree.GetItems();
	Else
		UserTaskParent = CurrentTreeRow.GetParent();
		TreeSections= UserTaskParent.GetItems();
	EndIf;
	
	CurrentRowIndex = CurrentTreeRow.IndexOf;
	If CurrentRowIndex = (TreeSections.Count() -1) Then
		Return; // The current row is at the bottom of the list. Do not move.
	EndIf;
	TreeSections.Move(CurrentTreeRow.IndexOf, 1);
	CurrentTreeRow.IndexOf = CurrentRowIndex + 1;
	// Change the next row index.
	NextRow = TreeSections.Get(CurrentRowIndex);
	NextRow.IndexOf = CurrentRowIndex;
	If NextRow.Hidden Then
		MoveDown(Undefined);
	EndIf;
	
EndProcedure

&AtClient
Procedure ClearAll(Command)
	
	Modified = True;
	For Each SectionRow In DisplayedUserTasksTree.GetItems() Do
		SectionRow.Check = False;
		For Each UserTaskRow In SectionRow.GetItems() Do
			UserTaskRow.Check = False;
		EndDo;
	EndDo;
	
EndProcedure

&AtClient
Procedure SelectAll(Command)
	
	Modified = True;
	For Each SectionRow In DisplayedUserTasksTree.GetItems() Do
		SectionRow.Check = True;
		For Each UserTaskRow In SectionRow.GetItems() Do
			UserTaskRow.Check = True;
		EndDo;
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillUserTaskTree(ViewSettings)
	
	ToDoList   = GetFromTempStorage(Parameters.ToDoList);
	UserTasksTree     = FormAttributeToValue("DisplayedUserTasksTree");
	CurrentSection = "";
	Index        = 0;
	ToDoItemIndex    = 0;
	TreeRow  = Undefined;
	
	If ViewSettings = Undefined Then
		ToDoListInternal.SetInitialSectionsOrder(ToDoList);
	EndIf;
	
	For Each ToDoItem In ToDoList Do
		
		If ToDoItem.IsSection
			AND CurrentSection <> ToDoItem.OwnerID Then
			If TreeRow <> Undefined Then
				RowsFilter = New Structure;
				RowsFilter.Insert("Hidden", False);
				NotHidden = TreeRow.Rows.FindRows(RowsFilter);
				TreeRow.Hidden = (NotHidden.Count() = 0);
			EndIf;
			
			TreeRow = UserTasksTree.Rows.Add();
			TreeRow.Presentation = ToDoItem.SectionPresentation;
			TreeRow.ID = ToDoItem.OwnerID;
			TreeRow.IsSection     = True;
			TreeRow.Check       = True;
			TreeRow.IndexOf        = Index;
			
			If ViewSettings <> Undefined Then
				SectionVisible = ViewSettings.SectionsVisibility[TreeRow.ID];
				If SectionVisible <> Undefined Then
					TreeRow.Check = SectionVisible;
				EndIf;
			EndIf;
			Index     = Index + 1;
			ToDoItemIndex = 0;
			
		ElsIf Not ToDoItem.IsSection Then
			UserTaskParent = UserTasksTree.Rows.Find(ToDoItem.OwnerID, "ID", True);
			If UserTaskParent = Undefined Then
				Continue;
			EndIf;
			UserTaskParent.ToDoDetails = UserTaskParent.ToDoDetails + ?(IsBlankString(UserTaskParent.ToDoDetails), "", Chars.LF) + ToDoItem.Presentation;
			Continue;
		EndIf;
		
		UserTaskRow = TreeRow.Rows.Add();
		UserTaskRow.Presentation = ToDoItem.Presentation;
		UserTaskRow.ID = ToDoItem.ID;
		UserTaskRow.IsSection     = False;
		UserTaskRow.Check       = True;
		UserTaskRow.IndexOf        = ToDoItemIndex;
		UserTaskRow.Hidden       = ToDoItem.HideInSettings;
		
		If ViewSettings <> Undefined Then
			UserTaskVisible = ViewSettings.UserTasksVisible[UserTaskRow.ID];
			If UserTaskVisible <> Undefined Then
				UserTaskRow.Check = UserTaskVisible;
			EndIf;
		EndIf;
		ToDoItemIndex = ToDoItemIndex + 1;
		
		CurrentSection = ToDoItem.OwnerID;
		
	EndDo;
	
	ValueToFormAttribute(UserTasksTree, "DisplayedUserTasksTree");
	
EndProcedure

&AtServer
Procedure SaveSettings()
	
	PreviousViewSettings = Common.CommonSettingsStorageLoad("ToDoList", "ViewSettings");
	CollapsedSections = Undefined;
	If TypeOf(PreviousViewSettings) = Type("Structure") Then
		PreviousViewSettings.Property("CollapsedSections", CollapsedSections);
	EndIf;
	
	If CollapsedSections = Undefined Then
		CollapsedSections = New Map;
	EndIf;
	
	// Save section position and visibility.
	SectionsVisibility = New Map;
	UserTasksVisible      = New Map;
	
	UserTasksTree = FormAttributeToValue("DisplayedUserTasksTree");
	For Each Section In UserTasksTree.Rows Do
		SectionsVisibility.Insert(Section.ID, Section.Check);
		For Each ToDoItem In Section.Rows Do
			UserTasksVisible.Insert(ToDoItem.ID, ToDoItem.Check);
		EndDo;
	EndDo;
	
	Result = New Structure;
	Result.Insert("UserTasksTree", UserTasksTree);
	Result.Insert("SectionsVisibility", SectionsVisibility);
	Result.Insert("UserTasksVisible", UserTasksVisible);
	Result.Insert("CollapsedSections", CollapsedSections);
	
	Common.CommonSettingsStorageSave("ToDoList", "ViewSettings", Result);
	
	// Save auto refresh settings.
	AutoRefreshSettings = Common.CommonSettingsStorageLoad("ToDoList", "AutoUpdateSettings");
	
	If AutoRefreshSettings = Undefined Then
		AutoRefreshSettings = New Structure;
	Else
		If UseAutoUpdate Then
			AutoUpdateEnabled = AutoRefreshSettings.AutoRefreshEnabled <> UseAutoUpdate;
		Else
			AutoUpdateDisabled = AutoRefreshSettings.AutoRefreshEnabled <> UseAutoUpdate;
		EndIf;
	EndIf;
	
	AutoRefreshSettings.Insert("AutoRefreshEnabled", UseAutoUpdate);
	AutoRefreshSettings.Insert("AutoRefreshPeriod", UpdatePeriod);
	
	Common.CommonSettingsStorageSave("ToDoList", "AutoUpdateSettings", AutoRefreshSettings);
	
EndProcedure

&AtServer
Procedure SetSectionOrder(ViewSettings)
	
	If ViewSettings = Undefined Then
		Return;
	EndIf;
	
	UserTasksTree = FormAttributeToValue("DisplayedUserTasksTree");
	Sections   = UserTasksTree.Rows;
	SavedUserTaskTree = ViewSettings.UserTasksTree;
	For Each SectionRow In Sections Do
		SavedSection = SavedUserTaskTree.Rows.Find(SectionRow.ID, "ID");
		If SavedSection = Undefined Then
			Continue;
		EndIf;
		SectionRow.IndexOf = SavedSection.IndexOf;
		UserTasks = SectionRow.Rows;
		LastUserTaskIndex = UserTasks.Count() - 1;
		For Each RowUserTask In UserTasks Do
			SavedUserTask = SavedSection.Rows.Find(RowUserTask.ID, "ID");
			If SavedUserTask = Undefined Then
				RowUserTask.IndexOf = LastUserTaskIndex;
				LastUserTaskIndex = LastUserTaskIndex - 1;
				Continue;
			EndIf;
			RowUserTask.IndexOf = SavedUserTask.IndexOf;
		EndDo;
		UserTasks.Sort("IndexOf asc");
	EndDo;
	
	Sections.Sort("IndexOf asc");
	ValueToFormAttribute(UserTasksTree, "DisplayedUserTasksTree");
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DisplayedUserTasksTreeMark.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DisplayedUserTasksTreePresentation.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DisplayedUserTasksTree.Hidden");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	Item.Appearance.SetParameterValue("Visible", False);
	
EndProcedure

#EndRegion