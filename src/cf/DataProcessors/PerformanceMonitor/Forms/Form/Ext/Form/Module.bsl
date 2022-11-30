///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

// Loads TS settings. If it is the first time the form is opened, adds all key operations from the 
// catalog to the TS.
//
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If NOT PerformanceMonitorInternal.SubsystemExists("StandardSubsystems.Core") Then
		SSLAvailable = False;
	Else
		SSLAvailable = True;
	EndIf;
	
	OverallSystemPerformance = PerformanceMonitorInternal.GetOverallSystemPerformanceItem();
	If OverallSystemPerformance.IsEmpty() Then
		Object.OverallSystemPerformance = NStr("ru = 'Общая производительность системы'; en = 'Overall system performance'; pl = 'Overall system performance';de = 'Overall system performance';ro = 'Overall system performance';tr = 'Overall system performance'; es_ES = 'Overall system performance'");
	Else
		Object.OverallSystemPerformance = OverallSystemPerformance;
	EndIf;
	
	Try
		SettingToImport = ImportKeyOperations(Object.OverallSystemPerformance);
		Object.Performance.Load(SettingToImport);
	Except
		MessageText = NStr("ru = 'Не удалось загрузить настройки.'; en = 'Cannot load settings.'; pl = 'Cannot load settings.';de = 'Cannot load settings.';ro = 'Cannot load settings.';tr = 'Cannot load settings.'; es_ES = 'Cannot load settings.'");
		PerformanceMonitorInternal.MessageToUser(MessageText);
	EndTry;
	
	If IsBlankString(Object.FilterOptionComment) Then
		Object.FilterOptionComment = "DontFilter";
	EndIf;
		
	SetConditionalAppearance();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	TableUpdated = False;
	ChartUpdated = False;
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectedValue, ChoiceSource)
	
	If Upper(ChoiceSource.FormName) = Upper("DataProcessor.PerformanceMonitor.Form.FilterForm") Then
		
		If SelectedValue <> Undefined Then
			UpdateIndicators(SelectedValue);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PerformanceOnStartEdit(Item, NewRow, Clone)
	
	If NOT NewRow Then
		Return;
	EndIf;
	
	OpenChoiceForm();
	
EndProcedure

&AtClient
Procedure FormOnCurrentPageChange(Item, CurrentPage)
	
	If Not TableUpdated Or Not ChartUpdated Then
		If Items.Form.CurrentPage.Name = "PageChart" Then
			ChartUpdated = True;
		ElsIf Items.Form.CurrentPage.Name = "TablePage" Then
			TableUpdated = True;
		EndIf;
		UpdateIndicators();
	EndIf;
	
EndProcedure

&AtClient
Procedure ResponseTimeThresholdOnChange(Item)
	
	SC = Items.Performance.CurrentData;
	If SC = Undefined Then
		Return;
	EndIf;
	
	ChangeResponseTimeThreshold(SC.KeyOperation, SC.ResponseTimeThreshold);
	UpdateIndicators();
	
EndProcedure

// Displays a key operation's execution history.
//
&AtClient
Procedure PerformanceSelection(Item, RowSelected, Field, StandardProcessing)
	
	TSRow = Object.Performance.FindByID(RowSelected);
	
	If Not StrStartsWith(Field.Name, "Performance")
		Or TSRow.KeyOperation = Object.OverallSystemPerformance Then
		Return;
	EndIf;
	StandardProcessing = False;
	
	BeginOfPeriod = 0;
	PeriodEnd = 0;
	PeriodIndex = Number(Mid(Field.Name, 19));
	If Not CalculateTimeRangeDates(BeginOfPeriod, PeriodEnd, PeriodIndex) Then
		Return;
	EndIf;
	
	HistorySettings = New Structure("KeyOperation, StartDate, EndDate", TSRow.KeyOperation, BeginOfPeriod, PeriodEnd);
	
	OpeningParameters = New Structure("HistorySettings", HistorySettings);
	OpenForm("DataProcessor.PerformanceMonitor.Form.ExecutionHistory", OpeningParameters, ThisObject);
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Update(Command)
	
	UpdateIndicators();
	
EndProcedure

&AtClient
Procedure MoveUp(Command)
	
	SC = Items.Performance.CurrentData;
	If SC = Undefined Then
		Return;
	EndIf;
	
	Temp = Object.Performance;
	CurrentIndex = Temp.IndexOf(SC);
	
	If Temp.Count() <= 1
		OR CurrentIndex = 0
		OR Temp[CurrentIndex - 1].KeyOperation = Object.OverallSystemPerformance
		OR SC.KeyOperation = Object.OverallSystemPerformance Then
		Return;
	EndIf;
	
	ShiftDirection = -1;
	ExecuteRowShift(ShiftDirection, CurrentIndex);
	
EndProcedure

&AtClient
Procedure MoveDown(Command)
	
	SC = Items.Performance.CurrentData;
	If SC = Undefined Then
		Return;
	EndIf;
	
	Temp = Object.Performance;
	CurrentIndex = Temp.IndexOf(SC);
	
	If Temp.Count() <= 1
		OR CurrentIndex = Temp.Count() - 1
		OR Temp[CurrentIndex + 1].KeyOperation = Object.OverallSystemPerformance
		OR SC.KeyOperation = Object.OverallSystemPerformance Then
		Return;
	EndIf;
	
	ShiftDirection = 1;
	ExecuteRowShift(ShiftDirection, CurrentIndex);
	
EndProcedure

