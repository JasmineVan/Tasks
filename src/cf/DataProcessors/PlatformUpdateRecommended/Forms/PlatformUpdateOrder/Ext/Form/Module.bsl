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
	
	FileInfobase = Common.FileInfobase();
	If FileInfobase Then
		UpdateOrderTemplate = DataProcessors.PlatformUpdateRecommended.GetTemplate("FileInfobaseUpdateOrder");
	Else
		UpdateOrderTemplate = DataProcessors.PlatformUpdateRecommended.GetTemplate("ClientServerInfobaseUpdateOrder");
	EndIf;
	
	ApplicationUpdateOrder = UpdateOrderTemplate.GetText();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ApplicationUpdateOrderOnClick(Item, EventData, StandardProcessing)
	If EventData.Href <> Undefined Then
		StandardProcessing = False;
		FileSystemClient.OpenURL(EventData.Href);
	EndIf;
EndProcedure

&AtClient
Procedure PrintGuide(Command)
	Items.ApplicationUpdateOrder.Document.execCommand("Print");
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ApplicationUpdateOrderDocumentGenerated(Item)
	// Print command visibility
	If Not Item.Document.queryCommandSupported("Print") Then
		Items.PrintGuide.Visible = False;
	EndIf;
EndProcedure

#EndRegion