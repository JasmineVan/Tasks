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
	
	// Filling the table of available sections.
	
	UsedSections = New Array;
	If Parameters.DataProcessorKind = Enums.AdditionalReportsAndDataProcessorsKinds.AdditionalDataProcessor Then
		UsedSections = AdditionalReportsAndDataProcessors.AdditionalDataProcessorSections();
	Else
		UsedSections = AdditionalReportsAndDataProcessors.AdditionalReportSections();
	EndIf;
	
	Desktop = AdditionalReportsAndDataProcessorsClientServer.StartPageName();
	
	For Each Section In UsedSections Do
		NewRow = Sections.Add();
		If Section = Desktop Then
			NewRow.Section = Catalogs.MetadataObjectIDs.EmptyRef();
		Else
			NewRow.Section = Common.MetadataObjectID(Section);
		EndIf;
		NewRow.Presentation = AdditionalReportsAndDataProcessors.SectionPresentation(NewRow.Section);
	EndDo;
	
	Sections.Sort("Presentation Asc");
	
	// Enabling sections
	
	For Each ListItem In Parameters.Sections Do
		FoundRow = Sections.FindRows(New Structure("Section", ListItem.Value));
		If FoundRow.Count() = 1 Then
			FoundRow[0].Used = True;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure OK(Command)
	
	SelectionResult = New ValueList;
	
	For Each ItemSection In Sections Do
		If ItemSection.Used Then
			SelectionResult.Add(ItemSection.Section);
		EndIf;
	EndDo;
	
	NotifyChoice(SelectionResult);
	
EndProcedure

#EndRegion
