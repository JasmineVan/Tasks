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
	
	If Parameters.FillingValues.Property("Application")
	   AND ValueIsFilled(Parameters.FillingValues.Application) Then
		
		AutoTitle = False;
		Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Путь к программе %1 на сервере Linux'; en = 'Path to application %1 on Linux server'; pl = 'Path to application %1 on Linux server';de = 'Path to application %1 on Linux server';ro = 'Path to application %1 on Linux server';tr = 'Path to application %1 on Linux server'; es_ES = 'Path to application %1 on Linux server'"),
			Parameters.FillingValues.Application);
		
		Items.Application.Visible = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// It is required to update the list of applications and their parameters on the server and on the 
	// client.
	RefreshReusableValues();
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_PathToDigitalSignatureAndEncryptionSoftwareAtServer",
		New Structure("Application", Record.Application), Record.SourceRecordKey);
	
EndProcedure

#EndRegion
