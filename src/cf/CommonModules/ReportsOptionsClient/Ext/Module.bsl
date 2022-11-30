///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Opens a form of the specified report.
//
// Parameters:
//  OwnerForm - ManagedForm, Undefined - a form that opens the report.
//  Option - CatalogRef.ReportsOptions, CatalogRef.AdditionalReportsAndDataProcessors - a report 
//            option to open the form for. If the CatalogRef.AdditionalReportsAndDataProcessors type 
//            is passed, an additional report attached to the application is opened.
//  AdditionalParameters - Structure - an internal parameter that is not intended for use.
//
Procedure OpenReportForm(Val OwnerForm, Val Option, Val AdditionalParameters = Undefined) Export
	Type = TypeOf(Option);
	If Type = Type("Structure") Then
		OpeningParameters = Option;
	ElsIf Type = Type("CatalogRef.ReportsOptions") 
		Or Type = AdditionalReportRefType() Then
		OpeningParameters = New Structure("Key", Option);
		If AdditionalParameters <> Undefined Then
			CommonClientServer.SupplementStructure(OpeningParameters, AdditionalParameters, True);
		EndIf;
		OpenForm("Catalog.ReportsOptions.ObjectForm", OpeningParameters, Undefined, True);
		Return;
	Else
		OpeningParameters = New Structure("Ref, Report, ReportType, ReportName, VariantKey, MeasurementsKey");
		If TypeOf(OwnerForm) = Type("ManagedForm") Then
			FillPropertyValues(OpeningParameters, OwnerForm);
		EndIf;
		FillPropertyValues(OpeningParameters, Option);
	EndIf;
	
	If AdditionalParameters <> Undefined Then
		CommonClientServer.SupplementStructure(OpeningParameters, AdditionalParameters, True);
	EndIf;
	
	ReportsOptionsClientServer.AddKeyToStructure(OpeningParameters, "RunMeasurements", False);
	
	OpeningParameters.ReportType = ReportsOptionsClientServer.ReportByStringType(OpeningParameters.ReportType, OpeningParameters.Report);
	If Not ValueIsFilled(OpeningParameters.ReportType) Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Не определен тип отчета в %1'; en = 'Report type is not specified in %1'; pl = 'Nie określono rodzaju sprawozdania w %1';de = 'Der Berichtstyp in %1 ist nicht festgelegt';ro = 'Tipul de raport în %1 nu este definit';tr = 'Rapor türü %1 belirlenmedi'; es_ES = 'Tipo de informe en %1 no está determinado'"), "ReportsOptionsClient.OpenReportForm");
	EndIf;
	
	If OpeningParameters.ReportType = "Internal" Or OpeningParameters.ReportType = "Extension" Then
		Kind = "Report";
		MeasurementsKey = CommonClientServer.StructureProperty(OpeningParameters, "MeasurementsKey");
		If ValueIsFilled(MeasurementsKey) Then
			ClientParameters = ClientParameters();
			If ClientParameters.RunMeasurements Then
				OpeningParameters.RunMeasurements = True;
				OpeningParameters.Insert("OperationName", MeasurementsKey + ".Opening");
				OpeningParameters.Insert("OperationComment", ClientParameters.MeasurementsPrefix);
			EndIf;
		EndIf;
	ElsIf OpeningParameters.ReportType = "Additional" Then
		Kind = "ExternalReport";
		If Not OpeningParameters.Property("Connected") Then
			ReportsOptionsServerCall.OnAttachReport(OpeningParameters);
		EndIf;
		If Not OpeningParameters.Connected Then
			Return;
		EndIf;
	Else
		ShowMessageBox(, NStr("ru = 'Вариант внешнего отчета можно открыть только из формы отчета.'; en = 'You can open external report options only from report forms.'; pl = 'Opcja sprawozdania zewnętrznego może zostać otwarta tylko z formularza sprawozdania.';de = 'Die Option für den externen Bericht kann nur über das Berichtsformular geöffnet werden.';ro = 'Opțiunea raportului extern poate fi deschisă numai din formularul de raport.';tr = 'Harici rapor seçeneği sadece rapor formundan açılabilir.'; es_ES = 'Opción de un informe externo puede abrirse solo desde el formulario de informes.'"));
		Return;
	EndIf;
	
	If Not ValueIsFilled(OpeningParameters.ReportName) Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Не определено имя отчета в %1'; en = 'Report name is not specified in %1'; pl = 'Nie określono nazwy sprawozdania w %1';de = 'Der Berichtsname ist nicht in festgelegt %1';ro = 'Numele raportului în %1 nu este determinat';tr = 'Rapor adı %1''de belirlenmedi'; es_ES = 'Nombre del informe no está determinado en %1'"), "ReportsOptionsClient.OpenReportForm");
	EndIf;
	
	FullReportName = Kind + "." + OpeningParameters.ReportName;
	
	UniqueKey = ReportsClientServer.UniqueKey(FullReportName, OpeningParameters.VariantKey);
	OpeningParameters.Insert("PrintParametersKey",        UniqueKey);
	OpeningParameters.Insert("WindowOptionsKey", UniqueKey);
	
	If OpeningParameters.RunMeasurements Then
		ReportsOptionsClientServer.AddKeyToStructure(OpeningParameters, "OperationComment");
		ModulePerformanceMonitorClient = CommonClient.CommonModule("PerformanceMonitorClient");
		MeasurementID = ModulePerformanceMonitorClient.TimeMeasurement(
			OpeningParameters.OperationName,,
			False);
		ModulePerformanceMonitorClient.SetMeasurementComment(MeasurementID, OpeningParameters.OperationComment);
	EndIf;
	
	OpenForm(FullReportName + ".Form", OpeningParameters, Undefined, True);
	
	If OpeningParameters.RunMeasurements Then
		ModulePerformanceMonitorClient.StopTimeMeasurement(MeasurementID);
	EndIf;
