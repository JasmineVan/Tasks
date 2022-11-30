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
	Objects.Insert(Metadata.Catalogs.Notes.FullName(), "AttributesToEditInBatchProcessing");
EndProcedure

// See CommonOverridable.OnAddMetadataObjectsRenaming. 
Procedure OnAddMetadataObjectsRenaming(Total) Export
	
	Library = "StandardSubsystems";
	
	OldName = "Role.NotesUsage";
	NewName  = "Role.AddEditNotes";
	Common.AddRenaming(Total, "2.3.3.11", OldName, NewName, Library);
	
EndProcedure

// See ToDoListOverridable.OnDetermineToDoListHandlers 
Procedure OnFillToDoList(ToDoList) Export
	
	ModuleToDoListServer = Common.CommonModule("ToDoListServer");
	If Not AccessRight("Edit", Metadata.Catalogs.Notes)
		Or Not GetFunctionalOption("UseNotes")
		Or ModuleToDoListServer.UserTaskDisabled("UserNotes") Then
		Return;
	EndIf;
	
	// This procedure is only called when To-do list subsystem is available. Therefore, the subsystem 
	// availability check is redundant.
	Sections = ModuleToDoListServer.SectionsForObject(Metadata.Catalogs.Notes.FullName());
	
	NumberOfNotes = NumberOfNotes();
	
	For Each Section In Sections Do
		NoteID = "UserNotes" + StrReplace(Section.FullName(), ".", "");
		ToDoItem = ToDoList.Add();
		ToDoItem.ID = NoteID;
		ToDoItem.HasToDoItems      = NumberOfNotes > 0;
		ToDoItem.Presentation = NStr("ru = 'Мои заметки'; en = 'My notes'; pl = 'My notes';de = 'My notes';ro = 'My notes';tr = 'My notes'; es_ES = 'My notes'");
		ToDoItem.Count    = NumberOfNotes;
		ToDoItem.Form         = "Catalog.Notes.Form.AllNotes";
		ToDoItem.Owner      = Section;
	EndDo;
	
EndProcedure

// See UserRemindersOverridable.OnFillSourceAttributesListWithReminderDates. 
Procedure OnFillSourceAttributesListWithReminderDates(Source, AttributesArray) Export
	
	If TypeOf(Source) = Type("CatalogRef.Notes") Then
		AttributesArray.Clear();
	EndIf;
	
EndProcedure

// See AccessManagementOverridable.OnFillListsWithAccessRestriction. 
Procedure OnFillListsWithAccessRestriction(Lists) Export
	
	Lists.Insert(Metadata.Catalogs.Notes, True);
	
EndProcedure

#EndRegion

#Region Private

Procedure SetClearNotesDeletionMark(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	DeletionMark = Source.DeletionMark;
	If Not DeletionMark AND Not Source.AdditionalProperties.Property("DeletionMarkCleared") Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	Notes.Ref AS Ref
	|FROM
	|	Catalog.Notes AS Notes
	|WHERE
	|	Notes.DeletionMark = &DeletionMark
	|	AND &OwnerField = &Owner";
	
	OwnerField = "Notes.Topic";
	If TypeOf(Source) = Type("CatalogObject.Users") 
		AND (DeletionMark Or Source.AdditionalProperties.Property("DeletionMarkCleared")) Then
			OwnerField = "Notes.Author";
	EndIf;
	
	QueryText = StrReplace(QueryText, "&OwnerField", OwnerField);
	
	Query = New Query(QueryText);
	Query.SetParameter("Owner", Source.Ref);
	Query.SetParameter("DeletionMark", Not DeletionMark);
	
	SetPrivilegedMode(True);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		NoteObject = Selection.Ref.GetObject();
		NoteObject.SetDeletionMark(DeletionMark, False);
		NoteObject.AdditionalProperties.Insert("NoteDeletionMark", True);
		Try
			NoteObject.Write();
		Except
			ErrorText = DetailErrorDescription(ErrorInfo());
			WriteLogEvent(NStr("ru = 'Заметки пользователя.Изменение пометки удаления'; en = 'User notes.Change deletion mark'; pl = 'User notes.Change deletion mark';de = 'User notes.Change deletion mark';ro = 'User notes.Change deletion mark';tr = 'User notes.Change deletion mark'; es_ES = 'User notes.Change deletion mark'", Common.DefaultLanguageCode()),
				EventLogLevel.Error, NoteObject.Metadata(), NoteObject.Ref, ErrorText);
		EndTry;
	EndDo;
	
EndProcedure

// Adds a flag of changing object deletion mark.
Procedure SetDeletionMarkChangeStatus(Source) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	If Not Source.DeletionMark Then
		DeletionMarkByRef = Common.ObjectAttributeValue(Source.Ref, "DeletionMark");
		If DeletionMarkByRef = True Then
			Source.AdditionalProperties.Insert("DeletionMarkCleared");
		EndIf;
	EndIf;
	
EndProcedure

Function NumberOfNotes()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	COUNT(CatalogNotes.Ref) AS Count
	|FROM
	|	Catalog.Notes AS CatalogNotes
	|WHERE
	|	CatalogNotes.Author = &User
	|		AND NOT CatalogNotes.DeletionMark";
	
	Query.SetParameter("User", Users.CurrentUser());
	
	QueryResult = Query.Execute().Unload();
	Return QueryResult[0].Count;
	
EndFunction

#EndRegion
