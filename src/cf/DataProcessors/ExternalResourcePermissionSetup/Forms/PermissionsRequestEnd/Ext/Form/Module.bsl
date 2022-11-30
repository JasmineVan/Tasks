///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var AllowClose;

&AtClient
Var WaitingCompleted;

#EndRegion

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Duration = Parameters.Duration;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	AllowClose = False;
	
	If Duration > 0 Then
		WaitingCompleted = False;
		AttachIdleHandler("AfterWaitForSettingsApplyingInCluster", Duration, True);
	Else
		WaitingCompleted = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Not AllowClose Then
		Cancel = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure AfterWaitForSettingsApplyingInCluster()
	
	AllowClose = True;
	Close(DialogReturnCode.OK);
	
EndProcedure

#EndRegion