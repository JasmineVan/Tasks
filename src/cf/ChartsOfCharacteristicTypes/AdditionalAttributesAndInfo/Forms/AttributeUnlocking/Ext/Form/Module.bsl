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
	
	If PropertyManagerInternal.AdditionalPropertyUsed(Parameters.Ref) Then
		
		Items.UserDialogs.CurrentPage = Items.ObjectUsed;
		
		Items.AllowEditing.DefaultButton = True;
		
		If Parameters.IsAdditionalAttribute = True Then
			Items.Warnings.CurrentPage = Items.AdditionalAttributeWarning;
		Else
			Items.Warnings.CurrentPage = Items.AdditionalInfoWarning;
		EndIf;
		
		StandardSubsystemsServer.SetFormAssignmentKey(ThisObject, "PropertyUsed");
		Items.NoteButtons.Visible = False;
	Else
		Items.UserDialogs.CurrentPage = Items.ObjectNotUsed;
		Items.ObjectUsed.Visible = False; // For compact form display.
		
		Items.OK.DefaultButton = True;
		
		If Parameters.IsAdditionalAttribute = True Then
			Items.Notes.CurrentPage = Items.AdditionalAttributeNote;
		Else
			Items.Notes.CurrentPage = Items.AdditionalInfoNote;
		EndIf;
		
		StandardSubsystemsServer.SetFormAssignmentKey(ThisObject, "PropertyNotUsed");
		Items.WarningButtons.Visible = False;
	EndIf;
	
	If Common.IsMobileClient() Then
		CommandBarLocation = FormCommandBarLabelLocation.Top;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure AllowEditing(Command)
	
	AttributesToUnlock = New Array;
	AttributesToUnlock.Add("ValueType");
	AttributesToUnlock.Add("Name");
	
	Close(AttributesToUnlock);
	
EndProcedure

#EndRegion
