///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var HandlerAfterGenerateAtClient Export;
&AtClient
Var RunMeasurements;
&AtClient
Var MeasurementID;
&AtClient
Var Directly;
&AtClient
Var GeneratingOnOpen;
&AtClient
Var IdleInterval;

#EndRegion

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	DefineBehaviorInMobileClient();
	
	// Define key report parameters.
	DetailsMode = (Parameters.Property("Details") AND Parameters.Details <> Undefined);
	OutputRight = AccessRight("Output", Metadata);
	
	ReportObject     = FormAttributeToValue("Report");
	ReportMetadata = ReportObject.Metadata();
	ReportFullName  = ReportMetadata.FullName();
	PredefinedOptions = New ValueList;
	If ReportObject.DataCompositionSchema <> Undefined Then
		For Each Option In ReportObject.DataCompositionSchema.SettingVariants Do
			PredefinedOptions.Add(Option.Name, Option.Presentation);
		EndDo;
	EndIf;
	
	SetCurrentOptionKey(ReportFullName, PredefinedOptions);
	
	// Preliminary initialization of the composer (if required).
	SchemaURL = CommonClientServer.StructureProperty(Parameters, "SchemaURL");
	If DetailsMode AND TypeOf(Parameters.Details) = Type("DataCompositionDetailsProcessDescription") Then
		NewDCSettings = GetFromTempStorage(Parameters.Details.Data).Settings;
		SchemaURL = CommonClientServer.StructureProperty(NewDCSettings.AdditionalProperties, "SchemaURL");
	EndIf;
	If TypeOf(SchemaURL) = Type("String") AND IsTempStorageURL(SchemaURL) Then
		DataCompositionSchema = GetFromTempStorage(SchemaURL);
		If TypeOf(DataCompositionSchema) = Type("DataCompositionSchema") Then
			SchemaURL = PutToTempStorage(DataCompositionSchema, UUID);
			Report.SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(SchemaURL));
		Else
			SchemaURL = PutToTempStorage(ReportObject.DataCompositionSchema, UUID);
		EndIf;
	Else
		SchemaURL = PutToTempStorage(ReportObject.DataCompositionSchema, UUID);
	EndIf;
	
	// Save form opening parameters.
	ParametersForm = New Structure(
		"PurposeUseKey, UserSettingsKey,
		|GenerateOnOpen, ReadOnly,
		|FixedSettings, Section, Subsystem, SubsystemPresentation");
	FillPropertyValues(ParametersForm, Parameters);
	ParametersForm.Insert("Filter", New Structure);
	If TypeOf(Parameters.Filter) = Type("Structure") Then
		CommonClientServer.SupplementStructure(ParametersForm.Filter, Parameters.Filter, True);
		Parameters.Filter.Clear();
	EndIf;
	
	// Define report settings.
	ReportByStringType = ReportsOptions.ReportType(Parameters.Report, True);
	If ReportByStringType = Undefined Then
		Information      = ReportsOptions.GenerateReportInformationByFullName(ReportFullName);
		Parameters.Report = Information.Report;
	EndIf;
	ReportSettings = ReportsOptions.ReportFormSettings(Parameters.Report, CurrentVariantKey, ReportObject);
	ReportSettings.Insert("OptionSelectionAllowed", True);
	ReportSettings.Insert("SchemaModified", False);
	ReportSettings.Insert("PredefinedOptions", PredefinedOptions);
	ReportSettings.Insert("SchemaURL",   SchemaURL);
	ReportSettings.Insert("SchemaKey",    "");
	ReportSettings.Insert("Contextual",  TypeOf(ParametersForm.Filter) = Type("Structure") AND ParametersForm.Filter.Count() > 0);
	ReportSettings.Insert("FullName",    ReportFullName);
	ReportSettings.Insert("Description", TrimAll(ReportMetadata.Presentation()));
	ReportSettings.Insert("ReportRef",  Parameters.Report);
	ReportSettings.Insert("Subsystem",   ParametersForm.Subsystem);
	ReportSettings.Insert("External",      TypeOf(ReportSettings.ReportRef) = Type("String"));
	ReportSettings.Insert("Safe",   SafeMode() <> False);
	UpdateInfoOnReportOption();
	CommonClientServer.SupplementStructure(ReportSettings, ReportsOptions.ClientParameters());
	
	ReportSettings.Insert("ReadCreateFromUserSettingsImmediatelyCheckBox", True);
	If Parameters.Property("GenerateOnOpen") AND Parameters.GenerateOnOpen = True Then
		Parameters.GenerateOnOpen = False;
		Items.GenerateImmediately.Check = True;
		ReportSettings.ReadCreateFromUserSettingsImmediatelyCheckBox = False;
	EndIf;
	
	// Default parameters.
	If Not CommonClientServer.StructureProperty(ReportSettings, "OutputSelectedCellsTotal", True) Then
		Items.IndicatorGroup.Visible = False;
		Items.IndicatorsArea.Visible = False;
		Items.IndicatorsKindsMoreActionsGroup.Visible = False;
		Items.ReportSpreadsheetDocument.SetAction("OnActivateArea", "");
	EndIf;
	
	// Hide option commands.
	ReportOptionsCommandsVisibility = CommonClientServer.StructureProperty(Parameters, "ReportOptionsCommandsVisibility");	
	
	If ReportOptionsCommandsVisibility = False Then
		ReportSettings.EditOptionsAllowed = False;
		ReportSettings.OptionSelectionAllowed = False;
		If IsBlankString(PurposeUseKey) Then
			PurposeUseKey = Parameters.VariantKey;
			ParametersForm.PurposeUseKey = PurposeUseKey;
		EndIf;
	EndIf;
	If ReportSettings.EditOptionsAllowed AND Not ReportsOptionsCached.InsertRight() Then
		ReportSettings.EditOptionsAllowed = False;
	EndIf;
	
	SelectAndEditOptionsWithoutSavingAllowed = CommonClientServer.StructureProperty(
		ReportSettings, "SelectAndEditOptionsWithoutSavingAllowed", False);
	
	If SelectAndEditOptionsWithoutSavingAllowed Then
		ReportSettings.EditOptionsAllowed = True;
		ReportSettings.OptionSelectionAllowed = True;
		VariantModified                      = False;
		If IsBlankString(PurposeUseKey) Then
			PurposeUseKey = Parameters.VariantKey;
			ParametersForm.PurposeUseKey = PurposeUseKey;
		EndIf;
	EndIf;
	
	// Register commands and form attributes that will not be deleted when overwriting quick settings.
	SetOfAttributes = GetAttributes();
	For Each Attribute In SetOfAttributes Do
		FullAttributeName = Attribute.Name + ?(IsBlankString(Attribute.Path), "", "." + Attribute.Path);
		ConstantAttributes.Add(FullAttributeName);
	EndDo;
	
	For Each Command In Commands Do
		ConstantCommands.Add(Command.Name);
	EndDo;
	
	If Not ReportOptionMode() Then 
		SetVisibilityAvailability();
	EndIf;
	
	// Close integration with email and mailing.
	CanSendEmails = False;
	If Common.SubsystemExists("StandardSubsystems.EmailOperations") Then
		ModuleEmailOperations = Common.CommonModule("EmailOperations");
		CanSendEmails = ModuleEmailOperations.CanSendEmails();
	EndIf;
	If CanSendEmails Then
		If ReportSettings.EditOptionsAllowed
			AND Common.SubsystemExists("StandardSubsystems.ReportMailing")
			AND Not ReportSettings.HideBulkEmailCommands Then
			ModuleReportDistribution = Common.CommonModule("ReportMailing");
			ModuleReportDistribution.ReportFormAddCommands(ThisObject, Cancel, StandardProcessing);
		Else // If the submenu contains only one command, the dropdown list is not shown.
			Items.SendByEmail.Title = Items.SendGroup.Title + "...";
			Items.Move(Items.SendByEmail, Items.SendGroup.Parent, Items.SendGroup);
		EndIf;
	Else
		Items.SendGroup.Visible = False;
	EndIf;
	
	// Determine if the report contains invalid data.
	If Not Items.GenerateImmediately.Check Then
		Try
			TablesToUse = ReportsOptions.TablesToUse(ReportObject.DataCompositionSchema);
			TablesToUse.Add(ReportSettings.FullName);
			If ReportSettings.Events.OnDefineUsedTables Then
				ReportObject.OnDefineUsedTables(CurrentVariantKey, TablesToUse);
			EndIf;
			ReportsOptions.CheckUsedTables(TablesToUse);
		Except
			ErrorText = NStr("ru = 'Не удалось определить используемые таблицы:'; en = 'Cannot identify referenced tables:'; pl = 'Nie można określić używanych tabel:';de = 'Die verwendeten Tabellen konnten nicht ermittelt werden:';ro = 'Eșec la determinarea tabelelor utilizate:';tr = 'Kullanılan tablolar belirlenemedi:'; es_ES = 'No se ha podido determinar las tablas usadas:'");
			ErrorText = ErrorText + Chars.LF + DetailErrorDescription(ErrorInfo());
			ReportsOptions.WriteToLog(EventLogLevel.Error, ErrorText, ReportSettings.OptionRef);
		EndTry;
	EndIf;
	
	DisplayReportState(NStr("ru = 'Отчет не сформирован. Нажмите ""Сформировать"" для получения отчета.'; en = 'Report not generated. To generate the report, click ""Run report"".'; pl = 'Raport nie został utworzony. Kliknij ""Uruchomić raport"", aby go utworzyć.';de = 'Der Bericht wird nicht generiert. Klicken Sie auf ""Bericht ausführen"", um den Bericht zu erstellen.';ro = 'Raportul nu este generat. Faceți click pe ""Generare"" pentru a obține raportul.';tr = 'Rapor oluşturulmadı. Raporu oluşturmak için ""Raporu çalıştır"" ''ı tıklayın.'; es_ES = 'El informe no está generado. Hacer clic en ""Lanzar el informe"" para generar el informe.'"));
	
	ReportsOverridable.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	If ReportSettings.Events.OnCreateAtServer Then
		ReportObject.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	EndIf;
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	RunMeasurements = False;
	// In the safe mode, additional reports are generated directly as they cannot attach themselves and 
	// use their own methods in background jobs.
	Directly = ReportSettings.External Or ReportSettings.Safe;
	GeneratingOnOpen = False;
	IdleInterval = ?(GetClientConnectionSpeed() = ClientConnectionSpeed.Low, 1, 0.2);
	If Items.GenerateImmediately.Check Then
		GeneratingOnOpen = True;
		AttachIdleHandler("Generate", 0.1, True);
	EndIf;
	CalculateIndicators();
EndProcedure

&AtClient
Procedure ChoiceProcessing(Result, SubordinateForm)
	ResultProcessed = False;
	
	// Get results from standard forms.
	If TypeOf(SubordinateForm) = Type("ManagedForm") Then
		SubordinateFormName = SubordinateForm.FormName;
		If SubordinateFormName = "SettingsStorage.ReportsVariantsStorage.Form.ReportSettings"
			Or SubordinateForm.OnCloseNotifyDescription <> Undefined Then
			ResultProcessed = True; // See. AllSettingsCompletion. 
		ElsIf TypeOf(Result) = Type("Structure") Then
			PointPosition = StrLen(SubordinateFormName);
			While CharCode(SubordinateFormName, PointPosition) <> 46 Do // Not a point.
				PointPosition = PointPosition - 1;
			EndDo;
			SourceFormSuffix = Upper(Mid(SubordinateFormName, PointPosition + 1));
			If SourceFormSuffix = Upper("ReportSettingsForm")
				Or SourceFormSuffix = Upper("SettingsForm")
				Or SourceFormSuffix = Upper("ReportVariantForm")
				Or SourceFormSuffix = Upper("VariantForm") Then
				
				UpdateSettingsFormItems(Result);
				ResultProcessed = True;
			EndIf;
		EndIf;
	ElsIf TypeOf(SubordinateForm) = Type("DataCompositionSchemaWizard") Then
#If ThickClientOrdinaryApplication OR ThickClientManagedApplication Then
		If Type(Result) = Type("DataCompositionSchema") Then
			ReportSettings.SchemaURL = PutToTempStorage(Result, UUID);
			
			Path = GetTempFileName();
			
			XMLWriter = New XMLWriter; 
			XMLWriter.OpenFile(Path, "UTF-8");
			XDTOSerializer.WriteXML(XMLWriter, Result, "dataCompositionSchema", "http://v8.1c.ru/8.1/data-composition-system/schema"); 
			XMLWriter.Close();
			
			BinaryData = New BinaryData(Path);
			BeginDeletingFiles(, Path);
			
			Report.SettingsComposer.Settings.AdditionalProperties.Insert("DataCompositionSchema", BinaryData);
			Report.SettingsComposer.Settings.AdditionalProperties.Insert("ReportInitialized",  False);
			
			FillingParameters = New Structure;
			FillingParameters.Insert("UserSettingsModified", True);
			FillingParameters.Insert("DCSettingsComposer", Report.SettingsComposer);
			FillingParameters.Insert("EventName", "DefaultSettings");
			
			UpdateSettingsFormItems(FillingParameters);
		EndIf;
#EndIf
	EndIf;
	
	// Extension functionality.
	If CommonClient.SubsystemExists("StandardSubsystems.ReportMailing") Then
		ModuleReportsMailingClient = CommonClient.CommonModule("ReportMailingClient");
		ModuleReportsMailingClient.ChoiceProcessingReportForm(ThisObject, Result, SubordinateForm, ResultProcessed);
	EndIf;
	ReportsClientOverridable.ChoiceProcessing(ThisObject, Result, SubordinateForm, ResultProcessed);
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	NotificationProcessed = False;
	If EventName = ReportsOptionsClient.EventNameChangingOption()
		Or EventName = "Write_ConstantsSet" Then
		NotificationProcessed = True;
		PanelOptionsCurrentOptionKey = " - ";
	EndIf;
	ReportsClientOverridable.NotificationProcessing(ThisObject, EventName, Parameter, Source, NotificationProcessed);
EndProcedure

&AtServer
Procedure BeforeLoadVariantAtServer(NewDCSettings)
	
	// If the report is not in DCS and settings are not imported, do nothing.
	If NewDCSettings = Undefined Or Not ReportOptionMode() Then
		Return;
	EndIf;
	
	ReportsOverridable.BeforeLoadVariantAtServer(ThisObject, NewDCSettings);
	If ReportSettings.Events.BeforeLoadVariantAtServer Then
		ReportObject = FormAttributeToValue("Report");
		ReportObject.BeforeLoadVariantAtServer(ThisObject, NewDCSettings);
	EndIf;
	
	// Prepare for calling the reinitialization event.
	If ReportSettings.Events.BeforeImportSettingsToComposer Then
		Try
			NewXMLSettings = Common.ValueToXMLString(NewDCSettings);
		Except
			NewXMLSettings = Undefined;
		EndTry;
		ReportSettings.Insert("NewXMLSettings", NewXMLSettings);
	EndIf;
EndProcedure

&AtServer
Procedure OnLoadVariantAtServer(NewDCSettings)
	
	// If the report is not in DCS and settings are not imported, do nothing.
	If Not ReportOptionMode() AND NewDCSettings = Undefined Then
		Return;
	EndIf;
	
	// Import fixed settings for the details mode.
	If DetailsMode Then
		ReportCurrentOptionDescription = CommonClientServer.StructureProperty(NewDCSettings.AdditionalProperties, "DescriptionOption");
		
		If Parameters <> Undefined AND Parameters.Property("Details") Then
			Report.SettingsComposer.LoadFixedSettings(Parameters.Details.UsedSettings);
			Report.SettingsComposer.FixedSettings.AdditionalProperties.Insert("DetailsMode", True);
		EndIf;
		
		If CurrentVariantKey = Undefined Then
			CurrentVariantKey = CommonClientServer.StructureProperty(NewDCSettings.AdditionalProperties, "VariantKey");
		EndIf;
	EndIf;
	
	// To set fixed filters, use the composer as it comprises the most complete collection of settings.
	// Those parameters whose settings were not defined can be missing from BeforeImport parameters.
	If TypeOf(ParametersForm.Filter) = Type("Structure") Then
		ReportsServer.SetFixedFilters(ParametersForm.Filter, Report.SettingsComposer.Settings, ReportSettings);
	EndIf;
	
	// Update the report option reference.
	If PanelOptionsCurrentOptionKey <> CurrentVariantKey Then
		UpdateInfoOnReportOption();
	EndIf;
	
	If ReportSettings.Events.OnLoadVariantAtServer Then
		ReportObject = FormAttributeToValue("Report");
		ReportObject.OnLoadVariantAtServer(ThisObject, NewDCSettings);
	EndIf;
EndProcedure

&AtServer
Procedure BeforeLoadUserSettingsAtServer(NewDCUserSettings)
	
	If ReportSettings.Events.BeforeImportSettingsToComposer Then
		// Prepare for reinitialization.
		Try
			NewUserXMLSettings = Common.ValueToXMLString(NewDCUserSettings);
		Except
			NewUserXMLSettings = Undefined;
		EndTry;
		ReportSettings.Insert("NewUserXMLSettings", NewUserXMLSettings);
	EndIf;
EndProcedure

&AtServer
Procedure OnLoadUserSettingsAtServer(NewDCUserSettings)
	If Parameters.Property("AutoTest")
		Or Not ReportOptionMode() Then
		Return;
	EndIf;
	
	If ReportSettings.Events.OnLoadUserSettingsAtServer Then
		ReportObject = FormAttributeToValue("Report");
		ReportObject.OnLoadUserSettingsAtServer(ThisObject, NewDCUserSettings);
	EndIf;
EndProcedure

&AtServer
Procedure OnUpdateUserSettingSetAtServer(StandardProcessing)
	If Parameters.Property("AutoTest")
		Or Not ReportOptionMode() Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	UpdateParameters = New Structure("EventName", "OnUpdateUserSettingSetAtServer");
 	UpdateSettingsFormItemsAtServer(UpdateParameters);
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	If Not ReportOptionMode() Then
		Return;
	EndIf;
	
	SettingsItems = Report.SettingsComposer.UserSettings.Items;
	For Each SettingItem In SettingsItems Do
		If TypeOf(SettingItem) <> Type("DataCompositionSettingsParameterValue")
			Or TypeOf(SettingItem.Value) <> Type("StandardPeriod")
			Or Not SettingItem.Use Then
			Continue;
		EndIf;
		
		NameTemplate = "SettingsComposerUserSettingsItem" + SettingsItems.IndexOf(SettingItem);
		
		StartDate = Items.Find(NameTemplate + "StartDate");
		EndDate = Items.Find(NameTemplate + "EndDate");
		If StartDate = Undefined Or EndDate = Undefined Then 
			Continue;
		EndIf;
		
		Value = SettingItem.Value;
		If StartDate.AutoMarkIncomplete = True
			AND Not ValueIsFilled(Value.StartDate)
			AND Not ValueIsFilled(Value.EndDate) Then
			ErrorText = NStr("ru = 'Не указан период'; en = 'The period is not specified.'; pl = 'Okres nie jest określony';de = 'Zeitraum ist nicht angegeben';ro = 'Perioada nu este specificată';tr = 'Dönem belirlenmedi'; es_ES = 'Período no está especificado'");
			DataPath = StartDate.DataPath;
		ElsIf Value.StartDate > Value.EndDate Then
			ErrorText = NStr("ru = 'Конец периода должен быть больше начала'; en = 'Period end must be later than period start.'; pl = 'Koniec okresu powinien być późniejszy niż początek';de = 'Das Periodenende sollte später als sein Beginn sein';ro = 'Sfârșitul perioadei ar trebui să fie mai târziu decât începutul acesteia';tr = 'Dönem sonu, başlangıcından sonra olmalıdır.'; es_ES = 'Fin del período tiene que ser más tarde que su inicio'");
			DataPath = EndDate.DataPath;
		Else
			Continue;
		EndIf;
		
		Common.MessageToUser(ErrorText,, DataPath,, Cancel);
	EndDo;
EndProcedure

&AtServer
Procedure OnSaveVariantAtServer(DCSettings)
	If Not ReportOptionMode() Then
		Return;
	EndIf;
	NewDCSettings = Report.SettingsComposer.GetSettings();
	ReportsClientServer.LoadSettings(Report.SettingsComposer, NewDCSettings);
	DCSettings.AdditionalProperties.Insert("Address", PutToTempStorage(NewDCSettings));
	DCSettings = NewDCSettings;
	PanelOptionsCurrentOptionKey = " - ";
	UpdateInfoOnReportOption();
	SetVisibilityAvailability(True);
EndProcedure

&AtServer
Procedure OnSaveUserSettingsAtServer(DCUserSettings)
	If Not ReportOptionMode() Then
		Return;
	EndIf;
	ReportsOptions.OnSaveUserSettingsAtServer(ThisObject, DCUserSettings);
	FillOptionsSelectionCommands();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

////////////////////////////////////////////////////////////////////////////////
// Spreadsheet document

&AtClient
Procedure ReportSpreadsheetDocumentChoice(Item, Area, StandardProcessing)
	
	SubsystemsIntegrationSSLClient.SpreadsheetDocumentSelectionHandler(ThisObject, Item, Area, StandardProcessing);
	If StandardProcessing Then
		ReportsClientOverridable.SpreadsheetDocumentSelectionHandler(ThisObject, Item, Area, StandardProcessing);
	EndIf;
	
	If StandardProcessing AND TypeOf(Area) = Type("SpreadsheetDocumentRange") Then
		If GoToLink(Area.Text) Then
			StandardProcessing = False;
			Return;
		EndIf;
		
		Try
			DetailsValue = Area.Details;
		Except
			DetailsValue = Undefined;
			// Reading details is unavailable for some spreadsheet document area types (AreaType property), so 
			// an exclusion attempt is made.
		EndTry;
		
		If DetailsValue <> Undefined AND GoToLink(DetailsValue) Then
			StandardProcessing = False;
			Return;
		EndIf;
		If GoToLink(Area.Mask) Then
			StandardProcessing = False;
			Return;
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure ReportSpreadsheetDocumentDetailsProcessing(Item, Details, StandardProcessing)
	If CommonClient.SubsystemExists("StandardSubsystems.EventLogAnalysis") Then
		ModuleEventLogAnalysisClient = CommonClient.CommonModule("EventLogAnalysisClient");
		ModuleEventLogAnalysisClient.ReportFormDetailProcessing(ThisObject, Item, Details, StandardProcessing);
	EndIf;
	ReportsClientOverridable.DetailProcessing(ThisObject, Item, Details, StandardProcessing);
EndProcedure

&AtClient
Procedure ReportSpreadsheetDocumentAdditionalDetailsProcessing(Item, Details, StandardProcessing)
	If CommonClient.SubsystemExists("StandardSubsystems.EventLogAnalysis") Then
		ModuleEventLogAnalysisClient = CommonClient.CommonModule("EventLogAnalysisClient");
		ModuleEventLogAnalysisClient.AdditionalDetailProcessingReportForm(ThisObject, Item, Details, StandardProcessing);
	EndIf;
	ReportsClientOverridable.AdditionalDetailProcessing(ThisObject, Item, Details, StandardProcessing);
EndProcedure

&AtClient
Procedure ReportSpreadsheetDocumentOnActivateArea(Item)
	AttachIdleHandler("CalculateIndicatorsDynamically", 0.2, True);
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Attachable objects

&AtClient
Procedure Attachable_SettingItem_OnChange(Item)
	SettingsComposer = Report.SettingsComposer;
	
	Index = PathToItemsData.ByName[Item.Name];
	If Index = Undefined Then 
		Index = ReportsClientServer.SettingItemIndexByPath(Item.Name);
	EndIf;
	
	SettingItem = SettingsComposer.UserSettings.Items[Index];
	
	IsFlag = StrStartsWith(Item.Name, "CheckBox") Or StrEndsWith(Item.Name, "CheckBox");
	If IsFlag Then 
		SettingItem.Value = ThisObject[Item.Name];
	EndIf;
	
	If TypeOf(SettingItem) = Type("DataCompositionSettingsParameterValue")
		AND ReportSettings.ImportSettingsOnChangeParameters.Find(SettingItem.Parameter) <> Undefined Then 
		
		SettingsComposer.Settings.AdditionalProperties.Insert("ReportInitialized", False);
		
		UpdateParameters = New Structure;
		UpdateParameters.Insert("DCSettingsComposer", SettingsComposer);
		UpdateParameters.Insert("UserSettingsModified", True);
		
		UpdateSettingsFormItems(UpdateParameters);
	EndIf;
EndProcedure

&AtClient
Procedure Attachable_SettingItem_StartChoice(Item, ChoiceData, StandardProcessing)
	ShowChoiceList(Item, StandardProcessing)
EndProcedure

&AtClient
Procedure Attachable_Period_OnChange(Item)
	ReportsClient.SetPeriod(ThisObject, Item.Name);
EndProcedure

&AtClient
Procedure Attachable_SelectPeriod(Command)
	ReportsClient.SelectPeriod(ThisObject, Command.Name);
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure AllSettings(Command)
	Name = ReportSettings.FullName + ".SettingsForm";
	
	FormParameters = New Structure;
	CommonClientServer.SupplementStructure(FormParameters, ParametersForm, True);
	FormParameters.Insert("VariantKey", String(CurrentVariantKey));
	FormParameters.Insert("Variant", Report.SettingsComposer.Settings);
	FormParameters.Insert("UserSettings", Report.SettingsComposer.UserSettings);
	FormParameters.Insert("ReportSettings", ReportSettings);
	FormParameters.Insert("DescriptionOption", String(ReportCurrentOptionDescription));
	
	Mode = FormWindowOpeningMode.LockOwnerWindow;
	
	Handler = New NotifyDescription("AllSettingsCompletion", ThisObject);
	
	RunMeasurements = ReportSettings.RunMeasurements AND ValueIsFilled(ReportSettings.MeasurementsKey);
	If RunMeasurements Then
		ModulePerformanceMonitorClient = CommonClient.CommonModule("PerformanceMonitorClient");
		MeasurementID = ModulePerformanceMonitorClient.TimeMeasurement(
			ReportSettings.MeasurementsKey + ".Settings",
			False, False);
		ModulePerformanceMonitorClient.SetMeasurementComment(MeasurementID, ReportSettings.MeasurementsPrefix);
	EndIf;
	
	OpenForm(Name, FormParameters, ThisObject, , , , Handler, Mode);
	
	If RunMeasurements Then
		ModulePerformanceMonitorClient.StopTimeMeasurement(MeasurementID);
	EndIf;
EndProcedure

&AtClient
Procedure AllSettingsCompletion(Result, ExecutionParameters) Export
	If Result = Undefined Then
		Return;
	EndIf;
	UpdateSettingsFormItems(Result);
EndProcedure

&AtClient
Procedure ChangeReportOption(Command)
	FormParameters = New Structure;
	CommonClientServer.SupplementStructure(FormParameters, ParametersForm, True);
	FormParameters.Insert("ReportSettings", ReportSettings);
	FormParameters.Insert("Variant", Report.SettingsComposer.Settings);
	FormParameters.Insert("VariantKey", String(CurrentVariantKey));
	FormParameters.Insert("UserSettings", Report.SettingsComposer.UserSettings);
	FormParameters.Insert("VariantPresentation", String(ReportCurrentOptionDescription));
	FormParameters.Insert("UserSettingsPresentation", "");
	
	OpenForm(ReportSettings.FullName + ".VariantForm", FormParameters, ThisObject);
EndProcedure

&AtClient
Procedure DefaultSettings(Command)
	FillingParameters = New Structure;
	FillingParameters.Insert("EventName", "DefaultSettings");
	
	If VariantModified Then
		FillingParameters.Insert("ClearOptionSettings", True);
		FillingParameters.Insert("VariantModified", False);
	EndIf;
	
	FillingParameters.Insert("ResetUserSettings", True);
	FillingParameters.Insert("UserSettingsModified", True);
	
	UpdateSettingsFormItems(FillingParameters);
EndProcedure

&AtClient
Procedure SendByEmail(Command)
	StatePresentation = Items.ReportSpreadsheetDocument.StatePresentation;
	If StatePresentation.Visible = True
		AND StatePresentation.AdditionalShowMode = AdditionalShowMode.Irrelevance Then
		QuestionText = NStr("ru = 'Отчет не сформирован. Сформировать?'; en = 'Report not generated. Do you want to generate the report?'; pl = 'Sprawozdanie nie zostało wygenerowane. Wygenerować?';de = 'Bericht nicht generiert. Generieren?';ro = 'Raportul nu a fost generat. Generați?';tr = 'Rapor oluşturulmadı. Oluşturulsun mu?'; es_ES = 'Informe no se ha generado. ¿Generar?'");
		Handler = New NotifyDescription("GenerateBeforeEmailing", ThisObject);
		ShowQueryBox(Handler, QuestionText, QuestionDialogMode.YesNo, 60, DialogReturnCode.Yes);
	Else
		ShowSendByEmailDialog();
	EndIf;
EndProcedure

&AtClient
Procedure ReportComposeResult(Command)
	ClearMessages();
	Generate();
EndProcedure

&AtClient
Procedure GenerateImmediately(Command)
	GenerateImmediately = Not Items.GenerateImmediately.Check;
	Items.GenerateImmediately.Check = GenerateImmediately;
	
	StateBeforeChange = New Structure("Visible, AdditionalShowMode, Picture, Text");
	FillPropertyValues(StateBeforeChange, Items.ReportSpreadsheetDocument.StatePresentation);
	
	Report.SettingsComposer.UserSettings.AdditionalProperties.Insert("GenerateImmediately", GenerateImmediately);
	UserSettingsModified = True;
	
	FillPropertyValues(Items.ReportSpreadsheetDocument.StatePresentation, StateBeforeChange);
EndProcedure

&AtClient
Procedure OtherReports(Command)
	FormParameters = New Structure;
	FormParameters.Insert("OptionRef", ReportSettings.OptionRef);
	FormParameters.Insert("ReportRef", ReportSettings.ReportRef);
	FormParameters.Insert("SubsystemRef", ParametersForm.Subsystem);
	FormParameters.Insert("ReportDescription", ReportSettings.Description);
	
	Block = FormWindowOpeningMode.LockOwnerWindow;
	
	OpenForm("SettingsStorage.ReportsVariantsStorage.Form.OtherReportsPanel", FormParameters, ThisObject, True, , , , Block);
EndProcedure

&AtClient
Procedure ImportSchema(Command)
	
	NotifyDescription = New NotifyDescription("ImportSchemaAfterLocateFile", ThisObject);
	
	ImportParameters = FileSystemClient.FileImportParameters();
	ImportParameters.Dialog.Filter = NStr("ru = 'Файлы XML (*.xml) |*.xml'; en = 'XML files (*.xml) |*.xml'; pl = 'Pliki XML (*.xml) |*.xml';de = 'XML-Dateien (*.xml) |*.xml';ro = 'Fișiere XML (*.xml) |*.xml';tr = 'XML dosyaları (*.xml) |*.xml'; es_ES = 'Archivos XML (*.xml) |*.xml'");
	ImportParameters.FormID = UUID;
	
	FileSystemClient.ImportFile(NotifyDescription, ImportParameters);
	
EndProcedure

&AtClient
Procedure EditSchema(Command)
#If ThickClientOrdinaryApplication OR ThickClientManagedApplication Then
	DataCompositionSchema = GetFromTempStorage(ReportSettings.SchemaURL);
	
	If DataCompositionSchema.DefaultSettings.AdditionalProperties.Property("DataCompositionSchema") Then
		DataCompositionSchema.DefaultSettings.AdditionalProperties.DataCompositionSchema = Undefined;
	EndIf;
	
	Designer = New DataCompositionSchemaWizard(DataCompositionSchema);
	Designer.Edit(ThisObject);
#Else
	ShowMessageBox(, (NStr("ru='Для того чтобы редактировать схему компоновки, необходимо запустить приложение в режиме толстого клиента.'; en = 'To edit composition schema, run the application in thick client mode.'; pl = 'Do wykonania edycji schematu układu, należy uruchomić aplikację w trybie klienta grubego.';de = 'Um das Layout-Schema zu bearbeiten, sollten Sie die Anwendung im Thick-Client-Modus starten.';ro = 'Pentru a edita schema de combinare trebuie să lansați aplicația în regim de fat-client.';tr = 'Düzen şemasını düzenlemek için uygulamayı kalın istemci modunda çalıştırmanız gerekir.'; es_ES = 'Para editar el esquema de composición, es necesario lanzar la aplicación en el modo del cliente grueso.'")));
#EndIf
EndProcedure

&AtClient
Procedure RestoreDefaultSchema(Command)
	Report.SettingsComposer.Settings.AdditionalProperties.Clear();
	
	DataParameters = Report.SettingsComposer.Settings.DataParameters.Items;
	ParametersNamesToClear = StrSplit("MetadataObjectType, MetadataObjectName, TableName", ", ", False);
	For Each ParameterName In ParametersNamesToClear Do 
		FoundParameter = DataParameters.Find(ParameterName);
		If FoundParameter <> Undefined Then 
			FoundParameter.Value = Undefined;
		EndIf;
	EndDo;
	
	FillingParameters = New Structure;
	FillingParameters.Insert("DCSettingsComposer", Report.SettingsComposer);
	FillingParameters.Insert("UserSettingsModified", True);
	
	UpdateSettingsFormItems(FillingParameters);
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Handlers of indicator calculation commands.

&AtClient
Procedure CalculateAmount(Command)
	CalculateIndicators(Command.Name);
EndProcedure

&AtClient
Procedure CalculateCount(Command)
	CalculateIndicators(Command.Name);
EndProcedure

&AtClient
Procedure CalculateAverage(Command)
	CalculateIndicators(Command.Name);
EndProcedure

&AtClient
Procedure CalculateMin(Command)
	CalculateIndicators(Command.Name);
EndProcedure

&AtClient
Procedure CalculateMax(Command)
	CalculateIndicators(Command.Name);
EndProcedure

&AtClient
Procedure CalculateAllIndicators(Command)
	SetIndicatorsVisibility(Not Items.CalculateAllIndicators.Check);
EndProcedure

&AtClient
Procedure CollapseIndicators(Command)
	SetIndicatorsVisibility(False);
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Attachable objects

&AtClient
Procedure Attachable_Command(Command)
	ConstantCommand = ConstantCommands.FindByValue(Command.Name);
	If ConstantCommand <> Undefined AND ValueIsFilled(ConstantCommand.Presentation) Then
		SubstringsArray = StrSplit(ConstantCommand.Presentation, ".");
		ModuleClient = CommonClient.CommonModule(SubstringsArray[0]);
		Handler = New NotifyDescription(SubstringsArray[1], ModuleClient, Command);
		ExecuteNotifyProcessing(Handler, ThisObject);
	Else
		ReportsClientOverridable.CommandHandler(ThisObject, Command, False);
	EndIf;
EndProcedure

&AtClient
Procedure Attachable_ImportReportOption(Command)
	FoundItems = AddedOptions.FindRows(New Structure("CommandName", Command.Name));
	If FoundItems.Count() = 0 Then
		ShowMessageBox(, NStr("ru = 'Вариант отчета не найден.'; en = 'Cannot find report option.'; pl = 'Opcja raportu nie została znaleziona.';de = 'Die Berichtsoption wurde nicht gefunden.';ro = 'Opțiunea de raport nu a fost găsită.';tr = 'Rapor seçeneği bulunamadı.'; es_ES = 'Opción del informe no se ha encontrado.'"));
		Return;
	EndIf;
	
	FormOption = FoundItems[0];
	ReportSettings.Delete("SettingsFormAdvancedMode");
	
	ImportOption(FormOption.VariantKey);
	
	UniqueKey = ReportsClientServer.UniqueKey(ReportSettings.FullName, FormOption.VariantKey);
	
	If Items.GenerateImmediately.Check Then
		AttachIdleHandler("Generate", 0.1, True);
	EndIf;
EndProcedure

&AtClient
Procedure EditFilterCriteria(Command)
	FormParameters = New Structure;
	FormParameters.Insert("OwnerFormType", ReportFormType);
	FormParameters.Insert("ReportSettings", ReportSettings);
	FormParameters.Insert("SettingsComposer", Report.SettingsComposer);
	Handler = New NotifyDescription("EditFilterCriteriaCompletion", ThisObject);
	OpenForm("SettingsStorage.ReportsVariantsStorage.Form.ReportFiltersConditions", FormParameters, ThisObject, True,,, Handler);
EndProcedure

&AtClient
Procedure EditFilterCriteriaCompletion(FiltersConditions, Context) Export
	If FiltersConditions = Undefined
		Or FiltersConditions = DialogReturnCode.Cancel
		Or FiltersConditions.Count() = 0 Then
		Return;
	EndIf;
	FillingParameters = New Structure;
	FillingParameters.Insert("EventName", "EditFilterCriteria");
	FillingParameters.Insert("DCSettingsComposer", Report.SettingsComposer);
	FillingParameters.Insert("UserSettingsModified", True);
	FillingParameters.Insert("FiltersConditions", FiltersConditions);
	
	UpdateSettingsFormItems(FillingParameters);
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Client

&AtClient
Procedure UpdateSettingsFormItems(UpdateParameters)
	UpdateSettingsFormItemsAtServer(UpdateParameters);
	
	If CommonClientServer.StructureProperty(UpdateParameters, "Regenerate", False) Then
		ClearMessages();
		Generate();
	EndIf;
EndProcedure

#Region GenerationWithSendingByEmail

&AtClient
Procedure GenerateBeforeEmailing(Response, AdditionalParameters) Export
	If Response = DialogReturnCode.Yes Then
		Handler = New NotifyDescription("SendByEmailAfterGenerate", ThisObject);
		ReportsClient.GenerateReport(ThisObject, Handler);
	EndIf;
EndProcedure

&AtClient
Procedure SendByEmailAfterGenerate(SpreadsheetDocumentGenerated, AdditionalParameters) Export
	If SpreadsheetDocumentGenerated Then
		ShowSendByEmailDialog();
	EndIf;
EndProcedure

#EndRegion

#Region Generation

&AtClient
Procedure Generate()
	RunMeasurements = ReportSettings.RunMeasurements AND ValueIsFilled(ReportSettings.MeasurementsKey);
	If RunMeasurements Then
		Comment = ReportSettings.MeasurementsPrefix + "; " + NStr("ru = 'Непосредственно:'; en = 'Directly:'; pl = 'Bezpośrednio:';de = 'Direkt:';ro = 'Nemijlocit:';tr = 'Doğrudan:'; es_ES = 'Directamente:'") + " " + String(Directly);
		ModulePerformanceMonitorClient = CommonClient.CommonModule("PerformanceMonitorClient");
		MeasurementID = ModulePerformanceMonitorClient.TimeMeasurement(
			ReportSettings.MeasurementsKey + ".Generation",
			False, False);
		ModulePerformanceMonitorClient.SetMeasurementComment(MeasurementID, Comment);
	EndIf;
	
	Result = ReportGenerationResult(GeneratingOnOpen, ReportSettings.External Or ReportSettings.Safe);
	If Result = Undefined Then 
		Return;
	EndIf;
	If Result.Status <> "Running" Then 
		AfterGenerate(Result, False);
		Return;
	EndIf;
	
	Handler = New NotifyDescription("AfterGenerate", ThisObject, True);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow = False;
	
	TimeConsumingOperationsClient.WaitForCompletion(Result, Handler, IdleParameters);
EndProcedure

&AtClient
Procedure AfterGenerate(Result, ImportReportGenerationResult) Export 
	If Result = Undefined Then 
		Return;
	EndIf;
		
	If Result.Status = "Completed" Then 
		If ImportReportGenerationResult Then
			ImportReportGenerationResult();
		EndIf;	
		ShowUserNotification(NStr("ru = 'Отчет сформирован'; en = 'Report is generated'; pl = 'Sprawozdanie zostało wygenerowane';de = 'Bericht wurde erstellt';ro = 'Raportul este generat';tr = 'Rapor oluşturuldu'; es_ES = 'Informe generado'"),, Title);
	ElsIf Result.Status = "Error" Then
		ShowGenerationErrors(Result.BriefErrorPresentation);
		ShowUserNotification(NStr("ru = 'Отчет не сформирован'; en = 'Report is not generated'; pl = 'Raport nie wygenerowany';de = 'Der Bericht wurde nicht generiert';ro = 'Raportul nu a fost generat';tr = 'Rapor düzenlenmedi'; es_ES = 'Informe no generado'"),, Title);
	EndIf;
	
	GeneratingOnOpen = False;
	
	RunMeasurements = ReportSettings.RunMeasurements AND ValueIsFilled(ReportSettings.MeasurementsKey);
	If RunMeasurements Then
		ModulePerformanceMonitorClient = CommonClient.CommonModule("PerformanceMonitorClient");
		ModulePerformanceMonitorClient.StopTimeMeasurement(MeasurementID);
	EndIf;
	
	ReportsClientOverridable.AfterGenerate(ThisObject, Result.Status = "Completed");
EndProcedure

&AtServer
Function ReportGenerationResult(Val GeneratingOnOpen, Directly)
	
	If ValueIsFilled(BackgroundJobID) Then
		TimeConsumingOperations.CancelJobExecution(BackgroundJobID);
		BackgroundJobID = Undefined;
	EndIf;
	
	If Not CheckFilling() Then
		If GeneratingOnOpen Then
			ErrorText = "";
			Messages = GetUserMessages(True);
			For Each Message In Messages Do
				ErrorText = ErrorText + ?(ErrorText = "", "", ";" + Chars.LF + Chars.LF) + Message.Text;
			EndDo;
			ShowGenerationErrors(ErrorText);
		EndIf;
		Return Undefined;
	EndIf;
	
	NameOfReport = StrSplit(ReportSettings.FullName, ".")[1];
	GenerationParameters = ReportGenerationParameters(NameOfReport, Directly);
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Выполнение отчета: %1'; en = 'Running report: %1'; pl = 'Wykonanie raportu: %1';de = 'Ausführung des Berichts: %1';ro = 'Executarea raportului: %1';tr = 'Raporu yerine getirme: %1'; es_ES = 'Realización del informe: %1'"),
		NameOfReport);
	ExecutionParameters.RunNotInBackground = Directly;
	
	Result = TimeConsumingOperations.ExecuteInBackground(
		"ReportsOptions.GenerateReportInBackground",
		GenerationParameters,
		ExecutionParameters);
		
	BackgroundJobID = Result.JobID;
	BackgroundJobStorageAddress = Result.ResultAddress;
	
	If Result.Status <> "Running" Then
		ImportReportGenerationResult();
	Else	
		DisplayReportState(NStr("ru = 'Отчет формируется...'; en = 'Generating report...'; pl = 'Generowanie sprawozdania...';de = 'Den Bericht erstellen...';ro = 'Are loc generarea raportului...';tr = 'Rapor oluşturma...'; es_ES = 'Generando el informe...'"), PictureLib.TimeConsumingOperation48);
	EndIf;
	Return Result;
	
