///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region FormCommandHandlers

&AtClient
Procedure EnableDisableScheduledJob(Command)
	
	SelectedRows = Items.List.SelectedRows;
	
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	CurrentData = Items.List.CurrentData;
	
	EnableDisableScheduledJobAtServer(SelectedRows, Not CurrentData.UseScheduledJob);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure EnableDisableScheduledJobAtServer(SelectedRows, UseScheduledJob)
	
	For Each RowData In SelectedRows Do
		
		If RowData.DeletionMark Then
			Continue;
		EndIf;
		
		SettingObject = RowData.Ref.GetObject();
		SettingObject.UseScheduledJob = UseScheduledJob;
		SettingObject.Write();
		
	EndDo;
	
	// Updating list data
	Items.List.Refresh();
	
EndProcedure

#EndRegion
