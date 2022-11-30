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
	
	SetDataAppearance();
	
	ImportParameters = Parameters.ImportParameters;

	MappingObjectName = Parameters.MappingObjectName;
	If Parameters.Property("ColumnsInformation") Then
		ColumnsList.Load(Parameters.ColumnsInformation.Unload());
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ColumnsListOnActivateRow(Item)
	If Item.CurrentData <> Undefined Then 
		ColumnDetails = Item.CurrentData.Comment;
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure OK(Command)
	ColumnPosition = 0;
	For Each TableRow In ColumnsList Do
		If TableRow.Visible Then
			ColumnPosition = ColumnPosition + 1;
			TableRow.Position = ColumnPosition;
		Else
			TableRow.Position = -1;
		EndIf;
	EndDo;
	Close(ColumnsList);
EndProcedure

&AtClient
Procedure ClearSettings(Command)
	Notification = New NotifyDescription("ClearSettingsCompletion", ThisObject, MappingObjectName);
	ShowQueryBox(Notification, NStr("ru = 'Установить настройки колонок в первоначальное состояние?'; en = 'Do you want to revert to the default column settings?'; pl = 'Przywrócić pierwotne ustawienia kolumn?';de = 'Setzen Sie die Spalteneinstellungen auf ihren ursprünglichen Zustand zurück?';ro = 'Setați setările coloanei la starea inițială?';tr = 'Sütun ayarlarını fabrika ayarlarına çevirmek mi istiyorsunuz?'; es_ES = '¿Volver a establecer las configuraciones de la columna para su estado original?'"), QuestionDialogMode.YesNo);
EndProcedure

&AtClient
Procedure SelectAll(Command)
	For each TableRow In ColumnsList Do 
		TableRow.Visible = True;
	EndDo;
EndProcedure

&AtClient
Procedure ClearAll(Command)
	For each TableRow In ColumnsList Do
		If Not TableRow.Required Then
			TableRow.Visible = False;
		EndIf;
	EndDo;
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetDataAppearance()

	ConditionalAppearance.Items.Clear();
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	AppearanceField = ConditionalAppearanceItem.Fields.Items.Add();
	AppearanceField.Field = New DataCompositionField("ColumnsListDescription");
	AppearanceField.Use = True;
	FilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem.LeftValue = New DataCompositionField("ColumnsList.Required"); 
	FilterItem.ComparisonType = DataCompositionComparisonType.Equal; 
	FilterItem.RightValue =True;
	FilterItem.Use = True;
	ConditionalAppearanceItem.Appearance.SetParameterValue("Font", New Font(,, True));
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	AppearanceField = ConditionalAppearanceItem.Fields.Items.Add();
	AppearanceField.Field = New DataCompositionField("ColumnsListVisibility");
	AppearanceField.Use = True;
	FilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem.LeftValue = New DataCompositionField("ColumnsList.Required"); 
	FilterItem.ComparisonType = DataCompositionComparisonType.Equal; 
	FilterItem.RightValue =True;
	FilterItem.Use = True;
	ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", True);
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	AppearanceField = ConditionalAppearanceItem.Fields.Items.Add();
	AppearanceField.Field = New DataCompositionField("ColumnsListSynonym");
	AppearanceField.Use = True;
	FilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem.LeftValue = New DataCompositionField("ColumnsList.Synonym");
	FilterItem.ComparisonType = DataCompositionComparisonType.NotFilled;
	FilterItem.Use = True;
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("ru = 'Стандартное наименование'; en = 'Standard name'; pl = 'Nazwa standardowa';de = 'Standard name';ro = 'Nume standard';tr = 'Standart isim'; es_ES = 'Nombre estándar'"));
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
EndProcedure

&AtClient
Procedure ClearSettingsCompletion(QuestionResult, MappingObjectName) Export
	If QuestionResult = DialogReturnCode.Yes Then
		ResetColumnsSettings(MappingObjectName);
	EndIf;
EndProcedure

&AtServer
Procedure ResetColumnsSettings(MappingObjectName)
	
	Common.CommonSettingsStorageSave("ImportDataFromFile", MappingObjectName, Undefined,, UserName());
	
	ColumnsListTable = ColumnsList.Unload();
	ColumnsListTable.Clear();
	DataProcessors.ImportDataFromFile.DetermineColumnsInformation(ImportParameters, ColumnsListTable);
	ValueToFormAttribute(ColumnsListTable, "ColumnsList");
	
EndProcedure

#EndRegion
