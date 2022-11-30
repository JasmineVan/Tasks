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
	
	Explanation = Parameters.Explanation;
	
	SpreadsheetDoc = New SpreadsheetDocument;
	TabTemplate = DataProcessors.MoveFilesToVolumes.GetTemplate("ReportTemplate");
	
	AreaHeader = TabTemplate.GetArea("Title");
	AreaHeader.Parameters.Details = NStr("ru = 'Файлы с ошибками:'; en = 'Files with errors:'; pl = 'Pliki z błędami:';de = 'Dateien mit Fehlern:';ro = 'Fișiere cu erori:';tr = 'Hatalı dosyalar:'; es_ES = 'Archivos con errores:'");
	SpreadsheetDoc.Put(AreaHeader);
	
	AreaRow = TabTemplate.GetArea("Row");
	
	For Each Selection In Parameters.FilesArrayWithErrors Do
		AreaRow.Parameters.Name = Selection.FileName;
		AreaRow.Parameters.Version = Selection.Version;
		AreaRow.Parameters.Error = Selection.Error;
		SpreadsheetDoc.Put(AreaRow);
	EndDo;
	
	Report.Put(SpreadsheetDoc);
	
EndProcedure

#EndRegion
