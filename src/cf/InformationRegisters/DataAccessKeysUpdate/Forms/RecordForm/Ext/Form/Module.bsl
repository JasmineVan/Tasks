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
	
	If Parameters.Key.IsEmpty() Then
		IsNewRecord = True;
		Items.LatestUpdatedItemDate.ReadOnly = True;
		Items.UniqueKey.ReadOnly = True;
		Items.RegisterRecordChangeDate.ReadOnly = True;
		Record.JobSize = 3;
	EndIf;
	
	ReadOnly = True;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If Not IsNewRecord Then
		Return;
	EndIf;
	
	CurrentObject.LatestUpdatedItemDate = AccessManagementInternal.MaxDate();
	CurrentObject.UniqueKey = New UUID;
	CurrentObject.RegisterRecordChangeDate = CurrentSessionDate();
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	IsNewRecord = False;
	
	Items.LatestUpdatedItemDate.ReadOnly = False;
	Items.UniqueKey.ReadOnly = False;
	Items.RegisterRecordChangeDate.ReadOnly = False;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure EnableEditing(Command)
	
	ReadOnly = False;
	
EndProcedure

#EndRegion
