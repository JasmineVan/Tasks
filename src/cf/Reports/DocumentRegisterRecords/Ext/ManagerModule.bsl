///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region ForCallsFromOtherSubsystems

// StandardSubsystems.ReportsOptions

// See ReportsOptionsOverridable.CustomizeReportsOptions. 
//
Procedure CustomizeReportOptions(Settings, ReportSettings) Export
	
	ModuleReportsOptions = Common.CommonModule("ReportsOptions");
	
	ReportSettings.DefineFormSettings = True;
	
	OptionSettings_Horizontal = ReportsOptions.OptionDetails(Settings, ReportSettings, "Main");
	OptionSettings_Horizontal.Details = NStr("ru = 'Горизонтальное размещение колонок с измерениями, ресурсами и реквизитами регистров.'; en = 'Horizontal arrangement of columns with dimensions, resources, and register attributes.'; pl = 'Horizontal arrangement of columns with dimensions, resources, and register attributes.';de = 'Horizontal arrangement of columns with dimensions, resources, and register attributes.';ro = 'Horizontal arrangement of columns with dimensions, resources, and register attributes.';tr = 'Horizontal arrangement of columns with dimensions, resources, and register attributes.'; es_ES = 'Horizontal arrangement of columns with dimensions, resources, and register attributes.'");
	OptionSettings_Horizontal.SearchSettings.Keywords = NStr("ru = 'Движения документа'; en = 'Document register records'; pl = 'Document register records';de = 'Document register records';ro = 'Document register records';tr = 'Document register records'; es_ES = 'Document register records'");
	
	OptionSettings_Vertical = ReportsOptions.OptionDetails(Settings, ReportSettings, "Additional");
	OptionSettings_Vertical.Details = NStr("ru = 'Вертикальное размещение колонок с измерениями, ресурсами и реквизитами позволяет расположить данные более компактно, для просмотра регистров с большим количеством колонок.'; en = 'Vertical arrangement of columns with dimensions, resources, and attributes allows you to arrange data more compactly to view registers with a large number of columns.'; pl = 'Vertical arrangement of columns with dimensions, resources, and attributes allows you to arrange data more compactly to view registers with a large number of columns.';de = 'Vertical arrangement of columns with dimensions, resources, and attributes allows you to arrange data more compactly to view registers with a large number of columns.';ro = 'Vertical arrangement of columns with dimensions, resources, and attributes allows you to arrange data more compactly to view registers with a large number of columns.';tr = 'Vertical arrangement of columns with dimensions, resources, and attributes allows you to arrange data more compactly to view registers with a large number of columns.'; es_ES = 'Vertical arrangement of columns with dimensions, resources, and attributes allows you to arrange data more compactly to view registers with a large number of columns.'");
	OptionSettings_Vertical.SearchSettings.Keywords = NStr("ru = 'Движения документа'; en = 'Document register records'; pl = 'Document register records';de = 'Document register records';ro = 'Document register records';tr = 'Document register records'; es_ES = 'Document register records'");
	
EndProcedure

// It is intended to be called from the ReportOptionsOverridable.BeforeAddReportCommands procedure.
// 
// Parameters:
//   ReportsCommands - ValuesTable - a table of commands to be shown in the submenu.
//                                 (See ReportsOptionsOverridable.BeforeAddReportsCommands).
//   Parameters - Structure - a structure containing command connection parameters.
//   DocumentsWithRecordsReport - Array, Undefined - an array of documents in which the command of 
//                                 reports opening will be displayed. Undefined if the report is 
//                                 displayed for all documents with the Posting property set in Allow
//                                 and filled register records collection.
//
// Returns:
//   ValueTableRow, Undefined - if you do not have rights to view the report, added command or Undefined.
//
Function AddDocumentRecordsReportCommand(ReportsCommands, Parameters, DocumentsWithRecordsReport = Undefined) Export
	
	If Not AccessRight("View", Metadata.Reports.DocumentRegisterRecords) Then
		Return Undefined;
	EndIf;
	
	CommandParameterTypeDetails = CommandParameterTypeDetails(ReportsCommands, Parameters, DocumentsWithRecordsReport);
	If CommandParameterTypeDetails = Undefined Then
		Return Undefined;
	EndIf;
	
	Command                    = ReportsCommands.Add();
	Command.Presentation      = NStr("ru = 'Движения документа'; en = 'Document register records'; pl = 'Document register records';de = 'Document register records';ro = 'Document register records';tr = 'Document register records'; es_ES = 'Document register records'");
	Command.MultipleChoice = False;
	Command.FormParameterName  = "";
	Command.Importance           = "SeeAlso";
	Command.ParameterType       = CommandParameterTypeDetails;
	Command.Manager           = "Report.DocumentRegisterRecords";
	Command.Shortcut    = New Shortcut(Key.L, False, True, True);
	
	Return Command;
	
