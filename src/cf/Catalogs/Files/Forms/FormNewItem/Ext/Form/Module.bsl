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
	
	CreateMode = Parameters.CreateMode;
	
	If Parameters.ScanCommandAvailable Then
		If Parameters.ScanCommandAvailable Then
			Items.CreateMode.ChoiceList.Add(3, NStr("ru = 'Со сканера'; en = 'From scanner'; pl = 'Ze skanera';de = 'Vom Scanner';ro = 'De la scanner';tr = 'Tarayıcıdan'; es_ES = 'Desde el escáner'"));
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure CreateFileExecute()
	Close(CreateMode);
EndProcedure

#EndRegion