EndFunction

&AtServer
Function ReportGenerationParameters(NameOfReport, Directly)
	ReportGenerationParameters = New Structure;
	ReportGenerationParameters.Insert("ReportRef", ReportSettings.ReportRef);
	ReportGenerationParameters.Insert("OptionRef", ReportSettings.OptionRef);
	ReportGenerationParameters.Insert("VariantKey", CurrentVariantKey);
	ReportGenerationParameters.Insert("DCSettings", Report.SettingsComposer.Settings);
	ReportGenerationParameters.Insert("FixedDCSettings", Report.SettingsComposer.FixedSettings);
	ReportGenerationParameters.Insert("DCUserSettings", Report.SettingsComposer.UserSettings);
	ReportGenerationParameters.Insert("SchemaModified", ReportSettings.SchemaModified);
	ReportGenerationParameters.Insert("SchemaKey", ReportSettings.SchemaKey);
	ReportGenerationParameters.Insert("KeyOperationName");
	ReportGenerationParameters.Insert("KeyOperationComment");
	
	FillPropertyValues(ReportGenerationParameters, ReportGenerationMeasurementsParameters(NameOfReport));
	
	If Directly Then
		If ReportSettings.SchemaModified Then
			ReportGenerationParameters.Insert("SchemaURL", ReportSettings.SchemaURL);
		EndIf;
		ReportGenerationParameters.Insert("Object", FormAttributeToValue("Report"));
		ReportGenerationParameters.Insert("FullName", ReportSettings.FullName);
	Else
		If ReportSettings.SchemaModified Then
			ReportGenerationParameters.Insert("DCSchema", GetFromTempStorage(ReportSettings.SchemaURL));
		EndIf;
	EndIf;
	
	Return ReportGenerationParameters;
