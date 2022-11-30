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
	
	If Parameters.Property("Topic") Then 
		Object.Topic = Parameters.Topic;
		Object.SubjectPresentation = Common.SubjectString(Object.Topic);
	EndIf;
	
	Items.Topic.Title = Object.SubjectPresentation;
	Items.SubjectGroup.Visible = ValueIsFilled(Object.Topic);
	
	If Object.Ref.IsEmpty() Then
		Object.Author = Users.CurrentUser();
		FormattedText = Parameters.CopyingValue.Content.Get();
		
		Items.NoteDate.Title = NStr("ru = 'Не записано'; en = 'Not written'; pl = 'Not written';de = 'Not written';ro = 'Not written';tr = 'Not written'; es_ES = 'Not written'")
	Else
		Items.NoteDate.Title = NStr("ru = 'Записано'; en = 'Written'; pl = 'Written';de = 'Written';ro = 'Written';tr = 'Written'; es_ES = 'Written'") + ": " + Format(Object.ChangeDate, "DLF=DDT");
	EndIf;
	
	SetVisibility();
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	FormattedText = CurrentObject.Content.Get();

	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.AccessManagement

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	CurrentObject.Content = New ValueStorage(FormattedText, New Deflation(9));
	
	HTMLText = "";
	Attachments = New Structure;
	FormattedText.GetHTML(HTMLText, Attachments);
	
	CurrentObject.ContentText = StringFunctionsClientServer.ExtractTextFromHTML(HTMLText);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	EndIf;
	// End StandardSubsystems.AccessManagement

	Items.NoteDate.Title = NStr("ru = 'Записано'; en = 'Written'; pl = 'Written';de = 'Written';ro = 'Written';tr = 'Written'; es_ES = 'Written'") + ": " + Format(Object.ChangeDate, "DLF=DDT");
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	NotifyChanged(Object.Ref);
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SubjectClick(Item)
	ShowValue(,Object.Topic);
EndProcedure

&AtClient
Procedure AuthorClick(Item)
	ShowValue(,Object.Author);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetVisibility()
	Items.Author.Title = Object.Author;
	OpenedByAuthor = Object.Author = Users.CurrentUser();
	Items.DisplayParameters.Visible = OpenedByAuthor;
	Items.AuthorInfo.Visible = Not OpenedByAuthor;
	
	ReadOnly = Not OpenedByAuthor;
	Items.Content.ReadOnly = Not OpenedByAuthor;
	Items.EditingCommandBar.Visible = OpenedByAuthor;
EndProcedure

#EndRegion
