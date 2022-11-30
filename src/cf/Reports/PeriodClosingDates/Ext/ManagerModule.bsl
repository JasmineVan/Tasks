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
	ReportSettings.Enabled = False;
	
	FirstOption = FirstOption();
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, FirstOption.Name);
	OptionSettings.Enabled  = True;
	OptionSettings.Details = FirstOption.Details;
	
	SecondOption = SecondOption();
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, SecondOption.Name);
	OptionSettings.Enabled  = True;
	OptionSettings.Details = SecondOption.Details;
	
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInfo, StandardProcessing)
	
	If FormType <> "Form" Then
		Return;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.ReportsOptions") Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	SelectedForm = "ReportForm";
	
EndProcedure

#EndRegion

#Region Private

// Called from the report form.
Procedure SetOption(Form, Option) Export
	
	FirstOption = FirstOption();
	SecondOption = SecondOption();
	
	CustomizeForm(Form, FirstOption, SecondOption, Option);
	
EndProcedure

// Calls the SetOption procedure.
Procedure CustomizeForm(Form, FirstOption, SecondOption, Option) Export
	
	Items = Form.Items;
	
	If Option = 0 Then
		Form.Parameters.GenerateOnOpen = True;
		Items.FormFirstOption.Title = FirstOption.Title;
		Items.FormSecondOption.Title = SecondOption.Title;
	Else
		FullReportName = "Report." + StrSplit(Form.FormName, ".", False)[1];
		
		// Saving the current user settings.
		Common.SystemSettingsStorageSave(
			FullReportName + "/" + Form.CurrentVariantKey + "/CurrentUserSettings",
			"",
			Form.Report.SettingsComposer.UserSettings);
	EndIf;
	
	If Option = 0 Then
		If Form.CurrentVariantKey = FirstOption.Name Then
			Option = 1;
		ElsIf Form.CurrentVariantKey = SecondOption.Name Then
			Option = 2;
		EndIf;
	EndIf;
	
	If Option = 0 Then
		Option = 1;
	EndIf;
	
	If Option = 1 Then
		Items.FormFirstOption.Check = True;
		Items.FormSecondOption.Check = False;
		Form.Title = FirstOption.Title;
		CurrentOptionKey = FirstOption.Name;
	Else
		Items.FormFirstOption.Check = False;
		Items.FormSecondOption.Check = True;
		Form.Title = SecondOption.Title;
		CurrentOptionKey = SecondOption.Name;
	EndIf;
	
	// Importing a new option.
	Form.SetCurrentVariant(CurrentOptionKey);
	
	// Regenerating the report.
	Form.ComposeResult(ResultCompositionMode.Auto);
	
EndProcedure

Function FirstOption()
	
	Try
		Properties = PeriodClosingDatesInternal.SectionsProperties();
	Except
		Properties = New Structure("ShowSections, AllSectionsWithoutObjects", False, True);
	EndTry;
	
	If Properties.ShowSections AND NOT Properties.AllSectionsWithoutObjects Then
		OptionName = "PeriodClosingDatesByUsers";
		
	ElsIf Properties.AllSectionsWithoutObjects Then
		OptionName = "PeriodClosingDatesByUsersWithoutObjects";
	Else
		OptionName = "PeriodClosingDatesByUsersWithoutSections";
	EndIf;
	
	OptionProperties = New Structure;
	OptionProperties.Insert("Name", OptionName);
	
	OptionProperties.Insert("Title",
		NStr("ru = 'Даты запрета изменения данных по пользователям'; en = 'Period-end closing dates by users'; pl = 'Daty zamknięcia wg użytkowników';de = 'Sperrdaten von Benutzern';ro = 'Datele de interdicție a modificării datelor pe utilizatori';tr = 'Kullanıcılara göre kapanış tarihleri'; es_ES = 'Fechas de cierre por usuarios'"));
	
	OptionProperties.Insert("Details",
		NStr("ru = 'Выводит даты запрета изменения, сгруппированные по пользователям.'; en = 'Displays period-end closing dates grouped by users.'; pl = 'Wyświetla daty zakazu zmian, pogrupowane wg użytkowników.';de = 'Zeigt Änderungsverbotsdaten an, die nach Benutzern gruppiert sind.';ro = 'Afișează datele de interdicție a modificării, grupate pe utilizatori.';tr = 'Kullanıcılara göre gruplandırılmış içe aktarma yasaklama tarihleri gösterir.'; es_ES = 'Muestra las fechas de restricción de cambio agrupadas por usuarios.'"));
	
	Return OptionProperties;
	
