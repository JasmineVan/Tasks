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
	
	If Object.Ref.IsEmpty() Then
		
		InitializeComposerServer(Undefined);
		
	EndIf;
	
	FillDescriptionChoiceList(ThisObject);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	SavedSettingsComposer = CurrentObject.SettingsComposer.Get();
	InitializeComposerServer(SavedSettingsComposer);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	CurrentObject.SettingsComposer = New ValueStorage(SettingsComposer.GetSettings());
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	Notify("Write_InteractionTabs", WriteParameters, Object.Ref);
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SettingsComposerSettingsFilterOnChange(Item)
	
	FillDescriptionChoiceList(ThisObject);
	
EndProcedure

&AtClient
Procedure DescriptionOnChange(Item)
	
	FillDescriptionChoiceList(ThisObject);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure InitializeComposerServer(CompositionSetup)
	
	CompositionSchema = DocumentJournals.Interactions.GetTemplate("SchemaInteractionsFilter");
	SchemaURL = PutToTempStorage(CompositionSchema, UUID);
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(SchemaURL));
	
	If CompositionSetup = Undefined Then
		SettingsComposer.LoadSettings(CompositionSchema.DefaultSettings);
	Else
		SettingsComposer.LoadSettings(CompositionSetup);
		SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillDescriptionChoiceList(Form)
	
	ChoiceList = Form.Items.Description.ChoiceList;
	
	ChoiceList.Clear();
	If Not IsBlankString(Form.Object.Description) Then
		ChoiceList.Add(Form.Object.Description);
	EndIf;
	FilterPresentation = String(Form.SettingsComposer.Settings.Filter);
	If Form.Object.Description <> FilterPresentation Then
		ChoiceList.Add(FilterPresentation);
	EndIf;
	
EndProcedure

#EndRegion
