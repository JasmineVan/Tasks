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
	
	SetOptionAtServer();
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure FirstOption(Command)
	
	SetOptionAtServer(1);
	
EndProcedure

&AtClient
Procedure SecondOption(Command)
	
	SetOptionAtServer(2);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetOptionAtServer(Option = 0)
	
	Reports.ImportRestrictionDates.SetOption(ThisObject, Option);
	
EndProcedure

#EndRegion
