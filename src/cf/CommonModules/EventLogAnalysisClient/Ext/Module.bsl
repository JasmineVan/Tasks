///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// Client events of the report form.

// The details handler of a spreadsheet document of a report form.
//
// Parameters:
//   ReportForm - ManagedForm - a report form.
//   Item - FormField - a spreadsheet document.
//   Details - this parameter is passed "as is" from handler parameters.
//   StandardProcessing - this parameter is passed "as is" from handler parameters.
//
// See also:
//   "Form field extension for a spreadsheet document field.DetailProcessing" in Syntax Assistant.
//
Procedure ReportFormDetailProcessing(ReportForm, Item, Details, StandardProcessing) Export
	If Details = Undefined Then
		Return;
	EndIf;
	
	If ReportForm.ReportSettings.FullName <> "Report.EventLogAnalysis" Then
		Return;
	EndIf;
	
	If TypeOf(Item.CurrentArea) = Type("SpreadsheetDocumentDrawing") Then
		If TypeOf(Item.CurrentArea.Object) = Type("Chart") Then
			StandardProcessing = False;
			Return;
		EndIf;
	EndIf;
	
	ReportOptionParameter = ReportsClientServer.FindParameter(
		ReportForm.Report.SettingsComposer.Settings,
		ReportForm.Report.SettingsComposer.UserSettings,
		"ReportOption");
	If ReportOptionParameter = Undefined Or ReportOptionParameter.Value <> "GanttChart" Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	DetailsType = Details.Get(0);
	If DetailsType = "ScheduledJobDetails" Then
		
		DetailsOption = New ValueList;
		DetailsOption.Add("ScheduledJobInfo", NStr("ru = 'Сведения о регламентном задании'; en = 'Scheduled job info'; pl = 'Informacja o zaplanowanym zadaniu';de = 'Geplante Auftragsinformationen';ro = 'Informații despre sarcina reglementară';tr = 'Planlı işler bilgisi'; es_ES = 'Información de la tarea programada'"));
		DetailsOption.Add("OpenEventLog", NStr("ru = 'Перейти к журналу регистрации'; en = 'Go to event log'; pl = 'Przejdź do dziennika zdarzeń';de = 'Ereignisprotokoll öffnen';ro = 'Accesați registrul de înregistrare';tr = 'Olay günlüğüne git'; es_ES = 'Ir al registro de eventos'"));
		
		HandlerParameters = New Structure;
		HandlerParameters.Insert("Details", Details);
		HandlerParameters.Insert("ReportForm", ReportForm);
		Handler = New NotifyDescription("DetailProcessingResultCompletion", ThisObject, HandlerParameters);
		ReportForm.ShowChooseFromMenu(Handler, DetailsOption);
		
	ElsIf DetailsType <> Undefined Then
		ShowScheduledJobInfo(Details);
	EndIf;
	
EndProcedure

// The handler of additional details (menu of a spreadsheet document of a report form).
//
// Parameters:
//   ReportForm - ManagedForm - a report form.
//   Item - FormField - a spreadsheet document.
//   Details - this parameter is passed "as is" from handler parameters.
//   StandardProcessing - this parameter is passed "as is" from handler parameters.
//
// See also:
//   "Form field extension for a spreadsheet document field.AdditionalDetailProcessing" in Syntax Assistant.
//
Procedure AdditionalDetailProcessingReportForm(ReportForm, Item, Details, StandardProcessing) Export
	If ReportForm.ReportSettings.FullName <> "Report.EventLogAnalysis" Then
		Return;
	EndIf;
	If TypeOf(Item.CurrentArea) = Type("SpreadsheetDocumentDrawing") Then
		If TypeOf(Item.CurrentArea.Object) = Type("Chart") Then
			StandardProcessing = False;
			Return;
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region Private

Procedure DetailProcessingResultCompletion(SelectedOption, HandlerParameters) Export
	If SelectedOption = Undefined Then
		Return;
	EndIf;
	
	Action = SelectedOption.Value;
	If Action = "ScheduledJobInfo" Then
		
		PointsList = HandlerParameters.ReportForm.ReportSpreadsheetDocument.Areas.GanttChart.Object.Points;
		For Each GanttChartPoint In PointsList Do
			
			PointDetails = GanttChartPoint.Details;
			If GanttChartPoint.Value = NStr("ru = 'Фоновые задания'; en = 'Background jobs'; pl = 'Zadania w tle';de = 'Hintergrund Aufgaben';ro = 'Sarcini de fundal';tr = 'Arkaplan işleri'; es_ES = 'Tareas de fondo'") Then
				Continue;
			EndIf;
			
			If PointDetails.Find(HandlerParameters.Details.Get(2)) <> Undefined Then
				ShowScheduledJobInfo(PointDetails);
				Break;
			EndIf;
			
		EndDo;
		
	ElsIf Action = "OpenEventLog" Then
		
		ScheduledJobSession = New ValueList;
		ScheduledJobSession.Add(HandlerParameters.Details.Get(1));
		StartDate = HandlerParameters.Details.Get(3);
		EndDate = HandlerParameters.Details.Get(4);
		EventLogFilter = New Structure("Session, StartDate, EndDate", 
			ScheduledJobSession, StartDate, EndDate);
		OpenForm("DataProcessor.EventLog.Form.EventLog", EventLogFilter);
		
	EndIf;
	
EndProcedure

Procedure ShowScheduledJobInfo(Details)
	FormParameters = New Structure("DetailsFromReport", Details);
	OpenForm("Report.EventLogAnalysis.Form.ScheduledJobInfo", FormParameters);
EndProcedure

#EndRegion