EndFunction

// See ReportsOptionsOverridable.CustomizeReportsOptions. 
Procedure OnSetUpReportsOptions(Settings) Export
	
	ReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.DocumentRegisterRecords);
	ReportsOptions.ReportDetails(Settings, Metadata.Reports.DocumentRegisterRecords).Enabled = False;
	
EndProcedure

// See ReportsOptionsOverridable.BeforeAddReportsCommands. 
Procedure BeforeAddReportCommands(ReportsCommands, FormSettings, StandardProcessing) Export
	
	AddDocumentRecordsReportCommand(ReportsCommands, FormSettings);
	
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#Region Private

Function CommandParameterTypeDetails(Val ReportsCommands, Val Parameters, Val DocumentsWithRecordsReport)
	
	If Not Parameters.Property("Sources") Then
		Return Undefined;
	EndIf;
	
	SourcesStrings = Parameters.Sources.Rows;
	
	If DocumentsWithRecordsReport <> Undefined Then
		DetachReportFromDocuments(ReportsCommands);
		DocumentsWithReport = New Map;
		For each DocumentWithReport In DocumentsWithRecordsReport Do
			DocumentsWithReport[DocumentWithReport] = True;
		EndDo;	
	Else	
		DocumentsWithReport = Undefined;
	EndIf;
	
	DocumentsTypesWithRegisterRecords = New Array;
	For Each SourceRow In SourcesStrings Do
		
		DataRefType = SourceRow.DataRefType;
		
		If TypeOf(DataRefType) = Type("Type") Then
			DocumentsTypesWithRegisterRecords.Add(DataRefType);
		ElsIf TypeOf(DataRefType) = Type("TypeDescription") Then
			CommonClientServer.SupplementArray(DocumentsTypesWithRegisterRecords, DataRefType.Types());
		EndIf;
		
	EndDo;
	
	DocumentsTypesWithRegisterRecords = CommonClientServer.CollapseArray(DocumentsTypesWithRegisterRecords);
	
	Index = DocumentsTypesWithRegisterRecords.Count() - 1;
	While Index >= 0 Do
		If Not IsAttachableType(DocumentsTypesWithRegisterRecords[Index], DocumentsWithReport) Then
			DocumentsTypesWithRegisterRecords.Delete(Index);
		EndIf;
		Index = Index - 1;
	EndDo;	
	
	Return ?(DocumentsTypesWithRegisterRecords.Count() > 0, New TypeDescription(DocumentsTypesWithRegisterRecords), Undefined);
	
EndFunction

Procedure DetachReportFromDocuments(ReportsCommands)
	
	SearchStructure = New Structure;
	SearchStructure.Insert("Manager", "Report.DocumentRegisterRecords");
	FoundRows = ReportsCommands.FindRows(SearchStructure);
	
	For Each FoundRow In FoundRows Do
		ReportsCommands.Delete(FoundRow);
	EndDo;
	
EndProcedure

Function IsAttachableType(TypeToCheck, DocumentsWithRecordsReport)
	
	MetadataObject = Metadata.FindByType(TypeToCheck);
	If MetadataObject = Undefined Then
		Return False;
	EndIf;
	
	If DocumentsWithRecordsReport <> Undefined AND DocumentsWithRecordsReport[MetadataObject] = Undefined Then
		Return False;
	EndIf;
	
	If Not Common.IsDocument(MetadataObject) Then
		Return False;
	EndIf;
	
	If MetadataObject.Posting <> Metadata.ObjectProperties.Posting.Allow
		Or MetadataObject.RegisterRecords.Count() = 0 Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

#EndRegion

#EndIf