EndFunction

&AtServer
Function ReportGenerationMeasurementsParameters(NameOfReport)
	MeasurementsParameters = New Structure("KeyOperationName, KeyOperationComment");
	
	If Not ReportSettings.RunMeasurements
		Or Not ValueIsFilled(ReportSettings.MeasurementsKey) Then
		Return MeasurementsParameters;
	EndIf;
	
	KeyOperationComment = New Map;
	KeyOperationComment.Insert("ReportName", NameOfReport);
	KeyOperationComment.Insert("OriginalOptionName", ReportSettings.OriginalOptionName);
	KeyOperationComment.Insert("External", Number(ReportSettings.External));
	KeyOperationComment.Insert("Custom", Number(ReportSettings.Custom));
	KeyOperationComment.Insert("Details", Number(DetailsMode));
	KeyOperationComment.Insert("ItemModified", Number(VariantModified));
	
	MeasurementsParameters.KeyOperationName = ReportSettings.MeasurementsKey + ".Generation";
	MeasurementsParameters.KeyOperationComment = KeyOperationComment;
	
	Return MeasurementsParameters;
EndFunction

&AtServer
Procedure ImportReportGenerationResult()
	If Not IsTempStorageURL(BackgroundJobStorageAddress) Then 
		Return;
	EndIf;
	
	Result = GetFromTempStorage(BackgroundJobStorageAddress);
	
	DeleteFromTempStorage(BackgroundJobStorageAddress);
	BackgroundJobStorageAddress = Undefined;
	BackgroundJobID = Undefined;
	
	If Result = Undefined Then 
		Return;
	EndIf;
	
	Success = CommonClientServer.StructureProperty(Result, "Success");
	If Success <> True Then
		ShowGenerationErrors(Result.ErrorText);
		Return;
	EndIf;
	
	DataStillUpdating = CommonClientServer.StructureProperty(Result, "DataStillUpdating", False);
	If DataStillUpdating Then
		Common.MessageToUser(ReportsOptions.DataIsBeingUpdatedMessage());
	EndIf;
	
	DisplayReportState();
	
	FillPropertyValues(ReportSettings.Print, ReportSpreadsheetDocument); // Save print settings.
	ReportSpreadsheetDocument = Result.SpreadsheetDocument;
	FillPropertyValues(ReportSpreadsheetDocument, ReportSettings.Print); // Recovery.
	
	If ValueIsFilled(ReportDetailsData) AND IsTempStorageURL(ReportDetailsData) Then
		DeleteFromTempStorage(ReportDetailsData);
	EndIf;
	ReportDetailsData = PutToTempStorage(Result.Details, UUID);
	
	If Not Result.VariantModified
		AND Not Result.UserSettingsModified Then
		Return;
	EndIf;
	
	Result.Insert("EventName", "AfterGenerate");
	Result.Insert("Directly", False);
	UpdateSettingsFormItemsAtServer(Result);