&AtClient
Procedure Setting(Command)
	
	OpenForm("DataProcessor.PerformanceMonitor.Form.AutomaticPerformanceMeasurementsExport", , ThisObject,,,,,FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SpecifyAPDEX(Command)
	
	TSRow = Object.Performance.FindByID(Items.Performance.CurrentRow);
	Item = Items.Performance.CurrentItem;
	
	If Not StrStartsWith(Item.Name, "Performance")
		OR TSRow.KeyOperation = Object.OverallSystemPerformance Then
		Return;
	EndIf;
	
	If TSRow[Item.Name] = 0 Then
		ShowMessageBox(,NStr("ru = 'Отсутствуют замеры производительности.
			|Рассчитать целевое время невозможно.'; 
			|en = 'There are no performance measurements.
			|Cannot calculate the response time threshold.'; 
			|pl = 'There are no performance measurements.
			|Cannot calculate the response time threshold.';
			|de = 'There are no performance measurements.
			|Cannot calculate the response time threshold.';
			|ro = 'There are no performance measurements.
			|Cannot calculate the response time threshold.';
			|tr = 'There are no performance measurements.
			|Cannot calculate the response time threshold.'; 
			|es_ES = 'There are no performance measurements.
			|Cannot calculate the response time threshold.'"));
		Return;
	EndIf;
	
	Notification = New NotifyDescription("SpecifyApdexCompletion", ThisObject);
	Tooltip = NStr("ru = 'Введите желаемое значение APDEX'; en = 'Enter desired Apdex value.'; pl = 'Enter desired Apdex value.';de = 'Enter desired Apdex value.';ro = 'Enter desired Apdex value.';tr = 'Enter desired Apdex value.'; es_ES = 'Enter desired Apdex value.'"); 
	ApdexValue = 0;
	ShowInputNumber(Notification, ApdexValue, Tooltip, 3, 2);
	
EndProcedure

&AtClient
Procedure SetFilter(Command)
	
	OpenForm("DataProcessor.PerformanceMonitor.Form.FilterForm", , ThisObject);
	
EndProcedure

&AtClient
Procedure AddKeyOperation(Command)
	OpenChoiceForm();
EndProcedure

&AtClient
Procedure DeleteKeyOperation(Command)
	DeleteKeyOperationAtServer();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Priority.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Performance.LineNumber");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ResponseTimeThreshold.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Performance.KeyOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Object.OverallSystemPerformance;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure

&AtClient
Procedure SpecifyApdexCompletion(Val ApdexValue, Val AdditionalParameters) Export
	
	If ApdexValue = Undefined Then
		Return;
	EndIf;
	
	If 0 > ApdexValue Or ApdexValue > 1 Then
		ShowMessageBox(,NStr("ru = 'Введен неправильный показатель APDEX.
			|Допустимые значения от 0 до 1.'; 
			|en = 'Invalid APDEX indicator was entered.
			|Possible values are from 0 to 1.'; 
			|pl = 'Invalid APDEX indicator was entered.
			|Possible values are from 0 to 1.';
			|de = 'Invalid APDEX indicator was entered.
			|Possible values are from 0 to 1.';
			|ro = 'Invalid APDEX indicator was entered.
			|Possible values are from 0 to 1.';
			|tr = 'Invalid APDEX indicator was entered.
			|Possible values are from 0 to 1.'; 
			|es_ES = 'Invalid APDEX indicator was entered.
			|Possible values are from 0 to 1.'"));
		Return;
	EndIf;
	
	ApdexValue = ?(ApdexValue = 0, 0.001, ApdexValue);
	
	TSRow = Object.Performance.FindByID(Items.Performance.CurrentRow);
	Item = Items.Performance.CurrentItem;
	TSRow[Item.Name] = ApdexValue;
	
	PeriodIndex = Number(Mid(Item.Name, 19));
	ResponseTimeThreshold = CalculateResponseTimeThreshold(TSRow.KeyOperation, ApdexValue, PeriodIndex);
	
	TSRow.ResponseTimeThreshold = ResponseTimeThreshold;
	ResponseTimeThresholdOnChange(Item);
EndProcedure

// Evaluates performance indicators.
//
&AtServer
Procedure UpdateIndicators(FilterValues = Undefined)
	
	If Items.Form.CurrentPage.Name = "PageChart" Then
		ChartUpdated = True;
		TableUpdated = False;
	ElsIf Items.Form.CurrentPage.Name = "TablePage" Then
		TableUpdated = True;
		ChartUpdated = False;
	EndIf;
	
	DataProcessorObject = FormAttributeToValue("Object");
	
	If Not SetupExecuted() Then
		Return;
	EndIf;
	
	// Getting the final KeyOperationTable for displaying it to a user.
	KeyOperationTable = DataProcessorObject.PerformanceIndicators();
	If KeyOperationTable = Undefined Then
		PerformanceMonitorInternal.MessageToUser(NStr("ru = 'Период установлен не верно.'; en = 'Invalid period.'; pl = 'Invalid period.';de = 'Invalid period.';ro = 'Invalid period.';tr = 'Invalid period.'; es_ES = 'Invalid period.'"));
		Return;
	EndIf;
	
	If KeyOperationTable.Count() = 0 Then
		Return;
	EndIf;
	
	If FilterValues <> Undefined Then
		SetFilterKeyOperationTable(KeyOperationTable, FilterValues);
	EndIf;
	
	If Items.Form.CurrentPage.Name = "PageChart" Then
		
		UpdateChart(KeyOperationTable);
		
	ElsIf Items.Form.CurrentPage.Name = "TablePage" Then
		
		HandleObjectAttributes(KeyOperationTable.Columns);
		Object.Performance.Load(KeyOperationTable);
		
	EndIf;
	
EndProcedure

// Calculates the time threshold for a specified APDEX.
//
// Parameters:
//  KeyOperation - CatalogRef.KeyOperations - key operation to calculate the time threshold for.
//  ValueAPDEX - Number - an APDEX value for calculating the response time threshold.
//  PeriodIndex - Number - index of the period to calculate the time threshold for.
//
// Returns:
//  Number - time threshold under which APDEX equals the specified value.
//
&AtServer
Function CalculateResponseTimeThreshold(KeyOperation, ApdexValue, PeriodIndex)
	
	KeyOperationTable = KeyOperationTableForApdexCalculating();
	KeyOperationTableRow = KeyOperationTable.Add();
	KeyOperationTableRow.KeyOperation = KeyOperation;
	KeyOperationTableRow.Priority = 1;
	
	ThisDataProcessor = FormAttributeToValue("Object");
	
	StepValue = 0;
	StepsCount = 0;
	If Not ThisDataProcessor.ChartPeriodicity(StepValue, StepsCount) Then
		Return False;
	EndIf;
	
	BeginOfPeriod = Object.StartDate + (StepValue * PeriodIndex);
	PeriodEnd = BeginOfPeriod + StepValue - 1;
	
	EvaluationParameters = ThisDataProcessor.ParametersStructureForAPDEXCalculation();
	EvaluationParameters.StepValue = StepValue;
	EvaluationParameters.StepsCount = 1;
	EvaluationParameters.StartDate = BeginOfPeriod;
	EvaluationParameters.EndDate = PeriodEnd;
	EvaluationParameters.OutputTotals = False;
	
	ResponseTimeThreshold = 0.01;
	PreviousResponseTimeThreshold = ResponseTimeThreshold;
	StepSeconds = 1;
	While True Do
		
		KeyOperationTable[0].ResponseTimeThreshold = ResponseTimeThreshold;
		EvaluationParameters.KeyOperationTable = KeyOperationTable;
		
		CalculatedKeyOperationTable = ThisDataProcessor.EvaluateApdex(EvaluationParameters);
		ApdexValueCalculated = CalculatedKeyOperationTable[0][3];
		
		If ApdexValueCalculated < ApdexValue Then
			
			PreviousResponseTimeThreshold = ResponseTimeThreshold;
			ResponseTimeThreshold = ResponseTimeThreshold + StepSeconds;
		
		ElsIf ApdexValueCalculated > ApdexValue Then
			
			If StepSeconds = 0.01 Or ResponseTimeThreshold = 0.01 Then
				Break;
			EndIf;
			
			StepSeconds = StepSeconds / 10;
			ResponseTimeThreshold = PreviousResponseTimeThreshold + StepSeconds;
		
		ElsIf ApdexValueCalculated = ApdexValue Then
			
			Break;
			
		EndIf;
		
	EndDo;
	
	Return ResponseTimeThreshold;
	
EndFunction

// Processes attributes of the Performance TS.
//
// Parameters:
//  KeyOperationTableColumns - ValueTableColumnCollection - used to select the attributes to discard 
//                                   or keep.
//
&AtServer
Procedure HandleObjectAttributes(KeyOperationTableColumns)
	
	ObjectAttributes = GetAttributes("Object.Performance");
	AttributesToDelete = AttributesToDelete(ObjectAttributes);
	
	// "Key operation," "Priority," and "Response time threshold" columns.
	PredefinedColumnCount = 3;
	
	// Changing column content
	If AttributesToDelete.Count() <> (KeyOperationTableColumns.Count() - PredefinedColumnCount) Then
		
		ChangeObjectAttributesComposition(KeyOperationTableColumns, AttributesToDelete);
		
		// Generating a list of fields for conditional appearance.
		FilterFields = New Array;
		AppearanceFields = New Array;
		For Each KeyOperationTableColumn In KeyOperationTableColumns Do
			If KeyOperationTableColumns.IndexOf(KeyOperationTableColumn) < PredefinedColumnCount Then
				Continue;
			EndIf;
			FilterFields.Add("Object.Performance." + KeyOperationTableColumn.Name);
			AppearanceFields.Add(KeyOperationTableColumn.Name);
		EndDo;
		
		SetTSConditionalAppearance(FilterFields, AppearanceFields, ConditionalAppearance, Object.OverallSystemPerformance);
		
	// Only column headers are changed.
	Else
		
		Cnt = -1;
		For Each Item In Items.Performance.ChildItems Do
			Cnt = Cnt + 1;
			// Skipping the first 3 elements to avoid changing "Key operation," "Priority," and "Response time threshold" column headers.
			If Cnt < PredefinedColumnCount Then
				Continue;
			EndIf;
			Item.Title = KeyOperationTableColumns[Cnt].Title;
		EndDo;
		
	EndIf;
	
EndProcedure

// Changes form attributes by removing unnecessary ones and adding new ones.
//
// Parameters:
//  KeyOperationTableColumns - ValueTableColumnCollection - used to select the attributes to discard 
//                                   or keep.
//  AttributesToDelete - Array - list of full names of attributes to be deleted, in Object.
//  	Performance.PerformanceN format, where N is the number.
//
&AtServer
Procedure ChangeObjectAttributesComposition(KeyOperationTableColumns, AttributesToDelete)
	
	// Deleting columns from "Performance" tabular section.
	For AttributeIndex = 0 To AttributesToDelete.Count() - 1 Do
		
		// Names of attribute to be deleted in Object.Performance.PerformanceN format, where N is a number. 
		// This expression gets a string in PerformanceN format.
		Item = Items.Find(Mid(AttributesToDelete[AttributeIndex], 27));
		If Item <> Undefined Then
			Items.Delete(Item);
		EndIf;
		
	EndDo;
	
	AttributesToAdd = AttributesToAdd(KeyOperationTableColumns);
	ChangeAttributes(AttributesToAdd, AttributesToDelete);
	
	// Adding columns to "Performance" tabular section.
	ObjectAttributes = GetAttributes("Object.Performance");
	For Each ObjectAttribute In ObjectAttributes Do
		
		AttributeName = ObjectAttribute.Name;
		If StrStartsWith(AttributeName, "Performance") Then
			Item = Items.Add(AttributeName, Type("FormField"), Items.Performance);
			Item.Type = FormFieldType.InputField;
			Item.DataPath = "Object.Performance." + AttributeName;
			Item.Title = ObjectAttribute.Title;
			Item.HeaderHorizontalAlign = ItemHorizontalLocation.Center;
			Item.Format = "ND=5; NFD=2; NZ=";
			Item.ReadOnly = True;
		EndIf;
		
	EndDo;
	
EndProcedure

// Creates an array of form attributes (Performance TS columns) to be added.
//
// Parameters:
//  KeyOperationTableColumns - ValueTableColumnCollection - list of columns to be created.
//
// Returns:
//  Array - array of form attributes.
//
&AtServerNoContext
Function AttributesToAdd(KeyOperationTableColumns)
	
	AttributesToAdd = New Array;
	TypeNumber63 = New TypeDescription("Number", New NumberQualifiers(6, 3, AllowedSign.Nonnegative));
	
	For Each KeyOperationTableColumn In KeyOperationTableColumns Do
		
		If KeyOperationTableColumns.IndexOf(KeyOperationTableColumn) < 3 Then
			Continue;
		EndIf;
		
		NewFormAttribute = New FormAttribute(KeyOperationTableColumn.Name, TypeNumber63, "Object.Performance", KeyOperationTableColumn.Title);
		AttributesToAdd.Add(NewFormAttribute);
		
	EndDo;
	
	Return AttributesToAdd;
	
EndFunction

// Creates an array of form attributes (Performance TS columns) to be deleted and deletes form items 
// related to these attributes.
//
// Returns:
//  Array - array of form attributes.
//
&AtServerNoContext
Function AttributesToDelete(ObjectAttributes)
	
	AttributesToDelete = New Array;
	
	AttributeIndex = 0;
	While AttributeIndex < ObjectAttributes.Count() Do
		
		AttributeName = ObjectAttributes[AttributeIndex].Name;
		If StrStartsWith(AttributeName, "Performance") Then
			AttributesToDelete.Add("Object.Performance." + AttributeName);
		EndIf;
		AttributeIndex = AttributeIndex + 1;
		
	EndDo;
	
	Return AttributesToDelete;
	
EndFunction

// Sets the conditional appearance for the Performance TS.
//
&AtServerNoContext
Procedure SetTSConditionalAppearance(FilterFields, AppearanceFields, ConditionalAppearance, OverallSystemPerformance);
	
	ConditionalAppearance.Items.Clear();
	
	// Removing OverallSystemPerformance key operation priority.
	AppearanceItem = ConditionalAppearance.Items.Add();
	// Appearance type
	AppearanceItem.Appearance.SetParameterValue("Text", "");
	// Appearance condition
	FilterItem = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	FilterItem.LeftValue = New DataCompositionField("Object.Performance.KeyOperation");
	FilterItem.RightValue = OverallSystemPerformance;
	// Appearance field
	AppearanceField = AppearanceItem.Fields.Items.Add();
	AppearanceField.Field = New DataCompositionField("Priority");
	
	// Setting "read only" property for the Priority column.
	AppearanceItem = ConditionalAppearance.Items.Add();
	// Appearance type
	AppearanceItem.Appearance.SetParameterValue("ReadOnly", True);
	// Appearance condition
	FilterItem = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem.ComparisonType = DataCompositionComparisonType.NotEqual;
	FilterItem.LeftValue = New DataCompositionField("Object.Performance.LineNumber");
	FilterItem.RightValue = 0;
	// Appearance field
	AppearanceField = AppearanceItem.Fields.Items.Add();
	AppearanceField.Field = New DataCompositionField("Priority");
	
	// Setting "read only" property for the response time threshold of OverallSystemPerformance key operation.
	AppearanceItem = ConditionalAppearance.Items.Add();
	// Appearance type
	AppearanceItem.Appearance.SetParameterValue("ReadOnly", True);
	// Appearance condition
	FilterItem = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	FilterItem.LeftValue = New DataCompositionField("Object.Performance.KeyOperation");
	FilterItem.RightValue = OverallSystemPerformance;
	// Appearance field
	AppearanceField = AppearanceItem.Fields.Items.Add();
	AppearanceField.Field = New DataCompositionField("ResponseTimeThreshold");
	
	// Setting "incomplete" mark for the response time threshold of all attributes except OverallSystemPerformance.
	AppearanceItem = ConditionalAppearance.Items.Add();
	// Appearance type
	AppearanceItem.Appearance.SetParameterValue("MarkIncomplete", True);
	// Appearance condition
	FilterGroup = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	//
	FilterItem = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem.ComparisonType = DataCompositionComparisonType.NotEqual;
	FilterItem.LeftValue = New DataCompositionField("Object.Performance.KeyOperation");
	FilterItem.RightValue = OverallSystemPerformance;
	//
	FilterItem = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	FilterItem.LeftValue = New DataCompositionField("Object.Performance.ResponseTimeThreshold");
	FilterItem.RightValue = 0;
	// Appearance field
	AppearanceField = AppearanceItem.Fields.Items.Add();
	AppearanceField.Field = New DataCompositionField("ResponseTimeThreshold");
	
	FieldsCount = FilterFields.Count() - 1;
	
	// Appearance if the operation is not performed.
	For FieldIndex = 0 To FieldsCount Do
		
		AppearanceItem = ConditionalAppearance.Items.Add();
		
		// Appearance type
		AppearanceItem.Appearance.SetParameterValue("Text", " ");
		// Appearance condition
		FilterItem = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
		FilterItem.ComparisonType = DataCompositionComparisonType.Equal;
		FilterItem.LeftValue = New DataCompositionField(FilterFields[FieldIndex]);
		FilterItem.RightValue = 0;
		// Appearance field
		AppearanceField = AppearanceItem.Fields.Items.Add();
		AppearanceField.Field = New DataCompositionField(AppearanceFields[FieldIndex]);
		
	EndDo;
	
	// Appearance for performance indicators.
	Map = ColorToAPDEXLevelMap();
	For Each KeyValue In Map Do
	
		For FieldIndex = 0 To FieldsCount Do
			
			AppearanceItem = ConditionalAppearance.Items.Add();
			
			// Appearance type
			AppearanceItem.Appearance.SetParameterValue("BackColor", KeyValue.Value.Color);
			// Appearance condition
			FilterItem = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
			FilterItem.ComparisonType = DataCompositionComparisonType.GreaterOrEqual;
			FilterItem.LeftValue = New DataCompositionField(FilterFields[FieldIndex]);
			FilterItem.RightValue = KeyValue.Value.From;
			// Appearance condition
			FilterItem = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
			FilterItem.ComparisonType = DataCompositionComparisonType.Less;
			FilterItem.LeftValue = New DataCompositionField(FilterFields[FieldIndex]);
			FilterItem.RightValue = KeyValue.Value.To;
			// Appearance field
			AppearanceField = AppearanceItem.Fields.Items.Add();
			AppearanceField.Field = New DataCompositionField(AppearanceFields[FieldIndex]);
			
		EndDo;
		
	EndDo;
	
EndProcedure

// Updates a chart.
//
// Parameters:
//  KeyOperationTable - ValueTable - data to use for updating the chart.
//
&AtServer
Procedure UpdateChart(KeyOperationTable)
	
	Chart = Object.Chart;
	
	Chart.RefreshEnabled = False;
	
	Chart.AutoMaxValue	= False;
	Chart.AutoMinValue	= False;
	Chart.MaxValue		= 1;
	Chart.MinValue		= 0;
	Chart.BaseValue			= 0;
	Chart.HideBaseValue	= True;
	
	Chart.Clear();
	
	TitleText = NStr("ru = 'Диаграмма производительности с %1 по %2 - шаг: %3'; en = 'Chart of performance from %1 to %2 with step %3'; pl = 'Chart of performance from %1 to %2 with step %3';de = 'Chart of performance from %1 to %2 with step %3';ro = 'Chart of performance from %1 to %2 with step %3';tr = 'Chart of performance from %1 to %2 with step %3'; es_ES = 'Chart of performance from %1 to %2 with step %3'");
	TitleText = StrReplace(TitleText, "%1", Format(Object.StartDate, "DLF=D"));
	TitleText = StrReplace(TitleText, "%2", Format(Object.EndDate, "DLF=D"));
	TitleText = StrReplace(TitleText, "%3", String(Object.Step));
	Items.Chart.Title = TitleText;
	
	KeyOperationTable.Columns.Delete(1); // Priority
	KeyOperationTable.Columns.Delete(1); // ResponseTimeThreshold
	
	For Each KeyOperationTableRow In KeyOperationTable Do
		
		Series = Chart.Series.Add(KeyOperationTableRow.KeyOperation);
		Series.Text = KeyOperationTableRow.KeyOperation;
		
	EndDo;
	
	KeyOperationTable.Columns.Delete(0); // KeyOperation
	
	For Each KeyOperationTableColumn In KeyOperationTable.Columns Do
		
		Dot = Chart.Points.Add(KeyOperationTableColumn.Name);
		Dot.Text = ?(Object.Step = "Hour", Left(KeyOperationTableColumn.Title, 2), KeyOperationTableColumn.Title); //Displaying only hours if the step is Hour.
		Row = 0;
		Column = KeyOperationTable.Columns.IndexOf(KeyOperationTableColumn);
		For Each Series In Chart.Series Do
			
			DotValue = KeyOperationTable[Row][Column];
			If DotValue <> Undefined AND DotValue <> Null Then
				Chart.SetValue(Dot, Series, ?(DotValue = 0.001 OR DotValue = 0, DotValue, DotValue - 0.001));
			EndIf;	
			Row = Row + 1;
			
		EndDo;
		
	EndDo;
	
	Chart.ChartType = ChartType.Line;
	
	Chart.RefreshEnabled = True;
	
EndProcedure

///////////////////////////////////////////////////////////////////////
// AUXILIARY PROCEDURES AND FUNCTIONS

// Shifts tabular section rows and re-prioritizes key operations.
//
// Parameters:
//  ShiftDirection - Number,
//  	-1, shift up
//  	1, shift down
//  CurrentIndex - Number - index of the row to be shifted.
//
&AtClient
Procedure ExecuteRowShift(ShiftDirection, CurrentIndex)
	
	Temp = Object.Performance;
	
	Priority1 = Temp[CurrentIndex].Priority;
	Priority2 = Temp[CurrentIndex + ShiftDirection].Priority;
	
	ExchangePriorities(
		Temp[CurrentIndex].KeyOperation,
		Priority1,
		Temp[CurrentIndex + ShiftDirection].KeyOperation, 
		Priority2);
		
	Temp[CurrentIndex].Priority = Priority2;
	Temp[CurrentIndex + ShiftDirection].Priority = Priority1;
	
	Temp.Move(CurrentIndex, ShiftDirection);
	
EndProcedure

// Sets an exclusive managed lock for a reference.
//
&AtServerNoContext
Procedure LockRef(Ref)
	
	DataLock = New DataLock;
	LockItem = DataLock.Add(Ref.Metadata().FullName());
	LockItem.SetValue("Ref", Ref);
	DataLock.Lock();
	
EndProcedure

// Starts a transaction and sets an exclusive managed lock according to the value of a reference.
// 
//
// Parameters:
//  Reference - AnyRef - reference to lock.
//
// Returns:
//  Object - object retrieved by reference.
//
&AtServerNoContext
Function StartObjectChange(Ref)
	
	LockRef(Ref);
	
	Object = Ref.GetObject();
	
	Return Object;
	
EndFunction

// Commits a transaction and records an object.
//
// Parameters:
//  Object - AnyObject - object to commit the changes for.
//  MustRecord - Boolean - whether to record the object before committing the transaction.
//
&AtServerNoContext
Procedure CommitObjectChange(Object, Write = True)
	
	If Write Then
		Object.Write();
	EndIf;
	
EndProcedure

// Swaps the priorities of two key operations.
//
// Parameters:
//  KeyOperation1 - CatalogRef.KeyOperations
//  Priority1 - Number - to be set for KeyOperation2.
//  KeyOperation2 - CatalogRef.KeyOperations
//  Priority2 - Number - to be set for KeyOperation1.
//
&AtServer
Procedure ExchangePriorities(KeyOperation1, Priority1, KeyOperation2, Priority2)
	
	BeginTransaction();
	
	Try
		KeyOperationsObject = StartObjectChange(KeyOperation1);
		KeyOperationsObject.Priority = Priority2;
		KeyOperationsObject.AdditionalProperties.Insert(PerformanceMonitorClientServer.DoNotCheckPriority());
		CommitObjectChange(KeyOperationsObject);
		
		KeyOperationsObject = StartObjectChange(KeyOperation2);
		KeyOperationsObject.Priority = Priority1;
		CommitObjectChange(KeyOperationsObject);
		
		CommitTransaction();
	Except
		RollbackTransaction();
 		WriteLogEvent(NStr("ru = 'Выполнение операции'; en = 'Performing transaction'; pl = 'Performing transaction';de = 'Performing transaction';ro = 'Performing transaction';tr = 'Performing transaction'; es_ES = 'Performing transaction'", Metadata.DefaultLanguage.LanguageCode), EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
 		Raise;
	EndTry;
	
EndProcedure

// Opens the choice form for the KeyOperations catalog and filters out operations that have already 
// been selected.
//
&AtClient
Procedure OpenChoiceForm()
	
	TS = Object.Performance;
	
	Filter = New Array;
	For TSIndex = 0 To TS.Count() - 1 Do
		Filter.Add(TS[TSIndex].KeyOperation);
	EndDo;
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", Filter);
	FormParameters.Insert("ChoiceMode", True);
	
	Notification = New NotifyDescription(
		"AddKeyOperationCompletion",
		ThisObject);
		
	OpenForm(
		"Catalog.KeyOperations.ChoiceForm", 
		FormParameters, 
		ThisObject,
		,,,
		Notification, FormWindowOpeningMode.LockWholeInterface);
	
EndProcedure

&AtClient
Procedure AddKeyOperationCompletion(KeyOperationParameters, Parameters) Export
	
	If KeyOperationParameters = Undefined Then
		Return;
	EndIf;
	AddKeyOperationServer(KeyOperationParameters);
	
EndProcedure

&AtServer
Procedure AddKeyOperationServer(KeyOperationParameters)
	
	NewRow = Object.Performance.Add();
	NewRow.KeyOperation = KeyOperationParameters.KeyOperation;
	NewRow.ResponseTimeThreshold = KeyOperationParameters.ResponseTimeThreshold;
	NewRow.Priority = KeyOperationParameters.Priority;
	
	Object.Performance.Sort("Priority");
	
EndProcedure

// Calculates the exact start and end dates for a time range.
//
// Parameters:
//  StartDate [OUT] - Date - period start date.
//  EndDate [OUT] - Date - period end date.
//  PeriodIndex [IN] - Number - period index.
//
// Returns:
//  Boolean:
//  	True if calculated,
//  	False otherwise.
//
&AtServer
Function CalculateTimeRangeDates(StartDate, EndDate, PeriodIndex)
	
	ThisDataProcessor = FormAttributeToValue("Object");
	
	StepValue = 0;
	StepsCount = 0;
	If Not ThisDataProcessor.ChartPeriodicity(StepValue, StepsCount) Then
		Return False;
	EndIf;
	
	If StepsCount <= PeriodIndex Then
		Raise NStr("ru = 'Количество шагов не может быть меньше индекса.'; en = 'The number of steps cannot be less than the index.'; pl = 'The number of steps cannot be less than the index.';de = 'The number of steps cannot be less than the index.';ro = 'The number of steps cannot be less than the index.';tr = 'The number of steps cannot be less than the index.'; es_ES = 'The number of steps cannot be less than the index.'");
	EndIf;
	
	StartDate = Object.StartDate + (StepValue * PeriodIndex);
	If StepValue <> 0 Then
		EndDate = StartDate + StepValue - 1;
	Else
		EndDate = EndOfDay(Object.EndDate);
	EndIf;
		
	Return True;
	
EndFunction

// Creates a value table to be used for APDEX calculation.
//
// Returns:
//  ValueTable - value table containing the structure to be used for APDEX calculation.
//
&AtServerNoContext
Function KeyOperationTableForApdexCalculating()
	
	KeyOperationTable = New ValueTable;
	KeyOperationTable.Columns.Add(
		"KeyOperation", 
		New TypeDescription("CatalogRef.KeyOperations"));
	KeyOperationTable.Columns.Add(
		"Priority", 
		New TypeDescription("Number", New NumberQualifiers(15, 0, AllowedSign.Nonnegative)));
	KeyOperationTable.Columns.Add(
		"ResponseTimeThreshold",
		New TypeDescription("Number", New NumberQualifiers(15, 2, AllowedSign.Nonnegative)));
	
	Return KeyOperationTable;
	
EndFunction

///////////////////////////////////////////////////////////////////////
// AUXILIARY PROCEDURES AND FUNCTIONS (APPEARANCE, SETTINGS)

// Returns the Unacceptable value color.
//
// Returns:
//  Color - value color
//
&AtServerNoContext
Function ColorUnacceptable()
	
	Return New Color(187, 187, 187);
	
EndFunction

// Returns the Poor value color.
//
// Returns:
//  Color - value color
//
&AtServerNoContext
Function ColorPoor()
	
	Return New Color(255, 212, 171);
	
EndFunction

// Returns the Tolerated value color.
//
// Returns:
//  Color - value color
//
&AtServerNoContext
Function ColorTolerated()
	
	Return New Color(255, 255, 153);
	
EndFunction

// Returns the Good value color.
//
// Returns:
//  Color - value color
//
&AtServerNoContext
Function ColorGood()
	
	Return New Color(204, 255, 204);
	
EndFunction

// Returns the Excellent value color.
//
// Returns:
//  Color - value color
//
&AtServerNoContext
Function ColorExcellent()
	
	Return New Color(204, 255, 255);
	
EndFunction

// Returns a map:
// Key - String - performance score.
// Value - Structure - measurement parameters.
//
// Returns:
//  Map
//
&AtServerNoContext
Function ColorToAPDEXLevelMap()
	
	Map = New Map;
	
	Values = New Structure("From, To, Color");
	Values.From = 0.001; // 0 means that the operation is not performed at all.
	Values.To = 0.5;
	Values.Color = ColorUnacceptable();
	Map.Insert("Unacceptable", Values);
	
	Values = New Structure("From, To, Color");
	Values.From = 0.5;
	Values.To = 0.7;
	Values.Color = ColorPoor();
	Map.Insert("Frustrated", Values);
	
	Values = New Structure("From, To, Color");
	Values.From = 0.7;
	Values.To = 0.85;
	Values.Color = ColorTolerated();
	Map.Insert("Tolerated", Values);
	
	Values = New Structure("From, To, Color");
	Values.From = 0.85;
	Values.To = 0.94;
	Values.Color = ColorGood();
	Map.Insert("Satisfactory", Values);
	
	Values = New Structure("From, To, Color");
	Values.From = 0.94;
	Values.To = 1.002; // As conditional appearance compares Before using Less, not LessOrEqual.
	Values.Color = ColorExcellent();
	Map.Insert("Excellent", Values);
	
	Return Map;
	
EndFunction

// Checks if form settings are correct.
//
// Returns:
//  True if the settings are correct,
//  False otherwise.
//
&AtServer
Function SetupExecuted()
	
	Completed = True;
	For Each TSRow In Object.Performance Do
		
		If TSRow.ResponseTimeThreshold = 0 
			AND TSRow.KeyOperation <> Object.OverallSystemPerformance Then
		
			PerformanceMonitorInternal.MessageToUser(
				NStr("ru = 'Целевое время обязательно должно быть заполнено.'; en = 'The response time threshold must be filled.'; pl = 'The response time threshold must be filled.';de = 'The response time threshold must be filled.';ro = 'The response time threshold must be filled.';tr = 'The response time threshold must be filled.'; es_ES = 'The response time threshold must be filled.'"),
				,
				"Performance[" + Format(Object.Performance.IndexOf(TSRow),"NG=0") + "].ResponseTimeThreshold",
				"Object");
			
			Completed = False;
			Break;
		EndIf;
		
	EndDo;
	
	Return Completed;
	
EndFunction

// Completes
// the Performance TS from the KeyOperations catalog when the form is opened for the first time.
//
&AtServerNoContext
Function ImportKeyOperations(OverallSystemPerformance)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	KeyOperations.Ref AS KeyOperation,
	|	KeyOperations.Priority AS Priority,
	|	KeyOperations.ResponseTimeThreshold AS ResponseTimeThreshold
	|FROM
	|	Catalog.KeyOperations AS KeyOperations
	|WHERE
	|	NOT KeyOperations.DeletionMark
	|
	|UNION ALL
	|
	|SELECT
	|	&OverallSystemPerformance,
	|	0,
	|	0
	|WHERE
	|	VALUETYPE(&OverallSystemPerformance) <> TYPE(Catalog.KeyOperations)
	|
	|ORDER BY
	|	Priority
	|AUTOORDERBY";
	Query.SetParameter("OverallSystemPerformance", OverallSystemPerformance);
	Result = Query.Execute();
	
	If Result.IsEmpty() Then
		Return New ValueTable;
	EndIf;
	
	Return Result.Unload();
	
EndFunction

// Changes the time threshold for a key operation.
//
// Parameters:
//  KeyOperation - CatalogRef.KeyOperations - key operation to change the time threshold for.
//  ResponseTimeThreshold - Number - new time threshold.
//
&AtServer
Procedure ChangeResponseTimeThreshold(KeyOperation, ResponseTimeThreshold)
	
	BeginTransaction();
	
	Try
		KeyOperationObject = StartObjectChange(KeyOperation);
		KeyOperationObject.ResponseTimeThreshold = ResponseTimeThreshold;
		CommitObjectChange(KeyOperationObject);
		
		CommitTransaction();
	Except
		RollbackTransaction();
 		WriteLogEvent(NStr("ru = 'Выполнение операции'; en = 'Performing transaction'; pl = 'Performing transaction';de = 'Performing transaction';ro = 'Performing transaction';tr = 'Performing transaction'; es_ES = 'Performing transaction'", Metadata.DefaultLanguage.LanguageCode), EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
 		Raise;
	EndTry;
	
EndProcedure

// Removes value table rows not matching the filtering criteria.
//
// Parameters:
//  KeyOperationTable - ValueTable - table to be filtered.
//  FilterValues - Array - array of strings used for filtering.
//
&AtServerNoContext
Procedure SetFilterKeyOperationTable(KeyOperationTable, FilterValues)
	
	If FilterValues.Direction > 0 Then
		If Upper(FilterValues.State) = "GOOD" Then
			Limit = 0.93;
		ElsIf Upper(FilterValues.State) = "FAIR" Then
			Limit = 0.84;
		ElsIf Upper(FilterValues.State) = "FRUSTRATED" Then
			Limit = 0.69;
		EndIf;
	ElsIf FilterValues.Direction < 0 Then
		If Upper(FilterValues.State) = "GOOD" Then
			Limit = 0.85;
		ElsIf Upper(FilterValues.State) = "FAIR" Then
			Limit = 0.7;
		ElsIf Upper(FilterValues.State) = "FRUSTRATED" Then
			Limit = 0.5;
		EndIf;
	EndIf;
	
	Cnt = 0;
	Delete = False;
	While Cnt < KeyOperationTable.Count() Do
		
		For Each KeyOperationTableColumn In KeyOperationTable.Columns Do
			If (Left(KeyOperationTableColumn.Name, 18) <> "Performance") Or (KeyOperationTable[Cnt][KeyOperationTableColumn.Name] = 0) Then
				Continue;
			EndIf;
			
			If FilterValues.Direction > 0 Then
				If KeyOperationTable[Cnt][KeyOperationTableColumn.Name] > Limit Then
					Delete = False;
					Break;
				Else
					Delete = True;
				EndIf;
			ElsIf FilterValues.Direction < 0 Then
				If KeyOperationTable[Cnt][KeyOperationTableColumn.Name] < Limit Then
					Delete = False;
					Break;
				Else
					Delete = True;
				EndIf;
			EndIf;
		EndDo;
		
		If Delete Then
			KeyOperationTable.Delete(Cnt);
		Else
			Cnt = Cnt + 1;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure DeleteKeyOperationAtServer()
	
	RowID = Items.Performance.CurrentRow;
	If RowID = Undefined Then
		Return;
	EndIf;
	
	PerformanceDynamicsData = Object.Performance;
	ActiveString = PerformanceDynamicsData.FindByID(RowID);
	If ActiveString <> Undefined Then
		PerformanceDynamicsData.Delete(PerformanceDynamicsData.IndexOf(ActiveString));
	EndIf;
	
EndProcedure

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	Comments = GetRecentComments();
	ChoiceData = New ValueList;
	For Each Comment In Comments Do
		ChoiceData.Add(Comment);
	EndDo;
	
	StandardProcessing = False;
EndProcedure

&AtServerNoContext
Function GetRecentComments()
	Return InformationRegisters.TimeMeasurements.GetRecentComments();
EndFunction

&AtClient
Procedure CommentChoiceProcessing(Item, ValueSelected, StandardProcessing)
	If NOT IsBlankString(ValueSelected) AND Object.FilterOptionComment = "DontFilter" Then
		Object.FilterOptionComment = "EqualTo";
	EndIf;
EndProcedure

&AtClient
Procedure EndDateChoiceProcessing(Item, ValueSelected, StandardProcessing)
	Object.EndDate = EndOfDay(ValueSelected);
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure ExportMeasurements(Command)
	OpenForm("DataProcessor.PerformanceMonitor.Form.ExportPerformanceMeasurements", , ThisObject,,,,,FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

#EndRegion