EndProcedure

// Opens the report panel. To use from common command modules.
//
// Parameters:
//  PathToSubsystem - String - a section name or a path to the subsystem for which the report panel is opened.
//                    Conforms to the following format: "SectionName[.NestedSubsystemName1][.NestedSubsystemName2][...]".
//                    Section must be described in ReportsOptionsOverridable.DefineSectionsWithReportsOptions.
//  CommandExecuteParameters - CommandExecuteParameters - parameters of the common command handler.
//
Procedure ShowReportBar(SubsystemPath, CommandExecuteParameters) Export
	ParametersForm = New Structure("SubsystemPath", SubsystemPath);
	
	WindowForm = ?(CommandExecuteParameters = Undefined, Undefined, CommandExecuteParameters.Window);
	RefForm = ?(CommandExecuteParameters = Undefined, Undefined, CommandExecuteParameters.URL);
	
	ClientParameters = ClientParameters();
	If ClientParameters.RunMeasurements Then
		ModulePerformanceMonitorClient = CommonClient.CommonModule("PerformanceMonitorClient");
		MeasurementID = ModulePerformanceMonitorClient.TimeMeasurement(
			"ReportPanel.Opening",,
			False);
		ModulePerformanceMonitorClient.SetMeasurementComment(MeasurementID, ClientParameters.MeasurementsPrefix + "; " + SubsystemPath);
	EndIf;
	
	OpenForm("CommonForm.ReportPanel", ParametersForm, , SubsystemPath, WindowForm, RefForm);
	
	If ClientParameters.RunMeasurements Then
		ModulePerformanceMonitorClient.StopTimeMeasurement(MeasurementID);
	EndIf;
EndProcedure

// Notifies open report panels and lists of forms and items about changes.
//
// Parameters:
//  Parameter - Arbitrary - any needed data can be passed.
//  Source - Arbitrary - an event source. For example, another form can be passed.
//
Procedure UpdateOpenForms(Parameter = Undefined, Source = Undefined) Export
	
	Notify(EventNameChangingOption(), Parameter, Source);
	
EndProcedure

#EndRegion

#Region Internal

// Opens a report option card with the settings that define its placement in the application interface.
//
// Parameters:
//  Option - CatalogRef.ReportsOptions - a report option reference.
//
Procedure ShowReportSettings(Option) Export
	FormParameters = New Structure;
	FormParameters.Insert("ShowCard", True);
	FormParameters.Insert("Key", Option);
	OpenForm("Catalog.ReportsOptions.ObjectForm", FormParameters);
EndProcedure

// Opens the several options placement setting dialog in sections.
//
// Parameters:
//   Options - Array - report options to move (CatalogRef.ReportsOptions).
//   Owner - ManagedForm - to block the owner window.
//
Procedure OpenOptionArrangeInSectionsDialog(Options, Owner = Undefined) Export
	
	If TypeOf(Options) <> Type("Array") Or Options.Count() < 1 Then
		ShowMessageBox(, NStr("ru = 'Выберите варианты отчетов, которые необходимо разместить в разделах.'; en = 'Select report options to assign to sections.'; pl = 'Wybierz warianty sprawozdania, które chcesz umieścić w sekcjach.';de = 'Wählen Sie Berichtsoptionen aus, die in Abschnitte eingefügt werden sollen.';ro = 'Selectați opțiunile de raport pentru a fi plasate în secțiuni.';tr = 'Bölümlere yerleştirilecek rapor seçeneklerini seçin.'; es_ES = 'Seleccionar las opciones del informe para colocarse en las secciones.'"));
		Return;
	EndIf;
	
	OpeningParameters = New Structure("Variants", Options);
	OpenForm("Catalog.ReportsOptions.Form.PlacementInSections", OpeningParameters, Owner);
	