EndProcedure

#EndRegion

&AtClient
Procedure ShowSendByEmailDialog()
	Attachment = New Structure;
	Attachment.Insert("AddressInTempStorage", PutToTempStorage(ReportSpreadsheetDocument, UUID));
	Attachment.Insert("Presentation", ReportCurrentOptionDescription);
	
	AttachmentsList = CommonClientServer.ValueInArray(Attachment);
	
	If CommonClient.SubsystemExists("StandardSubsystems.EmailOperations") Then
		ModuleEmailOperationsClient = CommonClient.CommonModule("EmailOperationsClient");
		SendOptions = ModuleEmailOperationsClient.EmailSendOptions();
		SendOptions.Subject = ReportCurrentOptionDescription;
		SendOptions.Attachments = AttachmentsList;
		ModuleEmailOperationsClient.CreateNewEmailMessage(SendOptions);
	EndIf;
EndProcedure

&AtClient
Procedure ShowChoiceList(Item, StandardProcessing)
	StandardProcessing = False;
	
	Info = ReportsClient.SettingItemInfo(Report.SettingsComposer, Item.Name);
	UserSettings = Report.SettingsComposer.UserSettings.Items;
	
	ChoiceParameters = ReportsClientServer.ChoiceParameters(
		Info.Settings, UserSettings, Info.Item);
	
	Item.AvailableTypes = ReportsClient.ValueTypeRestrictedByLinkByType(
		Info.Settings, UserSettings, Info.Item, Info.Details);
	
	If TypeOf(Info.UserSettingItem) = Type("DataCompositionSettingsParameterValue") Then 
		CurrentValue = Info.UserSettingItem.Value;
	Else
		CurrentValue = Info.UserSettingItem.RightValue;
	EndIf;
	
	Condition = ReportsClientServer.SettingItemCondition(Info.UserSettingItem, Info.Details);
	ChoiceOfGroupsAndItems = ReportsClient.ValueOfFoldersAndItemsUseType(
		Info.Details.ChoiceFoldersAndItems, Condition);
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("Marked", ReportsClientServer.ValuesByList(CurrentValue));
	OpeningParameters.Insert("TypeDescription", Item.AvailableTypes);
	OpeningParameters.Insert("ValuesForSelection", Item.ChoiceList);
	OpeningParameters.Insert("ValuesForSelectionFilled", Item.ChoiceList.Count() > 0);
	OpeningParameters.Insert("RestrictSelectionBySpecifiedValues", OpeningParameters.ValuesForSelectionFilled);
	OpeningParameters.Insert("Presentation", Item.Title);
	OpeningParameters.Insert("ChoiceParameters", New Array(ChoiceParameters));
	OpeningParameters.Insert("ChoiceFoldersAndItems", ChoiceOfGroupsAndItems);
	
	Handler = New NotifyDescription("CompleteChoiceFromList", ThisObject, Info.UserSettingItem);
	Mode = FormWindowOpeningMode.LockOwnerWindow;
	
	OpenForm("CommonForm.InputValuesInListWithCheckBoxes", OpeningParameters, ThisObject,,,, Handler, Mode);
