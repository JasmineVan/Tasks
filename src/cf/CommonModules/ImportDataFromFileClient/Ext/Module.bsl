﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Creates a new structure of parameters for importing data from a file to a tabular section.
//
// Returns:
//   Structure - parameters for opening the form for importing data to a tabular section:
//    * FullTabularSectionName - String - a full path to the document tabular section formatted as 
//                                           DocumentName.TabularSectionName.
//    * Header - String - a header of the form for importing data from a file.
//    * DataStructureTemplateName - String - a data input template name.
//    * Presentation - String - a window header in the data import form.
//    * AdditionalParameters - AnyType - any additional information that will be passed to the data 
//                                           mapping procedure.
//
Function DataImportParameters() Export
	ImportParameters = New Structure();
	ImportParameters.Insert("FullTabularSectionName");
	ImportParameters.Insert("Title");
	ImportParameters.Insert("DataStructureTemplateName");
	ImportParameters.Insert("AdditionalParameters");
	ImportParameters.Insert("TemplateColumns");
	
	Return ImportParameters;
EndFunction

// Opens the data import form for filling the tabular section.
//
// Parameters:
//   ImportParameters - Structure - see ImportDataFromFileClient.DataImportParameters. 
//   ImportNotification - NotifyDescription - the procedure called to add the imported data to the 
//                                               tabular section.
//
Procedure ShowImportForm(ImportParameters, ImportNotification) Export
	
	OpenForm("DataProcessor.ImportDataFromFile.Form", ImportParameters, 
		ImportNotification.Module, , , , ImportNotification);
		
EndProcedure


#EndRegion

#Region Internal

// Opens the data import form to fill in a tabular section of link mapping in the "Report options" subsystem.
//
// Parameters:
//   ImportParameters - Structure - see ImportDataFromFileClient.DataImportParameters. 
//   ImportNotification - NotifyDescription - the procedure called to add the imported data to the 
//                                               tabular section.
//
Procedure ShowRefFillingForm(ImportParameters, ImportNotification) Export
	
	OpenForm("DataProcessor.ImportDataFromFile.Form", ImportParameters,
		ImportNotification.Module,,,, ImportNotification);
		
EndProcedure

#EndRegion

#Region Private

// Opens a file import dialog.
//
// Parameters:
//  CompletionNotification - NotifyDescription - the procedure to call when a file is successfully put in a storage.
//  FileName	 - String - a file name in the dialog.
//
Procedure FileImportDialog(CompletionNotification , FileName = "") Export
	
	ImportParameters = FileSystemClient.FileImportParameters();
	ImportParameters.Dialog.Filter = NStr("ru='Все поддерживаемые форматы файлов(*.xls;*.xlsx;*.ods;*.mxl;*.csv)|*.xls;*.xlsx;*.ods;*.mxl;*.csv|Книга Excel 97 (*.xls)|*.xls|Книга Excel 2007 (*.xlsx)|*.xlsx|Электронная таблица OpenDocument (*.ods)|*.ods|Текстовый документ c разделителями (*.csv)|*.csv|Табличный документ (*.mxl)|*.mxl'; en = 'All supported file formats (*.xls; *.xlsx; *.ods; *.mxl; *.csv)|*.xls;*.xlsx;*.ods;*.mxl;*.csv|Excel Workbook 97 (*.xls)|*.xls|Excel Workbook 2007 (*.xlsx)|*.xlsx|OpenDocument Spreadsheet (*.ods)|*.ods|Comma-separated text (*.csv)|*.csv|Spreadsheet document (*.mxl)|*.mxl'; pl = 'Wszystkie obsługiwane formaty plików(*.xls;*.xlsx;*.ods;*.mxl;*.csv)|*.xls;*.xlsx;*.ods;*.mxl;*.csv|Księga Excel 97 (*.xls)|*.xls|Księga Excel 2007 (*.xlsx)|*.xlsx|Tabela elektroniczna OpenDocument (*.ods)|*.ods|Dokument tekstowy z rozdzielaczami (*.csv)|*.csv|Dokument tablicowy (*.mxl)|*.mxl';de = 'Alle unterstützten Dateiformate (*.xls;*.xlsx;*.ods;*.mxl;*.csv)|*.xls;*.xlsx;*.ods;*.mxl;*.csv|Excel 97 (*.xls)|*.xls|Excel 2007 (*.xlsx)|*.xlsx|OpenDocument Tabellenkalkulation (*.ods)|*.ods|Textdokument mit Trennzeichen (*.csv)|*.csv|Tabellendokument (*.mxl)|*.mxl';ro = 'Toate formatele de fișiere susținute(*.xls;*.xlsx;*.ods;*.mxl;*.csv)|*.xls;*.xlsx;*.ods;*.mxl;*.csv|Cartea Excel 97 (*.xls)|*.xls|Cartea Excel 2007 (*.xlsx)|*.xlsx|Tabel electronic OpenDocument (*.ods)|*.ods|Document text cu separatori (*.csv)|*.csv|Document tabelar (*.mxl)|*.mxl';tr = 'Tüm desteklenen dosya formatları (*.xls;*.xlsx;*.ods;*.mxl;*.csv)|*.xls;*.xlsx;*.ods;*.mxl;*.csv|Книга Excel 97 (*.xls)|*.xls| Excel 2007 kitabı (*.xlsx)|*.xlsx|Elektronik tablo OpenDocument (*.ods)|*.ods|Virgüllerle ayrılmış değerler dosyası (*.csv)|*.csv|Tablo belgesi (*.mxl)|*.mxl'; es_ES = 'Todos los formatos de archivos admitidos(*.xls;*.xlsx;*.ods;*.mxl;*.csv)|*.xls;*.xlsx;*.ods;*.mxl;*.csv|Libro Excel 97 (*.xls)|*.xls|Libro Excel 2007 (*.xlsx)|*.xlsx|Tabla electrónica OpenDocument (*.ods)|*.ods|Documento de texto con separadores (*.csv)|*.csv|Documento de tabla (*.mxl)|*.mxl'");
	ImportParameters.FormID = CompletionNotification.Module.UUID;
	
	
	FileSystemClient.ImportFile(CompletionNotification, ImportParameters, FileName);
	
EndProcedure

#EndRegion
