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
	
	If Parameters.Filter.Property("Application") 
	   AND ValueIsFilled(Parameters.Filter.Application) Then
		
		Application = Parameters.Filter.Application;
		
		AutoTitle = False;
		Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Пути к программе %1 на серверах Linux'; en = 'Paths to application %1 on Linux servers'; pl = 'Paths to application %1 on Linux servers';de = 'Paths to application %1 on Linux servers';ro = 'Paths to application %1 on Linux servers';tr = 'Paths to application %1 on Linux servers'; es_ES = 'Paths to application %1 on Linux servers'"), Application);
		
		Items.ListApplication.Visible = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListBeforeChangeRow(Item, Cancel)
	
	If Not ValueIsFilled(Application) Then
		Return;
	EndIf;
	
	Cancel = True;
	
	FormParameters = New Structure;
	FormParameters.Insert("Key", Items.List.CurrentRow);
	FormParameters.Insert("FillingValues", New Structure("Application", Application));
	
	OpenForm("InformationRegister.PathsToDigitalSignatureAndEncryptionApplicationsOnLinuxServers.RecordForm",
		FormParameters, Items.List, ,,,, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ListBeforeDelete(Item, Cancel)
	
	RowToDelete          = Items.List.CurrentRow;
	RowToDeleteApplication = Items.List.CurrentData.Application;
	
EndProcedure

&AtClient
Procedure ListAfterDelete(Item)
	
	Notify("Write_PathToDigitalSignatureAndEncryptionSoftwareAtServer",
		New Structure("Application", RowToDeleteApplication), RowToDelete);
	
EndProcedure

#EndRegion
