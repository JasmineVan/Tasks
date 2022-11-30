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
	
	TooBigFiles = Parameters.TooBigFiles;
	
	MaxFileSize = Int(FilesOperations.MaxFileSize() / (1024 * 1024));
	
	Message = StringFunctionsClientServer.SubstituteParametersToString(
	    NStr("ru = 'Некоторые файлы превышают предельный размер (%1 Мб) и не будут добавлены в хранилище.
	               |Продолжить импорт?'; 
	               |en = 'Some files exceed the size limit (%1 MB) and will not be added to the storage.
	               |Do you want to continue the upload?'; 
	               |pl = 'Niektóre pliki przekraczają limit rozmiaru (%1 Mb) i nie zostaną dodane do pamięci.
	               |Czy chcesz kontynuować?';
	               |de = 'Einige der Dateien überschreiten die Größenbeschränkung (%1MB) und werden dem Speicher nicht hinzugefügt. 
	               |Import fortsetzen?';
	               |ro = 'Unele dintre fișiere depășesc limita de dimensiune (%1 Mb) și nu vor fi adăugate la spațiul de stocare.
	               |Continuați să importați?';
	               |tr = 'Bazı dosyalar boyut sınırını (%1Mb) aşıyor ve depolama alanına eklenmeyecek.
	               | İçe aktarmaya devam et?'; 
	               |es_ES = 'Algunos de los archivos exceden el límite de tamaño (%1Mb) y no se añadirán al almacenamiento.
	               |¿Continuar la importación?'"),
	    String(MaxFileSize) );
	
	Title = Parameters.Title;
	
	If Common.IsMobileClient() Then
		CommandBarLocation = FormCommandBarLabelLocation.Top;
	EndIf;
	
EndProcedure

#EndRegion
