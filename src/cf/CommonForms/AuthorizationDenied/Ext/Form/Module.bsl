///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtClient
Procedure OnOpen(Cancel)
	
	AttachIdleHandler("IdleHandlerExitApplication", 5 * 60, True);
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	Terminate();
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure ExitApplication(Command)
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure IdleHandlerExitApplication()
	
	Close();
	
EndProcedure

#EndRegion
