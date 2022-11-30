///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	NewUUID = New UUID(IDAsString);
	If Record.ID <> NewUUID Then
		Record.ID = NewUUID;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	IDAsString = Record.ID;
	
EndProcedure

#EndRegion