EndProcedure

&AtClient
Procedure CompleteChoiceFromList(List, UserSettingItem) Export
	If TypeOf(List) <> Type("ValueList") Then
		Return;
	EndIf;
	
	SelectedValues = New ValueList;
	For Each ListItem In List Do 
		If ListItem.Check Then 
			FillPropertyValues(SelectedValues.Add(), ListItem);
		EndIf;
	EndDo;
	
	If TypeOf(UserSettingItem) = Type("DataCompositionSettingsParameterValue") Then 
		UserSettingItem.Value = SelectedValues;
	Else
		UserSettingItem.RightValue = SelectedValues;
	EndIf;
	UserSettingItem.Use = True;
EndProcedure

&AtClient
Function GoToLink(HyperlinkAddress)
	If IsBlankString(HyperlinkAddress) Then
		Return False;
	EndIf;
	ReferenceAddressInReg = Upper(HyperlinkAddress);
	If StrStartsWith(ReferenceAddressInReg, Upper("http://"))
		Or StrStartsWith(ReferenceAddressInReg, Upper("https://"))
		Or StrStartsWith(ReferenceAddressInReg, Upper("e1cib/"))
		Or StrStartsWith(ReferenceAddressInReg, Upper("e1c://")) Then
		FileSystemClient.OpenURL(HyperlinkAddress);
		Return True;
	EndIf;
	Return False;
