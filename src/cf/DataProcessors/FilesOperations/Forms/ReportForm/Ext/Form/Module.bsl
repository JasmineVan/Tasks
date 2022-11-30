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
	
	Report = FilesOperationsInternal.FilesImportGenerateReport(Parameters.ArrayOfFilesNamesWithErrors);
	
	If Parameters.Property("Title") Then
		Title = Parameters.Title;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ReportChoice(Item, Area, StandardProcessing)
	
#If Not WebClient Then
	// Path to file.
	If StrFind(Area.Text, ":\") > 0 OR StrFind(Area.Text, ":/") > 0 Then
		FilesOperationsInternalClient.OpenExplorerWithFile(Area.Text);
	EndIf;
#EndIf
	
EndProcedure

#EndRegion
