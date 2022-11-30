///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var ListDataPresentations;

#EndRegion

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Title = Parameters.DataPresentation;
	
	For each Presentation In Parameters.ListDataPresentations Do
		List.Add().Presentation = Presentation;
	EndDo;
	
EndProcedure

&AtClient
Procedure ListChoice(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	OpenData();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure SetPresentationList(PresentationsList, Context) Export
	
	ListDataPresentations = PresentationsList;
	
	Context = New NotifyDescription("SetPresentationList", ThisObject, Context);
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure ListOpen()
	
	OpenData();
	
EndProcedure

&AtClient
Procedure OpenData()
	
	If Items.List.CurrentRow = Undefined Then
		Return;
	EndIf;
	
	Row = List.FindByID(Items.List.CurrentRow);
	If Row = Undefined Then
		Return;
	EndIf;
	Index = List.IndexOf(Row);
	
	Value = ListDataPresentations[Index].Value;
	
	If TypeOf(Value) = Type("NotifyDescription") Then
		ExecuteNotifyProcessing(Value);
	Else
		ShowValue(, Value);
	EndIf;
	
EndProcedure

#EndRegion