EndFunction

&AtClient
Procedure ImportSchemaAfterLocateFile(SelectedFiles, AdditionalParameters) Export
	If SelectedFiles = Undefined Then
		Return;
	EndIf;
	
	BinaryData = GetFromTempStorage(SelectedFiles.Location);
	
	AdditionalProperties = Report.SettingsComposer.Settings.AdditionalProperties;
	AdditionalProperties.Clear();
	AdditionalProperties.Insert("DataCompositionSchema", BinaryData);
	AdditionalProperties.Insert("ReportInitialized", False);
	
	FillingParameters = New Structure;
	FillingParameters.Insert("UserSettingsModified", True);
	FillingParameters.Insert("DCSettingsComposer", Report.SettingsComposer);
	
	UpdateSettingsFormItems(FillingParameters);
EndProcedure

#Region CalculateIndicatorsForRange

// Calculate functions for the selected cell range.
// See the ReportSpreadsheetDocumentOnActivateArea event handler.
//
&AtClient
Procedure CalculateIndicatorsDynamically()
	Var CurrentCommand;
	
	IndicatorsCommands = IndicatorsCommands();
	For Each Command In IndicatorsCommands Do 
		If Items[Command.Key].Check Then 
			CurrentCommand = Command.Key;
			Break;
		EndIf;
	EndDo;
	
	CalculateIndicators(CurrentCommand);
EndProcedure

// Calculates and displays indicators of the selected spreadsheet document cell areas.
//
// Parameters:
//  CurrentCommand - String - an indicator calculation command name, for example, "CalculateAmount".
//                      Defines which indicator is the main one.
//
&AtClient
Procedure CalculateIndicators(CurrentCommand = "CalculateAmount")
	// Calculating indicators.
	CalculationParameters = CommonInternalClient.CellsIndicatorsCalculationParameters(ReportSpreadsheetDocument);
	If CalculationParameters.CalculateAtServer Then 
		CalculationIndicators = CalculationIndicatorsServer(CalculationParameters);
	Else
		CalculationIndicators = CommonInternalClientServer.CalculationCellsIndicators(
			ReportSpreadsheetDocument, CalculationParameters.SelectedAreas);
	EndIf;
	
	// Setting indicator values.
	FillPropertyValues(ThisObject, CalculationIndicators);
	
	// Switching and formatting indicators.
	IndicatorsCommands = IndicatorsCommands();
	For Each Command In IndicatorsCommands Do 
		Items[Command.Key].Check = False;
		
		IndicatorValue = CalculationIndicators[Command.Value];
		IndicatorDigitCapacity = Min(StrLen(Max(IndicatorValue, -IndicatorValue) % 1) - 2, 4);
		
		Items[Command.Value].EditFormat = "NFD=" + IndicatorDigitCapacity + "; NGS=' '; NZ=0";
	EndDo;
	Items[CurrentCommand].Check = True;
	
	// Main indicator output.
	CurrentIndicator = IndicatorsCommands[CurrentCommand];
	Indicator = ThisObject[CurrentIndicator];
	Items.Indicator.EditFormat = Items[CurrentIndicator].EditFormat;
	Items.IndicatorsKindsGroup.Picture = PictureLib[CurrentIndicator];
	Items.IndicatorsKindsMoreActionsGroup.Picture = PictureLib[CurrentIndicator];
EndProcedure

// Calculates indicators of numeric cells in a spreadsheet document.
//  see ReportsClientServer.CellsCalculationIndicators. 
//
&AtServer
Function CalculationIndicatorsServer(CalculationParameters)
	Return CommonInternalClientServer.CalculationCellsIndicators(ReportSpreadsheetDocument, CalculationParameters.SelectedAreas);
EndFunction

// Defines the correspondence between indicator calculation commands and indicators.
//
// Returns:
//   Map - Key - a command name, Value - an indicator name.
//
&AtClient
Function IndicatorsCommands()
	IndicatorsCommands = New Map();
	IndicatorsCommands.Insert("CalculateAmount", "Sum");
	IndicatorsCommands.Insert("CalculateCount", "Count");
	IndicatorsCommands.Insert("CalculateAverage", "Mean");
	IndicatorsCommands.Insert("CalculateMin", "Minimum");
	IndicatorsCommands.Insert("CalculateMax", "Maximum");
	
	Return IndicatorsCommands;
EndFunction

// Controls whether a calculation indicator panel is visible.
//
// Parameters:
//  Visibility - Boolean - indicates whether an indicator panel is visible.
//              See also Syntax Assistant: FormGroup.Visibility.
//
&AtClient
Procedure SetIndicatorsVisibility(Visibility)
	Items.IndicatorsArea.Visible = Visibility;
	Items.CalculateAllIndicators.Check = Visibility;
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
// Server call

&AtServer
Procedure SetVisibilityAvailability(OnSaveOption = False)
	ShowOptionsSelectionCommands = ReportOptionMode() AND ReportSettings.OptionSelectionAllowed;
	
	If Not OnSaveOption Then
		ShowOptionChangingCommands = ShowOptionsSelectionCommands AND ReportSettings.EditOptionsAllowed;
		SelectAndEditOptionsWithoutSavingAllowed = CommonClientServer.StructureProperty(
			ReportSettings, "SelectAndEditOptionsWithoutSavingAllowed", False);
		CountOfAvailableSettings = ReportsServer.CountOfAvailableSettings(Report.SettingsComposer);
		
		Items.AllSettings.Visible = ShowOptionChangingCommands Or CountOfAvailableSettings.Typical > 0;
		Items.MoreCommandBarAllSettings.Visible = Items.AllSettings.Visible;
		Items.ReportOptionsGroup.Visible = ShowOptionsSelectionCommands;
		
		SaveOptionAllowed = ShowOptionChangingCommands
			AND Not SelectAndEditOptionsWithoutSavingAllowed;
		CommonClientServer.SetFormItemProperty(
			Items, "SaveOption", "Visible", SaveOptionAllowed);
		CommonClientServer.SetFormItemProperty(
			Items, "SaveOptionMore", "Visible", SaveOptionAllowed);
		
		Items.OtherReports.Visible = ReportSettings.Subsystem <> Undefined
			AND ReportSettings.OptionSelectionAllowed;
		Items.MoreCommandBarOtherReports.Visible = Items.OtherReports.Visible;
		
		Items.EditReportOption.Visible = ShowOptionChangingCommands;
		Items.ChooseReportOption.Visible = ShowOptionsSelectionCommands;
		
		UseSettingsAllowed = ShowOptionsSelectionCommands AND CountOfAvailableSettings.Total > 0;
		CommonClientServer.SetFormItemProperty(
			Items, "SelectSettings", "Visible", UseSettingsAllowed);
		CommonClientServer.SetFormItemProperty(
			Items, "SaveSettings", "Visible", UseSettingsAllowed);
		
		Items.EditFilterCriteria.Visible = CountOfAvailableSettings.Total > 0 AND ReportOptionMode();
		
		If SelectAndEditOptionsWithoutSavingAllowed Then
			VariantModified = False;
		EndIf;
	EndIf;
	
	// Options selection commands.
	If PanelOptionsCurrentOptionKey <> CurrentVariantKey Then
		PanelOptionsCurrentOptionKey = CurrentVariantKey;
		
		If ShowOptionsSelectionCommands Then
			FillOptionsSelectionCommands();
		EndIf;
		
		If OutputRight Then
			WindowOptionsKey = ReportsClientServer.UniqueKey(ReportSettings.FullName, CurrentVariantKey);
			ReportSettings.Print.Insert("PrintParametersKey", WindowOptionsKey);
			FillPropertyValues(ReportSpreadsheetDocument, ReportSettings.Print);
		EndIf;
		
		URL = "";
		If ValueIsFilled(ReportSettings.OptionRef)
			AND Not ReportSettings.External
			AND Not ReportSettings.Contextual Then
			URL = GetURL(ReportSettings.OptionRef);
		EndIf;
	EndIf;
	
	// Schema modification commands.
	Items.EditSchema.Visible = ReportSettings.EditSchemaAllowed;
	Items.RestoreDefaultSchema.Visible = ReportSettings.RestoreStandardSchemaAllowed;
	Items.ImportSchema.Visible = ReportSettings.ImportSchemaAllowed
		// You cannot import an arbitrary DCS in SaaS due to safety regulations.
		AND Not Common.DataSeparationEnabled();
	
	// Title.
	ReportCurrentOptionDescription = TrimAll(ReportCurrentOptionDescription);
	If ValueIsFilled(ReportCurrentOptionDescription) Then
		Title = ReportCurrentOptionDescription;
	Else
		Title = ReportSettings.Description;
	EndIf;
	
	If DetailsMode Then
		Title = Title + " (" + NStr("ru = 'Расшифровка'; en = 'Details'; pl = 'Pełne brzmienie';de = 'Entschlüsselung';ro = 'Descifrare';tr = 'Deşifre'; es_ES = 'Explicación'") + ")";
	EndIf;