EndFunction

Function SecondOption()
	
	Try
		Properties = PeriodClosingDatesInternal.SectionsProperties();
	Except
		Properties = New Structure("ShowSections, AllSectionsWithoutObjects", False, True);
	EndTry;
	
	If Properties.ShowSections AND NOT Properties.AllSectionsWithoutObjects Then
		OptionName = "PeriodClosingDatesBySectionsObjectsForUsers";
		Title = NStr("ru = 'Даты запрета изменения данных по разделам и объектам'; en = 'Period-end closing dates by sections and objects'; pl = 'Daty zakazu zmiany danych wg działów i obiektów';de = 'Verbotsdaten zum Ändern von Daten nach Abschnitten und Objekten';ro = 'Datele de interdicție a modificării datelor pe compartimente și obiecte';tr = 'Bölümlere ve nesnelere göre veri değişikliği için son tarih'; es_ES = 'Fechas de restricción de cambio de datos por secciones y objetos'");
		OptionDetails =
			NStr("ru = 'Выводит даты запрета изменения, сгруппированные по разделам с объектами.'; en = 'Displays period-end closing dates grouped by sections with objects.'; pl = 'Wyświetla daty zakazu zmian, pogrupowane wg sekcji z obiektami.';de = 'Zeigt Änderungsverbotsdaten an, die nach Abschnitten mit Objekten gruppiert sind.';ro = 'Afișează datele de interdicție a modificării, grupate pe compartimente cu obiecte.';tr = 'Nesnelerle bölümlere göre gruplandırılmış değişiklik yasaklama tarihleri gösterir.'; es_ES = 'Muestra las fechas de restricción de cambio agrupadas por secciones y objetos.'");
		
	ElsIf Properties.AllSectionsWithoutObjects Then
		OptionName = "PeriodClosingDatesBySectionsForUsers";
		Title = NStr("ru = 'Даты запрета изменения данных по разделам'; en = 'Period-end closing dates by sections'; pl = 'Daty zakazu zmiany danych wg działów';de = 'Verbotsdaten zum Ändern von Daten nach Abschnitten';ro = 'Datele de interdicție a modificării datelor pe compartimente';tr = 'Bölümlere göre veri değişikliği için son tarih'; es_ES = 'Fechas de restricción de cambio de datos por secciones'");
		OptionDetails =
			NStr("ru = 'Выводит даты запрета изменения, сгруппированные по разделам.'; en = 'Displays period-end closing dates grouped by sections.'; pl = 'Wyświetla daty zakazu zmian, pogrupowane wg sekcji.';de = 'Zeigt Änderungsverbotsdaten an, die nach Abschnitten gruppiert sind.';ro = 'Afișează datele de interdicție a modificării, grupate pe compartimente.';tr = 'Bölümlere göre gruplandırılmış değişiklik yasaklama tarihleri gösterir.'; es_ES = 'Muestra las fechas de restricción de cambio agrupadas por secciones.'");
	Else
		OptionName = "PeriodClosingDatesByObjectsForUsers";
		Title = NStr("ru = 'Даты запрета изменения данных по объектам'; en = 'Period-end closing dates by objects'; pl = 'Daty zakazu zmian danych wg obiektów';de = 'Verbotsdaten zum Ändern von Daten nach Objekten';ro = 'Datele de interdicție a modificării datelor pe obiecte';tr = 'Nesnelere göre veri değişikliği için son tarih'; es_ES = 'Fechas de restricción de cambio de datos por objetos'");
		OptionDetails =
			NStr("ru = 'Выводит даты запрета изменения, сгруппированные по объектам.'; en = 'Displays period-end closing dates grouped by objects.'; pl = 'Wyświetla daty zakazu zmian, pogrupowane wg obiektów.';de = 'Zeigt Änderungsverbotsdaten an, die nach Objekten gruppiert sind.';ro = 'Afișează datele de interdicție a modificării, grupate pe obiecte.';tr = 'Nesnelere göre gruplandırılmış değişiklik yasaklama tarihleri gösterir.'; es_ES = 'Muestra las fechas de restricción de cambio agrupadas por objetos.'");
	EndIf;
	
	OptionProperties = New Structure;
	OptionProperties.Insert("Name",       OptionName);
	OptionProperties.Insert("Title", Title);
	OptionProperties.Insert("Details",  OptionDetails);
	
	Return OptionProperties;
	
EndFunction

#EndRegion

#EndIf
