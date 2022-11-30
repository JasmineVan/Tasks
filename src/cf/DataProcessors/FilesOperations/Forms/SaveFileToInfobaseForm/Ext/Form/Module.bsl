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
	
	File = Parameters.FileRef;
	VersionComment = Parameters.VersionComment;
	CreateNewVersion = Parameters.CreateNewVersion;
	Items.CreateNewVersion.Enabled = Parameters.CreateNewVersionAvailability;
	
	If File.StoreVersions Then
		CreateNewVersion = True;
	Else
		CreateNewVersion = False;
		Items.CreateNewVersion.Enabled = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Save(Command)
	
	ReturnStructure = New Structure("VersionComment, CreateNewVersion, ReturnCode",
		VersionComment, CreateNewVersion, DialogReturnCode.OK);
	
	Close(ReturnStructure);
	
	Notify("FilesOperations_NewFileVersionSaved");
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	ReturnStructure = New Structure("VersionComment, CreateNewVersion, ReturnCode",
		VersionComment, CreateNewVersion, DialogReturnCode.Cancel);
	
	Close(ReturnStructure);
	
EndProcedure

#EndRegion