EndProcedure

#EndRegion

#Region Private

// The procedure handles an event of the SubsystemsTree attribute in editing forms.
Procedure SubsystemsTreeUsageOnChange(Form, Item) Export
	TreeRow = Form.Items.SubsystemsTree.CurrentData;
	If TreeRow = Undefined Then
		Return;
	EndIf;
	
	// Skip the root row
	If TreeRow.Priority = "" Then
		TreeRow.Use = 0;
		Return;
	EndIf;
	
	If TreeRow.Use = 2 Then
		TreeRow.Use = 0;
	EndIf;
	
	TreeRow.Modified = True;
EndProcedure

// The procedure handles an event of the SubsystemsTree attribute in editing forms.
Procedure SubsystemsTreeImportanceOnChange(Form, Item) Export
	TreeRow = Form.Items.SubsystemsTree.CurrentData;
	If TreeRow = Undefined Then
		Return;
	EndIf;
	
	// Skip the root row
	If TreeRow.Priority = "" Then
		TreeRow.Importance = "";
		Return;
	EndIf;
	
	If TreeRow.Importance <> "" Then
		TreeRow.Use = 1;
	EndIf;
	
	TreeRow.Modified = True;
EndProcedure

// The analog of CommonClient.ShowMultilineTextEditingForm, working in one call.
//   It allows you to set your own header and works with table attributes unlike CommonClient.
//   ShowCommentEditingForm.
//
Procedure EditMultilineText(FormOrHandler, EditText, AttributeOwner, AttributeName, Val Title = "") Export
	
	If IsBlankString(Title) Then
		Title = NStr("ru = 'Комментарий'; en = 'Comment'; pl = 'Komentarz';de = 'Kommentar';ro = 'Comentariu';tr = 'Yorum'; es_ES = 'Comentario'");
	EndIf;
	
	SourceParameters = New Structure;
	SourceParameters.Insert("FormOrHandler", FormOrHandler);
	SourceParameters.Insert("AttributeOwner",  AttributeOwner);
	SourceParameters.Insert("AttributeName",       AttributeName);
	Handler = New NotifyDescription("EditMultilineTextCompletion", ThisObject, SourceParameters);
	
	ShowInputString(Handler, EditText, Title, , True);
	
EndProcedure

// EditMultilineText procedure execution result handler.
Procedure EditMultilineTextCompletion(Text, SourceParameters) Export
	
	If TypeOf(SourceParameters.FormOrHandler) = Type("ManagedForm") Then
		Form      = SourceParameters.FormOrHandler;
		Handler = Undefined;
	Else
		Form      = Undefined;
		Handler = SourceParameters.FormOrHandler;
	EndIf;
	
	If Text <> Undefined Then
		
		If TypeOf(SourceParameters.AttributeOwner) = Type("FormDataTreeItem")
			Or TypeOf(SourceParameters.AttributeOwner) = Type("FormDataCollectionItem") Then
			FillPropertyValues(SourceParameters.AttributeOwner, New Structure(SourceParameters.AttributeName, Text));
		Else
			SourceParameters.AttributeOwner[SourceParameters.AttributeName] = Text;
		EndIf;
		
		If Form <> Undefined Then
			If Not Form.Modified Then
				Form.Modified = True;
			EndIf;
		EndIf;
		
	EndIf;
	
	If Handler <> Undefined Then
		ExecuteNotifyProcessing(Handler, Text);
	EndIf;
	
EndProcedure

Function ClientParameters()
	Return CommonClientServer.StructureProperty(
		StandardSubsystemsClient.ClientParametersOnStart(),
		"ReportsOptions");
EndFunction

// Notification event name to change a report option.
Function EventNameChangingOption() Export
	Return "Write_ReportOptions";
EndFunction

// Notification event name to change common settings.
Function EventNameChangingCommonSettings() Export
	Return ReportsOptionsClientServer.FullSubsystemName() + ".CommonSettingsEdit";
EndFunction

// Returns an additional report reference type.
Function AdditionalReportRefType()
	Exists = CommonClient.SubsystemExists("StandardSubsystems.AdditionalReportsAndDataProcessors");
	If Exists Then
		Return Type("CatalogRef.AdditionalReportsAndDataProcessors");
	EndIf;
	
	Return Undefined;
EndFunction

#EndRegion
