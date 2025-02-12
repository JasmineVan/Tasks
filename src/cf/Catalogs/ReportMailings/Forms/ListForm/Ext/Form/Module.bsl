﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("Representation") Then
		Items.List.Representation = TableRepresentation[Parameters.Representation];
	EndIf;
	
	ErrorTextOnOpen = ReportMailing.CheckAddRightErrorText();
	If ValueIsFilled(ErrorTextOnOpen) Then
		Raise ErrorTextOnOpen;
	EndIf;
	
	// Set dynamic list filters.
	CommonClientServer.SetDynamicListFilterItem(
		List, "ExecuteOnSchedule", False,
		DataCompositionComparisonType.Equal, , False,
		DataCompositionSettingsItemViewMode.Normal);
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "SchedulePeriodicity", ,
		DataCompositionComparisonType.Equal, , False,
		DataCompositionSettingsItemViewMode.Normal);
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "Prepared", False,
		DataCompositionComparisonType.Equal, , False,
		DataCompositionSettingsItemViewMode.Normal);
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "Author", ,
		DataCompositionComparisonType.Equal, , False,
		DataCompositionSettingsItemViewMode.Normal);
	
	FillListParameter("ChoiceMode");
	FillListParameter("ChoiceFoldersAndItems");
	FillListParameter("MultipleChoice");
	FillListParameter("CurrentRow");
	
	If Not AccessRight("Update", Metadata.Catalogs.ReportMailings) Then
		// Show only personal mailing. Groups and excess columns are hidden.
		Items.List.Representation = TableRepresentation.List;
		CommonClientServer.SetDynamicListFilterItem(List, "IsFolder", False, , , True,
			DataCompositionSettingsItemViewMode.Inaccessible);
	EndIf;
	
	ReportFilter = Parameters.Report;
	SetFilter(False);

	List.Parameters.SetParameterValue("EmptyDate", '00010101');
	List.Parameters.SetParameterValue("NewStatePresentation", NStr("ru = 'Новая'; en = 'New'; pl = 'New';de = 'New';ro = 'New';tr = 'New'; es_ES = 'New'"));
	List.Parameters.SetParameterValue("NotCompletedStatePresentation", NStr("ru = 'Не выполнена'; en = 'Not completed'; pl = 'Not completed';de = 'Not completed';ro = 'Not completed';tr = 'Not completed'; es_ES = 'Not completed'"));
	List.Parameters.SetParameterValue("CompletedWithErrorsStatePresentation", NStr("ru = 'Выполнена с ошибками'; en = 'Completed with errors'; pl = 'Completed with errors';de = 'Completed with errors';ro = 'Completed with errors';tr = 'Completed with errors'; es_ES = 'Completed with errors'"));
	List.Parameters.SetParameterValue("CompletedStatePresentation", NStr("ru = 'Выполнена'; en = 'Completed'; pl = 'Completed';de = 'Completed';ro = 'Completed';tr = 'Completed'; es_ES = 'Completed'"));
	
	If Not Common.SubsystemExists("StandardSubsystems.BatchEditObjects")
		Or Not AccessRight("Update", Metadata.Catalogs.ReportMailings) Then
		Items.ChangeSelectedItems.Visible = False;
		Items.ChangeSelectedItemsList.Visible = False;
	EndIf;
	
	If Not AccessRight("EventLog", Metadata) Then
		Items.MailingEvents.Visible = False;
	EndIf;
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	SetListFilter(Settings);
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterOnChangeStatus(Item)
	SetFilter();
EndProcedure

&AtClient
Procedure FilterOnChangeReport(Item)
	SetFilter();
EndProcedure

&AtClient
Procedure FilterOnChangeEmployeeResponsible(Item)
	SetFilter();
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure ChangeSelectedItems(Command)
	ModuleBatchObjectModificationClient = CommonClient.CommonModule("BatchEditObjectsClient");
	ModuleBatchObjectModificationClient.ChangeSelectedItems(Items.List);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.LastRun", Items.LastRun.Name);
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.SuccessfulStart", Items.SuccessfulStart.Name);

	ConditionalAppearanceItem = List.ConditionalAppearance.Items.Add();
	ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	// Unprepared report mailings
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("IsFolder");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = False;
	DataFilterItem.Use = True;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("Prepared");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = False;
	DataFilterItem.Use = True;
	
	AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("TextColor");
	AppearanceColorItem.Value = Metadata.StyleItems.InaccessibleCellTextColor.Value;
	AppearanceColorItem.Use = True;
	
EndProcedure

&AtServer
Procedure FillListParameter(varKey)
	If Parameters.Property(varKey) AND ValueIsFilled(Parameters[varKey]) Then
		Items.List[varKey] = Parameters[varKey];
	EndIf;
EndProcedure

&AtServer
Procedure SetFilter(ClearFixedFilters = True)
	
	If ClearFixedFilters Then
		List.Filter.Items.Clear();
	EndIf;
	FilterParameters = New Map();
	FilterParameters.Insert("WithErrors", StateFilter);
	FilterParameters.Insert("Report", ReportFilter);
	FilterParameters.Insert("Author", EmployeeResponsibleFilter);
	SetListFilter(FilterParameters);
EndProcedure

&AtServer
Procedure SetListFilter(FilterParameters)
	
	CommonClientServer.SetDynamicListFilterItem(List, "Author", FilterParameters["Author"],,,
		Not FilterParameters["Author"].IsEmpty());
	CommonClientServer.SetDynamicListFilterItem(List, "WithErrors", FilterParameters["WithErrors"] = "Incomplete",,, 
		FilterParameters["WithErrors"] <> "All" AND ValueIsFilled(FilterParameters["WithErrors"]));
	CommonClientServer.SetDynamicListParameter(List, "ReportFilter", FilterParameters["Report"],
		ValueIsFilled(FilterParameters["Report"]) AND Not FilterParameters["Report"].IsEmpty());
	
EndProcedure

#EndRegion
