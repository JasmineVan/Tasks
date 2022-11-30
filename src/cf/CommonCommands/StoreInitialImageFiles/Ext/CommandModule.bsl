///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	If NOT HasFilesInVolumes() Then
		ShowMessageBox(, NStr("ru = 'Файлы в томах отсутствуют.'; en = 'No files in volumes.'; pl = 'Brak plików w woluminach.';de = 'Keine Dateien in Volumen.';ro = 'Nu există fișiere în volume.';tr = 'Ciltlerde dosyalar yok.'; es_ES = 'No hay archivos en los volúmenes.'"));
		Return;
	EndIf;
	
	OpenForm("CommonForm.SelectPathToVolumeFilesArchive", , CommandExecuteParameters.Source);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function HasFilesInVolumes()
	
	Return FilesOperationsInternal.HasFilesInVolumes();
	
EndFunction

#EndRegion
