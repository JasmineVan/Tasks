///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Returns description of columns of the tabular section or value table.
//
// Parameters:
//  Table - String, ValueTable - a table with columns. To receive a column list of the tabular 
//            section, specify its full name as a string as in metadata, for example "Documents.ProformaInvoice.TabularSections.Goods".
//  Columns - String - a list of comma-separated extracted columns. For example: "Number, Goods, Quantity".
// 
// Returns:
//  Array - a structure with column details for a template. See ImportDataFromFileClientServer. TemplateColumnDetails.
//
Function GenerateColumnDetails(Table, Columns = Undefined) Export
	
	DontExtractAllColumns = False;
	If Columns <> Undefined Then
		ColumnsListForExtraction = StrSplit(Columns, ",", False);
		DontExtractAllColumns = True;
	EndIf;
	
	ColumnsList = New Array;
	If TypeOf(Table) = Type("FormDataCollection") Then
		TableCopy = Table;
		InternalTable = TableCopy.Unload();
		InternalTable.Columns.Delete("SourceLineNumber");
		InternalTable.Columns.Delete("LineNumber");
	Else
		InternalTable= Table;
	EndIf;
	
	If TypeOf(InternalTable) = Type("ValueTable") Then
		For each Column In InternalTable.Columns Do
			If DontExtractAllColumns AND ColumnsListForExtraction.Find(Column.Name) = Undefined Then
				Continue;
			EndIf;
			NewColumn = ImportDataFromFileClientServer.TemplateColumnDetails(Column.Name, Column.ValueType, Column.Title, Column.Width);
			ColumnsList.Add(NewColumn);
		EndDo;
	ElsIf TypeOf(InternalTable) = Type("String") Then
		Object = Metadata.FindByFullName(InternalTable);
		For each Column In Object.Attributes Do
			If DontExtractAllColumns AND ColumnsListForExtraction.Find(Column.Name) = Undefined Then
				Continue;
			EndIf;
			NewColumn = ImportDataFromFileClientServer.TemplateColumnDetails(Column.Name, Column.Type, Column.Presentation());
			NewColumn.ToolTip = Column.ToolTip;
			NewColumn.Width = 30;
			ColumnsList.Add(NewColumn);
		EndDo;
	EndIf;
	Return ColumnsList;
EndFunction

#EndRegion

#Region Private

Procedure AddStatisticalInformation(OperationName, Value = 1, Comment = "") Export
	
	If Common.SubsystemExists("StandardSubsystems.MonitoringCenter") Then
		ModuleMonitoringCenter = Common.CommonModule("MonitoringCenter");
		OperationName = "ImportDataFromFile." + OperationName;
		ModuleMonitoringCenter.WriteBusinessStatisticsOperation(OperationName, Value, Comment);
	EndIf;
	
EndProcedure

#EndRegion