EndProcedure

&AtServer
Procedure ImportOption(OptionKey)
	If Not DetailsMode Then
		// Saving the current user settings.
		Common.SystemSettingsStorageSave(
			ReportSettings.FullName + "/" + CurrentVariantKey + "/CurrentUserSettings",
			"",
			Report.SettingsComposer.UserSettings);
	EndIf;
	DetailsMode = False;
	VariantModified = False;
	UserSettingsModified = False;
	ReportSettings.ReadCreateFromUserSettingsImmediatelyCheckBox = True;
	
	SetCurrentVariant(OptionKey);
	DisplayReportState(NStr("ru = 'Выбран другой вариант отчета. Нажмите ""Сформировать"" для получения отчета.'; en = 'Another report option is selected. To generate report, Click ""Run report"".'; pl = 'Wybrano inną opcję sprawozdania. Kliknij ""Wygeneruj"", aby otrzymać sprawozdanie.';de = 'Eine andere Berichtoption ist ausgewählt. Klicken Sie auf ""Generieren"", um den Bericht zu erhalten.';ro = 'Este selectată altă variantă a raportului. Faceți click pe ""Generare"" pentru a obține raportul.';tr = 'Başka bir rapor seçeneği seçildi. Raporu almak için ""Oluştur"" ''a tıklayın.'; es_ES = 'Otra opción del informe se ha seleccionado. Hace clic en ""Generar"" para recibir el informe.'"),
		PictureLib.Information32);
EndProcedure

&AtServer
Procedure DisplayReportState(Val StateText = "", Val StatePicture = Undefined)
	
	DisplayState = Not IsBlankString(StateText);
	If StatePicture = Undefined Or Not DisplayState Then 
		StatePicture = New Picture;
	EndIf;
	
	StatePresentation = Items.ReportSpreadsheetDocument.StatePresentation;
	StatePresentation.Visible = DisplayState;
	StatePresentation.AdditionalShowMode = 
		?(DisplayState, AdditionalShowMode.Irrelevance, AdditionalShowMode.DontUse);
	StatePresentation.Picture = StatePicture;
	StatePresentation.Text = StateText;

	Items.ReportSpreadsheetDocument.ReadOnly = DisplayState 
		Or Items.ReportSpreadsheetDocument.Output = UseOutput.Disable;
		
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Server

&AtServer
Procedure DefineBehaviorInMobileClient()
	If Not Common.IsMobileClient() Then 
		Return;
	EndIf;
	
	Items.CommandsAndIndicators.Title = NStr("ru = 'показатели'; en = 'indicators'; pl = 'wskaźniki';de = 'Kennzeichen';ro = 'indicatori';tr = 'göstergeler'; es_ES = 'indicadores'");
	Items.ReportSettingsGroup.Visible = False;
	Items.WorkInTableGroup.Visible = False;
	Items.OutputGroup.Visible = False;
	Items.Edit.Visible = False;
	
	Items.IndicatorGroup.HorizontalStretch = Undefined;
	Items.Indicator.Width = 0;
EndProcedure

&AtServer
Procedure SetCurrentOptionKey(ReportFullName, PredefinedOptions)
	PanelOptionsCurrentOptionKey = " - ";
	
	If ValueIsFilled(Parameters.VariantKey) Then
		CurrentVariantKey = Parameters.VariantKey;
	Else
		If Parameters.Property("CommandParameter")
			AND Common.RefTypeValue(Parameters.CommandParameter) Then 
			
			OwnerFullName = Parameters.CommandParameter.Metadata().FullName();
			ObjectKey = ReportFullName + "/" + OwnerFullName + "/CurrentVariantKey";
		Else
			ObjectKey = ReportFullName + "/CurrentVariantKey";
		EndIf;
		
		CurrentVariantKey = Common.SystemSettingsStorageLoad(ObjectKey, "");
	EndIf;
	
	If Not ValueIsFilled(CurrentVariantKey)
		AND PredefinedOptions.Count() > 0 Then
		
		CurrentVariantKey = PredefinedOptions[0].Value;
	EndIf;
EndProcedure

&AtServer
Procedure UpdateSettingsFormItemsAtServer(UpdateParameters = Undefined)
	ImportSettingsToComposer(UpdateParameters);
	
	ReportsServer.UpdateSettingsFormItems(
		ThisObject, Items.SettingsComposerUserSettings, UpdateParameters);
	
	If UpdateParameters.EventName <> "AfterGenerate" Then
		Regenerate = CommonClientServer.StructureProperty(UpdateParameters, "Regenerate", False);
		
		If Regenerate Then
			DisplayReportState(NStr("ru = 'Отчет формируется...'; en = 'Generating report...'; pl = 'Generowanie sprawozdania...';de = 'Den Bericht erstellen...';ro = 'Are loc generarea raportului...';tr = 'Rapor oluşturma...'; es_ES = 'Generando el informe...'"), PictureLib.TimeConsumingOperation48);
				
		ElsIf UpdateParameters.VariantModified
			Or UpdateParameters.UserSettingsModified Then
			
			DisplayReportState(NStr("ru = 'Изменились настройки. Нажмите ""Сформировать"" для получения отчета.'; en = 'Settings changed. To generate report, click ""Run report"".'; pl = 'Ustawienia zostały zmienione. Kliknij ""Wygeneruj"", aby otrzymać sprawozdanie.';de = 'Einstellungen wurden geändert. Klicken Sie auf ""Generieren"", um den Bericht zu erhalten.';ro = 'Setările au fost modificate. Faceți click pe ""Generați"" pentru a obține raportul.';tr = 'Ayarlar değiştirildi. Raporu almak için ""Oluştur"" ''a tıklayın.'; es_ES = 'Configuraciones se han cambiado. Hacer clic en ""Generar"" para obtener el informe.'"));
		EndIf;
	EndIf;
	
	// If a user is not allowed to change options of the report, the standard dialog box is not shown.
	If Not ReportSettings.EditOptionsAllowed Then
		VariantModified = False;
	EndIf;
	
	SetVisibilityAvailability();
EndProcedure

&AtServer
Procedure ImportSettingsToComposer(ImportParameters)
	CheckImportParameters(ImportParameters);
	
	AvailableSettings = ReportsServer.AvailableSettings(ImportParameters, ReportSettings);
	
	ApplyPredefinedSettings(AvailableSettings.Settings);
	
	ClearOptionSettings = CommonClientServer.StructureProperty(
		ImportParameters, "ClearOptionSettings", False);
	If ClearOptionSettings Then
		ImportOption(CurrentVariantKey);
	EndIf;
	
	ClearUserSettings = CommonClientServer.StructureProperty(
		ImportParameters, "ResetUserSettings", False);
	If ClearUserSettings Then
		AvailableSettings.UserSettings = New DataCompositionUserSettings;
	EndIf;
	
	ReportObject = FormAttributeToValue("Report");
	If ReportSettings.Events.BeforeImportSettingsToComposer Then 
		ReportObject.BeforeImportSettingsToComposer(
			ThisObject,
			ReportSettings.SchemaKey,
			CurrentVariantKey,
			AvailableSettings.Settings,
			AvailableSettings.UserSettings);
	EndIf;
	
	SettingsImported = ReportsClientServer.LoadSettings(
		Report.SettingsComposer,
		AvailableSettings.Settings,
		AvailableSettings.UserSettings,
		AvailableSettings.FixedSettings);
	
	// To set fixed filters, use the composer as it comprises the most complete collection of settings.
	// In BeforeImport parameters, some parameters can be missing if their settings were not overridden.
	If SettingsImported AND TypeOf(ParametersForm.Filter) = Type("Structure") Then
		ReportsServer.SetFixedFilters(ParametersForm.Filter, Report.SettingsComposer.Settings, ReportSettings);
	EndIf;
	
	If ParametersForm.Property("FixedSettings") Then 
		ParametersForm.FixedSettings = Report.SettingsComposer.FixedSettings;
	EndIf;
	
	ReportsServer.SetAvailableValues(ReportObject, ThisObject);
	ReportsServer.InitializePredefinedOutputParameters(ReportSettings, Report.SettingsComposer.Settings);
	
	AdditionalProperties = Report.SettingsComposer.Settings.AdditionalProperties;
	AdditionalProperties.Insert("VariantKey", CurrentVariantKey);
	AdditionalProperties.Insert("DescriptionOption", ReportCurrentOptionDescription);
	
	// Prepare for the composer preinitialization (used for details).
	If ReportSettings.SchemaModified Then
		AdditionalProperties.Insert("SchemaURL", ReportSettings.SchemaURL);
	EndIf;
	
	If ImportParameters.Property("SettingsFormAdvancedMode") Then
		ReportSettings.Insert("SettingsFormAdvancedMode", ImportParameters.SettingsFormAdvancedMode);
	EndIf;
	
	If ImportParameters.Property("SettingsFormPageName") Then
		ReportSettings.Insert("SettingsFormPageName", ImportParameters.SettingsFormPageName);
	EndIf;
	
	SetFiltersConditions(ImportParameters);
	
	If ImportParameters.VariantModified Then
		VariantModified = True;
	EndIf;
	
	If ImportParameters.UserSettingsModified Then
		UserSettingsModified = True;
	EndIf;
	
	If ReportSettings.ReadCreateFromUserSettingsImmediatelyCheckBox Then
		ReportSettings.ReadCreateFromUserSettingsImmediatelyCheckBox = False;
		Items.GenerateImmediately.Check = CommonClientServer.StructureProperty(
			AdditionalProperties,
			"GenerateImmediately",
			ReportSettings.GenerateImmediately);
	EndIf;
EndProcedure

