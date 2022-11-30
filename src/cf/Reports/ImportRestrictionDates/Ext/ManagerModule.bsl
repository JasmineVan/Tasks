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
	
	Reports.PeriodClosingDates.CustomizeForm(Form, FirstOption, SecondOption, Option);
	
EndProcedure

Function FirstOption()
	
	Try
		Properties = PeriodClosingDatesInternal.SectionsProperties();
	Except
		Properties = New Structure("ShowSections, AllSectionsWithoutObjects", False, True);
	EndTry;
	
	If Properties.ShowSections AND NOT Properties.AllSectionsWithoutObjects Then
		OptionName = "ImportRestrictionDatesByInfobases";
		
	ElsIf Properties.AllSectionsWithoutObjects Then
		OptionName = "ImportRestrictionDatesByInfobasesWithoutObjects";
	Else
		OptionName = "ImportRestrictionDatesByInfobasesWithoutSections";
	EndIf;
	
	OptionProperties = New Structure;
	OptionProperties.Insert("Name", OptionName);
	
	OptionProperties.Insert("Title",
		NStr("ru = 'Даты запрета загрузки данных по информационным базам'; en = 'Data import restriction dates by infobases'; pl = 'Data zakazu importu danych wg baz informacyjnych';de = 'Abschlussdatum des Datenimports durch Infobasen';ro = 'Datele de interdicție a importului de date în bazele de informații';tr = 'Verilerin veri tabanlarından içe aktarılmasına kapatıldığı tarih'; es_ES = 'Fecha de cierre de la importación de datos por infobases'"));
	
	OptionProperties.Insert("Details",
		NStr("ru = 'Выводит даты запрета загрузки для объектов, сгруппированные по информационным базам.'; en = 'Displays data import restriction dates for objects grouped by infobases.'; pl = 'Wyświetla daty zakazu pobierania obiektów, pogrupowanych wg baz informacyjnych.';de = 'Zeigt die Download-Verbotsdaten für Objekte an, die nach Informationsdatenbanken gruppiert sind.';ro = 'Afișează datele de interdicție a importului pentru obiecte, grupate pe bazele de informații.';tr = 'Veri tabanlarına göre gruplandırılmış nesneler için içe aktarma tarihleri gösterir.'; es_ES = 'Visualiza las fechas sin importar para los objetos agrupados por las bases de información.'"));
	
	Return OptionProperties;
	
EndFunction

Function SecondOption()
	
	Try
		Properties = PeriodClosingDatesInternal.SectionsProperties();
	Except
		Properties = New Structure("ShowSections, AllSectionsWithoutObjects", False, True);
	EndTry;
	
	If Properties.ShowSections AND NOT Properties.AllSectionsWithoutObjects Then
		OptionName = "ImportRestrictionDatesBySectionsObjectsForInfobases";
		Title = NStr("ru = 'Даты запрета загрузки данных по разделам и объектам'; en = 'Data import restriction dates by sections and objects'; pl = 'Daty zakazu pobierania danych wg działów i obiektów';de = 'Daten zum Verbot des Datenladens nach Abschnitten und Objekten';ro = 'Datele de interdicție a importului de date pe compartimente și obiecte';tr = 'Bölümlere ve nesnelere göre veri yüklenmesi için son tarih'; es_ES = 'Fechas de restricción de descargas de datos por secciones y objetos'");
		OptionDetails =
			NStr("ru = 'Выводит даты запрета загрузки, сгруппированные по разделам с объектами.'; en = 'Displays data import restriction dates grouped by sections with objects.'; pl = 'Wyświetla daty zakazu pobierania, pogrupowane wg sekcji z obiektami.';de = 'Zeigt die Download-Verbotsdaten gruppiert nach Objektbereichen an.';ro = 'Afișează datele de interdicție a importului, grupate pe compartimente cu obiecte.';tr = 'Nesnelerle bölümlere göre gruplandırılmış içe aktarma yasaklama tarihleri gösterir.'; es_ES = 'Visualiza las fechas sin importar para los usuarios agrupados por secciones con objetos.'");
		
	ElsIf Properties.AllSectionsWithoutObjects Then
		OptionName = "ImportRestrictionDatesBySectionsForInfobases";
		Title = NStr("ru = 'Даты запрета загрузки данных по разделам'; en = 'Data import restriction dates by sections'; pl = 'Daty zakazu pobierania danych wg działów';de = 'Verbotsdaten des Ladens von Daten nach Abschnitten';ro = 'Datele de interdicție a importului de date pe compartimente';tr = 'Bölümlere göre veri yüklenmesi için son tarih'; es_ES = 'Fechas de restricción de descargas de datos por secciones'");
		OptionDetails =
			NStr("ru = 'Выводит даты запрета загрузки, сгруппированные по разделам.'; en = 'Displays data import restriction dates grouped by sections.'; pl = 'Wyświetla daty zakazu pobierania, pogrupowane wg sekcji.';de = 'Zeigt die Download-Verbotsdaten nach Abschnitten gruppiert an.';ro = 'Afișează datele de interdicție a importului, grupate pe compartimente.';tr = 'Bölümlere göre gruplandırılmış içe aktarma yasaklama tarihleri gösterir.'; es_ES = 'Muestra las fechas de restricción de descargas agrupadas por secciones.'");
	Else
		OptionName = "ImportRestrictionDatesByObjectsForInfobases";
		Title = NStr("ru = 'Даты запрета загрузки данных по объектам'; en = 'Data import restriction dates by objects'; pl = 'Daty zakazu pobierania danych wg obiektów';de = 'Verbotsdaten des Ladens von Daten nach Objekten';ro = 'Datele de interdicție a importului de date pe obiecte';tr = 'Nesnelere göre veri yüklenmesi için son tarih'; es_ES = 'Fechas de restricción de descargas de datos por objetos'");
		OptionDetails =
			NStr("ru = 'Выводит даты запрета загрузки, сгруппированные по объектам.'; en = 'Displays data import restriction dates grouped by objects.'; pl = 'Wyświetla daty zakazu pobierania, pogrupowane wg obiektów.';de = 'Zeigt die Download-Verbotsdaten nach Objekten gruppiert an.';ro = 'Afișează datele de interdicție a importului, grupate pe obiecte.';tr = 'Nesnelere göre gruplandırılmış içe aktarma yasaklama tarihleri gösterir.'; es_ES = 'Muestra las fechas de restricción de descargas agrupadas por objetos.'");
	EndIf;
	
	OptionProperties = New Structure;
	OptionProperties.Insert("Name",       OptionName);
	OptionProperties.Insert("Title", Title);
	OptionProperties.Insert("Details",  OptionDetails);
	
	Return OptionProperties;
	
EndFunction

#EndRegion

#EndIf
