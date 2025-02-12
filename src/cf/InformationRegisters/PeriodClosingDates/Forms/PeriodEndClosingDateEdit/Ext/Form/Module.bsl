﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	UserPresentation = Parameters.UserPresentation;
	SectionPresentation       = Parameters.SectionPresentation;
	Object                    = Parameters.Object;
	PeriodEndClosingDateDetails       = Parameters.PeriodEndClosingDateDetails;
	PermissionDaysCount  = Parameters.PermissionDaysCount;
	PeriodEndClosingDate               = Parameters.PeriodEndClosingDate;
	If Not IsBlankString(Parameters.NoClosingDatePresentation) Then
		Items.PeriodEndClosingNotSet.ChoiceList[0].Presentation = Parameters.NoClosingDatePresentation;
	EndIf;	
	
	EnableDataChangeBeforePeriodEndClosingDate = PermissionDaysCount > 0;
	
	If Not ValueIsFilled(SectionPresentation)
	   AND Not ValueIsFilled(Object) Then
	   
		Items.SectionPresentation.Visible = False;
		Items.ObjectPresentation.Visible = False;
		StandardSubsystemsServer.SetFormAssignmentKey(ThisObject, "NoSectionOrObject");
		
	ElsIf Not ValueIsFilled(SectionPresentation) Then
		Items.SectionPresentation.Visible = False;
		StandardSubsystemsServer.SetFormAssignmentKey(ThisObject, "NoSection");
	
	ElsIf Not ValueIsFilled(Object) Then
		Items.ObjectPresentation.Visible = False;
		StandardSubsystemsServer.SetFormAssignmentKey(ThisObject, "NoObject");
		
	ElsIf ValueIsFilled(Object) Then
		If TypeOf(Object) = Type("String") Then
			Items.ObjectPresentation.TitleLocation = FormItemTitleLocation.None;
			Items.ObjectPresentation.Hyperlink = False;
		Else
			If Metadata.Documents.Contains(Object.Metadata()) Then
				ObjectPresentation = NStr("ru = 'Документ'; en = 'Document'; pl = 'Dokument';de = 'Dokument';ro = 'Document';tr = 'Belge'; es_ES = 'Documento'");
			ElsIf Metadata.Enums.Contains(Object.Metadata()) Then
				ObjectPresentation = NStr("ru = 'Элемент'; en = 'Item'; pl = 'Element';de = 'Artikel';ro = 'Articol';tr = 'Öğe'; es_ES = 'Artículo'");
				Items.ObjectPresentation.Hyperlink = False;
			Else	
				ObjectPresentation = Object.Metadata().ObjectPresentation;
				If IsBlankString(ObjectPresentation) Then
					ObjectPresentation = Object.Metadata().Presentation();
				EndIf;
			EndIf;
			Items.ObjectPresentation.Title = ObjectPresentation;
		EndIf;
	EndIf;
	
	If PeriodEndClosingDateDetails = "" Then // not set
		PeriodEndClosingDateDetails = "Custom";
	EndIf;
	
	// Caching the current date on the server.
	BegOfDay = CurrentSessionDate();
	PeriodClosingDatesInternalClientServer.SpecifyPeriodEndClosingDateSetupOnChange(ThisObject);
	PeriodClosingDatesInternalClientServer.UpdatePeriodEndClosingDateDisplayOnChange(ThisObject);
	
	If PeriodEndClosingDateDetails = "Custom" Then
		CurrentItem = Items.PeriodEndClosingDateSimpleMode;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	NotifyChoice(ReturnValue);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

////////////////////////////////////////////////////////////////////////////////
// Identical event handlers of PeriodClosingDates and EditPeriodEndClosingDate forms.

&AtClient
Procedure PeriodEndClosingDateDetailsOnChange(Item)
	
	PeriodClosingDatesInternalClientServer.SpecifyPeriodEndClosingDateSetupOnChange(ThisObject);
	AttachIdleHandler("UpdatePeriodEndClosingDateDisplayOnChangeIdleHandler", 0.1, True);
	
EndProcedure

&AtClient
Procedure PeriodEndClosingDateDetailsClear(Item, StandardProcessing)
	
	StandardProcessing = False;
	PeriodEndClosingDateDetails = Items.PeriodEndClosingDateDetails.ChoiceList[0].Value;
	PeriodClosingDatesInternalClientServer.SpecifyPeriodEndClosingDateSetupOnChange(ThisObject);
	AttachIdleHandler("UpdatePeriodEndClosingDateDisplayOnChangeIdleHandler", 0.1, True);
	
EndProcedure

&AtClient
Procedure PeriodEndClosingDateOnChange(Item)
	
	PeriodClosingDatesInternalClientServer.SpecifyPeriodEndClosingDateSetupOnChange(ThisObject);
	AttachIdleHandler("UpdatePeriodEndClosingDateDisplayOnChangeIdleHandler", 0.1, True);
	
EndProcedure

&AtClient
Procedure EnableDataChangeBeforePeriodEndClosingDateOnChange(Item)
	
	PeriodClosingDatesInternalClientServer.SpecifyPeriodEndClosingDateSetupOnChange(ThisObject);
	AttachIdleHandler("UpdatePeriodEndClosingDateDisplayOnChangeIdleHandler", 0.1, True);
	
EndProcedure

&AtClient
Procedure PermissionDaysCountOnChange(Item)
	
	PeriodClosingDatesInternalClientServer.SpecifyPeriodEndClosingDateSetupOnChange(ThisObject);
	AttachIdleHandler("UpdatePeriodEndClosingDateDisplayOnChangeIdleHandler", 0.1, True);
	
EndProcedure

&AtClient
Procedure PermissionDaysCountAutoComplete(Item, Text, ChoiceData, Wait, StandardProcessing)
	
	If IsBlankString(Text) Then
		Return;
	EndIf;
	
	PermissionDaysCount = Text;
	PeriodClosingDatesInternalClientServer.SpecifyPeriodEndClosingDateSetupOnChange(ThisObject);
	AttachIdleHandler("UpdatePeriodEndClosingDateDisplayOnChangeIdleHandler", 0.1, True);
	
EndProcedure

&AtClient
Procedure ObjectPresentationClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	ShowValue(, Object);
	
EndProcedure

&AtClient
Procedure MoreOptionsClick(Item)
	
	ExtendedModeSelected = True;
	Items.ExtendedMode.Visible = True;
	Items.OperationModesGroup.CurrentPage = Items.ExtendedMode;
	
EndProcedure

&AtClient
Procedure LessOptionsClick(Item)
	
	ExtendedModeSelected = False;
	Items.ExtendedMode.Visible = False;
	Items.OperationModesGroup.CurrentPage = Items.SimpleMode;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure OK(Command)
	
	ReturnValue = New Structure;
	ReturnValue.Insert("PeriodEndClosingDateDetails", PeriodEndClosingDateDetails);
	
	If PeriodEndClosingDateDetails = "" Then
		ReturnValue.Insert("PermissionDaysCount", 0);
		ReturnValue.Insert("PeriodEndClosingDate",              '00010101');
	Else
		ReturnValue.Insert("PermissionDaysCount", PermissionDaysCount);
		ReturnValue.Insert("PeriodEndClosingDate",              PeriodEndClosingDate);
	EndIf;
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure UpdatePeriodEndClosingDateDisplayOnChangeIdleHandler()
	
	PeriodClosingDatesInternalClientServer.UpdatePeriodEndClosingDateDisplayOnChange(ThisObject);
	
EndProcedure

#EndRegion
