///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region FormCommandHandlers

&AtClient
Procedure Select(Command)
	If FileType = 0 Then 
		Result = "xlsx";
	ElsIf FileType = 1 Then
		Result = "csv";
	ElsIf FileType = 4 Then
		Result = "xls";
	ElsIf FileType = 5 Then
		Result = "ods";
	Else
		Result = "mxl";
	EndIf;
	Close(Result);
EndProcedure

&AtClient
Procedure InstallAddonForFacilitatingWorkWithFiles(Command)
	BeginInstallFileSystemExtension(Undefined);
EndProcedure

#EndRegion








