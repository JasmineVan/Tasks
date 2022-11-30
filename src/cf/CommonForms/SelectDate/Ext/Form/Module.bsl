///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var ActionSelected;

#EndRegion

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	InitialValue = Parameters.InitialValue;
	
	If Not ValueIsFilled(InitialValue) Then
		InitialValue = CurrentSessionDate();
	EndIf;
	
	Parameters.Property("BeginOfRepresentationPeriod", Items.Calendar.BeginOfRepresentationPeriod);
	Parameters.Property("EndOfRepresentationPeriod", Items.Calendar.EndOfRepresentationPeriod);
	
	Calendar = InitialValue;
	
	Parameters.Property("Title", Title);
	
	If Parameters.Property("NoteText") Then
		Items.NoteText.Title = Parameters.NoteText;
	Else
		Items.NoteText.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	If ActionSelected <> True Then
		NotifyChoice(Undefined);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CalendarChoice(Item, SelectedDate)
	
	ActionSelected = True;
	NotifyChoice(SelectedDate);
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure OK(Command)
	
	SelectedDates = Items.Calendar.SelectedDates;
	
	If SelectedDates.Count() = 0 Then
		ShowMessageBox(,NStr("ru = 'Дата не выбрана.'; en = 'Please select a date.'; pl = 'Data nie jest wybrana.';de = 'Datum ist nicht ausgewählt.';ro = 'Data nu este selectată.';tr = 'Tarih seçilmedi.'; es_ES = 'Fecha no está seleccionada.'"));
		Return;
	EndIf;
	
	ActionSelected = True;
	NotifyChoice(SelectedDates[0]);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	ActionSelected = True;
	NotifyChoice(Undefined);
	
EndProcedure

#EndRegion

