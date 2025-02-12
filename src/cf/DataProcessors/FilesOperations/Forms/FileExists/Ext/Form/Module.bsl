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
	
	ApplyForAll = Parameters.ApplyForAll;
	MessageText   = Parameters.MessageText;
	BaseAction  = Parameters.BaseAction;
	
	If Common.IsMobileClient() Then
		CommandBarLocation = FormCommandBarLabelLocation.Top;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SetDefaultButton(BaseAction);
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure OverwriteExecute()
	
	ReturnStructure = New Structure("ApplyForAll, ReturnCode", 
		ApplyForAll, DialogReturnCode.Yes);
	Close(ReturnStructure);
	
EndProcedure

&AtClient
Procedure SkipExecute()
	
	ReturnStructure = New Structure("ApplyForAll, ReturnCode", 
		ApplyForAll, DialogReturnCode.Ignore);
	Close(ReturnStructure);
	
EndProcedure

&AtClient
Procedure AbortExecute()
	
	ReturnStructure = New Structure("ApplyForAll, ReturnCode", 
		ApplyForAll, DialogReturnCode.Abort);
	Close(ReturnStructure);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SetDefaultButton(DefaultAction)
	
	If DefaultAction = ""
	 Or DefaultAction = "Ignore" Then
		
		Items.Ignore.DefaultButton = True;
		
	ElsIf DefaultAction = "Yes" Then
		Items.Overwrite.DefaultButton = True;
		
	ElsIf DefaultAction = "Abort" Then
		Items.Abort.DefaultButton = True;
	EndIf;
	
EndProcedure

#EndRegion