&AtServer
Procedure CheckImportParameters(ImportParameters)
	If ImportParameters = Undefined Then 
		ImportParameters = New Structure;
	EndIf;
	
	If Not ImportParameters.Property("EventName") Then
		ImportParameters.Insert("EventName", "");
	EndIf;
	
	If Not ImportParameters.Property("VariantModified") Then
		ImportParameters.Insert("VariantModified", VariantModified);
	EndIf;
	
	If Not ImportParameters.Property("UserSettingsModified") Then
		ImportParameters.Insert("UserSettingsModified", UserSettingsModified);
	EndIf;
	
	If Not ImportParameters.Property("Result") Then
		ImportParameters.Insert("Result", New Structure);
	EndIf;
	
	ImportParameters.Insert("ReportObjectOrFullName", ReportSettings.FullName);
EndProcedure

&AtServer
Procedure ApplyPredefinedSettings(Settings)
	If Settings = Undefined
		Or Not ReportOptionMode()
		Or VariantModified
		Or CurrentLanguage() = Metadata.DefaultLanguage Then 
		Return;
	EndIf;
	
	IsPredefined = Not ReportSettings.Custom
		AND (ReportSettings.ReportType = Enums.ReportTypes.Internal
			Or ReportSettings.ReportType = Enums.ReportTypes.Extension)
		AND ValueIsFilled(ReportSettings.PredefinedRef);
	
	If IsPredefined Then 
		Settings = Report.SettingsComposer.Settings;
	EndIf;
EndProcedure

&AtServer
Procedure SetFiltersConditions(ImportParameters)
	FiltersConditions = CommonClientServer.StructureProperty(ImportParameters, "FiltersConditions");
	If FiltersConditions = Undefined Then
		Return;
	EndIf;
	
	Settings = Report.SettingsComposer.Settings;
	UserSettings = Report.SettingsComposer.UserSettings;
	
	For Each Condition In FiltersConditions Do
		UserSettingItem = UserSettings.GetObjectByID(Condition.Key);
		UserSettingItem.ComparisonType = Condition.Value;
		
		If ReportsClientServer.IsListComparisonKind(UserSettingItem.ComparisonType)
			AND TypeOf(UserSettingItem.RightValue) <> Type("ValueList") Then 
			
			UserSettingItem.RightValue = ReportsClientServer.ValuesByList(
				UserSettingItem.RightValue, True);
		EndIf;
		
		SettingItem = ReportsClientServer.GetObjectByUserID(
			Settings, UserSettingItem.UserSettingID,, UserSettings);
		
		FillPropertyValues(SettingItem, UserSettingItem, "ComparisonType, RightValue");
	EndDo;
EndProcedure

&AtServer
Procedure ShowGenerationErrors(ErrorInformation)
	If TypeOf(ErrorInformation) = Type("ErrorInfo") Then
		ErrorDescription = BriefErrorDescription(ErrorInformation);
		DetailedErrorPresentation = NStr("ru = 'Ошибка при формировании:'; en = 'Generation error:'; pl = 'Błąd wygenerowania:';de = 'Generierungsfehler:';ro = 'Eroare de generare:';tr = 'Oluşturma hatası:'; es_ES = 'Error de generación:'") + Chars.LF + DetailErrorDescription(ErrorInformation);
		If IsBlankString(ErrorDescription) Then
			ErrorDescription = DetailedErrorPresentation;
		EndIf;
	Else
		ErrorDescription = ErrorInformation;
		DetailedErrorPresentation = "";
	EndIf;
	
	DisplayReportState(ErrorDescription);
	If Not IsBlankString(DetailedErrorPresentation) Then
		ReportsOptions.WriteToLog(EventLogLevel.Warning, DetailedErrorPresentation, ReportSettings.OptionRef);
	EndIf;
EndProcedure

&AtServer
Procedure FillOptionsSelectionCommands()
	FormOptions = FormAttributeToValue("AddedOptions");
	FormOptions.Columns.Add("Found", New TypeDescription("Boolean"));
	AuthorizedUser = Users.AuthorizedUser();
	
	SearchParameters = New Structure;
	SearchParameters.Insert("Reports", ReportsServer.ValueToArray(ReportSettings.ReportRef));
	SearchParameters.Insert("OnlyPersonal", True);
	ReportOptionsTable = ReportsOptions.ReportOptionTable(SearchParameters);
	If ReportSettings.External Then // Add predefined options of the external report to the options table.
		For Each ListItem In ReportSettings.PredefinedOptions Do
			TableRow = ReportOptionsTable.Add();
			TableRow.Description = ListItem.Presentation;
			TableRow.VariantKey = ListItem.Value;
		EndDo;
	EndIf;
	ReportOptionsTable.GroupBy("Ref, VariantKey, Description, Author, AvailableToAuthorOnly");
	ReportOptionsTable.Sort("Description Asc, VariantKey Asc");
	
	MenuBorder = FormOptions.Count() - 1;
	For Each TableRow In ReportOptionsTable Do
		If TableRow.AvailableToAuthorOnly = True
			AND TableRow.Author <> AuthorizedUser Then
			Continue;
		EndIf;
		FoundItems = FormOptions.FindRows(New Structure("VariantKey, Found", TableRow.VariantKey, False));
		If FoundItems.Count() = 1 Then
			FormOption = FoundItems[0];
			FormOption.Found = True;
			
			Button = Items.Find(FormOption.CommandName);
			Button.Visible = True;
			Button.Title = TableRow.Description;
			Items.Move(Button, Items.ReportOptionsGroup);
			
			// More actions submenu (All actions).
			MoreButton = Items.Find(FormOption.CommandName + "MoreActions");
			MoreButton.Visible = True;
			MoreButton.Title = TableRow.Description;
			Items.Move(MoreButton, Items.MoreCommandBarReportOptionsGroup);
		Else
			MenuBorder = MenuBorder + 1;
			FormOption = FormOptions.Add();
			FillPropertyValues(FormOption, TableRow);
			FormOption.Found = True;
			FormOption.CommandName = "SelectOption_" + Format(MenuBorder, "NZ=0; NG=");
			
			Command = Commands.Add(FormOption.CommandName);
			Command.Action = "Attachable_ImportReportOption";
			
			Button = Items.Add(FormOption.CommandName, Type("FormButton"), Items.ReportOptionsGroup);
			Button.Type = FormButtonType.CommandBarButton;
			Button.CommandName = FormOption.CommandName;
			Button.Title = TableRow.Description;
			
			// More actions submenu (All actions).
			MoreButton = Items.Add(FormOption.CommandName + "MoreActions", Type("FormButton"), Items.MoreCommandBarReportOptionsGroup);
			MoreButton.Type = FormButtonType.CommandBarButton;
			MoreButton.CommandName = FormOption.CommandName;
			MoreButton.Title = TableRow.Description;
			
			ConstantCommands.Add(FormOption.CommandName);
		EndIf;
		
		Button.Check = (CurrentVariantKey = TableRow.VariantKey);
		Button.OnlyInAllActions = False;
		
		MoreButton.Check = (CurrentVariantKey = TableRow.VariantKey);
		MoreButton.OnlyInAllActions = True;
	EndDo;
	
	FoundItems = FormOptions.FindRows(New Structure("Found", False));
	For Each FormOption In FoundItems Do
		Button = Items.Find(FormOption.CommandName);
		Button.Visible = False;
		
		// More actions submenu (All actions).
		MoreButton = Items.Find(FormOption.CommandName + "MoreActions");
		MoreButton.Visible = False;
	EndDo;
	
	FormOptions.Columns.Delete("Found");
	ValueToFormAttribute(FormOptions, "AddedOptions");
EndProcedure

&AtServer
Procedure UpdateInfoOnReportOption()
	AdditionalProperties = Report.SettingsComposer.Settings.AdditionalProperties;
	AdditionalProperties.Insert("VariantKey", CurrentVariantKey);
	AdditionalProperties.Insert("DescriptionOption", ReportCurrentOptionDescription);
	
	ReportSettings.Insert("OptionRef", Undefined);
	ReportSettings.Insert("MeasurementsKey", Undefined);
	ReportSettings.Insert("PredefinedRef", Undefined);
	ReportSettings.Insert("OriginalOptionName", Undefined);
	ReportSettings.Insert("Custom", Undefined);
	ReportSettings.Insert("ReportType", Undefined);
	
	Query = New Query("
	|SELECT ALLOWED TOP 1
	|	ReportsOptions.Ref AS OptionRef,
	|	ReportsOptions.PredefinedVariant.MeasurementsKey AS MeasurementsKey,
	|	ReportsOptions.PredefinedVariant AS PredefinedRef,
	|	CASE
	|		WHEN ReportsOptions.Custom
	|			OR ReportsOptions.Parent.VariantKey IS NULL 
	|		THEN ReportsOptions.VariantKey
	|		ELSE ReportsOptions.Parent.VariantKey
	|	END AS OriginalOptionName,
	|	ReportsOptions.Custom AS Custom,
	|	ReportsOptions.ReportType
	|FROM
	|	Catalog.ReportsOptions AS ReportsOptions
	|WHERE
	|	ReportsOptions.Report = &Report
	|	AND ReportsOptions.VariantKey = &VariantKey
	|");
	Query.SetParameter("Report", ReportSettings.ReportRef);
	Query.SetParameter("VariantKey", CurrentVariantKey);
	
	Selection = Query.Execute().Select();
	If Not Selection.Next() Then
		Return;
	EndIf;
	
	MeasurementsKey = Selection.MeasurementsKey;
	If Not ValueIsFilled(MeasurementsKey) Then 
		MeasurementsKey = Common.TrimStringUsingChecksum(
			ReportSettings.FullName + "." + CurrentVariantKey, 135);
	EndIf;
	
	FillPropertyValues(ReportSettings, Selection);
	
	ReportSettings.MeasurementsKey = MeasurementsKey;
	ReportSettings.OriginalOptionName = ?(Selection.Custom, Selection.OriginalOptionName, CurrentVariantKey);
EndProcedure

&AtServer
Function ReportOptionMode()
	Return TypeOf(CurrentVariantKey) = Type("String") AND Not IsBlankString(CurrentVariantKey);
EndFunction

#EndRegion