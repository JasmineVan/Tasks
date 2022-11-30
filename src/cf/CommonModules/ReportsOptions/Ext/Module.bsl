///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Returns a reference to the report option.
//
// Parameters:
//  Report - CatalogRef.ExtensionObjectIDs,
//          CatalogRef.MetadataObjectIDs,
//          CatalogRef.AdditionalReportsAndDataProcessors,
//          String - a reference to the report or the external report full name.
//  OptionKey - String - the report option name.
//
// Returns:
//  CatalogRef.ReportsOptions, Undefined - the report option or Undefined if the report option is 
//          unavailable due to rights.
//
Function ReportOption(Report, OptionKey) Export
	Result = Undefined;
	
	Query = New Query;
	If TypeOf(Report) = Type("CatalogRef.ExtensionObjectIDs") Then
		Query.Text =
		"SELECT ALLOWED TOP 1
		|	ReportsOptions.Variant AS ReportOption
		|FROM
		|	InformationRegister.PredefinedExtensionsVersionsReportsOptions AS ReportsOptions
		|WHERE
		|	ReportsOptions.Report = &Report
		|	AND ReportsOptions.ExtensionsVersion = &ExtensionsVersion
		|	AND ReportsOptions.VariantKey = &VariantKey";
		Query.SetParameter("ExtensionsVersion", SessionParameters.ExtensionsVersion);
	Else
		Query.Text =
		"SELECT ALLOWED TOP 1
		|	ReportsOptions.Ref AS ReportOption
		|FROM
		|	Catalog.ReportsOptions AS ReportsOptions
		|WHERE
		|	ReportsOptions.Report = &Report
		|	AND ReportsOptions.VariantKey = &VariantKey
		|
		|ORDER BY
		|	ReportsOptions.DeletionMark";
	EndIf;
	Query.SetParameter("Report", Report);
	Query.SetParameter("VariantKey", OptionKey);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Result = Selection.ReportOption;
	EndIf;
	
	Return Result;
EndFunction

// Returns reports (CatalogRef.ReportsOptions) that are available to the current user.
// They must be used in all queries to the "ReportsOptions" catalog table as the filter by the 
// "Report" attribute except for filtering options from external reports.
// 
//
// Returns:
//  Array - reports that are available to the current user (CatalogRef.ExtensionObjectIDs,
//           String, CatalogRef.AdditionalReportsAndDataProcessors,
//           CatalogRef.MetadataObjectIDs).
//           The item type matches the Catalogs.ReportOptions.Attributes.Report attribute type.
//
Function CurrentUserReports() Export
	
	AvailableReports = New Array(ReportsOptionsCached.AvailableReports());
	
	// Additional reports that are available to the current user.
	If Common.SubsystemExists("StandardSubsystems.AdditionalReportsAndDataProcessors") Then
		ModuleAdditionalReportsAndDataProcessors = Common.CommonModule("AdditionalReportsAndDataProcessors");
		ModuleAdditionalReportsAndDataProcessors.OnAddAdditionalReportsAvailableForCurrentUser(AvailableReports);
	EndIf;
	
	Return AvailableReports;
	
EndFunction

// Returns the list of report options from the ReportsOptionsStorage settings storage.
// See also StandardSettingsStorageManager.GetList in Syntax Assistant.
// Unlike the platform method, the function checks access rights to the report instead of the "DataAdministration" right.
//
// Parameters:
//  ReportKey - String - a full report name with a fullstop.
//  User - String, UUID, 
//                 InfobaseUser, Undefined, 
//                 CatalogRef.Users - A name, ID, or reference to the user whose settings you need.
//                                                 
//                                                 If Undefined, a current user.
//
// Returns:
//   ValueList - a list of report options where:
//       * Value - String - a report option key.
//       * Presentation - String - a report option presentation.
//
//
Function ReportOptionsKeys(ReportKey, Val User = Undefined) Export
	
	Return SettingsStorages.ReportsVariantsStorage.GetList(ReportKey, User);
	
EndFunction

// The procedure deletes options of the specified report or all reports.
// See also StandardSettingsStorageManager.Delete in Syntax Assistant.
//
// Parameters:
//  ReportKey - String, Undefined - the report full name with a point.
//                                      If Undefined, settings of all reports will be deleted.
//  OptionKey - String, Undefined - the key of the report option to be deleted.
//                                        If Undefined, all report options will be deleted.
//  User - String, UUID, 
//                 InfobaseUser, Undefined, 
//                 CatalogRef.Users - the name, ID, or reference to the user whose settings will be 
//                                                 deleted.
//                                                 If Undefined, settings of all users will be deleted.
//
Procedure DeleteReportOption(ReportKey, OptionKey, Val User) Export
	
	SettingsStorages.ReportsVariantsStorage.Delete(ReportKey, OptionKey, User);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Support for overridable modules.

// The procedure calls the report manager module to fill in its settings.
// It is used for calling from the ReportsOptionsOverridable.CustomizeReportsOptions.
//
// Parameters:
//  Settings - Collection - the parameter is passed as is from the CustomizeReportsOptions procedure.
//  ReportMetadata - MetadataObject - metadata of the object that has the 
//                                       SetUpReportOptions(Settings, ReportSettings) export procedure in its manager module.
//
Procedure CustomizeReportInManagerModule(Settings, ReportMetadata) Export
	ReportSettings = ReportDetails(Settings, ReportMetadata);
	Try
		Reports[ReportMetadata.Name].CustomizeReportOptions(Settings, ReportSettings);
	Except
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Недопустимое значение параметра КлючВарианта в процедуре ВариантыОтчетов.НастроитьОтчетВМодулеМенеджера.
			|Не удалось настроить варианты отчета из модуля менеджера по причине:
			|%1'; 
			|en = 'Invalid value of OptionKey parameter specified. Procedure ReportsOptions.CustomizeReportInManagerModule.
			|Failed to configure report options from manager module. Reason:
			|%1'; 
			|pl = 'Niedopuszczalna wartość parametru OptionKey w procedurze ReportsOptions.CustomizeReportInManagerModule.
			|Nie udało się ustawić warianty raportu z modułu menedżera z powodu:
			|%1';
			|de = 'Ungültiger Wert des Parameters OptionKey in der Prozedur ReportsOptions.CustomizeReportInManagerModule.
			|Die Berichtsoptionen aus dem Manager-Modul können nicht konfiguriert werden aufgrund von:
			|%1';
			|ro = 'Valoare nevalidă a parametrului OptionKey în procedura ReportsOptions.CustomizeReportInManagerModule.
			|Nu se pot configura opțiunile de raport din modulul manager datorită:
			|%1';
			|tr = 'ReportsOptions.CustomizeReportInManagerModule prosedüründe OptionKey parametresinin kabul edilemeyen değeri. 
			| Rapor seçeneklerinin yönetici modülünden ayarlanamama nedeni: 
			|%1'; 
			|es_ES = 'Valor inaceptable del parámetro OptionKey en el procedimiento ReportsOptions.CustomizeReportInManagerModule.
			|No se ha podido ajustar las variantes del informe del módulo del gerente a causa de:
			|%1'"),
			DetailErrorDescription(ErrorInfo()));
		WriteToLog(EventLogLevel.Error, ErrorText, ReportMetadata);
	EndTry;
EndProcedure

// Returns settings of the specified report. The function is used to set up placement and common 
// report parameters in ReportsOptionsOverridable.CustomizeReportsOptions.
//
// Parameters:
//  Settings - Collection - used to describe settings of reports and options.
//                          The parameter is passed as is from the ReportsOptionsOverridable.
//                          CustomizeReportsOptions and CustomizeReportOptions procedures.
//  Report - MetadataObject, CatalogRef.MetadataObjectIDs - metadata or report reference.
//
// Returns:
//   ValueTreeRow - report settings and default settings for options of this report.
//     The returned value can be used in the OptionDetails function to get option settings.
//     Attributes to change:
//       * Enabled              - Boolean - if it is False, the report option is not registered in the subsystem.
//       * DefaultVisibility - Boolean - if False, the report option is hidden from the report panel by default.
//       * Placement           - Map - settings describing report option placement in sections.
//           ** Key     - MetadataObject - a subsystem where a report or a report option is placed.
//           ** Value - String           - settings related to placement in a subsystem (group).
//               *** ""        - output a report in a subsystem without highlighting.
//               *** "Important"  - output a report in a subsystem marked in bold.
//               *** "SeeAlso" - output a report in the "See also" group.
//       * FunctionalOptions - Array from String - names of functional options from the report option.
//       * SearchSettings  - Structure - additional settings related to the search of this report option.
//           You must configure these settings only in case DCS is not used or its functionality cannot be used completely.
//           For example, DCS can be used only for parametrization and receiving data whereas the 
//           output destination is a fixed template of a spreadsheet document.
//           ** FieldDescriptions - String - names of report option fields.
//           ** FilterAndParameterDescriptions - String - names of report option settings.
//           ** Keywords - String - additional terminology (including specific or obsolete).
//           Term separator: Chars.LF.
//           ** TemplatesNames - String - it is used instead of FieldDescriptions.
//               Names of spreadsheet or text document templates that are used to extract 
//               information on field descriptions.
//               Names are separated by commas.
//               Unfortunately, unlike DCS, templates do not contain information on links between 
//               fields and their presentations. Therefore it is recommended to fill in FieldDescriptions instead of 
//               TemplateNames for correct operating of the search engine.
//       * DCSSettingsFormat - Boolean - this report uses a standard settings storage format based 
//           on the DCS mechanics, and its main forms support the standard schema of interaction 
//           between forms (parameters and the type of return values).
//           If False, then consistency checks and some components that require the standard format 
//           will be disabled for this report.
//       * DefineFormSettings - Boolean - this report has application interface for integration with 
//           the report form, including overriding some form settings and subscribing to its events.
//           If True and the report is attached to the general ReportForm form, then the procedure 
//           must be defined in the report object module according to the following template:
//               
//               // Define settings of the "Report options" subsystem common report form.
//               //
//               // Parameters:
//               //   Form - ManagedForm, Undefined - a report form or a report settings form.
//               //      Undefined when called without a context.
//               //   OptionKey - String, Undefined - a predefined report option name
//               //       or a UUID of a custom one.
//               //      Undefined when called without a context.
//               //   Settings - Structure - see the return value of
//               //       ReportsClientServer.DefaultReportSettings().
//               //
//               Procedure DefineFormSettings(Form, VariantKey, Settings) Export
//               	// Procedure code.
//               EndProcedure
//     
//     Internal attributes (read-only):
//       * Report               - <see Catalogs.ReportOptions.Attributes.Report> - a full name or reference to a report.
//       * Metadata          - MetadataObject: Report - report metadata.
//       * OptionKey        - String - a report option key.
//       * DetailsReceived    - Boolean - indicates whether the row details are already received.
//           Details are generated by the OptionDetails() method.
//       * SystemInfo - Structure - another internal information.
//
Function ReportDetails(Settings, Report) Export

	If TypeOf(Report) = Type("MetadataObject") Then
		Result = Settings.FindRows(New Structure("Metadata, IsOption", Report, False));
	Else
		Result = Settings.FindRows(New Structure("Report, IsOption", Report, False));
	EndIf;
	
	If Result.Count() <> 1 Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Недопустимое значение параметра Отчет в функции ВариантыОтчетов.ОписаниеОтчета.
			|Отчет ""%1"" не подключен к подсистеме ""%2"". Проверьте свойство ""Хранилище вариантов"" в свойствах отчета.'; 
			|en = 'Invalid value of Report parameter is specified. Function ReportOptions.ReportDescription.
			|Report %1 is not attached to subsystem %2. Check Option storage property.'; 
			|pl = 'Niedopuszczalna wartość parametru Report w funkcji ReportOptions.ReportDescription.
			| Raport ""%1"" nie jest podłączony do podsystemu ""%2"". Sprawdź właściwość ""Magazyn wariantów"" we właściwościach raportu.';
			|de = 'Unzulässiger Wert des Berichtsparameters in der ReportOptions.ReportDescription.
			|Der Bericht ""%1"" ist nicht mit dem Subsystem ""%2"" verbunden. Überprüfen Sie in den Berichtseigenschaften die Eigenschaft ""Variantenspeicher"".';
			|ro = 'Valoare inadmisibilă a parametrului Report în funcția ReportOptions.ReportDescription.
			|Raportul ""%1"" nu este conectat la subsistemul ""%2"". Verificați proprietatea ""Storagele variantelor"" în proprietățile raportului.';
			|tr = 'Rapor parametresi için Report işlevinde geçersiz değer%1.ОписаниеОтчета.
			|Rapor """"alt sisteme bağlı değil""%2"". Rapor özelliklerinde seçenek deposu özelliğini kontrol edin.'; 
			|es_ES = 'Valor inaceptable del parámetro Report en la función ReportOptions.ReportDescription
			|El informe ""%1"" no está conectado al subsistema ""%2"". Compruebe la propiedad ""Almacenamiento de opciones"" en las propiedades del informe.'"),
			String(Report), SubsystemDescription(""));
	EndIf;
	
	Return Result[0];
EndFunction

// It finds report option settings. The function is used for configuring placement.
// For usage in ReportsOptionsOverridable.CustomizeReportsOptions.
//
// Parameters:
//  Settings - Collection - used to describe settings of reports and options.
//              The parameter is passed as is from the CustomizeReportsOptions and CustomizeReportOptions procedures.
//  Report - TreeRow, MetadataObject - settings details, metadata, or a report reference.
//  OptionKey - String - a report option name as it is defined in the data composition schema.
//
// Returns:
//   ValueTreeRow - report option settings.
//     Attributes to change:
//       * Enabled              - Boolean - if it is False, the report option is not registered in the subsystem.
//       * DefaultVisibility - Boolean - if False, the report option is hidden from the report panel by default.
//       * Description         - String - a report option description.
//       * Details             - String - a report option tooltip.
//       * Placement           - Map - settings describing report option placement in sections.
//           ** Key     - MetadataObject - a subsystem where a report or a report option is placed.
//           ** Value - String           - settings related to placement in a subsystem (group).
//               *** ""        - output an option in a subsystem without highlighting.
//               *** "Important"  - output an option in a subsystem marked in bold.
//               *** "SeeAlso" - output an option in the "See also" group.
//       * FunctionalOptions - Array from String - names of functional options from the report option.
//       * SearchSettings  - Structure - additional settings related to the search of this report option.
//           You must configure these settings only in case DCS is not used or its functionality cannot be used completely.
//           For example, DCS can be used only for parametrization and receiving data whereas the 
//           output destination is a fixed template of a spreadsheet document.
//           ** FieldDescriptions - String - names of report option fields.
//           ** FilterAndParameterDescriptions - String - names of report option settings.
//           ** Keywords - String - additional terminology (including specific or obsolete).
//           Term separator: Chars.LF.
//           ** TemplatesNames - String - it is used instead of FieldDescriptions.
//               Names of spreadsheet or text document templates that are used to extract 
//               information on field descriptions.
//               Names are separated by commas.
//               Unfortunately, unlike DCS, templates do not contain information on links between 
//               fields and their presentations. Therefore it is recommended to fill in FieldDescriptions instead of 
//               TemplateNames for correct operating of the search engine.
//       * DCSSettingsFormat - Boolean - this report uses a standard settings storage format based 
//           on the DCS mechanics, and its main forms support the standard schema of interaction 
//           between forms (parameters and the type of return values).
//           If False, then consistency checks and some components that require the standard format 
//           will be disabled for this report.
//       * DefineFormSettings - Boolean - this report has application interface for integration with 
//           the report form, including overriding some form settings and subscribing to its events.
//           If True and the report is attached to the general ReportForm form, then the procedure 
//           must be defined in the report object module according to the following template:
//               
//               // Define settings of the "Report options" subsystem common report form.
//               //
//               // Parameters:
//               //   Form - ManagedForm, Undefined - a report form or a report settings form.
//               //      Undefined when called without a context.
//               //   OptionKey - String, Undefined - a predefined report option name
//               //       or a UUID of a custom one.
//               //      Undefined when called without a context.
//               //   Settings - Structure - see the return value of
//               //       ReportsClientServer.DefaultReportSettings().
//               //
//               Procedure DefineFormSettings(Form, VariantKey, Settings) Export
//               	// Procedure code.
//               EndProcedure
//     
//     Internal attributes (read-only):
//       * Report               - <see Catalogs.ReportOptions.Attributes.Report> - a full name or reference to a report.
//       * Metadata          - MetadataObject: Report - report metadata.
//       * OptionKey        - String - a report option key.
//       * DetailsReceived    - Boolean - indicates whether the row details are already received.
//           Details are generated by the OptionDetails() method.
//       * SystemInfo - Structure - another internal information.
//
Function OptionDetails(Settings, Report, OptionKey) Export
	If TypeOf(Report) = Type("ValueTableRow") Then
		ReportDetails = Report;
	Else
		ReportDetails = ReportDetails(Settings, Report);
	EndIf;
	
	ReportOptionKey = ?(IsBlankString(OptionKey), ReportDetails.MainOption, OptionKey);
	Result = Settings.FindRows(New Structure("Report,VariantKey,IsOption", ReportDetails.Report, ReportOptionKey, True));
	If Result.Count() <> 1 Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Недопустимое значение параметра КлючВарианта в функции ВариантыОтчетов.ОписаниеВарианта:
				|вариант ""%1"" отсутствует в отчете ""%2"".'; 
				|en = 'Invalid value of OptionKey parameter. Function ReportOptions.OptionDescription.
				|Option %1 is missing in report %2.'; 
				|pl = 'Niedopuszczalna wartość parametru OptionKey w funkcji ReportOptions.OptionDescription:
				|brak wariantu ""%1"" w raporcie ""%2"".';
				|de = 'Ungültiger Wert des Parameters OptionKey in der Funktion ReportOptions.OptionDescription:
				|Die Varaiante ""%1"" fehlt im Bericht ""%2"".';
				|ro = 'Valoare inadmisibilă a parametrului OptionKey în funcția ReportOptions.OptionDescription:
				|varianta ""%1"" lipsește în raportul ""%2"".';
				|tr = 'Seçenek işlevinde anahtar değişken parametresi ReportOptions.OptionDescription: %1""%2""raporda eksik "
" seçeneği.'; 
				|es_ES = 'Valor inaceptable del parámetro OptionKey en la función ReportOptions.OptionDescription: no hay 
				|opción ""%1"" en el informe ""%2"".'"),
			OptionKey, ReportDetails.Metadata.Name);
	EndIf;
	
	FillOptionRowDetails(Result[0], ReportDetails);
	Return Result[0];
	
EndFunction

// The procedure sets the output mode for Reports and Options in report panels.
// To be called from the ReportsOptionsOverridable.CustomizeReportsOptions procedure of the 
// overridable module and from the CustomizeReportOptions procedure of the report object module.
//
// Parameters:
//  Settings - Collection - it is passed as is from the relevant parameter of the 
//              CustomizeReportsOptions and CustomizeReportOptions procedures.
//  ReportOrSubsystem - ValueTreeRow, MetadataObject: Report, MetadataObject: Subsystem -
//                       Details of a report or subsystem that are subject to the output mode configuration.
//                       If a subsystem is passed, the mode is set for all reports of this subsystem recursively.
//  GroupByReports - Boolean, String - mode of hyperlink output in report panel for this report:
//      * True, ByReports - options are grouped by a report.
//                By default, report panels output only a main report option. Other options of the 
//                report are displayed under the main one and are hidden. However, they can be found 
//                by the search or enabled by check boxes in the setup mode.
//                The main option is the first predefined option in the report schema.
//                This mode was introduced in version 2.2.2. It reduces the number of hyperlinks displayed in report panels.
//      * False, ByOptions - all report options are considered independent. They are visible by 
//              default and are displayed independently in report panels.
//              This mode was used in version 2.2.1 and earlier.
//
Procedure SetOutputModeInReportPanes(Settings, ReportOrSubsystem, GroupByReports) Export
	
	If TypeOf(GroupByReports) <> Type("Boolean") Then
		GroupByReports = (GroupByReports = Upper("ByReports"));
	EndIf;
	If TypeOf(ReportOrSubsystem) = Type("ValueTableRow") Or Metadata.Reports.Contains(ReportOrSubsystem) Then
		SetReportOutputModeInReportsPanels(Settings, ReportOrSubsystem, GroupByReports);
		Return;
	EndIf;

	Subsystems = New Array;
	Subsystems.Add(ReportOrSubsystem);
	Count = 1;
	ProcessedObjects = New Map;
	While Count > 0 Do
		Count = Count - 1;
		Subsystem = Subsystems[0];
		Subsystems.Delete(0);
		For Each NestedSubsystem In Subsystem.Subsystems Do
			Count = Count + 1;
			Subsystems.Add(NestedSubsystem);
		EndDo;
		For Each MetadataObject In ReportOrSubsystem.Content Do
			If ProcessedObjects[MetadataObject] <> Undefined Then
				Continue;
			EndIf;
			
			ProcessedObjects[MetadataObject] = True;
			If Metadata.Reports.Contains(MetadataObject) Then
				SetReportOutputModeInReportsPanels(Settings, MetadataObject, GroupByReports);
			EndIf;
		EndDo;
	EndDo;

EndProcedure

////////////////////////////////////////////////////////////////////////////////
// To call from reports.

// Updates content of the UserReportSettings catalog after saving the new setting.
// Called in the same name handler of the report form after the form code execution.
//
// Parameters:
//  Form - ManagedForm - a report form.
//  Settings - MetadataObject - it is passed as is from the OnSaveUserSettingsAtServer.
//
Procedure OnSaveUserSettingsAtServer(Form, Settings) Export
	
	FormAttributes = New Structure("ObjectKey, OptionRef");
	FillPropertyValues(FormAttributes, Form);
	If Not ValueIsFilled(FormAttributes.ObjectKey)
		Or Not ValueIsFilled(FormAttributes.OptionRef) Then
		ReportObject = Form.FormAttributeToValue("Report");
		ReportMetadata = ReportObject.Metadata();
		If Not ValueIsFilled(FormAttributes.ObjectKey) Then
			FormAttributes.ObjectKey = ReportMetadata.FullName();
		EndIf;
		If Not ValueIsFilled(FormAttributes.OptionRef) Then
			ReportInformation = GenerateReportInformationByFullName(FormAttributes.ObjectKey);
			If NOT ValueIsFilled(ReportInformation.ErrorText) Then
				ReportRef = ReportInformation.Report;
			Else
				ReportRef = FormAttributes.ObjectKey;
			EndIf;
			FormAttributes.OptionRef = ReportOption(ReportRef, Form.CurrentVariantKey);
		EndIf;
	EndIf;
	
	SettingsKey = FormAttributes.ObjectKey + "/" + Form.CurrentVariantKey;
	SettingsList = ReportsUserSettingsStorage.GetList(SettingsKey);
	SettingsCount = SettingsList.Count();
	UserRef = Users.AuthorizedUser();
	
	QueryText =
	"SELECT ALLOWED
	|	*
	|FROM
	|	Catalog.UserReportSettings AS UserReportSettings
	|WHERE
	|	UserReportSettings.Variant = &OptionRef
	|	AND UserReportSettings.User = &UserRef
	|
	|ORDER BY
	|	UserReportSettings.DeletionMark";
	
	Query = New Query;
	Query.SetParameter("OptionRef", FormAttributes.OptionRef);
	Query.SetParameter("UserRef", UserRef);
	Query.Text = QueryText;
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		ListItem = SettingsList.FindByValue(Selection.UserSettingKey);
		
		DeletionMark = (ListItem = Undefined);
		If DeletionMark <> Selection.DeletionMark Then
			SettingObject = Selection.Ref.GetObject();
			SettingObject.SetDeletionMark(DeletionMark);
		EndIf;
		If DeletionMark Then
			If SettingsCount = 0 Then
				Break;
			Else
				Continue;
			EndIf;
		EndIf;
		
		If Selection.Description <> ListItem.Presentation Then
			SettingObject = Selection.Ref.GetObject();
			SettingObject.Description = ListItem.Presentation;
			// The lock is not set as user settings are cut according to the users, so competitive work is not 
			// expected.
			SettingObject.Write();
		EndIf;
		
		SettingsList.Delete(ListItem);
		SettingsCount = SettingsCount - 1;
	EndDo;
	
	For Each ListItem In SettingsList Do
		SettingObject = Catalogs.UserReportSettings.CreateItem();
		SettingObject.Description                  = ListItem.Presentation;
		SettingObject.UserSettingKey = ListItem.Value;
		SettingObject.Variant                       = FormAttributes.OptionRef;
		SettingObject.User                  = UserRef;
		// The lock is not set as user settings are cut according to the users, so competitive work is not 
		// expected.
		SettingObject.Write();
	EndDo;
	
EndProcedure

// Extracts information on tables used in a schema or query.
// The calling code handles exceptions (for example, if an incorrect query text was passed).
//
// Parameters:
//  Object - DataCompositionSchema, String - a report schema or a query text.
//
// Returns:
//   Array - table names used in a schema or a query.
//
// Example:
//  // Call from the native form of the report using DCS.
//  UsedTables = ReportsOptions.UsedTables(FormAttributeToValue(Report).DataCompositionSchema);
//  ReportsOptions.CheckUsedTables(UsedTables).
//  // Call from the OnComposeResult handler of the report using DCS.
//  UsedTables = ReportOptions,.UsedTables(ThisObject.DataCompositionSchema);
//  ReportsOptions.CheckUsedTables(UsedTables).
//  // Call from the OnComposeResult handler of the report using query.
//  UsedTables = ReportOptions.UsedTables(QueryText);
//  ReportsOptions.CheckUsedTables(UsedTables).
//
Function TablesToUse(Object) Export
	Tables = New Array;
	If TypeOf(Object) = Type("DataCompositionSchema") Then
		RegisterDataSetsTables(Tables, Object.DataSets);
	ElsIf TypeOf(Object) = Type("String") Then
		RegisterQueryTables(Tables, Object);
	EndIf;
	Return Tables;
EndFunction

// Checks whether tables used in the schema or query are updated and inform the user about it.
// Check is executed by the InfobaseUpdate.ObjectProcessed() method.
// The calling code handles exceptions (for example, if an incorrect query text was passed).
//
// Parameters:
//  Object - DataCompositionSchema - a report schema.
//         - String - a query text.
//         - Array - table names used by the report.
//           * String - a table name.
//  Message - Boolean - when True and tables used by the report have not yet been updated, a message 
//             like The report can contain incorrect data will be output.
//             Optional. Default value is True.
//
// Returns:
//   Boolean - True when there are tables in the table list that are not yet updated.
//
// Example:
//  // Call from the native form of the report.
//  ReportsOptions.CheckUsedTables(FormAttributeToValue("Report").DataCompositionSchema);
//  // Call from the OnComposeResult report handler.
//  ReportsOptions.CheckUsedTables(ThisObject.DataCompositionSchema);
//  // Call upon query execution.
//  ReportOptions.CheckUsedTables(QueryText);
//
Function CheckUsedTables(Object, Message = True) Export
	If TypeOf(Object) = Type("Array") Then
		TablesToUse = Object;
	Else
		TablesToUse = TablesToUse(Object);
	EndIf;
	For Each FullName In TablesToUse Do
		If Not InfobaseUpdate.ObjectProcessed(FullName).Processed Then
			If Message Then
				Common.MessageToUser(DataIsBeingUpdatedMessage());
			EndIf;
			Return True;
		EndIf;
	EndDo;
	Return False;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// For calling from applied configuration update handlers.

// Resets user settings of specified reports.
//
// Parameters:
//  Key - MetadataObject: Report - metadata of the report for which settings must be reset.
//       - CatalogRef.ReportsOptions - option of the report for which settings must be reset.
//       - String - a full name of the report option for which settings must be reset.
//                  Filled in the <NameOfReport>/<NameOfOption> formate.
//                  If you pass "*", all configuration report settings will be reset.
//  SettingsTypes - Structure - optional. Types of user settings, that have to be reset.
//      Structure keys are also optional. The default value is indicated in parentheses.
//      * FilterItem - Boolean - (False) clear the  DataCompositionFilterItem setting.
//      * SettingsParameterValue - Boolean - (False) clear the DataCompositionSettingsParameterValue setting.
//      * SelectedFields - Boolean - (taken from the Other key) reset the DataCompositionSelectedFields setting.
//      * Order - Boolean - (taken from the Other key) clear the DataCompositionOrder setting.
//      * ConditionalAppearanceItem - Boolean - (taken from the Other key) reset the DataCompositionConditionalAppearanceItem setting.
//      * Other - Boolean - (True) reset other settings not explicitly described in the structure.
//
Procedure ResetUserSettings(varKey, SettingsTypes = Undefined) Export
	CommonClientServer.CheckParameter(
		"ReportsOptions.ResetUserSettings",
		"Key",
		varKey,
		New TypeDescription("String, MetadataObject, CatalogRef.ReportsOptions"));
	
	OptionsKeys = New Array; // The final list of keys to be cleared.
	
	// The list of keys can be filled from the query or you can pass one specific key from the outside.
	Query = New Query;
	QueryTemplate =
	"SELECT
	|	ISNULL(ReportsOptions.Report.Name, ReportsOptions.Report.ObjectName) AS ReportName,
	|	ReportsOptions.VariantKey
	|FROM
	|	Catalog.ReportsOptions AS ReportsOptions
	|WHERE
	|	&Condition";
	If varKey = "*" Then
		Query.Text = StrReplace(QueryTemplate, "&Condition", "ReportType = VALUE(Enum.ReportTypes.Internal)");
	ElsIf TypeOf(varKey) = Type("MetadataObject") Then
		Query.Text = StrReplace(QueryTemplate, "&Condition", "Report = &Report");
		Query.SetParameter("Report", Common.MetadataObjectID(varKey));
	ElsIf TypeOf(varKey) = Type("CatalogRef.ReportsOptions") Then
		Query.Text = StrReplace(QueryTemplate, "&Condition", "Ref = &Ref");
		Query.SetParameter("Ref", varKey);
	ElsIf TypeOf(varKey) = Type("String") Then
		OptionsKeys.Add(varKey);
	Else
		Raise NStr("ru = 'Некорректный тип параметра ""Отчет""'; en = 'Invalid type of Report parameter'; pl = 'Niepoprawny typ parametru ""Отчет""';de = 'Falscher Parametertyp ""Bericht""';ro = 'Tip incorect al parametrului ""Raport""';tr = '""Rapor"" parametresinin yanlış türü'; es_ES = 'Tipo incorrecto del parámetro ""Informe""'");
	EndIf;
	
	
	If Not IsBlankString(Query.Text) Then
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			OptionsKeys.Add(Selection.ReportName +"/"+ Selection.VariantKey);
		EndDo;
	EndIf;
	
	If SettingsTypes = Undefined Then
		SettingsTypes = New Structure;
	EndIf;
	ReportsOptionsClientServer.AddKeyToStructure(SettingsTypes, "FilterItem", True);
	ReportsOptionsClientServer.AddKeyToStructure(SettingsTypes, "SettingsParameterValue", True);
	ResetOtherSettings = CommonClientServer.StructureProperty(SettingsTypes, "OtherItems", True);
	
	SetPrivilegedMode(True);
	
	For Each OptionFullName In OptionsKeys Do
		ObjectKey = "Report." + OptionFullName + "/CurrentUserSettings";
		StorageSelection = SystemSettingsStorage.Select(New Structure("ObjectKey", ObjectKey));
		SuccessiveReadingErrors = 0;
		While True Do
			Try
				GotSelectionItem = StorageSelection.Next();
				SuccessiveReadingErrors = 0;
			Except
				GotSelectionItem = Undefined;
				SuccessiveReadingErrors = SuccessiveReadingErrors + 1;
				WriteToLog(EventLogLevel.Error, 
					NStr("ru = 'В процессе выборки пользовательских настроек отчетов из системного хранилища возникла ошибка:'; en = 'Error selecting custom report setting from the system storage:'; pl = 'W procesie wyboru ustawień użytkownika raportów z pamięci systemowej wystąpił błąd:';de = 'Bei der Auswahl der benutzerdefinierten Berichtseinstellungen aus dem Systemspeicher ist ein Fehler aufgetreten:';ro = 'Eroare la selectarea setărilor de utilizator ale rapoartelor din storagele de sistem:';tr = 'Standart depolama alanından kullanıcı ayarları seçilirken bir hata oluştu:'; es_ES = 'Durante la selección de los ajustes de usuario de los informes del almacenamiento de sistema ha ocurrido un error:'")
					+ Chars.LF
					+ DetailErrorDescription(ErrorInfo()));
			EndTry;
			
			If GotSelectionItem = False Then
				Break;
			ElsIf GotSelectionItem = Undefined Then
				If SuccessiveReadingErrors > 100 Then
					Break;
				Else
					Continue;
				EndIf;
			EndIf;
			
			DCUserSettings = StorageSelection.Settings;
			If TypeOf(DCUserSettings) <> Type("DataCompositionUserSettings") Then
				Continue;
			EndIf;
			HasChanges = False;
			Count = DCUserSettings.Items.Count();
			For Number = 1 To Count Do
				ReverseIndex = Count - Number;
				DCUserSetting = DCUserSettings.Items[ReverseIndex];
				Type = ReportsClientServer.SettingTypeAsString(TypeOf(DCUserSetting));
				Reset = CommonClientServer.StructureProperty(SettingsTypes, Type, ResetOtherSettings);
				If Reset Then
					DCUserSettings.Items.Delete(ReverseIndex);
					HasChanges = True;
				EndIf;
			EndDo;
			If HasChanges Then
				Common.SystemSettingsStorageSave(
					StorageSelection.ObjectKey,
					StorageSelection.SettingsKey,
					DCUserSettings,
					,
					StorageSelection.User);
			EndIf;
		EndDo;
	EndDo;
EndProcedure

// Moves user options from standard options storage to the subsystem storage.
// Used on partial deployment - when the ReportsOptionsStorage is set not for the entire 
// configuration, but in the properties of specific reports connected to the subsystem.
// It is recommended for using in specific version update handlers.
//
// Parameters:
//  ReportsNames - String - report names separated by commas.
//                          If the parameter is not specified, all reports are moved from standard 
//                          storage and then it is cleared.
//
// Example:
//  // Moving all user report options from upon update.
//  ReportsOptions.MoveReportsOptionsFromStandardStorage();
//  // Moving user report options, transferred to the Report options subsystem storage.
//  ReportsOptions.MoveReportsOptionsFromStandardStorage("EventLogAnalysis, ExpiringTasksOnDate");
//
Procedure MoveUsersOptionsFromStandardStorage(ReportsNames = "") Export
	ProcedurePresentation = NStr("ru = 'Прямая конвертация вариантов отчетов'; en = 'Direct conversion of report options'; pl = 'Konwersja bezpośrednia opcji sprawozdań';de = 'Direkte Konvertierung von Berichtsoptionen';ro = 'Conversia directă a opțiunilor pentru rapoarte';tr = 'Rapor seçeneklerinin doğrudan dönüşümü'; es_ES = 'Conversión directa de las opciones de informes'");
	WriteProcedureStartToLog(ProcedurePresentation);
	
	// The result that will be saved in the storage.
	ReportOptionsTable = Common.CommonSettingsStorageLoad("TransferReportOptions", "OptionsTable", , , "");
	If TypeOf(ReportOptionsTable) <> Type("ValueTable") Or ReportOptionsTable.Count() = 0 Then
		ReportOptionsTable = New ValueTable;
		ReportOptionsTable.Columns.Add("Report",     TypesDetailsString());
		ReportOptionsTable.Columns.Add("Variant",   TypesDetailsString());
		ReportOptionsTable.Columns.Add("Author",     TypesDetailsString());
		ReportOptionsTable.Columns.Add("Settings", New TypeDescription("ValueStorage"));
		ReportOptionsTable.Columns.Add("ReportPresentation",   TypesDetailsString());
		ReportOptionsTable.Columns.Add("VariantPresentation", TypesDetailsString());
		ReportOptionsTable.Columns.Add("AuthorID",   New TypeDescription("UUID"));
	EndIf;
	
	RemoveAll = (ReportsNames = "" Or ReportsNames = "*");
	ArrayOfObjectsKeysToDelete = New Array;
	
	StorageSelection = ReportsVariantsStorage.Select(NewFilterByObjectKey(ReportsNames));
	SuccessiveReadingErrors = 0;
	While True Do
		Try
			GotSelectionItem = StorageSelection.Next();
			SuccessiveReadingErrors = 0;
		Except
			GotSelectionItem = Undefined;
			SuccessiveReadingErrors = SuccessiveReadingErrors + 1;
			WriteToLog(EventLogLevel.Error,
				NStr("ru = 'В процессе выборки вариантов отчетов из стандартного хранилища возникла ошибка:'; en = 'Error occurred selecting report options from the standard storage:'; pl = 'Wystąpił błąd podczas wybierania wariantów sprawozdania z pamięci:';de = 'Beim Auswählen der Berichtsoptionen aus dem Standardspeicher ist ein Fehler aufgetreten:';ro = 'A apărut o eroare la selectarea opțiunilor de raportare din spațiul de stocare standard:';tr = 'Standart depolama alanından rapor seçenekleri seçilirken bir hata oluştu:'; es_ES = 'Ha ocurrido un error al seleccionar las opciones de informes desde el almacenamiento estándar:'")
				+ Chars.LF
				+ DetailErrorDescription(ErrorInfo()));
		EndTry;
		
		If GotSelectionItem = False Then
			If ReportsNames = "" Or ReportsNames = "*" Then
				Break;
			Else
				StorageSelection = ReportsVariantsStorage.Select(NewFilterByObjectKey(ReportsNames));
				Continue;
			EndIf;
		ElsIf GotSelectionItem = Undefined Then
			If SuccessiveReadingErrors > 100 Then
				Break;
			Else
				Continue;
			EndIf;
		EndIf;
		
		// Skipping not connected internal reports.
		ReportMetadata = Metadata.FindByFullName(StorageSelection.ObjectKey);
		If ReportMetadata <> Undefined Then
			StorageMetadata = ReportMetadata.VariantsStorage;
			If StorageMetadata = Undefined Or StorageMetadata.Name <> "ReportsVariantsStorage" Then
				RemoveAll = False;
				Continue;
			EndIf;
		EndIf;
		
		// All external report options will be transferred as it is impossible to define whether they are 
		// attached to the subsystem storage.
		ArrayOfObjectsKeysToDelete.Add(StorageSelection.ObjectKey);
		
		InfobaseUser = InfoBaseUsers.FindByName(StorageSelection.User);
		If InfobaseUser = Undefined Then
			User = Catalogs.Users.FindByDescription(StorageSelection.User, True);
			If Not ValueIsFilled(User) Then
				Continue;
			EndIf;
			UserID = User.IBUserID;
		Else
			UserID = InfobaseUser.UUID;
		EndIf;
		
		TableRow = ReportOptionsTable.Add();
		TableRow.Report     = StorageSelection.ObjectKey;
		TableRow.Variant   = StorageSelection.SettingsKey;
		TableRow.Author     = StorageSelection.User;
		TableRow.Settings = New ValueStorage(StorageSelection.Settings, New Deflation(9));
		TableRow.VariantPresentation = StorageSelection.Presentation;
		TableRow.AuthorID   = UserID;
		If ReportMetadata = Undefined Then
			TableRow.ReportPresentation = StorageSelection.ObjectKey;
		Else
			TableRow.ReportPresentation = ReportMetadata.Presentation();
		EndIf;
	EndDo;
	
	// Clear the standard storage.
	If RemoveAll Then
		ReportsVariantsStorage.Delete(Undefined, Undefined, Undefined);
	Else
		For Each ObjectKey In ArrayOfObjectsKeysToDelete Do
			ReportsVariantsStorage.Delete(ObjectKey, Undefined, Undefined);
		EndDo;
	EndIf;
	
	// Execution result
	WriteProcedureCompletionToLog(ProcedurePresentation);
	
	// Import options to the subsystem storage.
	ImportUserOptions(ReportOptionsTable);
EndProcedure

// Imports to the subsystem storage reports options previously saved from the system option storage 
// to the common settings storage.
// It is used to import report options upon full or partial deployment.
// At full deployment it can be called from the TransferReportsOptions data processor.
// It is recommended for using in specific version update handlers.
//
// Parameters:
//  UserOptions - ValueTable - optional. Used in internal scripts.
//       * Report - String - a full report name in the format of Report.<ReportName>.
//       * Option - String - a report option name.
//       * Author - String - a user name.
//       * Setting - ValueStorage - DataCompositionUserSettings.
//       * ReportPresentation - String - a report presentation.
//       * OptionPresentation - String - an option presentation.
//       * AuthorID - UUID - a user ID.
//
Procedure ImportUserOptions(UserOptions = Undefined) Export
	If UserOptions = Undefined Then
		UserOptions = Common.CommonSettingsStorageLoad(
			"TransferReportOptions", "UserOptions", , , "");
	EndIf;
	
	If TypeOf(UserOptions) <> Type("ValueTable")
		Or UserOptions.Count() = 0 Then
		Return;
	EndIf;
	
	ProcedurePresentation = NStr("ru = 'Завершить конвертацию вариантов отчетов'; en = 'Finalize report option conversion'; pl = 'Pełna konwersja opcji sprawozdań';de = 'Vollständige Konvertierung der Berichtsoptionen';ro = 'Finalizarea conversiei opțiunilor pentru rapoarte';tr = 'Rapor seçeneklerinin tam dönüşümü'; es_ES = 'Conversión completa de las opciones de informes'");
	WriteProcedureStartToLog(ProcedurePresentation);
	
	// Replacing column names for catalog structure.
	UserOptions.Columns.Report.Name = "ReportFullName";
	UserOptions.Columns.Variant.Name = "VariantKey";
	UserOptions.Columns.VariantPresentation.Name = "Description";
	
	// Transforming report names into MOID catalog references.
	UserOptions.Columns.Add("Report", Metadata.Catalogs.ReportsOptions.Attributes.Report.Type);
	UserOptions.Columns.Add("Defined", New TypeDescription("Boolean"));
	UserOptions.Columns.Add("ReportType", Metadata.Catalogs.ReportsOptions.Attributes.ReportType.Type);
	For Each OptionDetails In UserOptions Do
		ReportInformation = GenerateReportInformationByFullName(OptionDetails.ReportFullName);
		If TypeOf(ReportInformation.ErrorText) = Type("String") Then
			WriteToLog(EventLogLevel.Error, ReportInformation.ErrorText);
			Continue;
		EndIf;
		
		OptionDetails.Defined = True;
		FillPropertyValues(OptionDetails, ReportInformation, "Report, ReportType");
	EndDo;
	UserOptions.Sort("ReportFullName Asc, VariantKey Asc");
	
	ReportsSubsystems = PlacingReportsToSubsystems();
	
	Query = New Query("
	|SELECT
	|	UserOptions.Description,
	|	UserOptions.ReportPresentation,
	|	UserOptions.Report,
	|	UserOptions.ReportFullName,
	|	UserOptions.ReportType,
	|	UserOptions.VariantKey,
	|	UserOptions.Author AS AuthorPresentation,
	|	UserOptions.AuthorID,
	|	UserOptions.Settings AS Settings
	|INTO UserOptions
	|FROM
	|	&UserOptions AS UserOptions
	|WHERE
	|	UserOptions.Defined
	|;
	|
	|SELECT
	|	UserOptions.Description,
	|	UserOptions.ReportPresentation,
	|	UserOptions.Report,
	|	UserOptions.ReportFullName,
	|	UserOptions.ReportType,
	|	UserOptions.VariantKey,
	|	UserOptions.Settings,
	|	Variants.Ref,
	|	UserOptions.AuthorPresentation,
	|	Users.Ref AS Author
	|FROM
	|	UserOptions AS UserOptions
	|	LEFT JOIN Catalog.ReportsOptions AS Variants
	|		ON Variants.Report = UserOptions.Report
	|		AND Variants.VariantKey = UserOptions.VariantKey
	|		AND Variants.ReportType = UserOptions.ReportType
	|	LEFT JOIN Catalog.Users AS Users
	|		ON Users.IBUserID = UserOptions.AuthorID
	|		AND NOT Users.DeletionMark
	|");
	Query.SetParameter("UserOptions", UserOptions);
	
	OptionDetails = Query.Execute().Select();
	While OptionDetails.Next() Do 
		If ValueIsFilled(OptionDetails.Ref) Then
			Continue;
		EndIf;
		
		OptionStorage = Catalogs.ReportsOptions.CreateItem();
		FillPropertyValues(OptionStorage, OptionDetails, "Description, Report, ReportType, VariantKey, Author");
		
		OptionStorage.Custom = True;
		OptionStorage.AvailableToAuthorOnly = True;
		
		If TypeOf(OptionDetails.Settings) = Type("ValueStorage") Then
			OptionStorage.Settings = OptionDetails.Settings;
		Else
			OptionStorage.Settings = New ValueStorage(OptionDetails.Settings);
		EndIf;
		
		If Not ValueIsFilled(OptionDetails.Author) Then 
			Message = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Вариант ""%1"" отчета ""%2"": не найден автор ""%3""'; en = 'Report %2, option %1: cannot find author %3'; pl = 'Opcja ""%1"" sprawozdania ""%2"": nie znaleziono autora ""%3""';de = 'Option ""%1"" des Berichts ""%2"": Autor ""%3"" wurde nicht gefunden';ro = 'Opțiunea ""%1"" a raportului ""%2"": autorul ""%3"" nu a fost găsit';tr = '""%1"" Raporunun ""%2"" seçeneği: yazar ""%3"" bulunamadı'; es_ES = 'Opción ""%1"" del informe ""%2"": autor ""%3"" no se ha encontrado'"),
				OptionDetails.Description,
				OptionDetails.ReportPresentation,
				OptionDetails.AuthorPresentation);
			
			WriteToLog(EventLogLevel.Error, Message, OptionStorage.Ref);
		EndIf;
		
		// Since user report options are moved, placement settings can only be taken from report metadata.
		// 
		FoundSubsystems = ReportsSubsystems.FindRows(New Structure("ReportFullName", OptionDetails.ReportFullName));
		For Each SubsystemDetails In FoundSubsystems Do
			Subsystem = Common.MetadataObjectID(SubsystemDetails.SubsystemMetadata);
			If TypeOf(Subsystem) = Type("String") Then
				Continue;
			EndIf;
			Section = OptionStorage.Placement.Add();
			Section.Use = True;
			Section.Subsystem = Subsystem;
		EndDo;
		
		// Report options are created, thus competitive work with them is excluded.
		OptionStorage.Write();
	EndDo;
	
	Common.CommonSettingsStorageDelete("TransferReportOptions", "OptionsTable", "");
	
	WriteProcedureCompletionToLog(ProcedurePresentation);
EndProcedure

#Region ObsoleteProceduresAndFunctions

// Obsolete. You must stop using it.
//
// Returns:
//   ValueTable - used sections.
//
Function UsedSections() Export
	Result = New ValueTable;
	Result.Columns.Add("Ref",          New TypeDescription("CatalogRef.MetadataObjectIDs"));
	Result.Columns.Add("Metadata",      New TypeDescription("MetadataObject, String"));
	Result.Columns.Add("Name",             TypesDetailsString());
	Result.Columns.Add("Presentation",   TypesDetailsString());
	Result.Columns.Add("PanelCaption", TypesDetailsString());
	
	HomePageID = ReportsOptionsClientServer.HomePageID();
	
	SectionsList = New ValueList;
	
	ReportsOptionsOverridable.DefineSectionsWithReportOptions(SectionsList);
	
	If Common.SubsystemExists("StandardSubsystems.ApplicationSettings") Then
		ModuleDataProcessorsControlPanelSSL = Common.CommonModule("DataProcessors.SSLAdministrationPanel");
		ModuleDataProcessorsControlPanelSSL.OnDefineSectionsWithReportOptions(SectionsList);
	EndIf;
	
	For Each ListItem In SectionsList Do
		MetadataSection = ListItem.Value;
		If ValueIsFilled(ListItem.Presentation) Then
			CaptionPattern = ListItem.Presentation;
		Else
			CaptionPattern = NStr("ru = 'Отчеты раздела ""%1""'; en = '%1 reports'; pl = 'Sprawozdania ""%1""';de = 'Berichte von ""%1""';ro = '""%1"" rapoarte';tr = '""%1"" raporlar'; es_ES = 'Informes ""%1""'");
		EndIf;
		
		Row = Result.Add();
		Row.Ref = Common.MetadataObjectID(MetadataSection);
		If MetadataSection = HomePageID Then
			Row.Metadata    = HomePageID;
			Row.Name           = HomePageID;
			Row.Presentation = NStr("ru = 'Начальная страница'; en = 'Home page'; pl = 'Strona podstawowa';de = 'Startseite';ro = 'Pagina principală';tr = 'Ana sayfa'; es_ES = 'Página principal'");
		Else
			Row.Metadata    = MetadataSection;
			Row.Name           = MetadataSection.Name;
			Row.Presentation = MetadataSection.Presentation();
		EndIf;
		Row.PanelCaption = StrReplace(CaptionPattern, "%1", Row.Presentation); // Cannot go to the StrTemplate.
	EndDo;
	
	Return Result;
EndFunction

// Obsolete. You must stop using it.
// Full update of the report option search index.
// Call from the  OnAddUpdateHandlers of configuration.
// Warning: it should be called only once from the final application module.
// Not indented for calling from libraries.
//
// Parameters:
//   Handlers - Collection - it is passed "as it is" from the called procedure.
//   Version - String - a configuration version, migrating to which search index must be fully 
//       updated.
//     It is recommended to specify the latest functional version, during whose update changes were 
//       made to the presentations of metadata objects or their attributes that can be displayed in 
//       reports.
//       
//     Set if necessary.
//
// Example:
//	ReportOptions.AddCompleteUpdateHandlers(Handlers, "11.1.7.8");
//
Procedure AddCompleteUpdateHandlers(Handlers, Version) Export
	Return;
EndProcedure

// Obsolete. Use ReportOption.
// Receives a report option reference by a set of key attributes.
//
// Parameters:
//   Report - CatalogRef.ExtensionObjectIDs,
//           CatalogRef.MetadataObjectIDs,
//           CatalogRef.AdditionalReportsAndDataProcessors,
//           String - a report reference or a full name of the external report.
//   OptionKey - String - the report option name.
//
// Returns:
//   * CatalogRef.ReportsOptions - when option is found.
//   * Undefined                     - when option is not found.
//
Function GetRef(Report, OptionKey) Export
	
	Return ReportOption(Report, OptionKey);
	
EndFunction

#EndRegion

#EndRegion

#Region Internal

// The function gets the report object from the report option reference.
//
// Parameters:
//   Parameters - Structure - parameters of attaching and generating a report.
//       * OptionRef - CatalogRef.ReportsOptions - a report option reference.
//       * RefOfReport   - Arbitrary - a report reference.
//       * OptionKey   - String - a predefined report option name or a user report option ID.
//       * FormID - Undefined, UUID - an ID of the form from which the report is attached.
//
// Returns:
//   Structure - report parameters including the report Object.
//       * RefOfReport - Arbitrary     - a report reference.
//       * FullName    - String           - the full name of the report.
//       * Metadata   - MetadataObject - report metadata.
//       * Object       - ReportObject.<Report name>, ExternalReport - a report object.
//           ** SettingsComposer - DataCompositionSettingsComposer - report settings.
//           ** DataCompositionSchema - DataCompositionSchema - Report schema.
//       * OptionKey - String           - a predefined report option name or a user report option ID.
//       * SchemaURL   - String           - an address in the temporary storage where the report schema is placed.
//       * Success        - Boolean           - True if the report is attached.
//       * ErrorText  - String           - an error text.
//
// Usage locations:
//   ReportDistribution.InitializeReport().
//
Function AttachReportAndImportSettings(Parameters) Export
	Result = New Structure("OptionRef, ReportRef, VariantKey, FormSettings,
		|Object, Metadata, FullName,
		|DCSchema, SchemaURL, SchemaModified, DCSettings, DCUserSettings,
		|ErrorText, Success");
	FillPropertyValues(Result, Parameters);
	Result.Success = False;
	Result.SchemaModified = False;
	
	// Support the ability to directly select additional reports references in reports mailings.
	If TypeOf(Result.DCSettings) <> Type("DataCompositionSettings")
		AND Result.VariantKey = Undefined
		AND Result.Object = Undefined
		AND TypeOf(Result.OptionRef) = AdditionalReportRefType() Then
		// Automatically detecting a key and option reference if only a reference of additional report is passed.
		Result.ReportRef = Result.OptionRef;
		Result.OptionRef = Undefined;
		ConnectingReport = AttachReportObject(Result.ReportRef, True);
		If Not ConnectingReport.Success Then
			Result.ErrorText = ConnectingReport.ErrorText;
			Return Result;
		EndIf;
		FillPropertyValues(Result, ConnectingReport, "Object, Metadata, FullName");
		ConnectingReport.Clear();
		If Result.Object.DataCompositionSchema = Undefined Then
			Result.Success = True;
			Return Result;
		EndIf;
		DCSettingsOption = Result.Object.DataCompositionSchema.SettingVariants.Get(0);
		Result.VariantKey = DCSettingsOption.Name;
		Result.DCSettings  = DCSettingsOption.Settings;
		Result.OptionRef = ReportOption(Result.ReportRef, Result.VariantKey);
	EndIf;
	
	MustReadReportRef = (Result.Object = Undefined AND Result.ReportRef = Undefined);
	MustReadSettings = (TypeOf(Result.DCSettings) <> Type("DataCompositionSettings"));
	If MustReadReportRef Or MustReadSettings Then
		If TypeOf(Result.OptionRef) <> Type("CatalogRef.ReportsOptions")
			Or Not ValueIsFilled(Result.OptionRef) Then
			If Not MustReadReportRef AND Result.VariantKey <> Undefined Then
				Result.OptionRef = ReportOption(Result.ReportRef, Result.VariantKey);
			EndIf;
			If Result.OptionRef = Undefined Then
				Result.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'В методе ""%1"" не указаны параметры ""%2"".'; en = 'Parameters %2 are not provided in method %1.'; pl = 'W metodzie ""%1"" nie wskazane parametry ""%2"".';de = 'Die Parameter ""%2"" werden in der Methode ""%1"" nicht angegeben.';ro = 'În metoda ""%1"" nu sunt indicați parametrii ""%2"".';tr = '""%1"" yönteminde ""%2"" parametreleri belirtilmedi.'; es_ES = 'En el método ""%1"" no están indicados los parámetros ""%2"".'"),
					"AttachReportAndImportSettings",
					"OptionRef, ReportRef, VariantKey");
				Return Result;
			EndIf;
		EndIf;
		PropertiesNames = "VariantKey" + ?(MustReadReportRef, ", Report", "") + ?(MustReadSettings, ", Settings", "");
		OptionProperties = Common.ObjectAttributesValues(Result.OptionRef, PropertiesNames);
		Result.VariantKey = OptionProperties.VariantKey;
		If MustReadReportRef Then
			Result.ReportRef = OptionProperties.Report;
		EndIf;
		If MustReadSettings Then
			Result.DCSettings = OptionProperties.Settings.Get();
			MustReadSettings = (TypeOf(Result.DCSettings) <> Type("DataCompositionSettings"));
		EndIf;
	EndIf;
	
	If Result.Object = Undefined Then
		ConnectingReport = AttachReportObject(Result.ReportRef, True);
		If Not ConnectingReport.Success Then
			Result.ErrorText = ConnectingReport.ErrorText;
			Return Result;
		EndIf;
		FillPropertyValues(Result, ConnectingReport, "Object, Metadata, FullName");
		ConnectingReport.Clear();
		ConnectingReport = Undefined;
	ElsIf Result.FullName = Undefined Then
		Result.Metadata = Result.Object.Metadata();
		Result.FullName = Result.Metadata.FullName();
	EndIf;
	
	ReportObject = Result.Object;
	DCSettingsComposer = ReportObject.SettingsComposer;
	
	Result.FormSettings = ReportFormSettings(Result.ReportRef, Result.VariantKey, ReportObject);
	
	If ReportObject.DataCompositionSchema = Undefined Then
		Result.Success = True;
		Return Result;
	EndIf;
	
	// Reading settings.
	If MustReadSettings Then
		DCSettingsOptions = ReportObject.DataCompositionSchema.SettingVariants;
		DCSettingsOption = DCSettingsOptions.Find(Result.VariantKey);
		If DCSettingsOption = Undefined Then
			Result.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Вариант ""%1"" (ключ ""%2"") не найден в схеме отчета ""%3"".'; en = 'Cannot find report option %1, key  %2, in report scheme %3.'; pl = 'Wariantu ""%1"" (klucz ""%2"") nie znaleziono w schemacie raportu ""%3"".';de = 'Die Option ""%1"" (Schlüssel ""%2"") wird im Berichtsschema ""%3"" nicht gefunden.';ro = 'Varianta ""%1"" (cheia ""%2"") nu a fost găsită în schema raportului ""%3"".';tr = '""%1"" seçeneği (anahtar ""%2"") ""%3"" rapor şemasında bulunamadı.'; es_ES = 'La variante ""%1"" (clave ""%2"") no está encontrada en el esquema del informe ""%3"".'"),
				String(Result.OptionRef),
				Result.VariantKey,
				String(Result.ReportRef));
			Return Result;
		EndIf;
		Result.DCSettings = DCSettingsOption.Settings;
	EndIf;
	
	// Initializing schema.
	SchemaURLFilled = (TypeOf(Result.SchemaURL) = Type("String") AND IsTempStorageURL(Result.SchemaURL));
	If SchemaURLFilled AND TypeOf(Result.DCSchema) <> Type("DataCompositionSchema") Then
		Result.DCSchema = GetFromTempStorage(Result.SchemaURL);
	EndIf;
	
	Result.SchemaModified = (TypeOf(Result.DCSchema) = Type("DataCompositionSchema"));
	If Result.SchemaModified Then
		ReportObject.DataCompositionSchema = Result.DCSchema;
	EndIf;
	
	If Not SchemaURLFilled AND TypeOf(ReportObject.DataCompositionSchema) = Type("DataCompositionSchema") Then
		FormID = CommonClientServer.StructureProperty(Parameters, "FormID");
		If TypeOf(FormID) = Type("UUID") Then
			SchemaURLFilled = True;
			Result.SchemaURL = PutToTempStorage(ReportObject.DataCompositionSchema, FormID);
		ElsIf Result.SchemaModified Then
			SchemaURLFilled = True;
			Result.SchemaURL = PutToTempStorage(ReportObject.DataCompositionSchema);
		EndIf;
	EndIf;
	
	If SchemaURLFilled Then
		DCSettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(Result.SchemaURL));
	EndIf;
	
	If Result.FormSettings.Events.BeforeImportSettingsToComposer Then
		SchemaKey = CommonClientServer.StructureProperty(Parameters, "SchemaKey");
		ReportObject.BeforeImportSettingsToComposer(
			Result,
			SchemaKey,
			Result.VariantKey,
			Result.DCSettings,
			Result.DCUserSettings);
	EndIf;
	
	FixedDCSettings = CommonClientServer.StructureProperty(Parameters, "FixedDCSettings");
	If TypeOf(FixedDCSettings) = Type("DataCompositionSettings")
		AND DCSettingsComposer.FixedSettings <> FixedDCSettings Then
		DCSettingsComposer.LoadFixedSettings(FixedDCSettings);
	EndIf;
	
	ReportsClientServer.LoadSettings(DCSettingsComposer, Result.DCSettings, Result.DCUserSettings);
	
	Result.Success = True;
	Return Result;
EndFunction

// Updates additional report options when writing it.
//
// Usage locations:
//   Catalog.AdditionalReportsAndDataProcessors.OnWriteGlobalReport().
//
Procedure OnWriteAdditionalReport(CurrentObject, Cancel, ExternalObject) Export
	
	If Not ReportsOptionsCached.InsertRight() Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Недостаточно прав доступа для записи вариантов дополнительного отчета ""%1"".'; en = 'Insufficient rights to save options of additional report %1.'; pl = 'Niewystarczające prawa dostępu do opcji zapisu dodatkowego raportu ""%1"".';de = 'Unzureichende Zugriffsrechte zum Schreiben von Optionen des zusätzlichen Berichts ""%1"".';ro = 'Drepturi de acces insuficiente pentru a scrie opțiuni de raport suplimentar ""%1"".';tr = 'Ek rapor ""%1"" seçeneklerini yazmak için yetersiz erişim hakları.'; es_ES = 'Insuficientes derechos de acceso para grabar las opciones del informe adicional ""%1"".'"),
			CurrentObject.Description);
		WriteToLog(EventLogLevel.Error, ErrorText, CurrentObject.Ref);
		Common.MessageToUser(ErrorText);
		Return;
	EndIf;
	
	DeletionMark = CurrentObject.DeletionMark;
	If ExternalObject = Undefined
		Or Not CurrentObject.UseOptionStorage
		Or Not CurrentObject.AdditionalProperties.PublicationAvailable Then
		DeletionMark = True;
	EndIf;
	
	PredefinedOptions = New Map;
	If DeletionMark = False AND ExternalObject <> Undefined Then
		ReportMetadata = ExternalObject.Metadata();
		DCSchemaMetadata = ReportMetadata.MainDataCompositionSchema;
		If DCSchemaMetadata <> Undefined Then
			DCSchema = ExternalObject.GetTemplate(DCSchemaMetadata.Name);
			For Each DCSettingsOption In DCSchema.SettingVariants Do
				PredefinedOptions[DCSettingsOption.Name] = DCSettingsOption.Presentation;
			EndDo;
		Else
			PredefinedOptions[""] = ReportMetadata.Presentation();
		EndIf;
	EndIf;
	
	// When removing deletion mark from an additional report, it is not removed for user variants marked 
	// for deletion interactively.
	QueryText =
	"SELECT ALLOWED
	|	ReportsOptions.Ref AS Ref,
	|	ReportsOptions.VariantKey AS VariantKey,
	|	ReportsOptions.Custom AS Custom,
	|	ReportsOptions.DeletionMark AS DeletionMark
	|FROM
	|	Catalog.ReportsOptions AS ReportsOptions
	|WHERE
	|	ReportsOptions.Report = &Report
	|	AND (&DeletionMark
	|			OR NOT ReportsOptions.Custom
	|			OR NOT ReportsOptions.InteractiveSetDeletionMark)";
	
	Query = New Query(QueryText);
	Query.SetParameter("Report", CurrentObject.Ref);
	// When marking an additional report for deletion, all report oprtions are also marked for deletion.
	Query.SetParameter("DeletionMark", DeletionMark = True);
	
	// Set deletion mark.
	AdditionalReportOptions = Query.Execute().Unload();
	
	Lock = New DataLock;
	LockItem = Lock.Add("Catalog.ReportsOptions");
	LockItem.DataSource = AdditionalReportOptions;
	LockItem.UseFromDataSource("Ref", "Ref");
	
	For each ReportOption In AdditionalReportOptions Do
		
		OptionDeletionMark = DeletionMark;
		Presentation = PredefinedOptions[ReportOption.VariantKey];
		If Not OptionDeletionMark AND Not ReportOption.Custom AND Presentation = Undefined Then
			// A predefined item that is not found in the list of predefined items for this report.
			OptionDeletionMark = True;
		EndIf;
		
		If ReportOption.DeletionMark <> OptionDeletionMark Then
			OptionObject = ReportOption.Ref.GetObject();
			OptionObject.AdditionalProperties.Insert("PredefinedObjectsFilling", True);
			If OptionDeletionMark Then
				OptionObject.AdditionalProperties.Insert("IndexSchema", False);
			Else
				OptionObject.AdditionalProperties.Insert("ReportObject", ExternalObject);
			EndIf;
			OptionObject.SetDeletionMark(OptionDeletionMark);
		EndIf;
		
		If Presentation <> Undefined Then
			PredefinedOptions.Delete(ReportOption.VariantKey);
			
			OptionObject = ReportOption.Ref.GetObject();
			LocalizationServer.OnReadPresentationsAtServer(OptionObject);
			OptionObject.Description = Presentation;
			OptionObject.AdditionalProperties.Insert("ReportObject", ExternalObject);
			LocalizationServer.BeforeWriteAtServer(OptionObject);
			OptionObject.Write();
		EndIf;
	EndDo;
	
	If Not DeletionMark Then
		// Register new report options
		For Each Presentation In PredefinedOptions Do
			OptionObject = Catalogs.ReportsOptions.CreateItem();
			OptionObject.Report                = CurrentObject.Ref;
			OptionObject.ReportType            = Enums.ReportTypes.Additional;
			OptionObject.VariantKey         = Presentation.Key;
			OptionObject.Description         = Presentation.Value;
			OptionObject.Custom     = False;
			OptionObject.VisibleByDefault = True;
			OptionObject.AdditionalProperties.Insert("ReportObject", ExternalObject);
			LocalizationServer.BeforeWriteAtServer(OptionObject);
			OptionObject.Write();
		EndDo;
	EndIf;
	
EndProcedure

// Gets options of the passed report and their presentations.
//
// Usage locations:
//   UsersInternal.OnReceiveUserReportOptions().
//
Procedure UserReportOptions(FullReportName, InfobaseUser, ReportOptionTable, StandardProcessing) Export
	ReportKey = FullReportName;
	AllReportOptions = ReportOptionsKeys(ReportKey, InfobaseUser);
	
	For Each ReportOption In AllReportOptions Do
		CatalogItem = Catalogs.ReportsOptions.FindByDescription(ReportOption.Presentation);
		If CatalogItem = Undefined Then 
			Continue;
		EndIf;
		
		StandardProcessing = False;
		
		If Not CatalogItem.AvailableToAuthorOnly Then 
			Continue;
		EndIf;
		
		ReportOptionRow = ReportOptionTable.Add();
		ReportOptionRow.ObjectKey = FullReportName;
		ReportOptionRow.VariantKey = ReportOption.Value;
		ReportOptionRow.Presentation = ReportOption.Presentation;
		ReportOptionRow.StandardProcessing = False;
	EndDo;
	
	If Not StandardProcessing Then 
		Return;
	EndIf;
	
	MetadataOfReport = Metadata.FindByFullName(FullReportName);
	If (MetadataOfReport <> Undefined AND MetadataOfReport.VariantsStorage <> Undefined)
		Or TypeOf(ReportsVariantsStorage) <> Type("StandardSettingsStorageManager") Then 
		
		StandardProcessing = False;
	EndIf;
EndProcedure

// Deletes the passed report option from the report option storage.
//
// Usage locations:
//   UsersInternal.OnDeleteUserReportOptions().
//
Procedure DeleteUserReportOption(ReportOptionInfo, InfobaseUser, StandardProcessing) Export
	
	If ReportOptionInfo.StandardProcessing Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	DeleteReportOption(ReportOptionInfo.ObjectKey, ReportOptionInfo.VariantKey, InfobaseUser);
	
EndProcedure

// Generates additional parameters to open a report option.
//
// Parameters:
//   OptionRef - CatalogRef.ReportsOptions - a reference of the report option being opened..
//
Function OpeningParameters(OptionRef) Export
	OpeningParameters = New Structure("Ref, Report, ReportType, ReportName, VariantKey, MeasurementsKey");
	If TypeOf(OptionRef) = AdditionalReportRefType() Then
		// Support the ability to directly select additional reports references in reports mailings.
		OpeningParameters.Report     = OptionRef;
		OpeningParameters.ReportType = "Additional";
	Else
		QueryText =
		"SELECT ALLOWED
		|	ReportsOptions.Report,
		|	ReportsOptions.ReportType,
		|	ReportsOptions.VariantKey,
		|	ReportsOptions.PredefinedVariant.MeasurementsKey AS MeasurementsKey
		|FROM
		|	Catalog.ReportsOptions AS ReportsOptions
		|WHERE
		|	ReportsOptions.Ref = &Ref";
		
		Query = New Query;
		Query.SetParameter("Ref", OptionRef);
		Query.Text = QueryText;
		
		Selection = Query.Execute().Select();
		If Not Selection.Next() Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Недостаточно прав для открытия варианта ""%1"".'; en = 'Insufficient rights to open option %1.'; pl = 'Niewystarczające uprawnienia do otwarcia wariantu ""%1"".';de = 'Unzureichende Rechte zum Öffnen der Variante ""%1"".';ro = 'Drepturi insuficiente pentru deschiderea variantei ""%1"".';tr = '""%1"" seçeneğini açmak için yetersiz haklar.'; es_ES = 'Insuficientes derechos para abrir la variante ""%1"".'"), String(OptionRef));
		EndIf;
		
		FillPropertyValues(OpeningParameters, Selection);
		OpeningParameters.Ref    = OptionRef;
		OpeningParameters.ReportType = ReportsOptionsClientServer.ReportByStringType(Selection.ReportType, Selection.Report);
	EndIf;
	
	OnAttachReport(OpeningParameters);
	
	Return OpeningParameters;
EndFunction

// Attaching additional reports.
Procedure OnAttachReport(OpeningParameters) Export
	
	OpeningParameters.Insert("Connected", False);
	
	If OpeningParameters.ReportType = "Internal"
		Or OpeningParameters.ReportType = "Extension" Then
		
		MetadataOfReport = Common.MetadataObjectByID(
			OpeningParameters.Report, False);
		
		If TypeOf(MetadataOfReport) <> Type("MetadataObject") Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось открыть отчет ""%1"".
					|Возможно, было отключено расширение конфигурации с этим отчетом.'; 
					|en = 'Cannot open report %1.
					|The configuration extension that contains the report might have been disabled.'; 
					|pl = 'Nie można otworzyć sprawozdania ""%1"".
					|Być może rozszerzenie konfiguracji z tym sprawozdaniem zostało wyłączone.';
					|de = 'Der Bericht ""%1"" kann nicht geöffnet werden. 
					|Möglicherweise wurde die Konfigurationserweiterung mit diesem Bericht deaktiviert.';
					|ro = 'Eșec la deschiderea raportului ""%1"".
					|Probabil, că a fost dezactivată extensia configurației cu acest raport.';
					|tr = '""%1"" Raporu açılamıyor. 
					|Bu raporla yapılan yapılandırma uzantısı devre dışı bırakılmış olabilir.'; 
					|es_ES = 'No se puede abrir el informe ""%1"".
					|Puede ser que la extensión de la configuración con este informe se haya desactivado.'"),
				OpeningParameters.Report);
		EndIf;
		OpeningParameters.ReportName = MetadataOfReport.Name;
		OpeningParameters.Connected = True; // Configuration reports are always attached.
		
	ElsIf OpeningParameters.ReportType = "Extension" Then
		If Metadata.Reports.Find(OpeningParameters.ReportName) = Undefined Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось открыть отчет ""%1"".
					|Возможно, было отключено расширение конфигурации с этим отчетом.'; 
					|en = 'Cannot open report %1.
					|The configuration extension that contains the report might have been disabled.'; 
					|pl = 'Nie można otworzyć sprawozdania ""%1"".
					|Być może rozszerzenie konfiguracji z tym sprawozdaniem zostało wyłączone.';
					|de = 'Der Bericht ""%1"" kann nicht geöffnet werden. 
					|Möglicherweise wurde die Konfigurationserweiterung mit diesem Bericht deaktiviert.';
					|ro = 'Eșec la deschiderea raportului ""%1"".
					|Probabil, că a fost dezactivată extensia configurației cu acest raport.';
					|tr = '""%1"" Raporu açılamıyor. 
					|Bu raporla yapılan yapılandırma uzantısı devre dışı bırakılmış olabilir.'; 
					|es_ES = 'No se puede abrir el informe ""%1"".
					|Puede ser que la extensión de la configuración con este informe se haya desactivado.'"),
				OpeningParameters.ReportName);
		EndIf;
		OpeningParameters.Connected = True;
	ElsIf OpeningParameters.ReportType = "Additional" Then
		If Common.SubsystemExists("StandardSubsystems.AdditionalReportsAndDataProcessors") Then
			ModuleAdditionalReportsAndDataProcessors = Common.CommonModule("AdditionalReportsAndDataProcessors");
			ModuleAdditionalReportsAndDataProcessors.OnAttachReport(OpeningParameters);
		EndIf;
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Other procedures of internal interface.

Function SettingsUpdateParameters() Export
	
	Settings = New Structure;
	Settings.Insert("Configuration",      True);
	Settings.Insert("Extensions",        False);
	Settings.Insert("SharedData",       True);
	Settings.Insert("SeparatedData", True);
	Settings.Insert("Nonexclusive",       True);
	Settings.Insert("Deferred",        False);
	Settings.Insert("IndexSchema",False); // 
	If Common.DataSeparationEnabled() Then
		If Common.SeparatedDataUsageAvailable() Then
			Settings.SharedData       = False;
		Else // Shared session.
			Settings.SeparatedData = False;
		EndIf;
	ElsIf Common.IsStandaloneWorkplace() Then // SWP.
		Settings.SharedData       = False;
	EndIf;

	Settings.Extensions = Settings.SeparatedData;
	Return Settings;
	
EndFunction

// Updates subsystem metadata caches considering application operation mode.
// Usage example: after clearing settings storage.
//
// Parameters:
//   Settings - Structure - with the following properties:
//     * Configuration - Boolean - update the PredefinedReportsOptions shared catalog.
//     * Extensions   - Boolean - update the PredefinedExtensionsReportsOptions separated catalog.
//     * CommonData       - Boolean - update the PredefinedReportsOptions shared catalog.
//     * SeparatedData - Boolean - update the ReportsOptions separated catalog.
//     * RealTime - Boolean - update the list of report options, their descriptions and details.
//     * Deferred  - Boolean - fill in descriptions of fields, parameters, filters and keywords for the search.
//     * IndexSchema - Boolean - always index schemas (do not consider hash sums).
//
Function Refresh(Val Settings = Undefined) Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	If Settings = Undefined Then
		Settings = SettingsUpdateParameters();
	EndIf;
	
	Result = New Structure;
	Result.Insert("HasChanges", False);
	
	If Settings.Nonexclusive Then
		
		If Settings.SharedData Then
			
			If Settings.Configuration Then
				InterimResult = CommonDataNonexclusiveUpdate("ConfigurationCommonData", Undefined);
				Result.Insert("NonexclusiveUpdate_CommonData_Configuration", InterimResult);
				If InterimResult <> Undefined AND InterimResult.HasChanges Then
					Result.HasChanges = True;
				EndIf;
			EndIf;
			
			If Settings.Extensions Then
				InterimResult = CommonDataNonexclusiveUpdate("ExtensionsCommonData", Undefined);
				Result.Insert("NonexclusiveUpdate_CommonData_Extensions", InterimResult);
				If InterimResult <> Undefined AND InterimResult.HasChanges Then
					Result.HasChanges = True;
				EndIf;
			EndIf;
			
		EndIf;
		
		If Settings.SeparatedData Then
			
			If Settings.Configuration Then
				InterimResult = UpdateReportsOptions("SeparatedConfigurationData");
				Result.Insert("NonexclusiveUpdate_SeparatedData_Configuration", InterimResult);
				If InterimResult <> Undefined AND InterimResult.HasChanges Then
					Result.HasChanges = True;
				EndIf;
			EndIf;
			
			If Settings.Extensions Then
				InterimResult = UpdateReportsOptions("SeparatedExtensionData");
				Result.Insert("NonexclusiveUpdate_SeparatedData_Extensions", InterimResult);
				If InterimResult <> Undefined AND InterimResult.HasChanges Then
					Result.HasChanges = True;
				EndIf;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If Settings.Deferred Then
		
		If Settings.SharedData Then
			
			If Settings.Configuration Then
				InterimResult = UpdateSearchIndex("ConfigurationCommonData", Settings.IndexSchema);
				Result.Insert("DeferredUpdate_CommonData_Configuration", InterimResult);
				If InterimResult <> Undefined AND InterimResult.HasChanges Then
					Result.HasChanges = True;
				EndIf;
			EndIf;
			
			If Settings.Extensions Then
				InterimResult = UpdateSearchIndex("ExtensionsCommonData", Settings.IndexSchema);
				Result.Insert("DeferredUpdate_CommonData_Extensions", InterimResult);
				If InterimResult <> Undefined AND InterimResult.HasChanges Then
					Result.HasChanges = True;
				EndIf;
			EndIf;
			
		EndIf;
		
		If Settings.SeparatedData Then
			
			If Settings.Configuration Then
				InterimResult = UpdateSearchIndex("SeparatedConfigurationData", Settings.IndexSchema);
				Result.Insert("DeferredUpdate_SeparatedData_Configuration", InterimResult);
				If InterimResult <> Undefined AND InterimResult.HasChanges Then
					Result.HasChanges = True;
				EndIf;
			EndIf;
			
			If Settings.Extensions Then
				InterimResult = UpdateSearchIndex("SeparatedExtensionData", Settings.IndexSchema);
				Result.Insert("DeferredUpdate_SeparatedData_Extensions", InterimResult);
				If InterimResult <> Undefined AND InterimResult.HasChanges Then
					Result.HasChanges = True;
				EndIf;
			EndIf;
			
		EndIf;
		
	EndIf;
	SchedulePresentationsFilling();
	
	Return Result;
EndFunction

// Generates a report with the specified parameters.
//
// Parameters:
//   Parameters - Structure - parameters of attaching and generating a report.
//       * OptionRef - CatalogRef.ReportsOptions - a report option reference.
//       * RefOfReport   - Arbitrary - a report reference.
//       * OptionKey   - String - a predefined report option name or a user report option ID.
//       * FormID - Undefined, UUID - an ID of the form from which the report is attached.
//   CheckFilling - Boolean - if True, filling will be checked before generation.
//   GetCheckBoxEmpty - Boolean - if True, an analysis of filling is conducted after generation.
//
// Returns:
//   Structure - generation result.
//
// Usage locations:
//   ReportsMailing.GenerateReport().
//
// See also:
//   <Method>().
//
Function GenerateReport(Val Parameters, Val CheckFilling, Val GetCheckBoxEmpty) Export
	Result = New Structure("SpreadsheetDocument, Details,
		|OptionRef, ReportRef, VariantKey,
		|Object, Metadata, FullName,
		|DCSchema, SchemaURL, SchemaModified, FormSettings,
		|DCSettings, VariantModified,
		|DCUserSettings, UserSettingsModified,
		|ErrorText, Success, DataStillUpdating");
	
	Result.Success = False;
	Result.SpreadsheetDocument = New SpreadsheetDocument;
	Result.VariantModified = False;
	Result.UserSettingsModified = False;
	Result.DataStillUpdating = False;
	If GetCheckBoxEmpty Then
		Result.Insert("IsEmpty", False);
	EndIf;
	
	If Parameters.Property("Connection") Then
		Attachment = Parameters.Connection;
	Else
		Attachment = AttachReportAndImportSettings(Parameters);
	EndIf;
	FillPropertyValues(Result, Attachment); // , "Object, Metadata, FullName, OptionKey, DCSchema, SchemaURL, SchemaModified, FormSettings"
	If Not Attachment.Success Then
		Result.ErrorText = NStr("ru = 'Не удалось сформировать отчет:'; en = 'Report generation failed:'; pl = 'Nie udało się utworzyć raportu:';de = 'Der Bericht konnte nicht erstellt werden:';ro = 'Eșec la generarea raportului:';tr = 'Rapor oluşturulamadı:'; es_ES = 'No se ha podido generar el informe:'") + Chars.LF + Attachment.ErrorText;
		Return Result;
	EndIf;
	
	ReportObject = Result.Object;
	DCSettingsComposer = ReportObject.SettingsComposer;
	
	AuxProperties = DCSettingsComposer.UserSettings.AdditionalProperties;
	AuxProperties.Insert("VariantKey", Result.VariantKey);
	
	// Checking if data, by which report is being generated, is correct.
	
	If CheckFilling Then
		OriginalUserMessages = GetUserMessages(True);
		CheckPassed = ReportObject.CheckFilling();
		UserMessages = GetUserMessages(True);
		For Each Message In OriginalUserMessages Do
			Message.Message();
		EndDo;
		If Not CheckPassed Then
			Result.ErrorText = NStr("ru = 'Отчет не прошел проверку заполнения:'; en = 'Population check failed:'; pl = 'Raport nie przeszedł weryfikacji wypełnienia:';de = 'Der Bericht hat die Vollständigkeitsprüfung nicht bestanden:';ro = 'Raportul nu a susținut verificarea completării:';tr = 'Raporun doldurma şekli doğrulanamadı:'; es_ES = 'El informe no ha pasado la comprobación de relleno:'");
			For Each Message In UserMessages Do
				Result.ErrorText = Result.ErrorText + Chars.LF + Message.Text;
			EndDo;
			Return Result;
		EndIf;
	EndIf;
	
	Try
		TablesToUse = TablesToUse(Result.DCSchema);
		TablesToUse.Add(Result.FullName);
		If Result.FormSettings.Events.OnDefineUsedTables Then
			ReportObject.OnDefineUsedTables(Result.VariantKey, TablesToUse);
		EndIf;
		Result.DataStillUpdating = CheckUsedTables(TablesToUse, False);
	Except
		ErrorText = NStr("ru = 'Не удалось определить используемые таблицы:'; en = 'Cannot identify referenced tables:'; pl = 'Nie można określić używanych tabel:';de = 'Die verwendeten Tabellen konnten nicht ermittelt werden:';ro = 'Eșec la determinarea tabelelor utilizate:';tr = 'Kullanılan tablolar belirlenemedi:'; es_ES = 'No se ha podido determinar las tablas usadas:'");
		ErrorText = ErrorText + Chars.LF + DetailErrorDescription(ErrorInfo());
		WriteToLog(EventLogLevel.Error, ErrorText, Result.OptionRef);
	EndTry;
	
	// Generating and assessing the speed.
	
	KeyOperationName = CommonClientServer.StructureProperty(Parameters, "KeyOperationName");
	RunMeasurements = TypeOf(KeyOperationName) = Type("String") AND Not IsBlankString(KeyOperationName) AND RunMeasurements();
	If RunMeasurements Then
		KeyOperationComment = CommonClientServer.StructureProperty(Parameters, "KeyOperationComment");
		ModulePerformanceMonitor = Common.CommonModule("PerformanceMonitor");
		StartTime = ModulePerformanceMonitor.StartTimeMeasurement();
	EndIf;
	
	ReportObject.ComposeResult(Result.SpreadsheetDocument, Result.Details);
	
	If RunMeasurements Then
		ModulePerformanceMonitor.EndTechnologicalTimeMeasurement(
			KeyOperationName,
			StartTime,
			1,
			KeyOperationComment);
	EndIf;
	
	// Register the result.
	
	If AuxProperties <> DCSettingsComposer.UserSettings.AdditionalProperties Then
		NewAuxProperties = DCSettingsComposer.UserSettings.AdditionalProperties;
		CommonClientServer.SupplementStructure(NewAuxProperties, AuxProperties, False);
		AuxProperties = NewAuxProperties;
	EndIf;
	
	ItemModified = CommonClientServer.StructureProperty(AuxProperties, "VariantModified");
	If ItemModified = True Then
		Result.VariantModified = True;
		Result.DCSettings = DCSettingsComposer.Settings;
	EndIf;
	
	ItemsModified = CommonClientServer.StructureProperty(AuxProperties, "UserSettingsModified");
	If Result.VariantModified Or ItemsModified = True Then
		Result.UserSettingsModified = True;
		Result.DCUserSettings = DCSettingsComposer.UserSettings;
	EndIf;
	
	If GetCheckBoxEmpty Then
		If AuxProperties.Property("ReportIsBlank") Then
			IsEmpty = AuxProperties.ReportIsBlank;
		Else
			IsEmpty = ReportsServer.ReportIsBlank(ReportObject);
		EndIf;
		Result.Insert("IsEmpty", IsEmpty);
	EndIf;
	
	PrintSettings = Result.FormSettings.Print;
	PrintSettings.Insert("PrintParametersKey", ReportsClientServer.UniqueKey(Result.FullName, Result.VariantKey));
	FillPropertyValues(Result.SpreadsheetDocument, PrintSettings);
	
	// Setting headers and footers.
	
	HeaderOrFooterSettings = Undefined;
	Result.DCSettings.AdditionalProperties.Property("HeaderOrFooterSettings", HeaderOrFooterSettings);
	
	ReportDescription = "";
	If ValueIsFilled(Result.OptionRef) Then 
		ReportDescription = Common.ObjectAttributeValue(Result.OptionRef, "Description");
	ElsIf Result.Metadata <> Undefined Then 
		ReportDescription = Result.Metadata.Synonym;
	EndIf;
	
	HeaderFooterManagement.SetHeadersAndFooters(
		Result.SpreadsheetDocument, ReportDescription,, HeaderOrFooterSettings);
	
	Result.Success = True;
	
	// Clearing garbage.
	
	AuxProperties.Delete("VariantModified");
	AuxProperties.Delete("UserSettingsModified");
	AuxProperties.Delete("VariantKey");
	AuxProperties.Delete("ReportIsBlank");
	
	Return Result;
EndFunction

// Detalizes report availability by rights and functional options.
Function ReportsAvailability(ReportsReferences) Export

	Result = New ValueTable;
	Result.Columns.Add("Ref");
	Result.Columns.Add("Presentation", New TypeDescription("String"));
	Result.Columns.Add("Report", Metadata.Catalogs.ReportsOptions.Attributes.Report.Type);
	Result.Columns.Add("ReportByStringType", New TypeDescription("String"));
	Result.Columns.Add("Available", New TypeDescription("Boolean"));
	
	OptionsReferences = New Array;
	ConfigurationReportsReportsReferences = New Array;
	ExtensionsReportsReferences = New Array;
	AddlReportsRefs = New Array;
	
	Duplicates = New Map;
	
	SetPrivilegedMode(True);
	For Each Ref In ReportsReferences Do
		If Duplicates[Ref] <> Undefined Then
			Continue;
		EndIf;
		Duplicates[Ref] = True;
		
		TableRow = Result.Add();
		TableRow.Ref = Ref;
		TableRow.Presentation = String(Ref);
		Type = TypeOf(Ref);
		If Type = Type("CatalogRef.ReportsOptions") Then
			OptionsReferences.Add(Ref);
		Else
			TableRow.Report = Ref;
			TableRow.ReportByStringType = ReportsOptionsClientServer.ReportByStringType(Type, TableRow.Report);
			If TableRow.ReportByStringType = "Internal" Then
				ConfigurationReportsReportsReferences.Add(TableRow.Report);
			ElsIf TableRow.ReportByStringType = "Extension" Then
				ExtensionsReportsReferences.Add(TableRow.Report);
			ElsIf TableRow.ReportByStringType = "Additional" Then
				AddlReportsRefs.Add(TableRow.Report);
			EndIf;
		EndIf;
	EndDo;
	SetPrivilegedMode(False);
	
	If OptionsReferences.Count() > 0 Then
		ReportsValues = Common.ObjectsAttributeValue(OptionsReferences, "Report", True);
		For Each Ref In OptionsReferences Do
			TableRow = Result.Find(Ref, "Ref");
			ReportValue = ReportsValues[Ref];
			If ReportValue = Undefined Then
				TableRow.Presentation = NStr("ru = '<Недостаточно прав для работы с вариантом отчета>'; en = '<Insufficient rights to access the report option>'; pl = '<Niewystarczające uprawnienia do pracy z wariantem raportu>';de = '<Unzureichende Rechte, um mit der Berichtsvariante zu arbeiten>';ro = '<Drepturi insuficiente pentru lucrul cu varianta raportului>';tr = '<Rapor seçeneği ile çalışma hakları yetersiz>'; es_ES = '<Insuficientes derechos para usar la variante del informe>'");
			Else
				TableRow.Report = ReportValue;
				TableRow.ReportByStringType = ReportsOptionsClientServer.ReportByStringType(Undefined, TableRow.Report);
				If TableRow.ReportByStringType = "Internal" Then
					ConfigurationReportsReportsReferences.Add(TableRow.Report);
				ElsIf TableRow.ReportByStringType = "Extension" Then
					ExtensionsReportsReferences.Add(TableRow.Report);
				ElsIf TableRow.ReportByStringType = "Additional" Then
					AddlReportsRefs.Add(TableRow.Report);
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	ConfigurationReportsReportsReferences = CommonClientServer.CollapseArray(ConfigurationReportsReportsReferences);
	ExtensionsReportsReferences = CommonClientServer.CollapseArray(ExtensionsReportsReferences);
	AddlReportsRefs = CommonClientServer.CollapseArray(AddlReportsRefs);
	
	If ConfigurationReportsReportsReferences.Count() > 0 Then
		OnDefineReportsAvailability(ConfigurationReportsReportsReferences, Result);
	EndIf;
	
	If ExtensionsReportsReferences.Count() > 0 Then
		OnDefineReportsAvailability(ExtensionsReportsReferences, Result);
	EndIf;
	
	If AddlReportsRefs.Count() > 0 Then
		If Common.SubsystemExists("StandardSubsystems.AdditionalReportsAndDataProcessors") Then
			ModuleAdditionalReportsAndDataProcessors = Common.CommonModule("AdditionalReportsAndDataProcessors");
			ModuleAdditionalReportsAndDataProcessors.OnDetermineReportsAvailability(AddlReportsRefs, Result);
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

// Generates reference and report type by a full name.
//
// Parameters:
//   ReportFullName - String - the full name of the report in the following format:
//       "Report.<NameOfReport>" or "ExternalReport.<NameOfReport>".
//
// Returns:
//   Result - Structure -
//       * Report
//       * ReportType
//       * ReportName
//       * ReportMetadata
//       * ErrorText - String, Undefined - error text.
//
Function GenerateReportInformationByFullName(ReportFullName) Export
	Result = New Structure("Report, ReportType, ReportFullName, ReportName, ReportMetadata, ErrorText");
	Result.Report          = ReportFullName;
	Result.ReportFullName = ReportFullName;
	
	PointPosition = StrFind(ReportFullName, ".");
	If PointPosition = 0 Then
		Prefix = "";
		Result.ReportName = ReportFullName;
	Else
		Prefix = Left(ReportFullName, PointPosition - 1);
		Result.ReportName = Mid(ReportFullName, PointPosition + 1);
	EndIf;
	
	If Upper(Prefix) = "REPORT" Then
		Result.ReportMetadata = Metadata.Reports.Find(Result.ReportName);
		If Result.ReportMetadata = Undefined Then
			Result.ReportFullName = "ExternalReport." + Result.ReportName;
			WriteToLog(EventLogLevel.Warning,
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Отчет ""%1"" не найден в программе, он будет значиться как внешний.'; en = 'Cannot find report %1 in the application. It will be marked as external report.'; pl = 'W aplikacji nie znaleziono sprawozdania ""%1"", zostanie ono oznaczone jako zewnętrzne.';de = 'Der Report ""%1"" wurde in der Anwendung nicht gefunden, er wird als extern markiert.';ro = 'Raportul ""%1"" nu este găsit în aplicație, va fi marcat ca extern.';tr = 'Raporda ""%1"" bulunamıyor, harici olarak işaretlenecektir.'; es_ES = 'Informe ""%1"" no se ha encontrado en la aplicación, se marcará como externo.'"),
					ReportFullName));
		ElsIf Not AccessRight("View", Result.ReportMetadata) Then
			Result.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Недостаточно прав доступа к отчету ""%1"".'; en = 'Insufficient rights to access report %1.'; pl = 'Niewystarczające prawa dostępu do sprawozdania ""%1"".';de = 'Unzureichende Zugriffsrechte zum Berichten von ""%1"".';ro = 'Drepturi de acces insuficiente pentru a raporta ""%1"".';tr = '""%1"" raporlamak için haklar yetersiz.'; es_ES = 'Insuficientes derechos de acceso para el informe ""%1"".'"),
				ReportFullName);
		EndIf;
	ElsIf Upper(Prefix) = "EXTERNALREPORT" Then
		// It is not required to get metadata and perform checks.
	Else
		Result.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Для отчета ""%1"" невозможно определить тип (не установлен префикс).'; en = 'Cannot define type for report %1. Prefix is missing.'; pl = 'Nie można określić typu sprawozdania ""%1"" (nie ustawiono prefiksu).';de = 'Für den Bericht ""%1"" kann kein Typ definiert werden (Präfix ist nicht gesetzt).';ro = 'Tipul nu poate fi definit pentru raportul ""%1"" (prefixul nu este setat).';tr = '""%1"" Raporu için tür tanımlanamaz (önek ayarlanmamıştır).'; es_ES = 'Tipo no puede definirse para el informe ""%1"" (prefijo no está establecido).'"),
			ReportFullName);
		Return Result;
	EndIf;
	
	If Result.ReportMetadata = Undefined Then
		
		Result.Report = Result.ReportFullName;
		Result.ReportType = Enums.ReportTypes.External;
		
		// Replace a type and a reference of the external report for additional reports attached to the subsystem storage.
		If Common.SubsystemExists("StandardSubsystems.AdditionalReportsAndDataProcessors") Then
			
			Result.Insert("ByDefaultAllConnectedToStorage", ByDefaultAllConnectedToStorage());
			ModuleAdditionalReportsAndDataProcessors = Common.CommonModule("AdditionalReportsAndDataProcessors");
			ModuleAdditionalReportsAndDataProcessors.OnDetermineTypeAndReferenceIfReportIsAuxiliary(Result);
			Result.Delete("ByDefaultAllConnectedToStorage");
			
			If TypeOf(Result.Report) <> Type("String") Then
				Result.ReportType = Enums.ReportTypes.Additional;
			EndIf;
			
		EndIf;
		
	Else
		
		Result.Report = Common.MetadataObjectID(Result.ReportMetadata);
		Result.ReportType = ReportType(Result.Report);
		
	EndIf;
	
	Return Result;
	
EndFunction

// Checks the property value of the Option storage report.
//
// Parameters:
//   ReportMetadata - MetadataObject - metadata of the report whose property is being checked.
//   WarningText - String - check result details.
//
// Returns:
//   Boolean -
//       * True - the Option storage report property value is ReportsOptionsStorage.
//       * False - property value is not set or it is set but refers to Option storage not provided 
//                by the subsystem.
//
Function AdditionalReportOptionsStorageCorrect(MetadataOfReport, WarningText = "") Export 
	If MetadataOfReport.VariantsStorage = Metadata.SettingsStorages.ReportsVariantsStorage Then 
		Return True;
	EndIf;
	
	WarningTemplate = NStr("ru = 'Свойство отчета ""Хранилище вариантов"" %1.
		|Сохранение (выбор) вариантов отчета будет работать в ограниченном режиме.
		|Обратитесь к разработчику дополнительного (внешнего) отчета.'; 
		|en = 'The report property ""Option storage"" %1.
		|Saving and selecting report options are limited.
		|Contact the report developer.'; 
		|pl = 'Właściwość raportu ""Magazyn wariantów""%1.
		|Zapisywanie (wybór) wariantów raportu będzie działać w trybie ograniczonym.
		|Skontaktuj się z twórcą dodatkowego (zewnętrznego) raportu.';
		|de = 'Eigenschaft des Berichts ""VariantenSpeicher""%1.
		| Das Speichern (Auswählen) von Varianten des Berichts funktioniert in einem eingeschränkten Modus.
		|Wenden Sie sich an den Entwickler des zusätzlichen (externen) Berichts.';
		|ro = 'Proprietatea raportului ""Storagele variantelor"" %1.
		|Salvarea (selectarea) variantelor raportului va lucra în regim limitat.
		|Adresați-vă la dezvoltatorul raportului suplimentar (extern).';
		|tr = 'Seçenek deposu rapor özelliği%1.
		|Rapor seçeneklerinin kaydedilmesi (seçimi) sınırlı modda çalışacaktır.
		|Ek (harici) raporun geliştiricisine başvurun.'; 
		|es_ES = 'La propiedad del informe ""Almacenamiento de opciones"" %1.
		|Se puede guardar (seleccionar) las opciones del informe en el modo restringido.
		|Diríjase al desarrollador del informe adicional (externo).'");
	
	WarningParameter = NStr("ru = 'заполнено не корректно'; en = 'is invalid'; pl = 'nieprawidłowo wypełniono';de = 'ist nicht richtig ausgefüllt';ro = 'este completat incorect';tr = 'dolu doğru değil'; es_ES = 'rellenado incorrectamente'");
	If MetadataOfReport.VariantsStorage = Undefined Then 
		WarningParameter = NStr("ru = 'не заполнено'; en = 'is missing'; pl = 'nie wypełniono';de = 'nicht ausgefüllt';ro = 'nu este completat';tr = 'dolu değil'; es_ES = 'no rellenado'");
	EndIf;
	
	WarningText = StringFunctionsClientServer.SubstituteParametersToString(
		WarningTemplate, WarningParameter);
	
	Common.MessageToUser(WarningText);
	
	Return False;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// For a deployment report.

Function PredefinedReportsOptions(ReportsType = "Internal") Export
	CatalogAttributes = Metadata.Catalogs.ReportsOptions.Attributes;
	
	Result = New ValueTable;
	Result.Columns.Add("Report",                CatalogAttributes.Report.Type);
	Result.Columns.Add("Metadata",           New TypeDescription("MetadataObject"));
	Result.Columns.Add("UsesDCS",        New TypeDescription("Boolean"));
	Result.Columns.Add("VariantKey",         CatalogAttributes.VariantKey.Type);
	Result.Columns.Add("DetailsReceived",     New TypeDescription("Boolean"));
	Result.Columns.Add("Enabled",              New TypeDescription("Boolean"));
	Result.Columns.Add("VisibleByDefault", New TypeDescription("Boolean"));
	Result.Columns.Add("Description",         TypesDetailsString());
	Result.Columns.Add("Details",             TypesDetailsString());
	Result.Columns.Add("Placement",           New TypeDescription("Map"));
	Result.Columns.Add("SearchSettings",   New TypeDescription("Structure"));
	Result.Columns.Add("SystemInfo",  New TypeDescription("Structure"));
	Result.Columns.Add("Type",                  TypesDetailsString());
	Result.Columns.Add("IsOption",           New TypeDescription("Boolean"));
	Result.Columns.Add("FunctionalOptions",  New TypeDescription("Array"));
	Result.Columns.Add("GroupByReport", New TypeDescription("Boolean"));
	Result.Columns.Add("MeasurementsKey",          New TypeDescription("String"));
	Result.Columns.Add("MainOption",      CatalogAttributes.VariantKey.Type);
	Result.Columns.Add("DCSSettingsFormat",        New TypeDescription("Boolean"));
	Result.Columns.Add("DefineFormSettings", New TypeDescription("Boolean"));
	
	// Auxiliary info for the UpdateSettingsOfPredefinedItems procedure.
	Result.Columns.Add("FoundInDatabase", New TypeDescription("Boolean"));
	Result.Columns.Add("OptionFromBase"); // selection row from the table
	Result.Columns.Add("ParentOption", New TypeDescription(New TypeDescription("CatalogRef.PredefinedReportsOptions"), 
		"CatalogRef.PredefinedExtensionsReportsOptions"));
	
	Result.Indexes.Add("Report");
	Result.Indexes.Add("Report,IsOption");
	Result.Indexes.Add("Report,VariantKey");
	Result.Indexes.Add("Report,VariantKey,IsOption");
	Result.Indexes.Add("VariantKey");
	Result.Indexes.Add("Metadata,VariantKey");
	Result.Indexes.Add("Metadata,IsOption");
	
	GroupByReports = GlobalSettings().OutputReportsInsteadOfOptions;
	IndexingAllowed = SharedDataIndexingAllowed();
	HasAttachableCommands = Common.SubsystemExists("StandardSubsystems.AttachableCommands");
	If HasAttachableCommands Then
		AttachableReportsAndProcessorsComposition = Metadata.Subsystems["AttachableReportsAndDataProcessors"].Content;
		ModuleAttachableCommands = Common.CommonModule("AttachableCommands");
	EndIf;
	
	SeparatedDataUsageAvailable = Common.SeparatedDataUsageAvailable();
	ReportsSubsystems = PlacingReportsToSubsystems();
	StorageFlagCache = Undefined;
	SearchSettings = New Structure("FieldDescriptions, FilterParameterDescriptions, Keywords, TemplatesNames");
	
	For Each ReportMetadata In Metadata.Reports Do 
		If Not SeparatedDataUsageAvailable AND ReportMetadata.ConfigurationExtension() <> Undefined Then
			Continue;
		EndIf;
		
		If Not ReportAttachedToStorage(ReportMetadata, StorageFlagCache) Then
			Continue;
		EndIf;
		
		ReportRef = Common.MetadataObjectID(ReportMetadata);
		TypeOfReport = ReportType(ReportRef, True);
		If ReportsType <> Undefined AND ReportsType <> TypeOfReport Then
			Continue;
		EndIf;
		
		HasAttributes = (ReportMetadata.Attributes.Count() > 0);
		
		// Settings.
		ReportDetails = Result.Add();
		ReportDetails.Report                = ReportRef;
		ReportDetails.Metadata           = ReportMetadata;
		ReportDetails.Enabled              = True;
		ReportDetails.VisibleByDefault = True;
		ReportDetails.Details             = ReportMetadata.Explanation;
		ReportDetails.Description         = ReportMetadata.Presentation();
		ReportDetails.DetailsReceived     = True;
		ReportDetails.Type                  = TypeOfReport;
		ReportDetails.GroupByReport = GroupByReports;
		ReportDetails.UsesDCS        = (ReportMetadata.MainDataCompositionSchema <> Undefined);
		ReportDetails.DCSSettingsFormat    = ReportDetails.UsesDCS AND Not HasAttributes;
		ReportDetails.SearchSettings = SearchSettings;
		
		// Placement.
		FoundItems = ReportsSubsystems.FindRows(New Structure("ReportMetadata", ReportMetadata)); 
		For Each RowSubsystem In FoundItems Do
			ReportDetails.Placement.Insert(RowSubsystem.SubsystemMetadata, "");
		EndDo;
		
		// Predefined options.
		If ReportDetails.UsesDCS Then
			ReportManager = Reports[ReportMetadata.Name];
			DCSchema = Undefined;
			SettingsOptions = Undefined;
			Try
				DCSchema = ReportManager.GetTemplate(ReportMetadata.MainDataCompositionSchema.Name);
			Except
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Не удалось прочитать схему отчета:
						|%1'; 
						|en = 'Failed reading report scheme:
						|%1'; 
						|pl = 'Nie można odczytać schematu sprawozdania:
						|%1';
						|de = 'Das Schema des Berichts konnte nicht gelesen werden:
						|%1';
						|ro = 'Eșec la citirea schemei raportului:
						|%1';
						|tr = 'Rapor şeması okunamadı:
						|%1'; 
						|es_ES = 'No se ha podido leer el esquema del informe:
						|%1'"), DetailErrorDescription(ErrorInfo()));
				WriteToLog(EventLogLevel.Warning, ErrorText, ReportMetadata);
			EndTry;
			// Reading report option settings from the schema.
			If DCSchema <> Undefined Then
				Try
					SettingsOptions = DCSchema.SettingVariants;
				Except
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Не удалось прочитать список вариантов отчета:
							|%1'; 
							|en = 'Failed reading report option list:
							|%1'; 
							|pl = 'Nie udało się odczytać listę wariantów raportu:
							|%1';
							|de = 'Die Liste der Varianten des Berichts konnte nicht gelesen werden:
							|%1';
							|ro = 'Eșec la citirea listei variantelor raportului:
							|%1';
							|tr = 'Rapor seçenek listesi okunamadı:
							|%1'; 
							|es_ES = 'No se ha podido leer la lista de opciones del informe:
							|%1'"), DetailErrorDescription(ErrorInfo()));
					WriteToLog(EventLogLevel.Warning, ErrorText, ReportMetadata);
				EndTry;
			EndIf;
			// Reading report option settings from the manager module (if cannot read from the schema).
			If SettingsOptions = Undefined Then
				Try
					SettingsOptions = ReportManager.SettingVariants();
				Except
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Не удалось прочитать список вариантов отчета из модуля менеджера:
							|%1'; 
							|en = 'Failed reading report option list from manager module:
							|%1'; 
							|pl = 'Nie udało się odczytać listę wariantów raportu z modułu menedżera:
							|%1';
							|de = 'Die Liste der Berichtsvarianten konnte nicht vom Manager-Modul gelesen werden:
							|%1';
							|ro = 'Eșec la citirea listei variantelor raportului din modului managerului:
							|%1';
							|tr = 'Yönetici modülünden rapor seçenekleri listesi okunamadı:
							|%1'; 
							|es_ES = 'No se ha podido leer la lista de opciones del informe del módulo de gestor:
							|%1'"), DetailErrorDescription(ErrorInfo()));
					WriteToLog(EventLogLevel.Error, ErrorText, ReportMetadata);
				EndTry;
			EndIf;
			// Found variant registration.
			If SettingsOptions <> Undefined Then
				For Each DCSettingsOption In SettingsOptions Do
					OptionDetails = Result.Add();
					OptionDetails.Report        = ReportDetails.Report;
					OptionDetails.VariantKey = DCSettingsOption.Name;
					OptionDetails.Description = DCSettingsOption.Presentation;
					If IsBlankString(OptionDetails.Description) Then // if configuration is partly localised
						OptionDetails.Description = ?(OptionDetails.VariantKey <> "Main", OptionDetails.VariantKey,  // do not localize.
							ReportDetails.Description + "." + OptionDetails.VariantKey);
					EndIf;	
					OptionDetails.Type          = TypeOfReport;
					OptionDetails.IsOption   = True;
					If IsBlankString(ReportDetails.MainOption) Then
						ReportDetails.MainOption = OptionDetails.VariantKey;
					EndIf;
					If IndexingAllowed AND TypeOf(DCSettingsOption) = Type("DataCompositionSettingsVariant") Then
						Try
							OptionDetails.SystemInfo.Insert("DCSettings", DCSettingsOption.Settings);
						Except
							ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
								NStr("ru = 'Не удалось прочитать настройки варианта ""%1"":
									|%2'; 
									|en = 'Failed reading the ""%1"" report option settings:
									|%2'; 
									|pl = 'Nie można odczytać ustawień dla opcji sprawozdania ""%1"":
									|%2';
									|de = 'Die Varianten-Einstellungen für ""%1"" konnten nicht gelesen werden:
									|%2';
									|ro = 'Eșec la citirea setărilor variantei ""%1"":
									|%2';
									|tr = 'Seçenek ayarları okunamadı ""%1"":
									|%2'; 
									|es_ES = 'No se ha podido leer los ajustes de opción ""%1"":
									|%2'"), OptionDetails.VariantKey, DetailErrorDescription(ErrorInfo()));
							WriteToLog(EventLogLevel.Warning, ErrorText, ReportMetadata);
						EndTry;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
		
		If IsBlankString(ReportDetails.MainOption) Then
			OptionDetails = Result.Add();
			FillPropertyValues(OptionDetails, ReportDetails, "Report, Description");
			OptionDetails.VariantKey = "";
			OptionDetails.IsOption   = True;
			ReportDetails.MainOption = OptionDetails.VariantKey;
		EndIf;
		
		// Processing reports included in the AttachableReportsAndDataProcessors subsystem.
		If HasAttachableCommands AND AttachableReportsAndProcessorsComposition.Contains(ReportMetadata) Then
			VenderSettings = ModuleAttachableCommands.AttachableObjectSettings(ReportMetadata.FullName());
			If VenderSettings.DefineFormSettings Then
				ReportDetails.DefineFormSettings = True;
			EndIf;
			If VenderSettings.CustomizeReportOptions Then
				CustomizeReportInManagerModule(Result, ReportMetadata);
			EndIf;
		EndIf;
	EndDo;
	
	// Extension functionality.
	If ReportsType = Undefined Or ReportsType = "Internal" Then
		CustomizeReportInManagerModule(Result, Metadata.Reports.UniversalReport);
		SSLSubsystemsIntegration.OnSetUpReportsOptions(Result);
		ReportsOptionsOverridable.CustomizeReportsOptions(Result);
	EndIf;
	
	// Defining main report options.
	For Each ReportDetails In Result.FindRows(New Structure("IsOption", False)) Do
		
		If Not ReportDetails.GroupByReport Then
			ReportDetails.MainOption = "";
			Continue;
		EndIf;
		
		HasMainOption = Not IsBlankString(ReportDetails.MainOption);
		MainOptionEnabled = False;
		If HasMainOption Then
			Details = Result.FindRows(New Structure("Report,VariantKey,IsOption", 
				ReportDetails.Report, ReportDetails.MainOption, True))[0];
			MainOptionEnabled = Details.Enabled;
		EndIf;	
		
		If Not HasMainOption Or Not MainOptionEnabled Then
			For each OptionDetails In Result.FindRows(New Structure("Report", ReportDetails.Report)) Do
				If IsBlankString(OptionDetails.VariantKey) Then
					Continue;
				EndIf;
				FillOptionRowDetails(OptionDetails, ReportDetails);
				If OptionDetails.Enabled Then
					ReportDetails.MainOption = OptionDetails.VariantKey;
					OptionDetails.VisibleByDefault = True;
					Break;
				EndIf;
			EndDo;
		EndIf;

	EndDo;
	
	Return Result;
EndFunction

// Defines whether a report is attached to the report option storage.
Function ReportAttachedToStorage(ReportMetadata, AllAttachedByDefault = Undefined) Export
	StorageMetadata = ReportMetadata.VariantsStorage;
	If StorageMetadata = Undefined Then
		If AllAttachedByDefault = Undefined Then
			AllAttachedByDefault = ByDefaultAllConnectedToStorage();
		EndIf;
		ReportAttached = AllAttachedByDefault;
	Else
		ReportAttached = (StorageMetadata = Metadata.SettingsStorages.ReportsVariantsStorage);
	EndIf;
	Return ReportAttached;
EndFunction

// Defines whether a report is attached to the common report form.
Function ReportAttachedToMainForm(ReportMetadata, AllAttachedByDefault = Undefined) Export
	MetadataForm = ReportMetadata.DefaultForm;
	If MetadataForm = Undefined Then
		If AllAttachedByDefault = Undefined Then
			AllAttachedByDefault = ByDefaultAllConnectedToMainForm();
		EndIf;
		ReportAttached = AllAttachedByDefault;
	Else
		ReportAttached = (MetadataForm = Metadata.CommonForms.ReportForm);
	EndIf;
	Return ReportAttached;
EndFunction

// Defines whether a report is attached to the common report settings form.
Function ReportAttachedToSettingsForm(ReportMetadata, AllAttachedByDefault = Undefined) Export
	MetadataForm = ReportMetadata.DefaultSettingsForm;
	If MetadataForm = Undefined Then
		If AllAttachedByDefault = Undefined Then
			AllAttachedByDefault = ByDefaultAllConnectedToSettingsForm();
		EndIf;
		ReportAttached = AllAttachedByDefault;
	Else
		ReportAttached = (MetadataForm = Metadata.CommonForms.ReportSettingsForm);
	EndIf;
	Return ReportAttached;
EndFunction

// List of objects where report commands are used.
//
// Returns:
//   Array from MetadataObject - metadata objects with report commands.
//
Function ObjectsWithReportCommands() Export
	
	Result = New Array;
	SSLSubsystemsIntegration.OnDefineObjectsWithReportCommands(Result);
	ReportsOptionsOverridable.DefineObjectsWithReportCommands(Result);
	Return Result;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Configuration subsystems event handlers.

// See InfobaseUpdateSSL.OnAddUpdateHandlers. 
Procedure OnAddUpdateHandlers(Handlers) Export
	
	////////////////////////////////////////////////////////////////////////////////
	// 1. Updating shared data.
	
	Handler = Handlers.Add();
	Handler.HandlerManagement = True;
	Handler.SharedData     = True;
	Handler.ExecutionMode = "Seamless";
	Handler.Version          = "*";
	Handler.Procedure       = "ReportsOptions.ConfigurationCommonDataNonexclusiveUpdate";
	Handler.Priority       = 90;
	
	////////////////////////////////////////////////////////////////////////////////
	// 2. Updating separated data.
	
	// 2.1. Migrate separated data to version 2.1.1.0.
	Handler = Handlers.Add();
	Handler.ExecuteInMandatoryGroup = True;
	Handler.SharedData     = False;
	Handler.ExecutionMode = "Exclusive";
	Handler.Version          = "2.1.1.0";
	Handler.Priority       = 80;
	Handler.Procedure       = "ReportsOptions.GoToEdition21";
	
	// 2.2. Migrate separated data to version 2.1.3.6.
	Handler = Handlers.Add();
	Handler.ExecuteInMandatoryGroup = True;
	Handler.SharedData     = False;
	Handler.ExecutionMode = "Exclusive";
	Handler.Version          = "2.1.3.6";
	Handler.Priority       = 80;
	Handler.Procedure       = "ReportsOptions.FillPredefinedOptionsRefs";
	
	// 2.3. Update separated data in local mode.
	Handler = Handlers.Add();
	Handler.ExecuteInMandatoryGroup = True;
	Handler.SharedData     = False;
	Handler.ExecutionMode = "Seamless";
	Handler.Version          = "*";
	Handler.Priority       = 70;
	Handler.Procedure       = "ReportsOptions.ConfigurationSharedDataNonexclusiveUpdate";
	
	////////////////////////////////////////////////////////////////////////////////
	// 3. Deferred update.
	
	// 3.1. Adjustment to Taxi interface.
	Handler = Handlers.Add();
	Handler.ExecutionMode = "Deferred";
	Handler.ID   = New UUID("814d41ec-82e2-4d25-9334-8335e589fc1f");
	Handler.SharedData     = False;
	Handler.Version          = "2.2.3.31";
	Handler.Procedure       = "ReportsOptions.NarrowDownQuickSettings";
	Handler.Comment     = NStr("ru = 'Уменьшает количество быстрых настроек в пользовательских отчетах до 2 шт.'; en = 'Reduce the number of quick settings in custom reports to 2 settings.'; pl = 'Zmniejsza ilość szybkich ustawień w raportach użytkownika do 2 szt.';de = 'Reduziert die Anzahl der Schnelleinstellungen in benutzerdefinierten Berichten auf 2.';ro = 'Reduce cantitatea setărilor rapide în rapoartele utilizatorilor până la 2 unități.';tr = 'Özel raporlardaki hızlı ayar sayısını 2 adete kadar azaltır.'; es_ES = 'Disminuye la cantidad de los ajustes rápidos en los informes de usuario hasta 2 unidades.'");
	
	// 3.2. Fill in information to search for predefined report options.
	If SharedDataIndexingAllowed() Then
		Handler = Handlers.Add();
		If Common.DataSeparationEnabled() Then
			Handler.ExecutionMode = "Seamless";
			Handler.SharedData     = True;
		Else
			Handler.ExecutionMode = "Deferred";
			Handler.SharedData     = False; 
		EndIf;
		Handler.ID = New UUID("38d2a135-53e0-4c68-9bd6-3d6df9b9dcfb");
		Handler.Version        = "*";
		Handler.Procedure     = "ReportsOptions.UpdatePredefinedReportOptionsSearchIndex";
		Handler.Comment   = NStr("ru = 'Обновление индекса поиска отчетов, предусмотренных в программе.'; en = 'Update search index for predefined reports.'; pl = 'Aktualizacja indeksu wyszukiwania raportów, przewidzianych w programie.';de = 'Aktualisierung des Suchindexes der im Programm bereitgestellten Berichte.';ro = 'Actualizarea indexului de căutare a rapoartelor prevăzute în program.';tr = 'Program tarafından sağlanan rapor arama dizini güncelleme.'; es_ES = 'Actualización del índice de la búsqueda de los informes predeterminados en el programa.'");
	EndIf;
	
	// 3.3. Fill in information to search for user report options.
	Handler = Handlers.Add();
	Handler.ExecutionMode = "Deferred";
	Handler.SharedData     = False;
	Handler.ID   = New UUID("5ba93197-230b-4ac8-9abb-ab3662e5ff76");
	Handler.Version          = "*";
	Handler.Procedure       = "ReportsOptions.UpdateUserReportOptionsSearchIndex";
	Handler.Comment     = NStr("ru = 'Обновление индекса поиска отчетов, сохраненных пользователями.'; en = 'Update search index for custom reports.'; pl = 'Aktualizacja indeksu wyszukiwania raportów, zapisanych użytkownikiem.';de = 'Aktualisierung des Suchindexes für Berichte, die von Benutzern gespeichert wurden.';ro = 'Actualizarea indexului de căutare a rapoartelor salvate de utilizatori.';tr = 'Kullanıcılar tarafından kaydedilen rapor arama dizini güncelleme.'; es_ES = 'Actualización del índice de la búsqueda de los informes guardados por usuarios.'");
	
	// 3.4. Set the corresponding references to metadata object IDs in settings of universal report options.
	Handler = Handlers.Add();
	Handler.Version = "3.0.1.81";
	Handler.ID = New UUID("6cd3c6c1-6919-4e18-9725-eb6dbb841f4a");
	Handler.ExecutionMode = "Deferred";
	Handler.DeferredProcessingQueue = 1;
	Handler.UpdateDataFillingProcedure = "Catalogs.ReportsOptions.RegisterDataToProcessForMigrationToNewVersion";
	Handler.Procedure = "Catalogs.ReportsOptions.ProcessDataForMigrationToNewVersion";
	Handler.ObjectsToBeRead = "Catalog.ReportsOptions";
	Handler.ObjectsToChange = "Catalog.ReportsOptions";
	Handler.ObjectsToLock = "Catalog.ReportsOptions";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Comment = NStr("ru = 'Установка параметра ИсточникДанных в настройках вариантов универсального отчета.
		|После завершения обработки, переименование объектов метаданных не приведет к потере сохраненных вариантов отчетов'; 
		|en = 'Configuring DataSource parameter in universal report option settings.
		|Once completed, renaming of metadata objects will not result in report option loss.'; 
		|pl = 'Ustalenie DataSource parametru w ustawieniach wariantów raportu uniwersalnego.
		| Po zakończeniu przetwarzania, zmiana nazwy obiektów metadanych nie doprowadzi do utraty zapisanych wariantów raportów';
		|de = 'DataSource-Parameter in den Einstellungen der universellen Berichtsoption einstellen.
		|Nach Abschluss der Verarbeitung führt die Umbenennung von Metadatenobjekten nicht zum Verlust der gespeicherten Berichtsoptionen.';
		|ro = 'Setați parametrul DataSource în setările opțiunii rapoarte universale.
		|După finalizarea procesării, redenumirea obiectelor de metadate nu va duce la pierderea opțiunilor de raport salvate';
		|tr = 'Üniversal raporun seçeneklerinin ayarlarında DataSource parametresinin ayarı
		| İşleme tamamlandıktan sonra metaveri nesnelerin yeniden adlandırılması, kaydedilen raporların seçeneklerinin kaybına yol açmaz'; 
		|es_ES = 'Instalación del parámetro DataSource en los ajustes de las variantes del informe universal.
		|Al procesar, el cambio del nombre de los objetos de metadatos no llevará a la pérdida de las variantes guardadas del informe'");

EndProcedure

// See CommonOverridable.OnAddRefsSearchExceptions. 
Procedure OnAddReferenceSearchExceptions(RefSearchExclusions) Export
	
	RefSearchExclusions.Add(Metadata.Catalogs.ReportsOptions.TabularSections.Placement.Attributes.Subsystem);
	
EndProcedure

// See CommonOverridable.OnAddMetadataObjectsRenaming. 
Procedure OnAddMetadataObjectsRenaming(Total) Export
	
	Library = "StandardSubsystems";
	
	Common.AddRenaming(
		Total, "2.1.0.2", "Role.ReadReportOptions", "Role.ReportOptionsUsage", Library);
	Common.AddRenaming(
		Total, "2.3.3.3", "Role.ReportOptionsUsage", "Role.AddEditPersonalReportsOptions", Library);
	
EndProcedure

// See ExportImportDataOverridable.OnFillCommonDataTypesSupportingRefsMapOnImport. 
Procedure OnFillCommonDataTypesSupportingRefMappingOnExport(Types) Export
	
	Types.Add(Metadata.Catalogs.PredefinedReportsOptions);
	
EndProcedure

// See CommonOverridable.OnAddClientParametersOnStart. 
Procedure OnAddClientParametersOnStart(Parameters) Export
	Parameters.Insert("ReportsOptions", New FixedStructure(ClientParameters()));
EndProcedure

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport. 
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	
	Types.Add(Metadata.Catalogs.PredefinedExtensionsReportsOptions);
	Types.Add(Metadata.InformationRegisters.PredefinedExtensionsVersionsReportsOptions);
	
EndProcedure

// See ImportDataFromFileOverridable.OnDefineCatalogsForDataImport. 
Procedure OnDefineCatalogsForDataImport(CatalogsToImport) Export
	
	// Cannot import to the UserReportSettings catalog.
	TableRow = CatalogsToImport.Find(Metadata.Catalogs.UserReportSettings.FullName(), "FullName");
	If TableRow <> Undefined Then 
		CatalogsToImport.Delete(TableRow);
	EndIf;
	
EndProcedure

// See BatchObjectModificationOverridable.OnDetermineObjectsWithEditableAttributes. 
Procedure OnDefineObjectsWithEditableAttributes(Objects) Export
	Objects.Insert(Metadata.Catalogs.ReportsOptions.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.UserReportSettings.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.PredefinedReportsOptions.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.PredefinedExtensionsReportsOptions.FullName(), "AttributesToEditInBatchProcessing");
EndProcedure

// See UsersOverridable.OnDefineRolesAssignment. 
Procedure OnDefineRoleAssignment(RolesAssignment) Export
	
	// BothForUsersAndExternalUsers.
	RolesAssignment.BothForUsersAndExternalUsers.Add(
		Metadata.Roles.AddEditPersonalReportsOptions.Name);
	
EndProcedure

// See InformationRegisters.ExtensionsVersionsParameters.FillAllExtensionParameters. 
Procedure OnFillAllExtensionsParameters() Export
	
	Settings = SettingsUpdateParameters();
	Settings.Configuration = False;
	Settings.Extensions = True;
	Settings.SharedData = True;
	Settings.SeparatedData = True;
	Settings.Nonexclusive = True;
	Settings.Deferred = True;
	
	Refresh(Settings);
	
EndProcedure

// См. InformationRegisters.ExtensionsVersionsParameters.ClearAllExtensionParameters. 
Procedure OnClearAllExtemsionParameters() Export
	
	RecordSet = InformationRegisters.PredefinedExtensionsVersionsReportsOptions.CreateRecordSet();
	RecordSet.Filter.ExtensionsVersion.Set(SessionParameters.ExtensionsVersion);
	RecordSet.Write();
	
EndProcedure

// See AttachableCommandsOverridable.OnDefineAttachableObjectsSettingsComposition. 
Procedure OnDefineAttachableObjectsSettingsComposition(InterfaceSettings) Export
	Setting = InterfaceSettings.Add();
	Setting.Key          = "AddReportCommands";
	Setting.TypeDescription = New TypeDescription("Boolean");
	
	Setting = InterfaceSettings.Add();
	Setting.Key          = "CustomizeReportOptions";
	Setting.TypeDescription = New TypeDescription("Boolean");
	Setting.AttachableObjectsKinds = "REPORT";
	
	Setting = InterfaceSettings.Add();
	Setting.Key          = "DefineFormSettings";
	Setting.TypeDescription = New TypeDescription("Boolean");
	Setting.AttachableObjectsKinds = "REPORT";
EndProcedure

// See AttachableCommandsOverridable.OnDefineAttachableCommandsKinds. 
Procedure OnDefineAttachableCommandsKinds(AttachableCommandsKinds) Export
	Kind = AttachableCommandsKinds.Add();
	Kind.Name         = "Reports";
	Kind.SubmenuName  = "ReportsSubmenu";
	Kind.Title   = NStr("ru = 'Отчеты'; en = 'Reports'; pl = 'Sprawozdania';de = 'Berichte';ro = 'Rapoarte';tr = 'Raporlar'; es_ES = 'Informes'");
	Kind.Order     = 50;
	Kind.Picture    = PictureLib.Report;
	Kind.Representation = ButtonRepresentation.PictureAndText;
EndProcedure

// See AttachableCommandsOverridable.OnDefineCommandsAttachedToObject. 
Procedure OnDefineCommandsAttachedToObject(FormSettings, Sources, AttachedReportsAndDataProcessors, Commands) Export
	ReportsCommands = Commands.CopyColumns();
	ReportsCommands.Columns.Add("VariantKey", New TypeDescription("String, Null"));
	ReportsCommands.Columns.Add("Processed", New TypeDescription("Boolean"));
	ReportsCommands.Indexes.Add("Processed");
	
	StandardProcessing = Sources.Rows.Count() > 0;
	FormSettings.Insert("Sources", Sources);
	
	SSLSubsystemsIntegration.BeforeAddReportCommands(ReportsCommands, FormSettings, StandardProcessing);
	ReportsOptionsOverridable.BeforeAddReportCommands(ReportsCommands, FormSettings, StandardProcessing);
	ReportsCommands.FillValues(True, "Processed");
	If StandardProcessing Then
		ObjectsWithReportCommands = ObjectsWithReportCommands();
		For Each Source In Sources.Rows Do
			For Each DocumentRecorder In Source.Rows Do
				If ObjectsWithReportCommands.Find(DocumentRecorder.Metadata) <> Undefined Then
					OnAddReportsCommands(ReportsCommands, DocumentRecorder, FormSettings);
				EndIf;
			EndDo;
			If ObjectsWithReportCommands.Find(Source.Metadata) <> Undefined Then
				OnAddReportsCommands(ReportsCommands, Source, FormSettings);
			EndIf;
		EndDo;
	EndIf;
	
	FoundItems = AttachedReportsAndDataProcessors.FindRows(New Structure("AddReportCommands", True));
	For Each AttachedObject In FoundItems Do
		OnAddReportsCommands(ReportsCommands, AttachedObject, FormSettings);
	EndDo;
	
	KeyCommandParametersNames = "ID,Presentation,FunctionalOptions,Manager,FormName,VariantKey,
	|FormParameterName,FormParameters,Handler,AdditionalParameters,VisibilityInForms";
	
	AddedCommands = New Map;
	
	For Each ReportsCommand In ReportsCommands Do
		KeyParameters = New Structure(KeyCommandParametersNames);
		FillPropertyValues(KeyParameters, ReportsCommand);
		UUID = Common.CheckSumString(KeyParameters);
		
		FoundCommand = AddedCommands[UUID];
		If FoundCommand <> Undefined AND ValueIsFilled(FoundCommand.ParameterType) Then
			If ValueIsFilled(ReportsCommand.ParameterType) Then
				FoundCommand.ParameterType = New TypeDescription(FoundCommand.ParameterType, ReportsCommand.ParameterType.Types());
			Else
				FoundCommand.ParameterType = Undefined;
			EndIf;
			Continue;
		EndIf;
		
		Command = Commands.Add();
		AddedCommands.Insert(UUID, Command);
		
		FillPropertyValues(Command, ReportsCommand);
		Command.Kind = "Reports";
		If Command.Order = 0 Then
			Command.Order = 50;
		EndIf;
		If Command.WriteMode = "" Then
			Command.WriteMode = "WriteNewOnly";
		EndIf;
		If Command.MultipleChoice = Undefined Then
			Command.MultipleChoice = True;
		EndIf;
		If IsBlankString(Command.FormName) AND IsBlankString(Command.Handler) Then
			Command.FormName = "Form";
		EndIf;
		If Command.FormParameters = Undefined Then
			Command.FormParameters = New Structure;
		EndIf;
		Command.FormParameters.Insert("VariantKey", ReportsCommand.VariantKey);
		If IsBlankString(Command.Handler) Then
			Command.FormParameters.Insert("GenerateOnOpen", True);
			Command.FormParameters.Insert("ReportOptionsCommandsVisibility", False);
		EndIf;
	EndDo;
EndProcedure

// See AccessManagementOverridable.OnFillListsWithAccessRestriction. 
Procedure OnFillListsWithAccessRestriction(Lists) Export
	
	Lists.Insert(Metadata.Catalogs.ReportsOptions, True);
	Lists.Insert(Metadata.Catalogs.UserReportSettings, True);
	Lists.Insert(Metadata.InformationRegisters.ReportOptionsSettings, True);
	
EndProcedure

// See MonitoringCenterOverridable.OnCollectConfigurationStatisticsParameters. 
Procedure OnCollectConfigurationStatisticsParameters() Export
	
	If Not Common.SubsystemExists("StandardSubsystems.MonitoringCenter") Then
		Return;
	EndIf;
	
	ModuleMonitoringCenter = Common.CommonModule("MonitoringCenter");
	
	QueryText = 
	"SELECT
	|	COUNT(1) AS Count
	|FROM
	|	Catalog.ReportsOptions AS ReportsOptions
	|WHERE
	|	ReportsOptions.Custom";
	
	Query = New Query(QueryText);
	Selection = Query.Execute().Select();
	Selection.Next();
	
	ModuleMonitoringCenter.WriteConfigurationObjectStatistics("Catalog.ReportsOptions.Custom", Selection.Count());
	
EndProcedure

#EndRegion

#Region Private

// Subsystem presentation. It is used for writing to the event log and in other places.
Function SubsystemDescription(LanguageCode)
	Return NStr("ru = 'Варианты отчетов'; en = 'Report options'; pl = 'Opcje sprawozdania';de = 'Berichtsoptionen';ro = 'Variantele rapoartelor';tr = 'Rapor seçenekleri'; es_ES = 'Opciones de informe'", ?(LanguageCode = Undefined, Common.DefaultLanguageCode(), LanguageCode));
EndFunction

// Initializing reports.

// The function gets the report object from the report option reference.
//
// Parameters:
//   RefOfReport -
//     - CatalogRef.MetadataObjectIDs - a сonfiguration report reference.
//     - CatalogRef.ExtensionObjectIDs - an extension report reference.
//     - Arbitrary - a reference of an additional report or an external report.
//
// Returns:
//   Structure - report parameters including the report Object.
//       * Object      - ReportObject.<Report name>, ExternalReport - a report object.
//       * Name         - String           - a report object name.
//       * FullName   - String           - the full name of the report object.
//       * Metadata  - MetadataObject - a report metadata object.
//       * Ref      - Arbitrary     - a report reference.
//       * Success       - Boolean           - True if the report is attached.
//       * ErrorText - String           - an error text.
//
// Usage locations:
//   ReportDistribution.InitializeReport().
//
Function AttachReportObject(RefOfReport, GetMetadata)
	Result = New Structure("Object, Name, FullName, Metadata, Ref, ErrorText");
	Result.Insert("Success", False);
	
	If RefOfReport = Undefined Then
		Result.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'В методе ""%1"" не указан параметр ""%2"".'; en = 'Method %1 is missing parameter %2.'; pl = 'W metodzie ""%1"" nie wskazano parametru ""%2"".';de = 'Bei der Methode ""%1"" ist kein Parameter ""%2"" angegeben.';ro = 'În metoda ""%1"" nu este indicat parametrul ""%2"".';tr = '""%1"" yönteminde ""%2"" parametre belirtilmedi.'; es_ES = 'En el método ""%1"" no está indicado el parámetro ""%2"".'"),
			"AttachReportObject",
			"ReportRef");
		Return Result;
	Else
		Result.Ref = RefOfReport;
	EndIf;
	
	If TypeOf(Result.Ref) = Type("String") Then
		Result.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Отчет ""%1"" записан как внешний и не может быть подключен из программы'; en = 'Cannot attach report %1 from the application. Reason: the report is saved as external report.'; pl = 'Raport ""%1"" jest zapisany jako zewnętrzny i nie może być podłączony z aplikacji';de = 'Der Bericht ""%1"" ist als externer Bericht geschrieben und kann nicht von der Anwendung angehängt werden';ro = 'Raportul ""%1"" este scris ca fiind extern și nu poate fi atașat din aplicație';tr = '""%1"" raporu harici olarak yazılır ve uygulamadan bağlanamaz'; es_ES = 'La variante ""%1"" se ha guardado como externa y no puede conectarse desde el programa'"),
			Result.Ref);
		Return Result;
	EndIf;
	
	If TypeOf(Result.Ref) = Type("CatalogRef.MetadataObjectIDs")
	 Or TypeOf(Result.Ref) = Type("CatalogRef.ExtensionObjectIDs") Then
		
		Result.Metadata = Common.MetadataObjectByID(
			Result.Ref, False);
		
		If TypeOf(Result.Metadata) <> Type("MetadataObject") Then
			Result.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Отчет ""%1"" не найден в программе'; en = 'Cannot find report %1 in the application'; pl = 'Nie znaleziono raportu ""%1"" w programie';de = 'Bericht ""%1"" wird im Programm nicht gefunden';ro = 'Raportul ""%1"" nu a fost găsit în program';tr = '""%1"" raporu uygulamada bulunamadı'; es_ES = 'Informe ""%1"" no encontrado en el programa'"),
				Result.Name);
			Return Result;
		EndIf;
		Result.Name = Result.Metadata.Name;
		If Not AccessRight("Use", Result.Metadata) Then
			Result.ErrorText = NStr("ru = 'Недостаточно прав доступа'; en = 'Insufficient access rights'; pl = 'Brak praw dostępu!';de = 'Unzureichende Zugriffsrechte';ro = 'Drepturi de acces insuficiente';tr = 'Yetersiz erişim hakları.'; es_ES = 'Insuficientes derechos de acceso'");
			Return Result;
		EndIf;
		Try
			Result.Object = Reports[Result.Name].Create();
			Result.Success = True;
		Except
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Не удалось подключить отчет %1:'; en = 'Cannot attach report %1:'; pl = 'Nie można dołączyć raportu %1:';de = 'Der %1 Bericht kann nicht angehängt werden:';ro = 'Nu se poate atașa %1 raportul:';tr = '%1 raporu bağlanamadı: '; es_ES = 'No se ha podido conectar el informe %1:'"),
				Result.Metadata);
			ErrorText = ErrorText + Chars.LF + DetailErrorDescription(ErrorInfo());
			WriteToLog(EventLogLevel.Error, ErrorText, Result.Metadata);
		EndTry;
	Else
		If Common.SubsystemExists("StandardSubsystems.AdditionalReportsAndDataProcessors") Then
			ModuleAdditionalReportsAndDataProcessors = Common.CommonModule("AdditionalReportsAndDataProcessors");
			ModuleAdditionalReportsAndDataProcessors.OnAttachAdditionalReport(Result.Ref, Result, Result.Success, GetMetadata);
		EndIf;
	EndIf;
	
	If Result.Success AND GetMetadata Then
		Result.FullName = Result.Metadata.FullName();
	EndIf;
	
	Return Result;
EndFunction

// Data composition.

// Generates a report with the specified settings. Used in background jobs.
Procedure GenerateReportInBackground(Parameters, StorageAddress) Export
	Generation = GenerateReport(Parameters, False, False);
	
	Result = New Structure("SpreadsheetDocument, Details,
		|Success, ErrorText, DataStillUpdating,
		|VariantModified, UserSettingsModified");
	FillPropertyValues(Result, Generation);
	
	If Result.VariantModified Then
		Result.Insert("DCSettings", Generation.DCSettings);
	EndIf;
	If Result.UserSettingsModified Then
		Result.Insert("DCUserSettings", Generation.DCUserSettings);
	EndIf;
	
	PutToTempStorage(Result, StorageAddress);
EndProcedure

// Fills in settings details for a report option row if it is not filled in.
//
Procedure FillOptionRowDetails(OptionDetails, ReportDetails)
	If OptionDetails.DetailsReceived Then
		Return;
	EndIf;
	
	// Flag indicating whether the settings changed
	OptionDetails.DetailsReceived = True;
	
	// Copying report settings.
	FillPropertyValues(OptionDetails, ReportDetails, "Enabled, VisibleByDefault, GroupByReport");
	
	If OptionDetails.VariantKey = ReportDetails.MainOption Then
		// Default option.
		OptionDetails.Details = ReportDetails.Details;
		OptionDetails.VisibleByDefault = True;
	Else
		// Predefined option.
		If OptionDetails.GroupByReport Then
			OptionDetails.VisibleByDefault = False;
		EndIf;
	EndIf;
	
	OptionDetails.Placement = Common.CopyRecursive(ReportDetails.Placement);
	OptionDetails.FunctionalOptions = Common.CopyRecursive(ReportDetails.FunctionalOptions);
	OptionDetails.SearchSettings = Common.CopyRecursive(ReportDetails.SearchSettings);
	OptionDetails.MeasurementsKey = Common.TrimStringUsingChecksum("Report." + ReportDetails.Metadata.Name 
		+ "." + OptionDetails.VariantKey, 135);
	
EndProcedure

// Report panels.

// Generates a list of sections where the report panel calling commands are available.
//
// Returns:
//   ValueList - See description 1 of the ReportOptionsOverridable.DefineSectionsWithReportOptions() procedure parameter.
//
Function SectionsList() Export
	SectionsList = New ValueList;
	
	ReportsOptionsOverridable.DefineSectionsWithReportOptions(SectionsList);
	
	If Common.SubsystemExists("StandardSubsystems.ApplicationSettings") Then
		ModuleDataProcessorsControlPanelSSL = Common.CommonModule("DataProcessors.SSLAdministrationPanel");
		ModuleDataProcessorsControlPanelSSL.OnDefineSectionsWithReportOptions(SectionsList);
	EndIf;
	
	Return SectionsList;
EndFunction

// Sets output mode for report options in report panels.
//
// Parameters:
//   Settings - ValueTable - the parameter is passed as it is from the CustomizeReportsOptions procedure.
//   Report - ValueTableRow, MetadataObject: Report - settings details or report metadata.
//   GroupByReports - Boolean - the output mode in the report panel:
//       - True - by reports (options are hidden, and a report is enabled and visible).
//       - False - by options (options are visible; a report is disabled).
//
Procedure SetReportOutputModeInReportsPanels(Settings, Report, GroupByReports)
	If TypeOf(Report) = Type("ValueTableRow") Then
		ReportDetails = Report;
	Else
		ReportDetails = Settings.FindRows(New Structure("Metadata,IsOption", Report, False));
		If ReportDetails.Count() <> 1 Then
			WriteToLog(EventLogLevel.Warning, 
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Отчет ""%1"" не подключен к подсистеме.'; en = 'Report %1 is not attached to the subsystem.'; pl = 'Sprawozdanie ""%1"" nie jest połączone z podsystemem.';de = 'Der Bericht ""%1"" ist nicht an das Subsystem angehängt.';ro = 'Raportul ""%1"" nu este atașat la subsistem.';tr = 'Rapor ""%1"" alt sisteme bağlı değil.'; es_ES = 'Informe ""%1"" no se ha adjuntado al subsistema.'"), Report.Name));
			Return;
		EndIf;
		ReportDetails = ReportDetails[0];
	EndIf;
	ReportDetails.GroupByReport = GroupByReports;
EndProcedure

// Generates a table of replacements of old option keys for relevant ones.
//
// Returns:
//   ValueTable - Table of option name changes. Columns:
//       * ReportMetadata - MetadataObject: Report - metadata of the report whose schema contains the changed option name.
//       * OldOptionName - String - old option name before changes.
//       * RelevantOptionName - String - current (last relevant) option name.
//       * Report - CatalogRef.MetadataObjectIDs, String - a reference or a report name used for 
//           storage.
//
// See also:
//   ReportOptionsOverridable.RegisterChangesOfReportOptionsKeys().
//
Function KeysChanges()
	
	OptionsAttributes = Metadata.Catalogs.ReportsOptions.Attributes;
	
	Changes = New ValueTable;
	Changes.Columns.Add("Report",                 New TypeDescription("MetadataObject"));
	Changes.Columns.Add("OldOptionName",     OptionsAttributes.VariantKey.Type);
	Changes.Columns.Add("RelevantOptionName", OptionsAttributes.VariantKey.Type);
	
	// Overridable part.
	ReportsOptionsOverridable.RegisterChangesOfReportOptionsKeys(Changes);
	
	Changes.Columns.Report.Name = "ReportMetadata";
	Changes.Columns.Add("Report", OptionsAttributes.Report.Type);
	Changes.Indexes.Add("ReportMetadata, OldOptionName");
	
	// Check replacements for correctness.
	For Each Update In Changes Do
		Update.Report = Common.MetadataObjectID(Update.ReportMetadata);
		FoundItems = Changes.FindRows(New Structure("ReportMetadata, OldOptionName", Update.ReportMetadata, Update.RelevantOptionName));
		If FoundItems.Count() > 0 Then
			Conflict = FoundItems[0];
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Ошибка регистрации изменений имени варианта отчета ""%1"":
				|Актуальное имя варианта ""%2"" (старое имя ""%3"")
				|также числится как старое имя ""%4"" (актуальное имя ""%5"").'; 
				|en = 'Report option rename error. Report option: %1.
				|Previous name: %3. New name: %2.
				|The new name also registered as previous name %4 (current name %5).'; 
				|pl = 'Błąd rejestracji zmian imienia wariantu raportu ""%1"":
				|Aktualna nazwa wariantu ""%2"" (stara nazwa ""%3"")
				|także liczy się jako stara nazwa ""%4"" (aktualna nazwa ""%5"").';
				|de = 'Fehler bei der Registrierung des Namens der Berichtsvariante ""%1"":
				|Der aktuelle Name der Variante ""%2"" (alter Name ""%3"")
				| wird auch als alter Name ""%4"" (aktueller Name ""%5"") aufgeführt.';
				|ro = 'Eroare de înregistrare a modificărilor numelui variantei raportului ""%1"":
				|Numele actual al variantei ""%2"" (nume vechi ""%3"")
				|la fel este și nume vechi ""%4"" (nume actual ""%5"").';
				|tr = 'Rapor  seçeneği %1 adı 
				| olarak değiştirilirken bir hata oluştu
				|:  İlgili  seçenek %5 adı (eski adı %2"") da eski bir %3"" (güncel ad %4"") addır.'; 
				|es_ES = 'Ha ocurrido un error al registrar los cambios del nombre de la variante del informe ""%1"":
				|Nombre de la variante actual ""%2"" (nombre antiguo ""%3"")
				|es también un nombre antiguo ""%4"" (nombre actual ""%5"").'"),
				String(Update.Report),
				Update.RelevantOptionName,
				Update.OldOptionName,
				Conflict.OldOptionName,
				Conflict.RelevantOptionName);
		EndIf;
		FoundItems = Changes.FindRows(New Structure("ReportMetadata, OldOptionName", Update.ReportMetadata, Update.OldOptionName));
		If FoundItems.Count() > 2 Then
			Conflict = FoundItems[1];
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Ошибка регистрации изменений имени варианта отчета ""%1"":
				|Старое имя варианта ""%2"" (актуальное имя ""%3"")
				|также числится как старое имя 
				|варианта отчета ""%4"" (актуальное имя ""%5"").'; 
				|en = 'Report option rename error. Report option: %1.
				|Previous name: %2. New name: %3.
				|The previous name also registered as previous name %4
				| (current name %5).'; 
				|pl = 'Błąd rejestracji zmian imienia wariantu raportu ""%1"":
				|Stara nazwa wariantu ""%2"" (aktualna nazwa ""%3"")
				|także liczy się jako stara nazwa 
				|wariantu raportu ""%4"" (aktualna nazwa ""%5"").';
				|de = 'Fehler bei der Registrierung des Namens der Berichtsvariante ""%1"":
				|Der alte Name der Variante ""%2"" (aktueller Name ""%3"")
				|wird auch als alter Name 
				| der Berichtsvariante ""%4"" (aktueller Name ""%5"") aufgeführt.';
				|ro = 'Eroare de înregistrare a modificărilor numelui variantei raportului ""%1"":
				|Numele vechi al variantei ""%2"" (nume actual ""%3"")
				|la fel este și nume vechi 
				|al variantei raportului ""%4"" (nume actual ""%5"").';
				|tr = 'Rapor 
				|seçeneği adı ""%1"" değişikliği yazılırken bir hata oluştu: Eski seçenek adı ""%2"" 
				|(ilgili  ad ""%3""), 
				|eski raporun seçenek adı ""%4"" (güncel ad ""%5"") olarak listelendi.'; 
				|es_ES = 'Ha ocurrido un error al registrar el nombre de la variante del informe ""%1"":
				|Nombre de la variante antiguo ""%2"" (nombre actual ""%3"")
				|está en la lista como un nombre de 
				|la variante del informe antiguo ""%4"" (nombre relevante ""%5"").'"),
				String(Update.Report),
				Update.OldOptionName,
				Update.RelevantOptionName,
				String(Conflict.ReportMetadata.Presentation()),
				Conflict.RelevantOptionName);
		EndIf;
	EndDo;
	
	Return Changes;
EndFunction

// Generates a table of report placement by сonfiguration subsystems.
//
// Parameters:
//   Result          - Undefined - used for recursion.
//   SubsystemParent - Undefined - used for recursion.
//
// Returns:
//   Результат - ValueTable - Settings of report placement to subsystems.
//       * ReportMetadata      - MetadataObject: Report.
//       * ReportFullName       - String.
//       * SubsystemMetadata - MetadataObject: Subsystem.
//       * SubsystemFullName  - String.
//
Function PlacingReportsToSubsystems(Result = Undefined, ParentSubsystem = Undefined)
	If Result = Undefined Then
		FullNameTypesDetails = Metadata.Catalogs.MetadataObjectIDs.Attributes.FullName.Type;
		
		Result = New ValueTable;
		Result.Columns.Add("ReportMetadata",      New TypeDescription("MetadataObject"));
		Result.Columns.Add("ReportFullName",       FullNameTypesDetails);
		Result.Columns.Add("SubsystemMetadata", New TypeDescription("MetadataObject"));
		Result.Columns.Add("SubsystemFullName",  FullNameTypesDetails);
		
		Result.Indexes.Add("ReportFullName");
		Result.Indexes.Add("ReportMetadata");
		
		ParentSubsystem = Metadata;
	EndIf;
	
	// Iterating nested parent subsystems.
	For Each ChildSubsystem In ParentSubsystem.Subsystems Do
		
		If ChildSubsystem.IncludeInCommandInterface Then
			For Each ReportMetadata In ChildSubsystem.Content Do
				If Not Metadata.Reports.Contains(ReportMetadata) Then
					Continue;
				EndIf;
				
				TableRow = Result.Add();
				TableRow.ReportMetadata      = ReportMetadata;
				TableRow.ReportFullName       = ReportMetadata.FullName();
				TableRow.SubsystemMetadata = ChildSubsystem;
				TableRow.SubsystemFullName  = ChildSubsystem.FullName();
				
			EndDo;
		EndIf;
		
		PlacingReportsToSubsystems(Result, ChildSubsystem);
	EndDo;
	
	Return Result;
EndFunction

// Resetting the "Report options" predefined item settings connected to the "Report options" catalog 
//   item.
//
// Parameters:
//   OptionObject - CatalogObject.ReportOptions, FormDataStructure - a report option.
//
Function ResetReportOptionSettings(OptionObject) Export
	If OptionObject.Custom
		Or (OptionObject.ReportType <> Enums.ReportTypes.Internal
			AND OptionObject.ReportType <> Enums.ReportTypes.Extension)
		Or Not ValueIsFilled(OptionObject.PredefinedVariant) Then
		Return False;
	EndIf;
	
	OptionObject.Author = Undefined;
	OptionObject.AvailableToAuthorOnly = False;
	OptionObject.Details = "";
	OptionObject.Placement.Clear();
	OptionObject.DefaultVisibilityOverridden = False;
	Predefined = Common.ObjectAttributesValues(
		OptionObject.PredefinedVariant,
		"Description, VisibleByDefault");
	FillPropertyValues(OptionObject, Predefined);
	
	Return True;
EndFunction

// Generates description of the String types of the specified length.
Function TypesDetailsString(StringLength = 1000) Export
	Return New TypeDescription("String", , New StringQualifiers(StringLength));
EndFunction

// It defines full rights to subsystem data by role composition.
Function FullRightsToOptions() Export
	
	AccessParameters = AccessParameters("Update", Metadata.Catalogs.ReportsOptions, 
		Metadata.Catalogs.ReportsOptions.StandardAttributes.Ref.Name);
	Return AccessParameters.Accessibility AND Not AccessParameters.RestrictionByCondition;
	
EndFunction

// Checks whether a report option name is not occupied.
Function DescriptionIsUsed(Report, Ref, Description) Export
	If Description = Common.ObjectAttributeValue(Ref, "Description") Then
		Return False; // Check is disabled as the name did not change.
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	1 AS DescriptionIsUsed
	|FROM
	|	Catalog.ReportsOptions AS ReportsOptions
	|WHERE
	|	ReportsOptions.Report = &Report
	|	AND ReportsOptions.Ref <> &Ref
	|	AND ReportsOptions.Description = &Description
	|	AND ReportsOptions.DeletionMark = FALSE
	|	AND NOT ReportsOptions.PredefinedVariant IN (&DIsabledApplicationOptions)";
	Query.SetParameter("Report",        Report);
	Query.SetParameter("Ref",       Ref);
	Query.SetParameter("Description", Description);
	Query.SetParameter("DIsabledApplicationOptions", ReportsOptionsCached.DIsabledApplicationOptions());
	
	SetPrivilegedMode(True);
	Result = Not Query.Execute().IsEmpty();
	SetPrivilegedMode(False);
	
	Return Result;
EndFunction

// Checks whether a report option key is not occupied.
Function OptionKeyIsUsed(Report, Ref, OptionKey) Export
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	1 AS OptionKeyIsUsed
	|FROM
	|	Catalog.ReportsOptions AS ReportsOptions
	|WHERE
	|	ReportsOptions.Report = &Report
	|	AND ReportsOptions.Ref <> &Ref
	|	AND ReportsOptions.VariantKey = &VariantKey
	|	AND ReportsOptions.DeletionMark = FALSE";
	Query.SetParameter("Report",        Report);
	Query.SetParameter("Ref",       Ref);
	Query.SetParameter("VariantKey", OptionKey);
	
	SetPrivilegedMode(True);
	Result = Not Query.Execute().IsEmpty();
	SetPrivilegedMode(False);
	
	Return Result;
EndFunction

// Creates a filter by the ObjectKey attribute for StandardSettingsStorageManager.Select().
Function NewFilterByObjectKey(ReportsNames)
	If ReportsNames = "" Or ReportsNames = "*" Then
		Return Undefined;
	EndIf;
	
	SeparatorPosition = StrFind(ReportsNames, ",");
	If SeparatorPosition = 0 Then
		ObjectKey = ReportsNames;
		ReportsNames = "";
	Else
		ObjectKey = TrimAll(Left(ReportsNames, SeparatorPosition - 1));
		ReportsNames = Mid(ReportsNames, SeparatorPosition + 1);
	EndIf;
	
	If StrFind(ObjectKey, ".") = 0 Then
		ObjectKey = "Report." + ObjectKey;
	EndIf;
	
	Return New Structure("ObjectKey", ObjectKey);
EndFunction

// Global subsystem settings.
Function GlobalSettings() Export
	Result = New Structure;
	Result.Insert("OutputReportsInsteadOfOptions", False);
	Result.Insert("OutputDetails", True);
	Result.Insert("EditOptionsAllowed", True);
	Result.Insert("OutputGeneralHeaderOrFooterSettings", False);
	Result.Insert("OutputIndividualHeaderOrFooterSettings", False);
	
	Result.Insert("Search", New Structure);
	Result.Search.Insert("InputHint", NStr("ru = 'Наименование, поле или автор отчета'; en = 'Report description, field, or author'; pl = 'Nazwa, pole lub autor sprawozdania';de = 'Name, Feld oder Autor des Berichts';ro = 'Numele, câmpul sau autorul raportului';tr = 'Raporun adı, alanı veya yazarı'; es_ES = 'El nombre, el campo o el autor del informe'"));
	
	Result.Insert("OtherReports", New Structure);
	Result.OtherReports.Insert("CloseAfterChoice", True);
	Result.OtherReports.Insert("ShowCheckBox", False);
	
	ReportsOptionsOverridable.OnDefineSettings(Result);
	
	Return Result;
EndFunction

// Global settings of a report panel.
Function CommonPanelSettings() Export
	CommonSettings = Common.CommonSettingsStorageLoad(
		ReportsOptionsClientServer.FullSubsystemName(),
		"ReportPanel");
	If CommonSettings = Undefined Then
		CommonSettings = New Structure("ShowTooltips, SearchInAllSections, ShowTooltipsNotification");
		CommonSettings.ShowTooltipsNotification = False;
		CommonSettings.ShowTooltips           = GlobalSettings().OutputDetails;
		CommonSettings.SearchInAllSections          = False;
	Else
		// A feature can be considered new for a user only if a user has an understanding of what “old” 
		// features are (that is, if he has already worked with this form).
		If Not CommonSettings.Property("ShowTooltipsNotification") Then
			CommonSettings.Insert("ShowTooltipsNotification", True);
		EndIf;
	EndIf;
	Return CommonSettings;
EndFunction

// Global settings of a report panel.
Function SaveCommonPanelSettings(CommonSettings) Export
	If TypeOf(CommonSettings) <> Type("Structure") Then
		Return Undefined;
	EndIf;
	If CommonSettings.Count() < 3 Then
		CommonClientServer.SupplementStructure(CommonSettings, CommonPanelSettings(), False);
	EndIf;
	Common.CommonSettingsStorageSave(
		ReportsOptionsClientServer.FullSubsystemName(),
		"ReportPanel",
		CommonSettings);
	Return CommonSettings;
EndFunction

// Global client settings of a report.
Function ClientParameters() Export
	ClientParameters = New Structure;
	ClientParameters.Insert("RunMeasurements", RunMeasurements());
	If ClientParameters.RunMeasurements Then
		SetPrivilegedMode(True);
		ClientParameters.Insert("MeasurementsPrefix", StrReplace(SessionParameters["TimeMeasurementComment"], ";", "; "));
	EndIf;
	
	Return ClientParameters;
EndFunction

// Global client settings of a report.
Function RunMeasurements()
	If SafeMode() <> False Then
		Return False;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.PerformanceMonitor") Then
		ModulePerformanceMonitorServerCallCached = Common.CommonModule("PerformanceMonitorServerCallCached");
		If ModulePerformanceMonitorServerCallCached.RunPerformanceMeasurements() Then
			Return True;
		EndIf;
	EndIf;
	
	Return False;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Event log

// Record to the event log.
Procedure WriteToLog(Level, Message, ReportOption = Undefined) Export
	If TypeOf(ReportOption) = Type("MetadataObject") Then
		MetadataObject = ReportOption;
		Data = MetadataObject.Presentation();
	Else
		MetadataObject = Metadata.Catalogs.ReportsOptions;
		Data = ReportOption;
	EndIf;
	WriteLogEvent(SubsystemDescription(Undefined),
		Level, MetadataObject, Data, Message);
EndProcedure

// Writes a procedure start event to the event log.
Procedure WriteProcedureStartToLog(ProcedureName)
	
	EventLogOperations.AddMessageForEventLog(SubsystemDescription(Undefined),
		EventLogLevel.Information,,,
		StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Запуск процедуры ""%1"".'; en = 'Starting %1.'; pl = 'Rozpocząć procedurę ""%1"".';de = 'Starten Sie das ""%1"" Verfahren.';ro = 'Lansarea procedurii ""%1"".';tr = '""%1"" Prosedürünü başlatın.'; es_ES = 'Iniciar el procedimiento ""%1"".'"), ProcedureName)); 
		
EndProcedure

// Writes a procedure completion event to the event log.
Procedure WriteProcedureCompletionToLog(ProcedureName, ObjectsChanged = Undefined)
	
	Text = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Завершение процедуры ""%1"".'; en = 'Finishing %1.'; pl = 'Zakończyć procedurę ""%1"".';de = 'Beenden Sie das Verfahren ""%1"".';ro = 'Finalizați procedura ""%1"".';tr = '""%1"" prosedürün sonu.'; es_ES = 'Finalizar el procedimiento ""%1"".'"), ProcedureName);
	If ObjectsChanged <> Undefined Then
		Text = Text + " " 
			+ StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Изменено %1 объектов.'; en = '%1 objects have been modified.'; pl = 'Zmieniono %1 obiektów.';de = 'Geänderte %1 Objekte.';ro = 'Modificate %1 obiecte.';tr = '%1 nesne değiştirildi.'; es_ES = 'Cambiado %1 objetos.'"), ObjectsChanged);
	EndIf;
	EventLogOperations.AddMessageForEventLog(SubsystemDescription(Undefined),
		EventLogLevel.Information, , , Text);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Standard event handlers.

// Deleting personal report options upon user deletion.
Procedure OnRemoveUser(UserObject, Cancel) Export
	If UserObject.IsNew()
		Or UserObject.DataExchange.Load
		Or Cancel
		Or Not UserObject.DeletionMark Then
		Return;
	EndIf;
	
	// Set a deletion mark of personal user options.
	QueryText =
	"SELECT
	|	ReportsOptions.Ref
	|FROM
	|	Catalog.ReportsOptions AS ReportsOptions
	|WHERE
	|	ReportsOptions.Author = &UserRef
	|	AND ReportsOptions.DeletionMark = FALSE
	|	AND ReportsOptions.AvailableToAuthorOnly = TRUE";
	
	Query = New Query;
	Query.SetParameter("UserRef", UserObject.Ref);
	Query.Text = QueryText;
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		OptionObject = Selection.Ref.GetObject();
		OptionObject.AdditionalProperties.Insert("IndexSchema", False);
		OptionObject.SetDeletionMark(True);
	EndDo;
EndProcedure

// Delete subsystems references before their deletion.
Procedure BeforeDeleteMetadataObjectID(MetadataObjectIDObject, Cancel) Export
	If MetadataObjectIDObject.DataExchange.Load Then
		Return;
	EndIf;
	
	Subsystem = MetadataObjectIDObject.Ref;
	
	QueryText =
	"SELECT DISTINCT
	|	ReportsOptions.Ref
	|FROM
	|	Catalog.ReportsOptions AS ReportsOptions
	|WHERE
	|	ReportsOptions.Placement.Subsystem = &Subsystem";
	
	Query = New Query;
	Query.SetParameter("Subsystem", Subsystem);
	Query.Text = QueryText;
	
	OptionsToAssign = Query.Execute().Unload().UnloadColumn("Ref");
	
	BeginTransaction();
	Try
		Lock = New DataLock;
		For Each OptionRef In OptionsToAssign Do
			LockItem = Lock.Add(Metadata.Catalogs.ReportsOptions.FullName());
			LockItem.SetValue("Ref", OptionRef);
		EndDo;
		Lock.Lock();
		
		For Each OptionRef In OptionsToAssign Do
			OptionObject = OptionRef.GetObject();
			
			FoundItems = OptionObject.Placement.FindRows(New Structure("Subsystem", Subsystem));
			For Each TableRow In FoundItems Do
				OptionObject.Placement.Delete(TableRow);
			EndDo;
			
			OptionObject.Write();
		EndDo;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Updating an infobase.

// [*] Updates cache of сonfiguration metadata: the PredefinedReportOptions catalog and report 
//     option parameters in the register.
Procedure ConfigurationCommonDataNonexclusiveUpdate(UpdateParameters) Export
	
	Mode = "ConfigurationCommonData";
	StartPresentationsFilling(Mode, True);
	CommonDataNonexclusiveUpdate(Mode, UpdateParameters.SeparatedHandlers);
	
	SchedulePresentationsFilling();
	
EndProcedure

// [*] Updates data of the ReportsOptions catalog in some configuration reports.
Procedure ConfigurationSharedDataNonexclusiveUpdate() Export
	
	UpdateReportsOptions("SeparatedConfigurationData");
	
EndProcedure

Procedure UpdatePredefinedReportOptionsSearchIndex(Parameters = Undefined) Export
	
	UpdateSearchIndex("ConfigurationCommonData", True);
	
EndProcedure

Procedure UpdateUserReportOptionsSearchIndex(Parameters = Undefined) Export
	
	UpdateSearchIndex("SeparatedConfigurationData", True);
	
EndProcedure

// [2.1.1.1] Transfers data of the "Report options" catalog for revision 2.1.
Procedure GoToEdition21() Export
	ProcedurePresentation = NStr("ru = 'Перейти к редакции 2.1'; en = 'Migrate to edition 2.1'; pl = 'Przejdź do edycji 2.1';de = 'Zur Version 2.1 wechseln';ro = 'Salt la redacția 2.1';tr = '2.1.sürüme geç'; es_ES = 'Pasar a la redacción 2.1'");
	WriteProcedureStartToLog(ProcedurePresentation);
	
	QueryText =
	"SELECT DISTINCT
	|	ReportsOptions.Ref,
	|	ReportsOptions.DeleteObjectKey AS ReportFullName
	|FROM
	|	Catalog.ReportsOptions AS ReportsOptions
	|WHERE
	|	ReportsOptions.DeleteObjectKey <> """"";
	
	Query = New Query;
	Query.Text = QueryText;
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		// Generate report information.
		ReportInformation = GenerateReportInformationByFullName(Selection.ReportFullName);
		
		// Validate the result
		If TypeOf(ReportInformation.ErrorText) = Type("String") Then
			WriteToLog(EventLogLevel.Error, ReportInformation.ErrorText, Selection.Ref);
			Continue;
		EndIf;
		
		OptionObject = Selection.Ref.GetObject();
		
		If OptionObject.ReportType = Enums.ReportTypes.DeleteCustomReport
			Or OptionObject.ReportType = Enums.ReportTypes.External Then
			OptionObject.Custom = True;
		Else
			OptionObject.Custom = False;
		EndIf;
		
		OptionObject.Report = ReportInformation.Report;
		OptionObject.ReportType = ReportInformation.ReportType;
		
		If ReportInformation.ReportType = Enums.ReportTypes.External Then
			// Configuring external report option settings specific for all external report options.
			// All external report options are user options because predefined external report options are not 
			// registered in the application but are dynamically read each time.
			// 
			OptionObject.Custom = True;
			
			// External report options cannot be opened from the report panel.
			OptionObject.Placement.Clear();
			
		Else
			
			// Changing full subsystem names to references of the "Metadata object IDs" catalog.
			Edition21ArrangeSettingsBySections(OptionObject);
			
			// Transferring user settings from the tabular section to the information register.
			Edition21MoveUserSettingsToRegister(OptionObject);
			
		EndIf;
		
		// Options are supplied without an author.
		If Not OptionObject.Custom Then
			OptionObject.Author = Undefined;
		EndIf;
		
		OptionObject.DeleteObjectKey = "";
		OptionObject.DeleteObjectPresentation = "";
		OptionObject.DeleteQuickAccessExceptions.Clear();
		WritePredefinedObject(OptionObject);
	EndDo;
	
	WriteProcedureCompletionToLog(ProcedurePresentation);
EndProcedure

// [2.1.3.6] Fills in references of the predefined items of the "Report options" catalog.
Procedure FillPredefinedOptionsRefs() Export
	ProcedurePresentation = NStr("ru = 'Заполнить ссылки предопределенных вариантов отчетов'; en = 'Populate predefined report option references'; pl = 'Wypełnij linki predefiniowanych wariantów raportów';de = 'Füllen Sie Links zu vordefinierten Berichtsoptionen aus';ro = 'Completare referințele variantelor predefinite ale rapoartelor';tr = 'Önceden tanımlanan rapor seçeneklerin referanslarını doldur'; es_ES = 'Rellenar los enlaces de las variantes predeterminadas de los informes'");
	WriteProcedureStartToLog(ProcedurePresentation);
	
	// Generate a table of replacements of old option keys for relevant ones.
	Changes = KeysChanges();
	
	// Get report option references for key replacement. Exclude report options if their relevant keys 
	// are already registered or their old keys are not occupied.
	// 
	// 
	QueryText =
	"SELECT
	|	Changes.Report AS Report,
	|	Changes.OldOptionName AS OldOptionName,
	|	Changes.RelevantOptionName AS RelevantOptionName
	|INTO ttChanges
	|FROM
	|	&Changes AS Changes
	|
	|INDEX BY
	|	OldOptionName,
	|	RelevantOptionName
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	ReportsOptions.Ref AS ReportOption,
	|	CAST(ReportsOptions.Report AS Catalog.MetadataObjectIDs) AS ReportForKeysReplacement,
	|	ISNULL(ttChanges.RelevantOptionName, ReportsOptions.VariantKey) AS LatestOptionKey
	|INTO ttRelevant
	|FROM
	|	Catalog.ReportsOptions AS ReportsOptions
	|		LEFT JOIN ttChanges AS ttChanges
	|		ON ReportsOptions.Report = ttChanges.Report
	|			AND ReportsOptions.VariantKey = ttChanges.OldOptionName
	|WHERE
	|	ReportsOptions.Custom = FALSE
	|	AND ReportsOptions.ReportType = &ReportType
	|	AND ReportsOptions.DeletionMark = FALSE
	|	AND ReportsOptions.PredefinedVariant = &EmptyPredefined
	|
	|INDEX BY
	|	LatestOptionKey,
	|	ReportOption
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ttRelevant.ReportOption,
	|	PredefinedReportsOptions.Description,
	|	PredefinedReportsOptions.VariantKey,
	|	ISNULL(PredefinedReportsOptions.Ref, UNDEFINED) AS PredefinedVariant
	|FROM
	|	ttRelevant AS ttRelevant
	|		LEFT JOIN Catalog.PredefinedReportsOptions AS PredefinedReportsOptions
	|		ON ttRelevant.ReportForKeysReplacement = PredefinedReportsOptions.Report
	|			AND ttRelevant.LatestOptionKey = PredefinedReportsOptions.VariantKey";
	
	Query = New Query;
	Query.SetParameter("Changes", Changes);
	Query.SetParameter("ReportType", Enums.ReportTypes.Internal); // Extension support is not required.
	Query.SetParameter("EmptyPredefined", Catalogs.PredefinedReportsOptions.EmptyRef());
	Query.Text = QueryText;
	
	// Replace option names with references.
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		OptionObject = Selection.Ref.GetObject();
		OptionObject.AdditionalProperties.Insert("PredefinedObjectsFilling", True);
		OptionObject.AdditionalProperties.Insert("IndexSchema", False);
		If ValueIsFilled(Selection.PredefinedVariant) Then
			FillPropertyValues(OptionObject, Selection, "Description, VariantKey, PredefinedVariant");
			FoundItems = OptionObject.Placement.FindRows(New Structure("DeletePredefined", True));
			For Each TableRow In FoundItems Do
				OptionObject.Placement.Delete(TableRow);
			EndDo;
			OptionObject.Details = "";
			InfobaseUpdate.WriteObject(OptionObject);
		Else
			OptionObject.SetDeletionMark(True);
		EndIf;
	EndDo;
	
	WriteProcedureCompletionToLog(ProcedurePresentation);
	
EndProcedure

// [2.2.3.30] Reduces the number of quick settings in user report options to 2 pcs.
Procedure NarrowDownQuickSettings(IncomingParameters = Undefined) Export
	ProcedurePresentation = NStr("ru = 'Сокращение количества быстрых настроек в отчетах'; en = 'Reduce the number of report quick settings'; pl = 'Zmniejszenie ilości szybkich ustawień w raportach';de = 'Reduzierung der Anzahl der Schnelleinstellungen in Berichten';ro = 'Reducerea numărului de setări rapide în rapoarte';tr = 'Raporlarda hızlı ayar sayısını azalt'; es_ES = 'Disminución de la cantidad de los ajustes rápidos en los informes'");
	WriteProcedureStartToLog(ProcedurePresentation);
	
	// Reading information from a previous run with errors.
	Parameters = Common.CommonSettingsStorageLoad(
		ReportsOptionsClientServer.FullSubsystemName(),
		"NarrowDownQuickSettings");
	Query = New Query;
	If Parameters = Undefined Then
		Query.Text = "SELECT Ref, Report FROM Catalog.ReportsOptions WHERE Custom AND ReportType <> &External";
		Query.SetParameter("External", Enums.ReportTypes.External);
		AttemptNumber = 1;
	Else
		Query.Text = "SELECT Ref, Report FROM Catalog.ReportsOptions WHERE Ref IN (&OptionsWithErrors)";
		Query.SetParameter("OptionsWithErrors", Parameters.OptionsWithErrors);
		AttemptNumber = Parameters.AttemptNumber + 1;
	EndIf;
	ValueTable = Query.Execute().Unload();
	
	Written = 0;
	ErrorsCount = 0;
	AttachedReports = New Map;
	AllAttachedByDefault = Undefined;
	OptionsWithErrors = New Array;
	
	For Each TableRow In ValueTable Do
		ReportObject = AttachedReports.Get(TableRow.Report); 
		If ReportObject = Undefined Then 
			Attachment = AttachReportObject(TableRow.Report, True);
			If Attachment.Success Then
				ReportObject = Attachment.Object;
				ReportMetadata = Attachment.Metadata;
				If Not ReportAttachedToMainForm(ReportMetadata, AllAttachedByDefault) Then
					// Report is not attached to the common report form.
					// The number of quick settings must be reduced by an applied code.
					ReportObject = "";
				EndIf;
			Else // The report is not found.
				WriteToLog(EventLogLevel.Error, Attachment.ErrorText, TableRow.Ref);
				ReportObject = "";
			EndIf;
			AttachedReports.Insert(TableRow.Report, ReportObject);
		EndIf;
		If ReportObject = "" Then
			Continue;
		EndIf;
		
		OptionObject = TableRow.Ref.GetObject();
		
		ErrorInformation = Undefined;
		Try
			WritingRequired = ReduceQuickSettingsNumber(OptionObject, ReportObject);
		Except
			ErrorInformation = ErrorInfo();
			WritingRequired = False;
		EndTry;
		If ErrorInformation <> Undefined Then // An error occurred.
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Вариант ""%1"" отчета ""%2"":'; en = 'Option %1 of report %2:'; pl = 'Wariant ""%1"" raportu ""%2"":';de = 'Option ""%1"" des Berichts ""%2"":';ro = 'Varianta ""%1"" a raportului ""%2"":';tr = '""%1"" raporun ""%2"" seçeneği:'; es_ES = 'Variante ""%1"" del informe ""%2"":'")
				+ Chars.LF + NStr("ru = 'При уменьшении количества быстрых настроек пользовательского возникла ошибка:'; en = 'Error reducing number of quick settings:'; pl = 'Przy zmniejszeniu ilości szybkich ustawień użytkownika wystąpił błąd:';de = 'Bei der Reduzierung der Anzahl schneller benutzerdefinierter Einstellungen ist ein Fehler aufgetreten:';ro = 'La reducerea numărului de setări rapide de utilizator s-a produs eroarea:';tr = 'Hızlı kullanıcı ayarlarının sayısı azaltılırken bir hata oluştu:'; es_ES = 'Al disminuir la cantidad de los ajustes rápidos de usuarios ha ocurrido un error:'")
				+ Chars.LF + DetailErrorDescription(ErrorInformation),
				OptionObject.Ref, OptionObject.VariantKey, OptionObject.Report);
			WriteToLog(EventLogLevel.Error, ErrorText);
			OptionsWithErrors.Add(OptionObject.Ref);
			ErrorsCount = ErrorsCount + 1;
		EndIf;
		
		If WritingRequired Then
			OptionObject.AdditionalProperties.Insert("IndexSchema", False);
			OptionObject.AdditionalProperties.Insert("ReportObject", ReportObject);
			WritePredefinedObject(OptionObject);
			Written = Written + 1;
		EndIf;
	EndDo;
	
	If ErrorsCount > 0 Then
		// Writing information for the next run.
		Parameters = New Structure;
		Parameters.Insert("AttemptNumber", AttemptNumber);
		Parameters.Insert("OptionsWithErrors", OptionsWithErrors);
		
		Common.CommonSettingsStorageSave(
			ReportsOptionsClientServer.FullSubsystemName(),
			"NarrowDownQuickSettings",
			Parameters);
	ElsIf AttemptNumber > 1 Then
		// Deleting information from previous runs.
		Common.CommonSettingsStorageDelete(
			ReportsOptionsClientServer.FullSubsystemName(),
			"NarrowDownQuickSettings",
			UserName());
	EndIf;
	
	WriteProcedureCompletionToLog(ProcedurePresentation, Written);
	
	If ErrorsCount > 0 Then
		ErrorText = ProcedurePresentation + ":" + Chars.LF + StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось уменьшить количество быстрых настроек %1 отчетов.'; en = 'Failed to reduce the number of quick settings for %1 report(s).'; pl = 'Nie udało się zmniejszyć ilość szybkich ustawień %1 sprawozdań.';de = 'Die Anzahl der Schnelleinstellungen %1 für Berichte konnte nicht reduziert werden.';ro = 'Eșec la reducerea numărului de setări rapide ale setărilor %1 rapoartelor.';tr = 'Raporların hızlı ayarlarının sayısı azaltılamadı %1'; es_ES = 'No se ha podido disminuir la cantidad de los ajustes rápidos %1 de informes.'"), ErrorsCount);
		WriteLogEvent(SubsystemDescription(Undefined),
			EventLogLevel.Warning, , , ErrorText);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Updating an infobase / Initial filling and update of catalogs.

// Updates cache of сonfiguration metadata/applied extensions.
Function CommonDataNonexclusiveUpdate(Mode, SeparatedHandlers)
	
	////////////////////////////////////////////////////////////////////////////////
	// Only for predefined report options.
	
	Result = New Structure;
	Result.Insert("UpdateConfiguration",  Mode = "ConfigurationCommonData");
	Result.Insert("UpdateExtensions",    Mode = "ExtensionsCommonData");
	Result.Insert("SeparatedHandlers", SeparatedHandlers);
	Result.Insert("HasChanges",       False);
	Result.Insert("HasImportantChanges", False);
	Result.Insert("ReportsOptions", PredefinedReportsOptions(?(Result.UpdateConfiguration, "Internal", "Extension")));
	Result.Insert("UpdateMeasurements", Result.UpdateConfiguration AND Common.SubsystemExists("StandardSubsystems.PerformanceMonitor"));
	Result.Insert("MeasurementsTable",  MeasurementsTable());
	Result.Insert("SaaSModel",   Common.DataSeparationEnabled());
	
	UpdateKeysOfPredefinedItems(Mode, Result);
	MarkDeletedPredefinedItems(Mode, Result);
	GenerateOptionsFunctionalityTable(Mode, Result);
	MarkOptionsOfDeletedReportsForDeletion(Mode, Result);
	WriteFunctionalOptionsTable(Mode, Result);
	RecordCurrentExtensionsVersion();
	
	// Update separated data in SaaS mode.
	If Result.SaaSModel AND Result.HasImportantChanges Then
		Handlers = Result.SeparatedHandlers;
		If Handlers = Undefined Then
			Handlers = InfobaseUpdate.NewUpdateHandlerTable();
			Result.SeparatedHandlers = Handlers;
		EndIf;
		
		Handler = Handlers.Add();
		Handler.ExecutionMode = "Seamless";
		Handler.Version    = "*";
		Handler.Procedure = "ReportsOptions.ConfigurationSharedDataNonexclusiveUpdate";
		Handler.Priority = 70;
	EndIf;
	
	Return Result;
EndFunction

// Updates data of the ReportsOptions catalog.
Function UpdateReportsOptions(Mode)
	
	Result = New Structure;
	Result.Insert("HasChanges",       False);
	Result.Insert("HasImportantChanges", False);
	
	// 1. Update separated report options.
	UpdateReportsOptionsByPredefinedOnes(Mode, Result);

	// 2. Set a deletion mark for options of deleted reports.
	MarkOptionsOfDeletedReportsForDeletion(Mode, Result);
	
	Return Result;
	
EndFunction

// Update the search index of report options.
Function UpdateSearchIndex(Mode, IndexSchema)
	If Mode = "ConfigurationCommonData" AND Not SharedDataIndexingAllowed() Then
		Return Undefined;
	EndIf;
	
	StartPresentationsFilling(Mode, False);
	
	SharedData = (Mode = "ConfigurationCommonData" Or Mode = "ExtensionsCommonData");
	Clarification = Lower(ModePresentation(Mode)) + ", " + ?(IndexSchema, NStr("ru = 'полное'; en = 'full'; pl = 'pełne';de = 'vollständig';ro = 'complet';tr = 'tam'; es_ES = 'completo'"), NStr("ru = 'по изменениям'; en = 'by changes'; pl = 'według zmian';de = 'durch Änderung';ro = 'privind modificările';tr = 'değişikliklere göre'; es_ES = 'por cambios'"));
	
	ProcedurePresentation = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Обновление индекса поиска (%1)'; en = 'Updating search index (%1)'; pl = 'Aktualizacja indeksu wyszukiwania (%1)';de = 'Aktualisierung des Suchindex (%1)';ro = 'Actualizarea indexului de căutare (%1)';tr = 'Arama endeksinin yenilenmesi (%1)'; es_ES = 'Actualización del índice de la búsqueda (%1)'"), Clarification);
	WriteProcedureStartToLog(ProcedurePresentation);
	
	Query = New Query;
	
	If SharedData Then
		Search = New Structure("Report, VariantKey, IsOption", , , True);
		If Mode = "ConfigurationCommonData" Then
			PredefinedOptions = PredefinedReportsOptions("Internal");
			Query.Text =
			"SELECT
			|	PredefinedReportsOptions.Ref,
			|	PredefinedReportsOptions.Report
			|FROM
			|	Catalog.PredefinedReportsOptions AS PredefinedReportsOptions
			|WHERE
			|	PredefinedReportsOptions.DeletionMark = FALSE";
		ElsIf Mode = "ExtensionsCommonData" Then
			PredefinedOptions = PredefinedReportsOptions("Extension");
			Query.Text =
			"SELECT
			|	PredefinedExtensionsVersionsReportsOptions.Variant AS Ref,
			|	PredefinedExtensionsVersionsReportsOptions.Report
			|FROM
			|	InformationRegister.PredefinedExtensionsVersionsReportsOptions AS PredefinedExtensionsVersionsReportsOptions
			|WHERE
			|	PredefinedExtensionsVersionsReportsOptions.ExtensionsVersion = &ExtensionsVersion
			|	AND PredefinedExtensionsVersionsReportsOptions.Variant <> &EmptyRef";
			Query.SetParameter("ExtensionsVersion", SessionParameters.ExtensionsVersion);
			Query.SetParameter("EmptyRef", Catalogs.PredefinedExtensionsReportsOptions.EmptyRef());
		EndIf;
	Else
		Query.Text =
		"SELECT
		|	ReportsOptions.Ref,
		|	ReportsOptions.Report
		|FROM
		|	Catalog.ReportsOptions AS ReportsOptions
		|WHERE
		|	ReportsOptions.Custom
		|	AND ReportsOptions.ReportType = &ReportType
		|	AND ReportsOptions.Report IN(&AvailableReports)";
		Query.SetParameter("AvailableReports", New Array(ReportsOptionsCached.AvailableReports(False)));
		If Mode = "SeparatedConfigurationData" Then
			Query.SetParameter("ReportType", Enums.ReportTypes.Internal);
		ElsIf Mode = "SeparatedExtensionData" Then
			Query.SetParameter("ReportType", Enums.ReportTypes.Extension);
		EndIf;
	EndIf;
	
	ReportsWithIssues = New Map;
	NewInfo = New Map;
	PreviousInfo = New Structure("SettingsHash, FieldDescriptions, FilterParameterDescriptions, Keywords");
	
	ErrorsList = New Array;
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		If ReportsWithIssues[Selection.Report] = True Then
			Continue; // Report is not attached. Error was registered earlier.
		EndIf;
		
		BeginTransaction();
		Try
			Lock = New DataLock;
			LockItem = Lock.Add("Catalog.ReportsOptions");
			LockItem.SetValue("Ref", Selection.Ref);
			OptionObject = Selection.Ref.GetObject();
			If OptionObject = Undefined Then
				RollbackTransaction();
				Continue;
			EndIf;
			
			ReportInfo = NewInfo[Selection.Report];
			If ReportInfo = Undefined Then
				ReportInfo = New Structure("DCSettings,SearchSettings,ReportObject,IndexSchema");
				NewInfo[Selection.Report] = ReportInfo;
			EndIf;	
			
			If SharedData Then
				FillPropertyValues(Search, OptionObject, "Report, VariantKey");
				FoundItems = PredefinedOptions.FindRows(Search);
				If FoundItems.Count() = 0 Then
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Вариант ""%1"" не найден для отчета ""%2""'; en = 'Cannot find option %1 for report %2.'; pl = 'Dla sprawozdania ""%2"" nie znaleziono wariantu ""%1""';de = 'Option ""%1"" wurde für Bericht ""%2"" nicht gefunden ';ro = 'Opțiunea ""%1"" nu a fost găsită pentru raportul ""%2""';tr = '""%1"" rapor için ""%2"" seçeneği bulunamadı.'; es_ES = 'Opción ""%1"" no se ha encontrado para el informe ""%2""'"), 
						OptionObject.VariantKey, OptionObject.Report);
					WriteToLog(EventLogLevel.Error, ErrorText, OptionObject.Ref);
					RollbackTransaction();
					Continue; // An error occurred.
				EndIf;
				
				OptionDetails = FoundItems[0];
				FillOptionRowDetails(OptionDetails, PredefinedOptions.FindRows(
					New Structure("Report,IsOption", OptionObject.Report, False))[0]);
				
				// If an option is disabled, it cannot be searched for.
				If Not OptionDetails.Enabled Then
					RollbackTransaction();
					Continue; // Filling is not required.
				EndIf;
				
				ReportInfo.DCSettings = CommonClientServer.StructureProperty(OptionDetails.SystemInfo, "DCSettings");
				ReportInfo.SearchSettings = OptionDetails.SearchSettings;
			EndIf;
			
			FillPropertyValues(PreviousInfo, FieldsForSearch(OptionObject));
			PreviousInfo.SettingsHash = OptionObject.SettingsHash;
			ReportInfo.IndexSchema = IndexSchema; // Reindexe forcedly, without checking the hash.
			
			Try
				SchemaIndexed = FillFieldsForSearch(OptionObject, ReportInfo);
			Except
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Не удалось перестроить индекс поиска для варианта ""%1"" отчета ""%2"". Возможно, отчет неисправен.'; en = 'Cannot rebuild the search index for option %1, report%2. The report might be corrupted.'; pl = 'Nie udało się przebudować indeks wyszukiwania dla wariantu ""%1"" raportu ""%2"". Możliwe, że raport jest uszkodzony.';de = 'Es war nicht möglich, den Suchindex für die Option ""%1"" des Berichts ""%2"" umzustellen. Möglicherweise ist der Bericht fehlerhaft.';ro = 'Eșec la restructurarea indexului de căutare pentru varianta ""%1"" raportului ""%2"". Posibil, raportul este defect.';tr = '""%1"" raporun ""%2"" seçeneği için arama endeksi yeniden yapılandırılamadı. Rapor arızalı olabilir.'; es_ES = 'No se ha podido reconstruir el índice de la búsqueda para la variante ""%1"" del informe ""%2"". Es posible que el informe esté dañado.'"), 
					OptionObject.VariantKey, OptionObject.Report);
				WriteToLog(EventLogLevel.Error, ErrorText + Chars.LF 
					+ DetailErrorDescription(ErrorInfo()), OptionObject.Ref);
				ErrorsList.Add(ErrorText);
				RollbackTransaction();
				Continue;
			EndTry;
			
			If SchemaIndexed AND SearchSettingsChanged(OptionObject, PreviousInfo) Then
				If SharedData Then
					WritePredefinedObject(OptionObject);
				Else
					InfobaseUpdate.WriteObject(OptionObject);
				EndIf;
			EndIf;
			
			If ReportInfo.ReportObject = Undefined Then
				ReportsWithIssues[Selection.Report] = True; // The report was not attached
			EndIf;
			
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;	
	EndDo;
	SetPresentationsFillingFlag(True, False, Mode);
	
	WriteProcedureCompletionToLog(ProcedurePresentation);
	
	Return Undefined;
EndFunction

// Replacing obsolete report option keys with relevant ones.
Procedure UpdateKeysOfPredefinedItems(Mode, Result)
	
	ProcedurePresentation = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Обновление ключей вариантов отчетов (%1)'; en = 'Updating report option keys (%1)'; pl = 'Aktualizacja kluczy wariantów sprawozdań (%1)';de = 'Berichtsoptionsschlüssel aktualisieren (%1)';ro = 'Actualizarea cheilor variantelor de rapoarte (%1)';tr = 'Rapor seçeneklerinin anahtarlarının güncellenmesi (%1)'; es_ES = 'Actualización de las claves de variantes de los informes (%1)'"), 
		?(Mode = "ConfigurationCommonData", NStr("ru = 'метаданные конфигурации'; en = 'configuration metadata'; pl = 'metadane konfiguracji';de = 'Konfigurations-Metadaten';ro = 'metadatele configurației';tr = 'yapılandırmanın meta verileri'; es_ES = 'metadatos de configuración'"), NStr("ru = 'метаданные расширений'; en = 'extension metadata'; pl = 'metadane rozszerzeń';de = 'Erweiterungs-Metadaten';ro = 'metadatele extensiilor';tr = 'uzantıların metaverileri'; es_ES = 'metadatos de extensiones'")));
	WriteProcedureStartToLog(ProcedurePresentation);
	
	// Generate a table of replacements of old option keys for relevant ones.
	Changes = KeysChanges();
	
	// Get report option references for key replacement. Exclude report options if their relevant keys 
	// are already registered or their old keys are not occupied.
	// 
	// 
	QueryText =
	"SELECT
	|	Changes.Report,
	|	Changes.OldOptionName,
	|	Changes.RelevantOptionName
	|INTO ttChanges
	|FROM
	|	&Changes AS Changes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	ttChanges.Report,
	|	ttChanges.RelevantOptionName,
	|	ReportOptionsOld.Ref
	|FROM
	|	ttChanges AS ttChanges
	|		LEFT JOIN Catalog.PredefinedReportsOptions AS ReportOptionsLatest
	|		ON ttChanges.Report = ReportOptionsLatest.Report
	|			AND ttChanges.RelevantOptionName = ReportOptionsLatest.VariantKey
	|		LEFT JOIN Catalog.PredefinedReportsOptions AS ReportOptionsOld
	|		ON ttChanges.Report = ReportOptionsOld.Report
	|			AND ttChanges.OldOptionName = ReportOptionsOld.VariantKey
	|WHERE
	|	ReportOptionsLatest.Ref IS NULL 
	|	AND NOT ReportOptionsOld.Ref IS NULL ";
	
	If Mode = "ExtensionsCommonData" Then
		QueryText = StrReplace(QueryText, ".PredefinedReportsOptions", ".PredefinedExtensionsReportsOptions");
		CatalogName = "Catalog.PredefinedExtensionsReportsOptions";
	Else	
		CatalogName = "Catalog.PredefinedReportsOptions";
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Changes", Changes);
	Query.Text = QueryText;
	
	// Replace obsolete option names with relevant ones.
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Result.HasChanges = True;
		Result.HasImportantChanges = True;
		
		BeginTransaction();
		Try
			Lock = New DataLock;
			LockItem = Lock.Add(CatalogName);
			LockItem.SetValue("Ref", Selection.Ref);
			Lock.Lock();
			
			OptionObject = Selection.Ref.GetObject();
			OptionObject.VariantKey = Selection.RelevantOptionName;
			WritePredefinedObject(OptionObject);
			
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	EndDo;
	
	WriteProcedureCompletionToLog(ProcedurePresentation);
EndProcedure

Procedure MarkDeletedPredefinedItems(Mode, Result)
	
	ProcedurePresentation = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Обновление настроек предопределенных (%1)'; en = 'Updating predefined settings (%1)'; pl = 'Aktualizacja ustawień predefiniowanych (%1)';de = 'Vordefinierte Einstellungen aktualisieren (%1)';ro = 'Actualizarea setărilor celor predefinite (%1)';tr = 'Önceden tanımlanan ayarlarının güncellenmesi (%1)'; es_ES = 'Actualización de los ajustes predeterminados (%1)'"), 
		?(Mode = "ConfigurationCommonData", NStr("ru = 'метаданные конфигурации'; en = 'configuration metadata'; pl = 'metadane konfiguracji';de = 'Konfigurations-Metadaten';ro = 'metadatele configurației';tr = 'yapılandırmanın meta verileri'; es_ES = 'metadatos de configuración'"), NStr("ru = 'метаданные расширений'; en = 'extension metadata'; pl = 'metadane rozszerzeń';de = 'Erweiterungs-Metadaten';ro = 'metadatele extensiilor';tr = 'uzantıların metaverileri'; es_ES = 'metadatos de extensiones'")));
	WriteProcedureStartToLog(ProcedurePresentation);
	
	OptionsAttributes = Metadata.Catalogs.ReportsOptions.Attributes;
	
	If Mode = "ConfigurationCommonData" Then
		QueryText = "SELECT * FROM Catalog.PredefinedReportsOptions ORDER BY DeletionMark";
		EmptyRef = Catalogs.PredefinedReportsOptions.EmptyRef();
		TableName = "Catalog.PredefinedReportsOptions";
	ElsIf Mode = "ExtensionsCommonData" Then
		QueryText = "SELECT * FROM Catalog.PredefinedExtensionsReportsOptions ORDER BY DeletionMark";
		EmptyRef = Catalogs.PredefinedExtensionsReportsOptions.EmptyRef();
		TableName = "Catalog.PredefinedExtensionsReportsOptions";
	EndIf;
	
	// Mapping information from database and metadata and marking obsolete object from the base for deletion.
	Result.ReportsOptions.Indexes.Add("Report, VariantKey, FoundInDatabase, IsOption");
	SearchForOption = New Structure("Report, VariantKey, FoundInDatabase, IsOption");
	SearchForOption.FoundInDatabase = False;
	SearchForOption.IsOption        = True;
	
	Query = New Query(QueryText);
	PredefinedReportsOptions = Query.Execute().Unload();
	
	For Each OptionFromBase In PredefinedReportsOptions Do
		
		FillPropertyValues(SearchForOption, OptionFromBase, "Report, VariantKey");
		FoundItems = Result.ReportsOptions.FindRows(SearchForOption);
		If FoundItems.Count() > 0 Then
			OptionDetails = FoundItems[0];
			ReportDetails = Result.ReportsOptions.FindRows(New Structure("Report, IsOption", OptionFromBase.Report, False))[0];
			FillOptionRowDetails(OptionDetails, ReportDetails);
			OptionDetails.FoundInDatabase = True;
			OptionDetails.OptionFromBase = OptionFromBase;
			Continue;
		EndIf;
		
		If OptionFromBase.DeletionMark AND OptionFromBase.Parent = EmptyRef Then
			Continue; // No action required.
		EndIf;
		
		BeginTransaction();
		Try
			Lock = New DataLock;
			LockItem = Lock.Add(TableName);
			LockItem.SetValue("Ref", OptionFromBase.Ref);
			Lock.Lock();
			
			OptionObject = OptionFromBase.Ref.GetObject();
			If OptionObject = Undefined Then
				RollbackTransaction();
				Continue;
			EndIf;
				
			OptionObject.DeletionMark = True;
			OptionObject.Parent = EmptyRef;
			WritePredefinedObject(OptionObject);
			
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
		
		Result.HasChanges = True;
		Result.HasImportantChanges = True;
		
	EndDo;
	
	WriteProcedureCompletionToLog(ProcedurePresentation);
EndProcedure

Procedure GenerateOptionsFunctionalityTable(Mode, Result)
	
	OptionsAttributes = Metadata.Catalogs.ReportsOptions.Attributes;
	
	If Mode = "ConfigurationCommonData" Then
		EmptyRef = Catalogs.PredefinedReportsOptions.EmptyRef();
	ElsIf Mode = "ExtensionsCommonData" Then
		EmptyRef = Catalogs.PredefinedExtensionsReportsOptions.EmptyRef();
	EndIf;
	
	FunctionalOptionsTable = New ValueTable;
	FunctionalOptionsTable.Columns.Add("Report",                   OptionsAttributes.Report.Type);
	FunctionalOptionsTable.Columns.Add("PredefinedVariant", OptionsAttributes.PredefinedVariant.Type);
	FunctionalOptionsTable.Columns.Add("FunctionalOptionName",  New TypeDescription("String"));
	
	Result.Insert("FunctionalOptionsTable", FunctionalOptionsTable);
	
	ReportsWithSettingsList = New ValueList;
	Result.Insert("ReportsWithSettingsList", ReportsWithSettingsList);
	
	MainOptions = New Map;
	For Each OptionDetails In Result.ReportsOptions Do
		
		If Not OptionDetails.IsOption Then
			If OptionDetails.DefineFormSettings Then
				ReportsWithSettingsList.Add(OptionDetails.Report);
			EndIf;
			Continue;
		EndIf;
		
		// Set the ParentOption attribute to relate report options to main report options.
		ReportDetails = Result.ReportsOptions.FindRows(New Structure("Report, IsOption", OptionDetails.Report, False))[0];
		FillOptionRowDetails(OptionDetails, ReportDetails);
		If IsBlankString(ReportDetails.MainOption) Or OptionDetails.VariantKey = ReportDetails.MainOption Then
			MainOptionKey = OptionDetails.Report.FullName + "." + OptionDetails.VariantKey;
			OptionRef = MainOptions[MainOptionKey];
			If OptionRef = Undefined Then
				OptionDetails.ParentOption = EmptyRef;
				OptionRef = UpdatePredefinedReportOption(Mode, OptionDetails, Result); 
				MainOptions[MainOptionKey] = OptionRef;
			EndIf
		Else
			MainOption = Result.ReportsOptions.FindRows(
				New Structure("Report, VariantKey", OptionDetails.Report, ReportDetails.MainOption))[0];
			MainOptionKey = MainOption.Report.FullName + "." + MainOption.VariantKey;
			MainOptionRef = MainOptions[MainOptionKey];
			If MainOptionRef = Undefined Then
				MainOption.ParentOption = EmptyRef;
				MainOptionRef = UpdatePredefinedReportOption(Mode, MainOption, Result); 
				MainOptions[MainOptionKey] = MainOptionRef;
			EndIf;	
			OptionDetails.ParentOption = MainOptionRef;
			OptionRef = UpdatePredefinedReportOption(Mode, OptionDetails, Result);
		EndIf;
		
		For Each FunctionalOptionName In OptionDetails.FunctionalOptions Do
			LinkWithFunctionalOption = FunctionalOptionsTable.Add();
			LinkWithFunctionalOption.Report                   = OptionDetails.Report;
			LinkWithFunctionalOption.PredefinedVariant = OptionRef;
			LinkWithFunctionalOption.FunctionalOptionName  = FunctionalOptionName;
		EndDo;
		
	EndDo;

EndProcedure

// Writes option settings to catalog data.
Function UpdatePredefinedReportOption(Mode, OptionDetails, Result)
	
	BeginTransaction();
	Try
		OptionFromBase = OptionDetails.OptionFromBase;
		If Result.UpdateMeasurements Then
			varKey = ?(OptionDetails.FoundInDatabase, OptionFromBase.MeasurementsKey, "");
			RegisterOptionMeasurementsForUpdate(varKey, OptionDetails.MeasurementsKey, OptionDetails.Description, Result);
		EndIf;
		If OptionDetails.FoundInDatabase Then
			If OptionFromBase.DeletionMark = True // Details are got => clear deletion mark
				Or KeySettingsOfPredefinedItemChanged(OptionDetails, OptionFromBase) Then
				Result.HasImportantChanges = True; // Rewriting key settings (rewriting separated data is required).
			ElsIf Not SecondarySettingsOfPredefinedItemChanged(OptionDetails, OptionFromBase) Then
				RollbackTransaction();
				Return OptionFromBase.Ref;
			EndIf;
			
			If Mode = "ConfigurationCommonData" Then
				TableName = "Catalog.PredefinedReportsOptions";
			ElsIf Mode = "ExtensionsCommonData" Then
				TableName = "Catalog.PredefinedExtensionsReportsOptions";
			EndIf;
			Lock = New DataLock;
			LockItem = Lock.Add(TableName);
			LockItem.SetValue("Ref", OptionDetails.OptionFromBase.Ref);
			Lock.Lock();
			
			OptionObject = OptionDetails.OptionFromBase.Ref.GetObject();
			OptionObject.Placement.Clear();
			If OptionObject.DeletionMark Then
				OptionObject.DeletionMark = False;
			EndIf;
		Else
			Result.HasImportantChanges = True; // Registering a new object (separated data update is required).
			If Mode = "ConfigurationCommonData" Then
				OptionObject = Catalogs.PredefinedReportsOptions.CreateItem();
			ElsIf Mode = "ExtensionsCommonData" Then
				OptionObject = Catalogs.PredefinedExtensionsReportsOptions.CreateItem();
			EndIf;
		EndIf;
		
		FillPropertyValues(OptionObject, OptionDetails, 
			"Report, VariantKey, Enabled, VisibleByDefault, GroupByReport");
		FieldsForSearch = FieldsForSearch(OptionObject);
		FieldsForSearch.Description = OptionDetails.Description;
		FieldsForSearch.Details = OptionDetails.Details;
		SetFieldsForSearch(OptionObject, FieldsForSearch);
		
		OptionObject.Parent = OptionDetails.ParentOption;
		
		OptionPlacement = New Array;
		For Each Section In OptionDetails.Placement Do
			FullName = ?(TypeOf(Section.Key) = Type("String"), Section.Key, Section.Key.FullName());
			OptionPlacement.Add(FullName);
		EndDo;
		SubsystemsIDs = Common.MetadataObjectIDs(OptionPlacement);
		For Each ReportPlacement In OptionDetails.Placement Do
			AssignmentRow = OptionObject.Placement.Add();
			FullName = ?(TypeOf(ReportPlacement.Key) = Type("String"), ReportPlacement.Key, ReportPlacement.Key.FullName());
			AssignmentRow.Subsystem = SubsystemsIDs[FullName];
			AssignmentRow.Important  = (Lower(ReportPlacement.Value) = Lower("Important"));
			AssignmentRow.SeeAlso = (Lower(ReportPlacement.Value) = Lower("SeeAlso"));
		EndDo;
		
		If Result.UpdateMeasurements Then
			OptionObject.MeasurementsKey = OptionDetails.MeasurementsKey;
		EndIf;
		
		Result.HasChanges = True;
		WritePredefinedObject(OptionObject);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Return OptionObject.Ref;
EndFunction

// Defines whether key settings of a predefined report option are changed.
Function KeySettingsOfPredefinedItemChanged(OptionDetails, OptionFromBase)
	Return (OptionFromBase.Description <> OptionDetails.Description
		Or OptionFromBase.Parent <> OptionDetails.ParentOption
		Or OptionFromBase.VisibleByDefault <> OptionDetails.VisibleByDefault);
EndFunction

// Defines whether secondary settings of a predefined report option are changed.
Function SecondarySettingsOfPredefinedItemChanged(OptionDetails, OptionFromBase)
	// Header
	If OptionFromBase.Enabled <> OptionDetails.Enabled
		Or OptionFromBase.Details <> OptionDetails.Details
		Or OptionFromBase.MeasurementsKey <> OptionDetails.MeasurementsKey
		Or OptionFromBase.GroupByReport <> OptionDetails.GroupByReport Then
		Return True;
	EndIf;
	
	// Placement table
	PlacementTable = OptionFromBase.Placement;
	If PlacementTable.Count() <> OptionDetails.Placement.Count() Then
		Return True;
	EndIf;
	
	For Each KeyAndValue In OptionDetails.Placement Do
		Subsystem = Common.MetadataObjectID(KeyAndValue.Key);
		If TypeOf(Subsystem) = Type("String") Then
			Continue;
		EndIf;
		AssignmentRow = PlacementTable.Find(Subsystem, "Subsystem");
		If AssignmentRow = Undefined
			Or AssignmentRow.Important <> (Lower(KeyAndValue.Value) = Lower("Important"))
			Or AssignmentRow.SeeAlso <> (Lower(KeyAndValue.Value) = Lower("SeeAlso")) Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
EndFunction

// Defines whether search settings of a predefined report option are changed.
Function SearchSettingsChanged(OptionFromBase, PreviousInfo)
	Return OptionFromBase.SettingsHash <> PreviousInfo.SettingsHash
		Or OptionFromBase.FieldDescriptions <> PreviousInfo.FieldDescriptions
		Or OptionFromBase.FilterParameterDescriptions <> PreviousInfo.FilterParameterDescriptions
		Or OptionFromBase.Keywords <> PreviousInfo.Keywords;
EndFunction

// Adjusts separated data to shared data.
Procedure UpdateReportsOptionsByPredefinedOnes(Mode, Result)
	
	ProcedurePresentation = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Обновление вариантов отчетов (%1)'; en = 'Updating report options (%1)'; pl = 'Aktualizacja wariantów sprawozdań (%1)';de = 'Aktualisierung der Berichtsoptionen (%1)';ro = 'Actualizarea variantelor de rapoarte (%1)';tr = 'Rapor seçeneklerinin güncellenmesi (%1)'; es_ES = 'Actualuzación de las variantes de los informes (%1)'"), 
		Lower(ModePresentation(Mode)));
	WriteProcedureStartToLog(ProcedurePresentation);
	
	// Updating predefined option information.
	QueryText =
	"SELECT
	|	PredefinedConfigurations.Ref AS PredefinedVariant,
	|	PredefinedConfigurations.Description AS Description,
	|	PredefinedConfigurations.Report AS Report,
	|	PredefinedConfigurations.GroupByReport AS GroupByReport,
	|	PredefinedConfigurations.VariantKey AS VariantKey,
	|	PredefinedConfigurations.VisibleByDefault AS VisibleByDefault,
	|	PredefinedConfigurations.Parent AS Parent
	|INTO ttPredefined
	|FROM
	|	Catalog.PredefinedReportsOptions AS PredefinedConfigurations
	|WHERE
	|	PredefinedConfigurations.DeletionMark = FALSE
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ReportsOptions.Ref,
	|	ReportsOptions.DeletionMark,
	|	ReportsOptions.Report,
	|	ReportsOptions.ReportType,
	|	ReportsOptions.VariantKey,
	|	ReportsOptions.Description,
	|	ReportsOptions.PredefinedVariant,
	|	ReportsOptions.VisibleByDefault,
	|	ReportsOptions.Parent,
	|	ReportsOptions.DefaultVisibilityOverridden
	|INTO ttReportOptions
	|FROM
	|	Catalog.ReportsOptions AS ReportsOptions
	|WHERE
	|	(ReportsOptions.ReportType = &ReportType
	|		OR VALUETYPE(ReportsOptions.Report) = &AttributeTypeReport)
	|	AND ReportsOptions.Custom = FALSE
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CASE
	|		WHEN ttPredefined.PredefinedVariant IS NULL 
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS SetDeletionMark,
	|	CASE
	|		WHEN ttReportOptions.Ref IS NULL 
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS CreateNew,
	|	ttPredefined.PredefinedVariant AS PredefinedVariant,
	|	ttPredefined.Description AS Description,
	|	ttPredefined.Report AS Report,
	|	ttPredefined.VariantKey AS VariantKey,
	|	ttPredefined.GroupByReport AS GroupByReport,
	|	CASE
	|		WHEN ttPredefined.Parent = &EmptyOptionRef
	|			THEN UNDEFINED
	|		ELSE ttPredefined.Parent
	|	END AS PredefinedOptionParent,
	|	CASE
	|		WHEN ttReportOptions.DefaultVisibilityOverridden
	|			THEN ttReportOptions.VisibleByDefault
	|		ELSE ttReportOptions.VisibleByDefault
	|	END AS VisibleByDefault,
	|	ttReportOptions.Ref AS AttributeRef,
	|	ttReportOptions.Parent AS AttributeParent,
	|	ttReportOptions.Report AS AttributeReport,
	|	ttReportOptions.VariantKey AS AttributeVariantKey,
	|	ttReportOptions.Description AS AttributeDescription,
	|	ttReportOptions.PredefinedVariant AS AttributePredefinedVariant,
	|	ttReportOptions.DeletionMark AS AttributeDeletionMark,
	|	ttReportOptions.VisibleByDefault AS AttributeVisibleByDefault
	|FROM
	|	ttReportOptions AS ttReportOptions
	|		FULL JOIN ttPredefined AS ttPredefined
	|		ON ttReportOptions.PredefinedVariant = ttPredefined.PredefinedVariant";
	
	Query = New Query;
	If Mode = "SeparatedConfigurationData" Then
		Query.SetParameter("ReportType", Enums.ReportTypes.Internal);
		Query.SetParameter("AttributeTypeReport", Type("CatalogRef.MetadataObjectIDs"));
		Query.SetParameter("EmptyOptionRef", Catalogs.PredefinedReportsOptions.EmptyRef());
	ElsIf Mode = "SeparatedExtensionData" Then
		Query.SetParameter("ReportType", Enums.ReportTypes.Extension);
		Query.SetParameter("AttributeTypeReport", Type("CatalogRef.ExtensionObjectIDs"));
		Query.SetParameter("EmptyOptionRef", Catalogs.PredefinedExtensionsReportsOptions.EmptyRef());
		QueryText = StrReplace(QueryText, ".PredefinedReportsOptions", ".PredefinedExtensionsReportsOptions");
	EndIf;
	Query.Text = QueryText;
	
	Result.Insert("EmptyRef", Catalogs.ReportsOptions.EmptyRef());
	Result.Insert("SearchForParents", New Map);
	Result.Insert("ProcessedPredefinedItems", New Map);
	Result.Insert("MainOptions", New ValueTable);
	Result.MainOptions.Columns.Add("Report", Metadata.Catalogs.ReportsOptions.Attributes.Report.Type);
	Result.MainOptions.Columns.Add("Variant", New TypeDescription("CatalogRef.ReportsOptions"));
	
	AttributesToChange = New Structure("DeletionMark, Parent,
		|Description, Report, VariantKey, PredefinedVariant, VisibleByDefault");
	
	PredefinedItemsPivotTable = Query.Execute().Unload();
	PredefinedItemsPivotTable.Columns.Add("Processed", New TypeDescription("Boolean"));
	PredefinedItemsPivotTable.Columns.Add("Parent", New TypeDescription("CatalogRef.ReportsOptions"));
	
	// Updating main predefined options (without a parent).
	Search = New Structure("PredefinedOptionParent, SetDeletionMark", Undefined, False);
	FoundItems = PredefinedItemsPivotTable.FindRows(Search);
	For Each TableRow In FoundItems Do
		If TableRow.Processed Then
			Continue;
		EndIf;
		If Result.ProcessedPredefinedItems[TableRow.PredefinedVariant] <> Undefined Then
			TableRow.SetDeletionMark = True;
		EndIf;
		
		TableRow.Parent = Result.EmptyRef;
		UpdateSeparatedPredefinedItem(Result, AttributesToChange, TableRow);
		
		If Not TableRow.SetDeletionMark
			AND TableRow.GroupByReport
			AND Result.SearchForParents[TableRow.Report] = Undefined Then
			Result.SearchForParents[TableRow.Report] = TableRow.AttributeRef;
			MainOption = Result.MainOptions.Add();
			MainOption.Report   = TableRow.Report;
			MainOption.Variant = TableRow.AttributeRef;
		EndIf;
	EndDo;
	
	// Updating all remaining predefined options (subordinates).
	PredefinedItemsPivotTable.Sort("SetDeletionMark Asc");
	For Each TableRow In PredefinedItemsPivotTable Do
		If TableRow.Processed Then
			Continue;
		EndIf;
		If Result.ProcessedPredefinedItems[TableRow.PredefinedVariant] <> Undefined Then
			TableRow.SetDeletionMark = True;
		EndIf;
		If TableRow.SetDeletionMark Then
			ParentRef = Result.EmptyRef;
		Else
			ParentRef = Result.SearchForParents[TableRow.Report];
		EndIf;
		
		TableRow.Parent = ParentRef;
		UpdateSeparatedPredefinedItem(Result, AttributesToChange, TableRow);
	EndDo;
	
	// Updating user option parents.
	QueryText = 
	"SELECT
	|	MainReportOptions.Report,
	|	MainReportOptions.Variant
	|INTO ttMain
	|FROM
	|	&MainReportOptions AS MainReportOptions
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ReportsOptions.Ref,
	|	ttMain.Variant AS Parent
	|FROM
	|	Catalog.ReportsOptions AS ReportsOptions
	|		INNER JOIN ttMain AS ttMain
	|		ON ReportsOptions.Report = ttMain.Report
	|			AND ReportsOptions.Parent <> ttMain.Variant
	|			AND ReportsOptions.Parent.Parent <> ttMain.Variant
	|			AND ReportsOptions.Ref <> ttMain.Variant
	|WHERE
	|	ReportsOptions.Custom 
	|	OR NOT ReportsOptions.DeletionMark";
	
	Query = New Query;
	Query.SetParameter("MainReportOptions", Result.MainOptions);
	Query.Text = QueryText;
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Result.HasChanges = True;
		
		BeginTransaction();
		Try
			Lock = New DataLock;
			LockItem = Lock.Add("Catalog.ReportsOptions");
			LockItem.SetValue("Ref", Selection.Ref);
			
			OptionObject = Selection.Ref.GetObject();
			OptionObject.Parent = Selection.Parent;
			OptionObject.Lock();
			InfobaseUpdate.WriteObject(OptionObject);
			
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;	
	EndDo;
	
	WriteProcedureCompletionToLog(ProcedurePresentation);
EndProcedure

// Updates predefined data in separated mode.
Procedure UpdateSeparatedPredefinedItem(Result, AttributesToChange, TableRow)
	If TableRow.Processed Then
		Return;
	EndIf;
	
	TableRow.Processed = True;
	
	If TableRow.SetDeletionMark Then 
		
		If TableRow.AttributeParent = Result.EmptyRef 
			AND TableRow.AttributeDeletionMark = True Then
			Return; // Already marked.
		EndIf;
		
		BeginTransaction();
		Try
			Lock = New DataLock;
			LockItem = Lock.Add("Catalog.ReportsOptions");
			LockItem.SetValue("Ref", TableRow.AttributeRef);
			Lock.Lock();
			
			OptionObject = TableRow.AttributeRef.GetObject();
			OptionObject.Lock();
			
			OptionObject.Parent = Result.EmptyRef;
			OptionObject.DeletionMark = True;
			InfobaseUpdate.WriteObject(OptionObject);
			
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;	
		
		Result.HasChanges = True;
		Return;
	EndIf;
		
	If TableRow.GroupByReport AND Not ValueIsFilled(TableRow.PredefinedOptionParent) Then
		TableRow.Parent = Result.EmptyRef;
	EndIf;
	Result.ProcessedPredefinedItems[TableRow.PredefinedVariant] = True;
	FillPropertyValues(AttributesToChange, TableRow);
	AttributesToChange.DeletionMark = False;
	
	If Not TableRow.CreateNew AND PropertiesValuesMatch(AttributesToChange, TableRow, "Attribute") Then
		Return; // No changes.
	EndIf;
	
	BeginTransaction();
	Try
		If TableRow.CreateNew Then // Add.
			OptionObject = Catalogs.ReportsOptions.CreateItem();
			OptionObject.PredefinedVariant = TableRow.PredefinedVariant;
			OptionObject.Custom = False;
		Else // Update (if there are changes).
			Lock = New DataLock;
			LockItem = Lock.Add("Catalog.ReportsOptions");
			LockItem.SetValue("Ref", TableRow.AttributeRef);
			Lock.Lock();
			
			// Transferring user settings.
			ReplaceUserSettingsKeys(AttributesToChange, TableRow);
			
			OptionObject = TableRow.AttributeRef.GetObject();
			OptionObject.Lock();
		EndIf;
		ExcludeProperties = ?(OptionObject.DefaultVisibilityOverridden, "VisibleByDefault", Undefined);
		FillPropertyValues(OptionObject, AttributesToChange, , ExcludeProperties);
		ReportByStringType = ReportsOptionsClientServer.ReportByStringType(Undefined, OptionObject.Report);
		OptionObject.ReportType = Enums.ReportTypes[ReportByStringType];
		
		InfobaseUpdate.WriteObject(OptionObject);
	
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
		
	Result.HasChanges = True;
	If TableRow.CreateNew Then	
		TableRow.AttributeRef = OptionObject.Ref;
	EndIf;
	
EndProcedure

// Returns True if values of the Structure and Collection properties match the PrefixInCollection prefix.
Function PropertiesValuesMatch(Structure, Collection, PrefixInCollection = "")
	For Each KeyAndValue In Structure Do
		If Collection[PrefixInCollection + KeyAndValue.Key] <> KeyAndValue.Value Then
			Return False;
		EndIf;
	EndDo;
	Return True;
EndFunction

// Setting a deletion mark for deleted report options.
Procedure MarkOptionsOfDeletedReportsForDeletion(Mode, Result)
	
	ProcedurePresentation = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Удаление вариантов удаленных отчетов (%1)'; en = 'Deleting options of deleted reports (%1)'; pl = 'Usunięcie wariantów usuniętych raportów (%1)';de = 'Löschen von entfernten Berichtsoptionen (%1)';ro = 'Ștergerea variantelor rapoartelor șterse (%1)';tr = 'Silinmiş raporların seçeneklerini sil (%1)'; es_ES = 'Eliminación de las variantes de los informes eliminados (%1)'"), 
		Lower(ModePresentation(Mode)));
	WriteProcedureStartToLog(ProcedurePresentation);
	
	Query = New Query;
	QueryText =
	"SELECT
	|	ReportsOptions.Ref AS Ref
	|FROM
	|	Catalog.ReportsOptions AS ReportsOptions
	|WHERE
	|	NOT ReportsOptions.DeletionMark
	|	AND ReportsOptions.ReportType = &ReportType
	|	AND ISNULL(ReportsOptions.Report.DeletionMark, TRUE)";
	
	TableName = "Catalog.ReportsOptions";
	If Mode = "ConfigurationCommonData" Then
		QueryText = StrReplace(QueryText, ".ReportsOptions", ".PredefinedReportsOptions");
		QueryText = StrReplace(QueryText, "AND ReportsOptions.ReportType = &ReportType", "");
		TableName = "Catalog.PredefinedReportsOptions";
	ElsIf Mode = "ExtensionsCommonData" Then
		QueryText = StrReplace(QueryText, ".ReportsOptions", ".PredefinedExtensionsReportsOptions");
		QueryText = StrReplace(QueryText, "AND ReportsOptions.ReportType = &ReportType", "");
		TableName = "Catalog.PredefinedExtensionsReportsOptions";
	ElsIf Mode = "SeparatedConfigurationData" Then
		Query.SetParameter("ReportType", Enums.ReportTypes.Internal);
	ElsIf Mode = "SeparatedExtensionData" Then
		Query.SetParameter("ReportType", Enums.ReportTypes.Extension);
	EndIf;
	
	Query.Text = QueryText;
	OptionsToDeleteRefs = Query.Execute().Unload().UnloadColumn("Ref");
	For Each OptionRef In OptionsToDeleteRefs Do
		Result.HasChanges = True;
		Result.HasImportantChanges = True;
		
		BeginTransaction();
		Try
			Lock = New DataLock;
			LockItem = Lock.Add(TableName);
			LockItem.SetValue("Ref", OptionRef);
			Lock.Lock();
			
			OptionObject = OptionRef.GetObject();
			If OptionObject = Undefined Then
				RollbackTransaction();
				Continue;
			EndIf;	
			OptionObject.Lock();
			OptionObject.DeletionMark = True;
			WritePredefinedObject(OptionObject);
			
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;	
	EndDo;
	
	WriteProcedureCompletionToLog(ProcedurePresentation);
EndProcedure

// Transferring custom settings of the option from the relevant storage.
Procedure ReplaceUserSettingsKeys(OldOption, UpdatedOption)
	If OldOption.VariantKey = UpdatedOption.VariantKey
		Or Not ValueIsFilled(OldOption.VariantKey)
		Or Not ValueIsFilled(UpdatedOption.VariantKey)
		Or TypeOf(UpdatedOption.Report) <> Type("CatalogRef.MetadataObjectIDs") Then
		Return;
	EndIf;
	
	ReportFullName = UpdatedOption.Report.FullName;
	OldObjectKey = ReportFullName + "/" + OldOption.VariantKey;
	NewObjectKey = ReportFullName + "/" + UpdatedOption.VariantKey;
	
	Filter = New Structure("ObjectKey", OldObjectKey);
	StorageSelection = ReportsUserSettingsStorage.Select(Filter);
	SuccessiveReadingErrors = 0;
	While True Do
		// Reading settings from the storage by the old key.
		Try
			GotSelectionItem = StorageSelection.Next();
			SuccessiveReadingErrors = 0;
		Except
			GotSelectionItem = Undefined;
			SuccessiveReadingErrors = SuccessiveReadingErrors + 1;
			WriteToLog(EventLogLevel.Error,
				NStr("ru = 'В процессе выборки вариантов отчетов из стандартного хранилища возникла ошибка:'; en = 'Error selecting report options from standard storage:'; pl = 'Wystąpił błąd podczas wybierania wariantów sprawozdania z pamięci:';de = 'Beim Auswählen der Berichtsoptionen aus dem Standardspeicher ist ein Fehler aufgetreten:';ro = 'A apărut o eroare la selectarea opțiunilor de raportare din spațiul de stocare standard:';tr = 'Standart depolama alanından rapor seçenekleri seçilirken bir hata oluştu:'; es_ES = 'Ha ocurrido un error al seleccionar las opciones de informes desde el almacenamiento estándar:'")
					+ Chars.LF + DetailErrorDescription(ErrorInfo()),
				OldOption.Ref);
		EndTry;
		
		If GotSelectionItem = False Then
			Break;
		ElsIf GotSelectionItem = Undefined Then
			If SuccessiveReadingErrors > 100 Then
				Break;
			Else
				Continue;
			EndIf;
		EndIf;
		
		// Reading settings description.
		SettingsDetails = ReportsUserSettingsStorage.GetDescription(
			StorageSelection.ObjectKey,
			StorageSelection.SettingsKey,
			StorageSelection.User);
		
		// Writing settings to the storage by a new key.
		ReportsUserSettingsStorage.Save(
			NewObjectKey,
			StorageSelection.SettingsKey,
			StorageSelection.Settings,
			SettingsDetails,
			StorageSelection.User);
	EndDo;
	
	// Clearing old storage settings.
	ReportsUserSettingsStorage.Delete(OldObjectKey, Undefined, Undefined);
EndProcedure

// Writes a predefined object.
Procedure WritePredefinedObject(OptionObject)
	OptionObject.AdditionalProperties.Insert("PredefinedObjectsFilling");
	InfobaseUpdate.WriteObject(OptionObject);
EndProcedure

// Registers changes in the measurement table.
Procedure RegisterOptionMeasurementsForUpdate(Val OldKey, Val UpdatedKey, Val UpdatedDescription, Result)
	If IsBlankString(OldKey) Then
		OldKey = UpdatedKey;
	EndIf;
	
	MeasurementUpdating = Result.MeasurementsTable.Add();
	MeasurementUpdating.OldName     = OldKey     + ".Opening";
	MeasurementUpdating.UpdatedName = UpdatedKey + ".Opening";
	MeasurementUpdating.UpdatedDescription = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Отчет ""%1"" (открытие)'; en = 'Report %1 (open)'; pl = 'Raport ""%1"" (otwarcie)';de = 'Bericht ""%1"" (Eröffnung)';ro = 'Raportul ""%1"" (deschidere)';tr = 'Rapor ""%1"" (açılış)'; es_ES = 'Informe ""%1"" (apertura)'"), UpdatedDescription);
	
	MeasurementUpdating = Result.MeasurementsTable.Add();
	MeasurementUpdating.OldName     = OldKey     + ".Generation";
	MeasurementUpdating.UpdatedName = UpdatedKey + ".Generation";
	MeasurementUpdating.UpdatedDescription = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Отчет ""%1"" (формирование)'; en = 'Report %1 (generate)'; pl = 'Raport ""%1"" (tworzenie)';de = 'Bericht ""%1"" (Formation)';ro = 'Raportul ""%1"" (generare)';tr = 'Rapor ""%1"" (oluşturma)'; es_ES = 'Informe ""%1"" (generar)'"), UpdatedDescription);
	
	MeasurementUpdating = Result.MeasurementsTable.Add();
	MeasurementUpdating.OldName     = OldKey     + ".Settings";
	MeasurementUpdating.UpdatedName = UpdatedKey + ".Settings";
	MeasurementUpdating.UpdatedDescription = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Отчет ""%1"" (настройки)'; en = 'Report %1 (settings)'; pl = 'Raport ""%1"" (ustawienia)';de = 'Bericht ""%1"" (Einstellungen)';ro = 'Raportul ""%1"" (setări)';tr = 'Rapor ""%1"" (ayarlar)'; es_ES = 'Informe ""%1"" (ajustes)'"), UpdatedDescription);
EndProcedure

Function MeasurementsTable()
	Result = New ValueTable;
	Result.Columns.Add("OldName", TypesDetailsString(150));
	Result.Columns.Add("UpdatedName", TypesDetailsString(150));
	Result.Columns.Add("UpdatedDescription", TypesDetailsString(150));
	Return Result;
EndFunction

// Write report option parameters (metadata cache for application speed).
//   FunctionalOptionsTable - ValueTable - a connection of functional options and predefined report options:
//     * Report - CalalogRef.MetadataObjectsIDs
//     * PredefinedOption - CatalogRef.PredefinedReportsOptions.
//     * FunctionalOptionName - String
//   ReportsWithSettings - Array from CatalogRef.MetadataObjectIDs - reports whose object module 
//        contains procedures of integration with the common report form.
//
Procedure WriteFunctionalOptionsTable(Mode, Result)
	If Mode = "ExtensionsCommonData" AND Not ValueIsFilled(SessionParameters.ExtensionsVersion) Then
		Return; // The update is not required.
	EndIf;
	ProcedurePresentation = NStr("ru = 'Запись неразделенного кэша в регистр'; en = 'Save shared cache to register'; pl = 'Zapis niepodzielonej pamięci podręcznej do rejestru';de = 'Schreiben eines ungeteilten Caches in ein Register';ro = 'Înregistrarea cache-ului neseparat în registru';tr = 'Karşılıksız önbelleği sicile kaydetme'; es_ES = 'Guardar caché no dividido en el registro'");
	WriteProcedureStartToLog(ProcedurePresentation);
	
	Result.FunctionalOptionsTable.Sort("Report, PredefinedVariant, FunctionalOptionName");
	Result.ReportsWithSettingsList.SortByValue();
	
	NewValue = New Structure;
	NewValue.Insert("FunctionalOptionsTable", Result.FunctionalOptionsTable);
	NewValue.Insert("ReportsWithSettings", Result.ReportsWithSettingsList.UnloadValues());
	
	FullSubsystemName = ReportsOptionsClientServer.FullSubsystemName();
	
	If Mode = "ConfigurationCommonData" Then
		StandardSubsystemsServer.SetApplicationParameter(FullSubsystemName, NewValue);
	ElsIf Mode = "ExtensionsCommonData" Then
		StandardSubsystemsServer.SetExtensionParameter(FullSubsystemName, NewValue);
	EndIf;
	
	WriteProcedureCompletionToLog(ProcedurePresentation);
EndProcedure

// Write the PredefinedExtensionsVersionsReportsOptions register.
//
// Value to save:
//   ValueStorage (Structure) - Cached parameters:
//       * FunctionalOptionsTable - ValueTable - Options and predefined report options names.
//           ** Report - CatalogRef.ExtensionObjectIDs - a report reference.
//           ** PredefinedOption - CatalogRef.PredefinedReportOptionsOfExtensions - The option reference.
//           ** FunctionalOptionName - String - a functional option name.
//       * ReportsWithSettings - Array from CatalogRef.ExtensionObjectIDs - reports whose object 
//           module contains procedures of deep integration with the common report form.
//
Procedure RecordCurrentExtensionsVersion()
	If Not ValueIsFilled(SessionParameters.ExtensionsVersion) Then
		Return; // The update is not required.
	EndIf;
	
	ProcedurePresentation = NStr("ru = 'Запись регистра версий расширений'; en = 'Save extension version register'; pl = 'Zapis rejestru wersji rozszerzeń';de = 'Schreiben des Registers der Erweiterungsversionen';ro = 'Înregistrarea registrului versiunilor extensiilor';tr = 'Uzantı sürüm kaydı'; es_ES = 'Guardar el registro en de las versiones de las extensiones'");
	WriteProcedureStartToLog(ProcedurePresentation);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	PredefinedExtensions.Ref AS Variant,
	|	PredefinedExtensions.Report,
	|	PredefinedExtensions.VariantKey
	|FROM
	|	Catalog.PredefinedExtensionsReportsOptions AS PredefinedExtensions
	|WHERE
	|	PredefinedExtensions.DeletionMark = FALSE";
	
	Table = Query.Execute().Unload();
	Dimensions = New Structure("ExtensionsVersion", SessionParameters.ExtensionsVersion);
	Resources = New Structure;
	Set = InformationRegisters.PredefinedExtensionsVersionsReportsOptions.Set(Table, Dimensions, Resources, True);
	InfobaseUpdate.WriteRecordSet(Set, True);
	
	WriteProcedureCompletionToLog(ProcedurePresentation);
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Update of presentations in other languages.

// The FillPredefinedReportsOptionsPresentations scheduled job handler.
Procedure FillPredefinedReportsOptionsPresentations(Languages, CurrentLanguageIndex) Export
	
	Common.OnStartExecuteScheduledJob(
		Metadata.ScheduledJobs.PredefinedReportOptionsUpdate);
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	UpdateParameters = SettingsUpdateParameters();
	UpdateParameters.Deferred = True;
	Refresh(UpdateParameters);
	
	If CurrentLanguageIndex < Languages.Count() - 1 Then
		SchedulePresentationsFilling(Languages, CurrentLanguageIndex + 1);
		Return;
	EndIf;
	
	Jobs = ScheduledJobs.GetScheduledJobs(
		New Structure("Metadata", Metadata.ScheduledJobs.PredefinedReportOptionsUpdate));
	For each PresentationsFilling In Jobs Do
		PresentationsFilling.Delete();
	EndDo;		

EndProcedure

Procedure SchedulePresentationsFilling(Val LanguageCodes = Undefined, Val LanguageIndex = 0)
	
	If Common.FileInfobase() Then
		Return;
	EndIf;
		
	If Common.DataSeparationEnabled() Then
		Return;
	EndIf;

	If LanguageCodes = Undefined Then
		LanguageCodes = New Array;
		For each Language In Metadata.Languages Do
			If Language <> CurrentLanguage() Then
				LanguageCodes.Add(Language.LanguageCode);
			EndIf;	
		EndDo;	
	EndIf;
	
	If LanguageIndex >= LanguageCodes.Count() Then
		Return;
	EndIf;
	
	LanguageCode = LanguageCodes[LanguageIndex];
	
	InternalUser = InternalUser(LanguageCode);
	If InternalUser = Undefined Then 
		Return;
	EndIf;
	
	PresentationsFilling = ScheduledJobs.CreateScheduledJob(
		Metadata.ScheduledJobs.PredefinedReportOptionsUpdate);
	PresentationsFilling.UserName = InternalUser;
	PresentationsFilling.Description = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Заполнение представлений предопределенных вариантов отчетов для языка %1'; en = 'Populating presentations of predefined report options for the %1 language'; pl = 'Wypełnienie predefiniowane opcje raportu dla języka %1';de = 'Ausfüllen der Darstellungen von vordefinierten Berichtsoptionen für die Sprache %1';ro = 'Completarea prezentărilor variantelor predefinite ale rapoartelor pentru limba %1';tr = 'Dil için önceden tanımlanmış rapor seçeneklerinin görünümlerini doldurma%1'; es_ES = 'Relleno de presentaciones predeterminadas de opciones de informes para el lenguaje %1'"), String(LanguageCode));
	PresentationsFilling.Parameters.Add(LanguageCodes);
	PresentationsFilling.Parameters.Add(LanguageIndex);
		
	PresentationsFilling.Use = True;	
	PresentationsFilling.Schedule.BeginTime = CurrentSessionDate() + 60;	
	PresentationsFilling.Write();

EndProcedure

Function InternalUser(Val LanguageCode)
	Result = InfoBaseUsers.FindByName("ServiceUserToUpdatePresentations");
	If Result = Undefined Then
		If InfoBaseUsers.GetUsers().Count() = 0 Then 
			Return Undefined;
		EndIf;
		
		Result = InfoBaseUsers.CreateUser();
		Result.Name = "ServiceUserToUpdatePresentations";
		Result.CannotChangePassword = True;
		Result.ShowInList = False;
	EndIf;
	Result.Language = LocalizationServer.LanguageByCode(LanguageCode);
	Result.Write();
	
	Return Result.Name;
EndFunction

Function ModePresentation(Mode)
	
	Modes = New Map;
	Modes.Insert("ConfigurationCommonData", NStr("ru = 'Общие данные конфигурации'; en = 'Shared configuration data'; pl = 'Dane ogólne konfiguracji';de = 'Allgemeine Konfigurationsdaten';ro = 'Date generale ale configurației';tr = 'Genel yapılandırma verileri'; es_ES = 'Datos comunes de configuración'"));
	Modes.Insert("ExtensionsCommonData", NStr("ru = 'Общие данные расширений'; en = 'Shared extension data'; pl = 'Dane ogólne rozszerzeń';de = 'Allgemeine Erweiterungsdaten';ro = 'Date generale ale extensiei';tr = 'Paylaşılan uzantı verileri'; es_ES = 'Datos comunes de extensiones'"));
	Modes.Insert("SeparatedConfigurationData", NStr("ru = 'Разделенные данные конфигурации'; en = 'Separate configuration data'; pl = 'Rozdzielone dane konfiguracji';de = 'Konfigurationsdaten teilen';ro = 'Date separate ale configurației';tr = 'Bölünmüş yapılandırma verileri'; es_ES = 'Datos compartidos de configuración'"));
	Modes.Insert("SeparatedExtensionData", NStr("ru = 'Разделенные данные расширений'; en = 'Separate extension data'; pl = 'Rozdzielone dane rozszerzeń';de = 'Erweiterungsdaten teilen';ro = 'Date separate ale extensiei';tr = 'Bölünmüş uzantı verileri'; es_ES = 'Datos compartidos de extensiones'"));
	
	ModePresentation = Modes.Get(Mode);
	
	Return ?(ModePresentation = Undefined, "", ModePresentation);
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Updating an infobase / Migrating to revision 2.1.

// Changing the structure of storing settings by sections to MOID catalog references.
//   The procedure is called only for internal report options.
//
Procedure Edition21ArrangeSettingsBySections(OptionObject)
	
	Count = OptionObject.Placement.Count();
	For Number = 1 To Count Do
		ReverseIndex = Count - Number;
		TableRow = OptionObject.Placement[ReverseIndex];
		
		If ValueIsFilled(TableRow.Subsystem) Then
			Continue; // Filling is not required.
		EndIf;
		
		If Not ValueIsFilled(TableRow.DeleteSubsystem) Then
			OptionObject.Placement.Delete(TableRow);
			Continue; // Filling is not possible.
		EndIf;
		
		SubsystemFullName = "Subsystem." + StrReplace(TableRow.DeleteSubsystem, "\", ".Subsystem.");
		SubsystemMetadata = Metadata.FindByFullName(SubsystemFullName);
		If SubsystemMetadata = Undefined Then
			OptionObject.Placement.Delete(TableRow);
			Continue; // Filling is not possible.
		EndIf;
		
		SubsystemRef = Common.MetadataObjectID(SubsystemMetadata);
		If Not ValueIsFilled(SubsystemRef) Or TypeOf(SubsystemRef) = Type("String") Then
			OptionObject.Placement.Delete(TableRow);
			Continue; // Filling is not possible.
		EndIf;
		
		TableRow.Use = True;
		TableRow.Subsystem = SubsystemRef;
		TableRow.DeleteSubsystem = "";
		TableRow.DeleteName = "";
		
	EndDo;
	
EndProcedure

// Filling in the ReportOptionsSettings register.
//   The procedure is called only for internal report options.
//
Procedure Edition21MoveUserSettingsToRegister(OptionObject)
	SubsystemsTable = OptionObject.Placement.Unload(New Structure("Use", True));
	SubsystemsTable.GroupBy("Subsystem");
	
	UsersTable = OptionObject.DeleteQuickAccessExceptions.Unload();
	UsersTable.Columns.DeleteUser.Name = "User";
	UsersTable.GroupBy("User");
	
	SettingsPackage = New ValueTable;
	SettingsPackage.Columns.Add("Subsystem",   SubsystemsTable.Columns.Subsystem.ValueType);
	SettingsPackage.Columns.Add("User", UsersTable.Columns.User.ValueType);
	SettingsPackage.Columns.Add("Visible",    New TypeDescription("Boolean"));
	
	For Each RowSubsystem In SubsystemsTable Do
		For Each UserString In UsersTable Do
			Setting = SettingsPackage.Add();
			Setting.Subsystem   = RowSubsystem.SectionOrGroup;
			Setting.User = UserString.User;
			Setting.Visible    = Not OptionObject.VisibleByDefault;
		EndDo;
	EndDo;
	
	Dimensions = New Structure("Variant", OptionObject.Ref);
	Resources   = New Structure("QuickAccess", False);
	InformationRegisters.ReportOptionsSettings.WriteSettingsPackage(SettingsPackage, Dimensions, Resources, True);
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Operations with the subsystem tree from forms.

// Adds conditional appearance items of the subsystem tree.
Procedure SetSubsystemsTreeConditionalAppearance(Form) Export
	
	Form.Items.SubsystemsTreeImportance.ChoiceList.Add(ImportantPresentation());
	Form.Items.SubsystemsTreeImportance.ChoiceList.Add(SeeAlsoPresentation());
	
	Item = Form.ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Form.Items.SubsystemsTree.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SubsystemsTree.Priority");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = "";

	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	Item = Form.ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Form.Items.SubsystemsTreeUsage.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Form.Items.SubsystemsTreeImportance.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SubsystemsTree.Priority");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = "";

	Item.Appearance.SetParameterValue("Show", False);
	
EndProcedure

// Generates a subsystem tree according to base option data.
Function SubsystemsTreeGenerate(Form, OptionBasis) Export
	// Blank tree without settings.
	Prototype = Form.FormAttributeToValue("SubsystemsTree", Type("ValueTree"));
	SubsystemsTree = ReportsOptionsCached.CurrentUserSubsystems().Copy();
	For Each PrototypeColumn In Prototype.Columns Do
		If SubsystemsTree.Columns.Find(PrototypeColumn.Name) = Undefined Then
			SubsystemsTree.Columns.Add(PrototypeColumn.Name, PrototypeColumn.ValueType);
		EndIf;
	EndDo;
	
	// Parameters.
	Context = New Structure("SubsystemsTree");
	Context.SubsystemsTree = SubsystemsTree;
	
	// Placement configured by the administrator.
	Subsystems = New Array;
	For Each AssignmentRow In OptionBasis.Placement Do
		Subsystems.Add(AssignmentRow.Subsystem);
		SubsystemsTreeRegisterSubsystemsSettings(Context, AssignmentRow, AssignmentRow.Use);
	EndDo;
	
	// Placement predefined by the developer.
	QueryText = 
	"SELECT
	|	Placement.Ref,
	|	Placement.LineNumber,
	|	Placement.Subsystem,
	|	Placement.Important,
	|	Placement.SeeAlso
	|FROM
	|	Catalog.PredefinedReportsOptions.Placement AS Placement
	|WHERE
	|	Placement.Ref = &Ref
	|	AND NOT Placement.Subsystem IN (&Subsystems)";
	
	If TypeOf(OptionBasis.PredefinedVariant) = Type("CatalogRef.PredefinedExtensionsReportsOptions") Then
		QueryText = StrReplace(QueryText, "PredefinedReportsOptions", "PredefinedExtensionsReportsOptions");
	EndIf;
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", OptionBasis.PredefinedVariant);
	// Do not read subsystem settings predefined by the administrator.
	Query.SetParameter("Subsystems", Subsystems);
	PredefinedItemPlacement = Query.Execute().Unload();
	For Each AssignmentRow In PredefinedItemPlacement Do
		SubsystemsTreeRegisterSubsystemsSettings(Context, AssignmentRow, True);
	EndDo;
	
	Return Context.SubsystemsTree;
EndFunction

// Adds a subsystem to the tree.
Procedure SubsystemsTreeRegisterSubsystemsSettings(Context, AssignmentRow, Usage)
	FoundItems = Context.SubsystemsTree.Rows.FindRows(New Structure("Ref", AssignmentRow.Subsystem), True);
	If FoundItems.Count() = 0 Then
		Return;
	EndIf;
	
	TreeRow = FoundItems[0];
	
	If AssignmentRow.Important Then
		TreeRow.Importance = ImportantPresentation();
	ElsIf AssignmentRow.SeeAlso Then
		TreeRow.Importance = SeeAlsoPresentation();
	Else
		TreeRow.Importance = "";
	EndIf;
	TreeRow.Use = Usage;
EndProcedure

// Saves placement settings changed by the user to the tabular section of the report option.
//
// Parameters:
//   OptionObject - CatalogObject.ReportOptions, FormDataStructure - a report option object.
//   ChangedSubsystems - Array - an array of value tree rows, which contains changed placement settings.
//
Procedure SubsystemsTreeWrite(OptionObject, ChangedSubsystems) Export
	
	For Each Subsystem In ChangedSubsystems Do
		TabularSectionRow = OptionObject.Placement.Find(Subsystem.Ref, "Subsystem");
		If TabularSectionRow = Undefined Then
			// The variant placement setting must be registered unconditionally (even if the Usage flag is disabled)
			// - than this setting will replace the predefined one (from the shared catalog).
			TabularSectionRow = OptionObject.Placement.Add();
			TabularSectionRow.Subsystem = Subsystem.Ref;
		EndIf;
		
		If Subsystem.Use = 0 Then
			TabularSectionRow.Use = False;
		ElsIf Subsystem.Use = 1 Then
			TabularSectionRow.Use = True;
		Else
			// Leaving as it is
		EndIf;
		
		If Subsystem.Importance = ImportantPresentation() Then
			TabularSectionRow.Important  = True;
			TabularSectionRow.SeeAlso = False;
		ElsIf Subsystem.Importance = SeeAlsoPresentation() Then
			TabularSectionRow.Important  = False;
			TabularSectionRow.SeeAlso = True;
		Else
			TabularSectionRow.Important  = False;
			TabularSectionRow.SeeAlso = False;
		EndIf;
	EndDo;
EndProcedure

// Importance group presentation.
Function SeeAlsoPresentation() Export
	Return NStr("ru = 'См. также'; en = 'See also:'; pl = 'Zobacz również';de = 'Siehe auch';ro = 'Mai vezi';tr = 'Ayrıca bakınız'; es_ES = 'Ver también'");
EndFunction 

// Importance group presentation.
Function ImportantPresentation() Export
	Return NStr("ru = 'Важный'; en = 'Important'; pl = 'Ważne';de = 'Wichtig';ro = 'Important';tr = 'Önemli'; es_ES = 'Importante'");
EndFunction

// Separator that is used to display several descriptions in the interface.
Function PresentationSeparator()
	Return ", ";
EndFunction

// The function converts a report type into a string ID.
Function ReportType(ReportRef, ResultString = False) Export
	RefType = TypeOf(ReportRef);
	If RefType = Type("CatalogRef.MetadataObjectIDs") Then
		varKey = "Internal";
	ElsIf RefType = Type("CatalogRef.ExtensionObjectIDs") Then
		varKey = "Extension";
	ElsIf RefType = Type("String") Then
		varKey = "External";
	ElsIf RefType = AdditionalReportRefType() Then
		varKey = "Additional";
	Else
		varKey = ?(ResultString, Undefined, "EmptyRef");
	EndIf;
	Return ?(ResultString, varKey, PredefinedValue("Enum.ReportTypes." + varKey));
EndFunction

// Returns an additional report reference type.
Function AdditionalReportRefType()
	Exists = Common.SubsystemExists("StandardSubsystems.AdditionalReportsAndDataProcessors");
	If Exists Then
		Return Type("CatalogRef.AdditionalReportsAndDataProcessors");
	EndIf;
	
	Return Undefined;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Generating presentations of fields, parameters, and filters for search.

// The function is called from the OnWrite option event.
// Returns:
//   Boolean - True if search fields are filled in and you need to write OptionObject.
//
Function FillFieldsForSearch(OptionObject, ReportInfo = Undefined) Export
	
	FieldsForSearch = FieldsForSearch(OptionObject);
	
	CheckHash = ReportInfo = Undefined Or Not ReportInfo.IndexSchema;
	If CheckHash Then
		// Checking if fields were filled in earlier.
		FillFields = Left(FieldsForSearch.FieldDescriptions, 1) <> "#";
		FillParametersAndFilters = Left(FieldsForSearch.FilterParameterDescriptions, 1) <> "#";
		If Not FillFields AND Not FillParametersAndFilters Then
			Return False; // Filling is not required.
		EndIf;
	Else	
		FillFields = True;
		FillParametersAndFilters = True;
	EndIf;
	
	// Getting a report object, DCS settings, and an option.
	IsPredefined = TypeOf(OptionObject) = Type("CatalogObject.PredefinedReportsOptions")
		Or TypeOf(OptionObject) = Type("CatalogObject.PredefinedExtensionsReportsOptions")
		Or Not OptionObject.Custom;
	
	// Preset search settings.
	SearchSettings = ?(ReportInfo <> Undefined, ReportInfo.SearchSettings, Undefined);
	If SearchSettings <> Undefined Then
		WritingRequired = False;
		If ValueIsFilled(SearchSettings.FieldDescriptions) Then
			FieldsForSearch.FieldDescriptions = "#" + TrimAll(SearchSettings.FieldDescriptions);
			FillFields = False;
			WritingRequired = True;
		EndIf;
		If ValueIsFilled(SearchSettings.FilterParameterDescriptions) Then
			FieldsForSearch.FilterParameterDescriptions = "#" + TrimAll(SearchSettings.FilterParameterDescriptions);
			FillParametersAndFilters = False;
			WritingRequired = True;
		EndIf;
		If ValueIsFilled(SearchSettings.Keywords) Then
			FieldsForSearch.Keywords = "#" + TrimAll(SearchSettings.Keywords);
			WritingRequired = True;
		EndIf;
		If Not FillFields AND Not FillParametersAndFilters Then
			SetFieldsForSearch(OptionObject, FieldsForSearch);
			Return WritingRequired; // Filling is completed, write an object.
		EndIf;
	EndIf;
	
	// In some scenarios, an object can be already cached in additional properties.
	ReportObject = ?(ReportInfo <> Undefined, ReportInfo.ReportObject, Undefined);
	
	// When a report object is not cached, attach an object in the regular way.
	If ReportObject = Undefined Then
		Attachment = AttachReportObject(OptionObject.Report, False);
		If Attachment.Success Then
			ReportObject = Attachment.Object;
		EndIf;	
		If ReportInfo <> Undefined Then
			ReportInfo.ReportObject = ReportObject;
		EndIf;
		If ReportObject = Undefined Then
			WriteToLog(EventLogLevel.Error, Attachment.ErrorText, OptionObject.Ref);
			Return False; // An issue occurred during report attachement.
		EndIf;
	EndIf;
	
	// Extracting template texts is possible only once a report object is received.
	If SearchSettings <> Undefined AND ValueIsFilled(SearchSettings.TemplatesNames) Then
		FieldsForSearch.FieldDescriptions = "#" + ExtractTemplateText(ReportObject, SearchSettings.TemplatesNames);
		If Not FillParametersAndFilters Then
			SetFieldsForSearch(OptionObject, FieldsForSearch);
			Return True; // Filling is completed, write an object.
		EndIf;
	EndIf;
	
	// The composition schema that will be a basis for report execution.
	DCSchema = ReportObject.DataCompositionSchema;
	
	// If a report is not on DCS, presentations are not filled or filled by applied features.
	If DCSchema = Undefined Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Для варианта ""%1"" отчета ""%2"" не заполнены настройки поиска:
			|Наименования полей, параметров и отборов.'; 
			|en = 'Report %2, option %1. Search settings required:
			|Description of fields, parameters, and filters.'; 
			|pl = 'Dla wariantu ""%1"" raportu ""%2"" nie wypełnione ustawienia wyszukiwania: 
			|Nazwa pól, parametrów i selekcji.';
			|de = 'Für die Variante ""%1"" des Berichts ""%2"" werden die Sucheinstellungen nicht ausgefüllt:
			|Feldnamen, Parameter und Auswahlen.';
			|ro = 'Setările de căutare nu sunt completate pentru varianta ""%1"" a raportului ""%2"":
			|Nume de câmpuri, parametri și filtre.';
			|tr = '""%2""Rapor ""%1"" seçeneği için Arama ayarları doldurulmadı:
			| alan adları, seçenekler ve seçimler.'; 
			|es_ES = 'Para la opción ""%1"" del informe ""%2"" los ajustes de búsqueda no están rellenados:
			|Nombre de campos, parámetros y selecciones.'"),
			OptionObject.VariantKey, OptionObject.Report);
		If IsPredefined Then
			ErrorText = ErrorText + Chars.LF
				+ NStr("ru = 'Подробнее - см. процедуру ""НастроитьВариантыОтчетов"" модуля ""ВариантыОтчетовПереопределяемый"".'; en = 'For more information, see ReportsOptionsOverridable.CustomizeReportsOptions.'; pl = 'Więcej - patrz procedurę ""CustomizeReportsOptions"" modułu "" see ReportsOptionsOverridable"".';de = 'Weitere Informationen finden Sie in der Prozedur „CustomizeReportsOptions“ des Moduls „ see ReportsOptionsOverridable“.';ro = 'Detalii - vezi procedura ""CustomizeReportsOptions"" a modulului "" see ReportsOptionsOverridable"".';tr = 'Daha fazla - bkz. ""CustomizeReportsOptions"" modülün "" see ReportsOptionsOverridable"" prosedürü'; es_ES = 'Más véase el procedimiento ""CustomizeReportsOptions"" del módulo "" see ReportsOptionsOverridable"".'");
		EndIf;
		WriteToLog(EventLogLevel.Information, ErrorText, OptionObject.Ref);
		
		Return False;
	EndIf;
	
	DCSettings = ?(ReportInfo <> Undefined, ReportInfo.DCSettings, Undefined);
	If TypeOf(DCSettings) <> Type("DataCompositionSettings") Then
		DCSettingsOption = DCSchema.SettingVariants.Find(OptionObject.VariantKey);
		If DCSettingsOption <> Undefined Then
			DCSettings = DCSettingsOption.Settings;
		EndIf;
	EndIf;
	
	// Read settings from option data.
	If TypeOf(DCSettings) <> Type("DataCompositionSettings")
		AND TypeOf(OptionObject) = Type("CatalogObject.ReportsOptions") Then
		Try
			DCSettings = OptionObject.Settings.Get();
		Except
			MessageTemplate = NStr("ru = 'Не удалось прочитать настройки пользовательского варианта отчета:
				|%1'; 
				|en = 'Cannot read settings of a custom report option:
				|%1.'; 
				|pl = 'Nie udało się odczytać ustawienia wariantu raportu użytkownika: 
				|%1';
				|de = 'Es war nicht möglich, die Einstellungen der benutzerdefinierten Variante des Berichts zu lesen:
				|%1';
				|ro = 'Eșec la citirea setărilor variantei de utilizator a raportului:
				|%1';
				|tr = 'Raporun kullanıcı seçeneğinin ayarları okunamadı: 
				|%1'; 
				|es_ES = 'No se ha podido leer los ajustes de la variante de usuario del informe:
				|%1'");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate,
				DetailErrorDescription(ErrorInfo()));
			WriteToLog(EventLogLevel.Error, MessageText, OptionObject.Ref);
			Return False; 
		EndTry;
	EndIf;
	
	// Last check.
	If TypeOf(DCSettings) <> Type("DataCompositionSettings") Then
		If TypeOf(OptionObject) = Type("CatalogObject.PredefinedReportsOptions")
			Or TypeOf(OptionObject) = Type("CatalogObject.PredefinedExtensionsReportsOptions") Then
			WriteToLog(EventLogLevel.Error, 
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Не удалось прочитать настройки предопределенного варианта отчета ""%1"".'; en = 'Cannot read settings of a predefined report option: %1.'; pl = 'Nie udało się odczytać ustawiania predefiniowanego wariantu raportu ""%1"".';de = 'Es war nicht möglich, die Einstellungen der vordefinierten Version des Berichts ""%1"" zu lesen.';ro = 'Eșec la citirea setărilor variantei predefinite a raportului ""%1"".';tr = 'Raporun ön tanımlanmış seçeneğinin ayarları okunamadı: %1'; es_ES = 'No se ha podido leer los ajustes de la variante predeterminada del informe ""%1"".'"), OptionObject.MeasurementsKey),
				OptionObject.Ref);
		EndIf;
		Return False;
	EndIf;
	
	NewSettingsHash = Common.CheckSumString(Common.ValueToXMLString(DCSettings));
	If CheckHash AND OptionObject.SettingsHash = NewSettingsHash Then
		Return False; // Settings did not change.
	EndIf;
	OptionObject.SettingsHash = NewSettingsHash;
	
	DCSettingsComposer = ReportObject.SettingsComposer;
	DCSettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(DCSchema));
	ReportsClientServer.LoadSettings(DCSettingsComposer, DCSettings);
	
	If FillFields Then
		// Transforming all settings of automatic grouping into field sets.
		//   See "DataCompositionAutoSelectedField", "DataCompositionAutoGroupField",
		//   "DataCompositionAutoOrderItem" in Syntax Assistant.
		DCSettingsComposer.ExpandAutoFields();
		FieldsForSearch.FieldDescriptions = GenerateFiledsPresentations(DCSettingsComposer);
	EndIf;
	
	If FillParametersAndFilters Then
		FieldsForSearch.FilterParameterDescriptions = GenerateParametersAndFiltersPresentations(DCSettingsComposer);
	EndIf;
	
	SetFieldsForSearch(OptionObject, FieldsForSearch);
	Return True;
	
EndFunction

Function FieldsForSearch(ReportOption) 
	
	Result = New Structure;
	Result.Insert("FieldDescriptions", "");
	Result.Insert("FilterParameterDescriptions", "");
	IsUserReportOption = (TypeOf(ReportOption) = Type("CatalogObject.ReportsOptions"));
	If Not IsUserReportOption Then
		Result.Insert("Keywords", "");
		Result.Insert("Details", "");
		Result.Insert("Description", "");
	EndIf;	
	
	If CurrentLanguage() = Metadata.DefaultLanguage Or IsUserReportOption Then
		FillPropertyValues(Result, ReportOption);
		Return Result;
	EndIf;	
	
	PresentationForLanguage = ReportOption.Presentations.Find(CurrentLanguage().LanguageCode, "LanguageCode");
	If PresentationForLanguage = Undefined Then
		Return Result;
	EndIf;	
	
	FillPropertyValues(Result, PresentationForLanguage);
	Return Result;
	
EndFunction

Procedure SetFieldsForSearch(ReportOption, FieldsForSearch)
	
	IsUserReportOption = (TypeOf(ReportOption) = Type("CatalogObject.ReportsOptions"));
	If CurrentLanguage() = Metadata.DefaultLanguage Or IsUserReportOption Then
		FillPropertyValues(ReportOption, FieldsForSearch);
		Return;
	EndIf;	
	
	PresentationForLanguage = ReportOption.Presentations.Find(CurrentLanguage().LanguageCode, "LanguageCode");
	If PresentationForLanguage = Undefined Then
		PresentationForLanguage = ReportOption.Presentations.Add();
	EndIf;	
	
	FillPropertyValues(PresentationForLanguage, FieldsForSearch);
	PresentationForLanguage.LanguageCode = CurrentLanguage().LanguageCode;
	
EndProcedure

Procedure StartPresentationsFilling(Val Mode, Val ResetCache)
	SetPresentationsFillingFlag(CurrentSessionDate(), ResetCache, Mode);
EndProcedure

Procedure SetPresentationsFillingFlag(Val Value, Val ResetCache, Val Mode)
	
	ParameterName = ReportsOptionsClientServer.FullSubsystemName() + ".PresentationsFilled";
	If Mode = "ConfigurationCommonData" Then
		Parameters = StandardSubsystemsServer.ApplicationParameter(ParameterName);
	Else
		Parameters = StandardSubsystemsServer.ExtensionParameter(ParameterName);
	EndIf;
	If Parameters = Undefined Then
		Parameters = New Map;
	ElsIf ResetCache Then
		Parameters.Clear();
	EndIf;
	Parameters[CurrentLanguage().LanguageCode] = Value;
	
	If Mode = "ConfigurationCommonData" Then
		StandardSubsystemsServer.SetApplicationParameter(ParameterName, Parameters);
	Else
		StandardSubsystemsServer.SetExtensionParameter(ParameterName, Parameters);
	EndIf;
	
EndProcedure

Function PresentationsFilled(Val Mode = "") Export
	
	ParameterName = ReportsOptionsClientServer.FullSubsystemName() + ".PresentationsFilled";
	If Mode = "ConfigurationCommonData" Then
		Parameters = StandardSubsystemsServer.ApplicationParameter(ParameterName);
	ElsIf Mode = "SeparatedConfigurationData" Then
		Parameters = StandardSubsystemsServer.ExtensionParameter(ParameterName);
	Else
		CommonResult = PresentationsFilled("ConfigurationCommonData");
		SeparatedResult = PresentationsFilled("SeparatedConfigurationData");
		If CommonResult = "NotFilled" Or SeparatedResult = "NotFilled" Then
			Return "NotFilled";
		ElsIf CommonResult = "ToFill" Or SeparatedResult = "ToFill" Then
			Return "ToFill";
		EndIf;
		Return "Filled";
	EndIf;
	If Parameters = Undefined Then
		Parameters = New Map;
	EndIf;
	
	Result = Parameters[CurrentLanguage().LanguageCode];
	If TypeOf(Result) = Type("Date") Then
		Return ?(CurrentSessionDate() - Result < 15 * 60, "ToFill", "NotFilled"); // timeout is 15 minutes
	EndIf;
	Return ?(Result = True, "Filled", "NotFilled");
	
EndFunction	

// Presentations of groups and fields from DCS.
Function GenerateFiledsPresentations(DCSettingsComposer)

	Result = StrSplit(String(DCSettingsComposer.Settings.Selection), ",", False);

	Collections = New Array;
	Collections.Add(DCSettingsComposer.Settings.Structure);
	Index = 0;
	While Index < Collections.Count() Do
		Collection = Collections[Index];
		Index = Index + 1;
		
		For Each Setting In Collection Do
			
			If TypeOf(Setting) = Type("DataCompositionNestedObjectSettings") Then
				If Not Setting.Use Then
					Continue;
				EndIf;
				Setting = Setting.Settings;
			EndIf;
			
			CommonClientServer.SupplementArray(Result, StrSplit(String(Setting.Selection), ",", False));
			
			If TypeOf(Setting) = Type("DataCompositionSettings") Then
				Collections.Add(Setting.Structure);
			ElsIf TypeOf(Setting) = Type("DataCompositionGroup") Then
				If Not Setting.Use Then
					Continue;
				EndIf;
				Collections.Add(Setting.Structure);
			ElsIf TypeOf(Setting) = Type("DataCompositionTable") Then
				If Not Setting.Use Then
					Continue;
				EndIf;
				Collections.Add(Setting.Rows);
			ElsIf TypeOf(Setting) = Type("DataCompositionTableGroup") Then
				If Not Setting.Use Then
					Continue;
				EndIf;
				Collections.Add(Setting.Structure);
			ElsIf TypeOf(Setting) = Type("DataCompositionChart") Then
				If Not Setting.Use Then
					Continue;
				EndIf;
				Collections.Add(Setting.Series);
				Collections.Add(Setting.Points);
			ElsIf TypeOf(Setting) = Type("DataCompositionChartGroup") Then
				If Not Setting.Use Then
					Continue;
				EndIf;
				Collections.Add(Setting.Structure);
			EndIf;
			
		EndDo;
		
	EndDo;
	
	Result = CommonClientServer.CollapseArray(Result);
	
	Return StrConcat(Result, Chars.LF);
EndFunction

// Presentations of parameters and filters from DCS.
Function GenerateParametersAndFiltersPresentations(DCSettingsComposer)
	Result = New Array;
	DCSettings = DCSettingsComposer.Settings;
	Modes = DataCompositionSettingsItemViewMode;
	
	For Each UserSetting In DCSettingsComposer.UserSettings.Items Do
		SettingType = TypeOf(UserSetting);
		If SettingType = Type("DataCompositionSettingsParameterValue") Then
			IsFilter = False;
		ElsIf SettingType = Type("DataCompositionFilterItem") Then
			IsFilter = True;
		Else
			Continue;
		EndIf;
		
		If UserSetting.ViewMode = Modes.Inaccessible Then
			Continue;
		EndIf;
		
		ID = UserSetting.UserSettingID;
		
		CommonSetting = ReportsClientServer.GetObjectByUserID(DCSettings, ID);
		If CommonSetting = Undefined Then
			Continue;
		EndIf;
		If UserSetting.ViewMode = Modes.Auto
			AND CommonSetting.ViewMode <> Modes.QuickAccess Then
			Continue;
		EndIf;
		
		PresentationsStructure = New Structure("Presentation, UserSettingPresentation", "", "");
		FillPropertyValues(PresentationsStructure, CommonSetting);
		If ValueIsFilled(PresentationsStructure.UserSettingPresentation) Then
			ItemHeader = PresentationsStructure.UserSettingPresentation;
		ElsIf ValueIsFilled(PresentationsStructure.Presentation) Then
			ItemHeader = PresentationsStructure.Presentation;
		Else
			AvailableSetting = ReportsClientServer.FindAvailableSetting(DCSettings, CommonSetting);
			If AvailableSetting <> Undefined AND ValueIsFilled(AvailableSetting.Title) Then
				ItemHeader = AvailableSetting.Title;
			Else
				ItemHeader = String(?(IsFilter, CommonSetting.LeftValue, CommonSetting.Parameter));
			EndIf;
		EndIf;
		
		ItemHeader = TrimAll(ItemHeader);
		If ItemHeader <> "" Then
			Result.Add(ItemHeader);
		EndIf;
		
	EndDo;
	
	Result = CommonClientServer.CollapseArray(Result);
	
	Return StrConcat(Result, Chars.LF);
EndFunction

// Extracts text information from a template.
Function ExtractTemplateText(ReportObject, TemplatesNames)
	ExtractedText = "";
	If TypeOf(TemplatesNames) = Type("String") Then
		TemplatesNames = StrSplit(TemplatesNames, ",", False);
	EndIf;
	AreasTexts = New Array;
	For Each TemplateName In TemplatesNames Do
		Template = ReportObject.GetTemplate(TrimAll(TemplateName));
		If TypeOf(Template) = Type("SpreadsheetDocument") Then
			Bottom = Template.TableHeight;
			Right = Template.TableWidth;
			CheckedCells = New Map;
			For ColumnNumber = 1 To Right Do
				For RowNumber = 1 To Bottom Do
					Cell = Template.Area(RowNumber, ColumnNumber, RowNumber, ColumnNumber);
					If CheckedCells[Cell.Name] <> Undefined Then
						Continue;
					EndIf;
					CheckedCells[Cell.Name] = True;
					If TypeOf(Cell) <> Type("SpreadsheetDocumentRange") Then
						Continue;
					EndIf;
					AreaText = TrimAll(Cell.Text);
					If IsBlankString(AreaText) Then
						Continue;
					EndIf;
					
					AreasTexts.Add(AreaText);
					
				EndDo;
			EndDo;
		ElsIf TypeOf(Template) = Type("TextDocument") Then
			AreasTexts.Add(TrimAll(Template.GetText()));
		EndIf;
	EndDo;
	Return StrConcat(AreasTexts, Chars.LF);
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Reducing the number of user settings.

// The function is called from the OnWrite option event. Some checks are performed before the call.
Function ReduceQuickSettingsNumber(OptionObject, ReportObject)
	
	If OptionObject = Undefined Then
		Return False; // No option in the base. Filling is not required.
	EndIf;
	
	// The composition schema that will be a basis for report execution.
	DCSchema = ReportObject.DataCompositionSchema;
	If DCSchema = Undefined Then
		Return False; // Report is not in DCS. Filling is not required.
	EndIf;
	
	// Read settings from option data.
	DCSettings = OptionObject.Settings.Get();
	If TypeOf(DCSettings) <> Type("DataCompositionSettings") Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Обнаружены пустые настройки пользовательского варианта ""%1"" отчета ""%2"".'; en = 'Blank settings are found. Report %2, custom option %1.'; pl = 'Wykryto puste ustawienia opcji użytkownika ""%1"" sprawozdania ""%2"".';de = 'Leere Einstellungen der Benutzeroption ""%1"" des Berichts ""%2"" werden erkannt.';ro = 'Sunt detectate setările goale ale opțiunii utilizator ""%1"" a raportului ""%2"".';tr = '""%1"" Seçeneğinin ""%2"" kullanıcı seçeneğinin boş ayarları algılandı.'; es_ES = 'Configuraciones vacías de la opción de usuario ""%1"" del informe ""%2"" se han detectado.'"), 
			OptionObject.VariantKey, OptionObject.Report);
		WriteToLog(EventLogLevel.Error, ErrorText, OptionObject.Ref);
		Return False; // An error occurred.
	EndIf;
	
	// The code describes the link between data composition settings and data composition schema.
	DCSettingsComposer = ReportObject.SettingsComposer;
	
	// Initialize the composer and its settings (Settings) with the source of available setting.
	DCSettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(DCSchema));
	
	// Import settings to the composer and clear user settings.
	ReportsClientServer.LoadSettings(DCSettingsComposer, DCSettings);
	
	OutputConditions = New Structure;
	OutputConditions.Insert("UserSettingsOnly", True);
	OutputConditions.Insert("QuickSettingsOnly",          True);
	OutputConditions.Insert("CurrentDCNodeID", Undefined);
	
	ReportSettings = ReportFormSettings(OptionObject.Report, OptionObject.VariantKey, ReportObject);
	
	Information = ReportsServer.AdvancedInformationOnSettings(DCSettingsComposer, ReportSettings, ReportObject, OutputConditions);
	QuickSettings = Information.UserSettings.Copy(New Structure("OutputAllowed, Quick", True, True));
	If QuickSettings.Count() <= 2 Then
		ReportsServer.ClearAdvancedInformationOnSettings(Information);
		Return False; // Reducing the number is not required.
	EndIf;
	
	ToExclude = QuickSettings.FindRows(New Structure("ItemsType", "StandardPeriod"));
	For Each TableRow In ToExclude Do
		QuickSettings.Delete(TableRow);
	EndDo;
	
	Spent = ToExclude.Count();
	For Each TableRow In QuickSettings Do
		If Spent < 2 Then
			Spent = Spent + 1;
			Continue;
		EndIf;
		TableRow.DCOptionSetting.ViewMode = DataCompositionSettingsItemViewMode.Normal;
	EndDo;
	
	OptionObject.Settings = New ValueStorage(DCSettingsComposer.Settings);
	ReportsServer.ClearAdvancedInformationOnSettings(Information);
	
	Return True;
EndFunction

Function ReportFormSettings(ReportRef, OptionKey, ReportObject) Export
	ReportSettings = ReportsClientServer.DefaultReportSettings();
	
	ReportsWithSettings = ReportsOptionsCached.Parameters().ReportsWithSettings;
	If ReportsWithSettings.Find(ReportRef) = Undefined 
		AND (ReportObject = Undefined Or Metadata.Reports.Contains(ReportObject.Metadata()))Then
		Return ReportSettings;
	EndIf;
	
	If ReportObject = Undefined Then
		Attachment = AttachReportObject(ReportRef, False);
		If Attachment.Success Then
			ReportObject = Attachment.Object;
		Else
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось получить настройки отчета ""%1"":'; en = 'Failed to get settings for report %1:'; pl = 'Nie udało się otrzymać ustawienia raportu ""%1"":';de = 'Die Berichtseinstellungen konnten nicht übernommen werden ""%1"":';ro = 'Eșec la obținerea setării raportului ""%1"":';tr = '""%1"" raporun ayarları elde edilemedi: '; es_ES = 'No se puede recibir los ajustes del informe ""%1"".'") + Chars.LF + Attachment.ErrorText,
				ReportRef);
			WriteToLog(EventLogLevel.Information, Text, ReportRef);
			Return ReportSettings;
		EndIf;
	EndIf;
	
	Try
		ReportObject.DefineFormSettings(Undefined, OptionKey, ReportSettings);
	Except
		ReportSettings = ReportsClientServer.DefaultReportSettings();
	EndTry;
	
	If Not GlobalSettings().EditOptionsAllowed Then
		ReportSettings.EditOptionsAllowed = False;
	EndIf;
	
	Return ReportSettings;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Search.

// Whether it is possible to index report schema content.
Function SharedDataIndexingAllowed()
	Return Not Common.DataSeparationEnabled();
EndFunction

Function ReportOptionTable(Val SearchParameters) Export
	
	Return FindReportsOptions(SearchParameters, True).ValueTable;
	
EndFunction	

// Returns the list of report options according to specified parameters.
// When searching by the SearchString substring, it also highlights found places in report names and details.
//
// Parameters:
//   SearchParameters - Structure - with the following properties:
//     * SearchString  - String - Optional. One or several words that are contained in the titles 
//                                and details of the required reports.
//     * Subsystems    - Array from CatalogRef.MetadataObjectIDs - Optional.
//                       Search only among report options that refer to specified subsystems.
//     * ExactFilterBySubsystems - Boolean - optional. If True, output results from the specified subsystems only.
//                       Otherwise, offer relevant search results from other subsystems as well.
//     * Reports        - Array from CatalogRef.ReportsOptions - optional. Search only among specified reports.
//     * ReportsTypes   - Array from EnumRef.ReportTypes - optional. Search only among specified 
//                       report types.
//     * DeletionMark - Boolean - optional. If False, all report options are returned.
//                       If True or not specified, only reports not marked for deletion are returned.
//     * OnlyPersonal  - Boolean - optional. If False or not specified, all report options are 
//                       retuned to administrator, and users get only available for them report options.
//                       If True, administrator also gets personal report options as a user without 
//                       full rights.
//   GetSummaryTable - Boolean - optional. If True, the ValueTable property is populated in the return value.
//   GetHighlight - Boolean - optional. If True, the following properties are populated in return value
//                       OptionsHighlight, Subsystems, SubsystemsHighlight, OptionsLinkedWithSubsystems, ParentsLinkedWithOptions.
//
// Returns:
//   Structure - with the following properties:
//       * References - Array from CatalogRef.ReportsOptions -
//           Report options whose names and details contain all words being searched.
//       * OptionsHighlight - Map - highlighting found words (if SearchString is specified).
//           ** Key - CatalogRef.ReportsOptions.
//           ** Value - Structure - with the following properties:
//               *** Ref - CatalogRef.ReportsOptions.
//               *** FieldDescriptions                    - String.
//               *** FilterAndParameterDescriptions       - String.
//               *** Keywords                        - String.
//               *** Details                             - String.
//               *** UserSettingsDescriptions - String.
//               *** WhereFound                           - Structure:
//                   **** FieldDescriptions                    - Number.
//                   **** FilterAndParameterDescriptions       - Number.
//                   **** Keywords                        - Number.
//                   **** Details                             - Number.
//                   **** UserSettingsDescriptions - Number.
//       * Subsystems - Array from CatalogRef.MetadataObjectIDs -
//           Filled in with subsystems whose names contain all words to search for.
//           All nested report options must be displayed for such subsystems.
//       * SubsystemsHighlight - Map - highlighting found words (if SearchString is specified).
//           ** Key - CatalogRef.ReportsOptions.
//           ** Value - Structure - with the following properties:
//               *** Ref - CatalogRef.MetadataObjectIDs.
//               *** SubsystemDescription - String.
//       * OptionsLinkedWithSubsystems - Map - report options and their subsystems.
//           Filled in when some words are found in option data, and other words are found in descriptions of its subsystems.
//           In this case, an option must be displayed in found subsystems only (it must not be displayed in other subsystems).
//           Applied in the report panel.
//           ** Key - CatalogRef.ReportsOptions - an option.
//           ** Value - Array From CatalogRef.MetadataObjectIDs - Subsystem.
//       * ValueTable - ValueTable - it is populated if SearchParameters.GetSummaryTable is specified:
//           ** Ref - CatalogRef.ReportsOptions
//           ** Parent - CatalogRef.ReportsOptions
//           ** Description - String.
//           ** AvailableToAuthorOnly - Boolean
//           ** Author - CatalogRef.Users, CatalogRef.ExternalUsers
//           ** AuthorPresentation - String
//           ** Report - CalalogRef.MetadataObjectsIDs, CatalogRef.ExtensionObjectsIDs,
//                      String, CatalogRef.AdditionalReportsAndDataProcessors
//           ** ReportName - String
//           ** VariantKey - String
//           ** ReportType - EnumRef.ReportTypes
//           ** User - Boolean
//           ** PredefinedOption - CatalogRef.PredefinedReportsOptions, CatalogRef.PredefinedExtensionsReportsOptions
//           ** FilterAndParameterDescriptions       - String
//           ** FieldDescriptions - String
//           ** Keywords - String
//           ** Details - String
//           ** Subsystem
//           ** SubsystemDescription - String
//           ** UserSettingKey - String
//           ** UserSettingPresentation - String
//           ** DeletionMark - Boolean
//
Function FindReportsOptions(Val SearchParameters, Val GetSummaryTable = False, Val GetHighlight = False) Export
	
	If PresentationsFilled() = "NotFilled" Then
		Settings = SettingsUpdateParameters();
		Settings.Deferred = True;
		Refresh(Settings);
	EndIf;	
	
	HasSearchString = SearchParameters.Property("SearchString") AND ValueIsFilled(SearchParameters.SearchString);
	HasFilterByReports = SearchParameters.Property("Reports") AND ValueIsFilled(SearchParameters.Reports);
	HasFilterBySubsystems = SearchParameters.Property("Subsystems") AND ValueIsFilled(SearchParameters.Subsystems);
	ExactFilterBySubsystems = HasFilterBySubsystems
		AND CommonClientServer.StructureProperty(SearchParameters, "ExactFilterBySubsystems", True);
	HasFilterByReportTypes = SearchParameters.Property("ReportTypes") AND ValueIsFilled(SearchParameters.ReportTypes);
	
	Result = New Structure;
	Result.Insert("References", New Array);
	Result.Insert("OptionsHighlight", New Map);
	Result.Insert("Subsystems", New Array);
	Result.Insert("SubsystemsHighlight", New Map);
	Result.Insert("OptionsLinkedWithSubsystems", New Map);
	Result.Insert("ParentsLinkedWithOptions", New Array);
	If GetSummaryTable Then
		Result.Insert("ValueTable", New ValueTable);
	EndIf;
	If Not HasFilterBySubsystems AND Not HasSearchString AND Not HasFilterByReportTypes AND Not HasFilterByReports Then
		Return Result;
	EndIf;
	
	HasFilterByVisibility = HasFilterBySubsystems AND SearchParameters.Property("OnlyItemsVisibleInReportPanel") 
		AND SearchParameters.OnlyItemsVisibleInReportPanel = True;
	OnlyItemsNotMarkedForDeletion = ?(SearchParameters.Property("DeletionMark"), SearchParameters.DeletionMark, True);
	If HasFilterByReports Then
		FilterByReports = SearchParameters.Reports;
		SearchParameters.Insert("DIsabledApplicationOptions", DisabledReportOptions(FilterByReports));
	Else
		SearchParameters.Insert("DIsabledApplicationOptions", ReportsOptionsCached.DIsabledApplicationOptions());
		SearchParameters.Insert("UserReports", CurrentUserReports());
		FilterByReports = SearchParameters.UserReports;
	EndIf;
	
	HasRightToReadAuthors = AccessRight("Read", Metadata.Catalogs.Users);
	CurrentUser = Users.AuthorizedUser();
	ShowPersonalReportsOptionsByOtherAuthors = Users.IsFullUser();
	If SearchParameters.Property("OnlyPersonal") Then
		ShowPersonalReportsOptionsByOtherAuthors = ShowPersonalReportsOptionsByOtherAuthors AND SearchParameters.OnlyPersonal;
	EndIf;	
	
	Query = New Query;
	Query.SetParameter("CurrentUser",          CurrentUser);
	Query.SetParameter("UserReports",           FilterByReports);
	Query.SetParameter("DIsabledApplicationOptions", SearchParameters.DIsabledApplicationOptions);
	Query.SetParameter("ExtensionsVersion",             SessionParameters.ExtensionsVersion);
	Query.SetParameter("NoFilterByDeletionMark",   NOT OnlyItemsNotMarkedForDeletion);
	Query.SetParameter("HasRightToReadAuthors",       HasRightToReadAuthors);
	Query.SetParameter("HasFilterByReportTypes",      HasFilterByReportTypes);
	Query.SetParameter("HasFilterBySubsystems",       HasFilterBySubsystems);
	Query.SetParameter("ReportTypes",                  ?(HasFilterByReportTypes, SearchParameters.ReportTypes, New Array));
	Query.SetParameter("DontGetDetails",           Not HasSearchString AND Not GetSummaryTable);
	Query.SetParameter("GetSummaryTable",      GetSummaryTable);
	Query.SetParameter("DesktopDescription",    NStr("ru = 'Начальная страница'; en = 'Home page'; pl = 'Strona podstawowa';de = 'Startseite';ro = 'Pagina principală';tr = 'Ana sayfa'; es_ES = 'Página principal'"));
	Query.SetParameter("ShowPersonalReportsOptionsByOtherAuthors", ShowPersonalReportsOptionsByOtherAuthors);
	Query.SetParameter("IsMainLanguage",              CurrentLanguage() = Metadata.DefaultLanguage);
	Query.SetParameter("LanguageCode",                     CurrentLanguage().LanguageCode);
	
	If HasFilterBySubsystems Or HasSearchString Then
		QueryText =
		"SELECT ALLOWED
		|	ReportsOptions.Ref AS Ref,
		|	ReportsOptions.Parent AS Parent,
		|	CASE
		|		WHEN &HasRightToReadAuthors
		|				AND &GetSummaryTable
		|			THEN ReportsOptions.Author
		|		ELSE UNDEFINED
		|	END AS Author,
		|	ReportsOptions.AvailableToAuthorOnly AS AvailableToAuthorOnly,
		|	ReportsOptions.Report AS Report,
		|	ReportsOptions.VariantKey AS VariantKey,
		|	ReportsOptions.ReportType AS ReportType,
		|	ReportsOptions.Custom AS Custom,
		|	ReportsOptions.PredefinedVariant AS PredefinedVariant,
		|	CASE
		|		WHEN ReportsOptions.Custom
		|			THEN ReportsOptions.InteractiveSetDeletionMark
		|		WHEN ReportsOptions.ReportType = VALUE(Enum.ReportTypes.Extension)
		|			THEN AvailableExtensionOptions.Variant IS NULL
		|		ELSE ISNULL(ConfigurationOptions.DeletionMark, ReportsOptions.DeletionMark)
		|	END AS DeletionMark,
		|	ReportsOptions.VisibleByDefault AS VisibleByDefault,
		|	CASE
		|		WHEN &DontGetDetails
		|			THEN UNDEFINED
		|		WHEN ReportsOptions.Custom
		|				OR ReportsOptions.PredefinedVariant IN (UNDEFINED, VALUE(Catalog.PredefinedReportsOptions.EmptyRef), VALUE(Catalog.PredefinedExtensionsReportsOptions.EmptyRef))
		|			THEN CAST(ISNULL(OptionPresentations.Description, ReportsOptions.Description) AS STRING(1000))
		|		WHEN &IsMainLanguage
		|			THEN CAST(ISNULL(ISNULL(ConfigurationOptions.Description, ExtensionOptions.Description), ReportsOptions.Description) AS STRING(1000))
		|		ELSE CAST(ISNULL(ISNULL(PresentationsFromConfiguration.Description, PresentationsFromExtensions.Description), ReportsOptions.Description) AS STRING(1000))
		|	END AS OptionDescription,
		|	CASE
		|		WHEN &DontGetDetails
		|			THEN UNDEFINED
		|		WHEN &IsMainLanguage
		|				AND SUBSTRING(ReportsOptions.FieldDescriptions, 1, 1) = """"
		|			THEN CAST(ISNULL(ConfigurationOptions.FieldDescriptions, ExtensionOptions.FieldDescriptions) AS STRING(1000))
		|		WHEN NOT &IsMainLanguage
		|				AND SUBSTRING(ReportsOptions.FieldDescriptions, 1, 1) = """"
		|			THEN CAST(ISNULL(PresentationsFromConfiguration.FieldDescriptions, PresentationsFromExtensions.FieldDescriptions) AS STRING(1000))
		|		ELSE CAST(ReportsOptions.FieldDescriptions AS STRING(1000))
		|	END AS FieldDescriptions,
		|	CASE
		|		WHEN &DontGetDetails
		|			THEN UNDEFINED
		|		WHEN &IsMainLanguage
		|				AND SUBSTRING(ReportsOptions.FilterParameterDescriptions, 1, 1) = """"
		|			THEN CAST(ISNULL(ConfigurationOptions.FilterParameterDescriptions, ExtensionOptions.FilterParameterDescriptions) AS STRING(1000))
		|		WHEN NOT &IsMainLanguage
		|				AND SUBSTRING(ReportsOptions.FilterParameterDescriptions, 1, 1) = """"
		|			THEN CAST(ISNULL(PresentationsFromConfiguration.FilterParameterDescriptions, PresentationsFromExtensions.FilterParameterDescriptions) AS STRING(1000))
		|		ELSE CAST(ReportsOptions.FilterParameterDescriptions AS STRING(1000))
		|	END AS FilterParameterDescriptions,
		|	CASE
		|		WHEN &DontGetDetails
		|			THEN UNDEFINED
		|		WHEN &IsMainLanguage
		|				AND SUBSTRING(ReportsOptions.Keywords, 1, 1) = """"
		|			THEN CAST(ISNULL(ConfigurationOptions.Keywords, ExtensionOptions.Keywords) AS STRING(1000))
		|		WHEN NOT &IsMainLanguage
		|				AND SUBSTRING(ReportsOptions.Keywords, 1, 1) = """"
		|			THEN CAST(ISNULL(PresentationsFromConfiguration.Keywords, PresentationsFromExtensions.Keywords) AS STRING(1000))
		|		ELSE CAST(ReportsOptions.Keywords AS STRING(1000))
		|	END AS Keywords,
		|	CASE
		|		WHEN &DontGetDetails
		|			THEN UNDEFINED
		|		WHEN ReportsOptions.Custom
		|				OR ReportsOptions.PredefinedVariant IN (UNDEFINED, VALUE(Catalog.PredefinedReportsOptions.EmptyRef), VALUE(Catalog.PredefinedExtensionsReportsOptions.EmptyRef))
		|			THEN CAST(ISNULL(OptionPresentations.Details, ReportsOptions.Details) AS STRING(1000))
		|		WHEN &IsMainLanguage
		|				AND SUBSTRING(ReportsOptions.Details, 1, 1) = """"
		|			THEN CAST(ISNULL(ConfigurationOptions.Details, ExtensionOptions.Details) AS STRING(1000))
		|		ELSE CAST(ISNULL(OptionPresentations.Details, ReportsOptions.Details) AS STRING(1000))
		|	END AS Details
		|INTO Variants
		|FROM
		|	Catalog.ReportsOptions AS ReportsOptions
		|		LEFT JOIN InformationRegister.PredefinedExtensionsVersionsReportsOptions AS AvailableExtensionOptions
		|		ON ReportsOptions.PredefinedVariant = AvailableExtensionOptions.Variant
		|			AND (AvailableExtensionOptions.ExtensionsVersion = &ExtensionsVersion)
		|		LEFT JOIN Catalog.PredefinedReportsOptions AS ConfigurationOptions
		|		ON ReportsOptions.PredefinedVariant = ConfigurationOptions.Ref
		|		LEFT JOIN Catalog.PredefinedExtensionsReportsOptions AS ExtensionOptions
		|		ON ReportsOptions.PredefinedVariant = ExtensionOptions.Ref
		|		LEFT JOIN Catalog.ReportsOptions.Presentations AS OptionPresentations
		|		ON ReportsOptions.Ref = OptionPresentations.Ref
		|			AND (OptionPresentations.LanguageCode = &LanguageCode)
		|		LEFT JOIN Catalog.PredefinedReportsOptions.Presentations AS PresentationsFromConfiguration
		|		ON ReportsOptions.PredefinedVariant = PresentationsFromConfiguration.Ref
		|			AND (PresentationsFromConfiguration.LanguageCode = &LanguageCode)
		|		LEFT JOIN Catalog.PredefinedExtensionsReportsOptions.Presentations AS PresentationsFromExtensions
		|		ON ReportsOptions.PredefinedVariant = PresentationsFromExtensions.Ref
		|			AND (PresentationsFromExtensions.LanguageCode = &LanguageCode)
		|WHERE
		|	(NOT &HasFilterByReportTypes
		|			OR ReportsOptions.ReportType IN (&ReportTypes))
		|	AND ReportsOptions.Report IN(&UserReports)
		|	AND NOT ReportsOptions.PredefinedVariant IN (&DIsabledApplicationOptions)
		|	AND (&ShowPersonalReportsOptionsByOtherAuthors
		|			OR ReportsOptions.AvailableToAuthorOnly = FALSE
		|			OR ReportsOptions.Author = &CurrentUser)
		|
		|INDEX BY
		|	Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	ReportsOptions.Ref AS Ref,
		|	ConfigurationPlacement.Subsystem AS Subsystem,
		|	CASE
		|		WHEN &DontGetDetails
		|			THEN UNDEFINED
		|		WHEN ConfigurationPlacement.Subsystem.FullName = ""Subsystems""
		|			THEN &DesktopDescription
		|		ELSE ConfigurationPlacement.Subsystem.Synonym
		|	END AS SubsystemDescription
		|INTO PlacementPredefined
		|FROM
		|	Variants AS ReportsOptions
		|		INNER JOIN Catalog.PredefinedReportsOptions.Placement AS ConfigurationPlacement
		|		ON (ReportsOptions.Custom = FALSE)
		|			AND (&ShowPersonalReportsOptionsByOtherAuthors
		|				OR ReportsOptions.AvailableToAuthorOnly = FALSE
		|				OR ReportsOptions.Author = &CurrentUser)
		|			AND (ReportsOptions.DeletionMark = FALSE
		|				OR &NoFilterByDeletionMark)
		|			AND ReportsOptions.PredefinedVariant = ConfigurationPlacement.Ref
		|			AND (NOT &HasFilterBySubsystems
		|				OR ConfigurationPlacement.Subsystem IN (&ReportsSubsystems))
		|
		|UNION ALL
		|
		|SELECT
		|	ReportsOptions.Ref,
		|	ExtensionsPlacement.Subsystem,
		|	CASE
		|		WHEN &DontGetDetails
		|			THEN UNDEFINED
		|		WHEN ExtensionsPlacement.Subsystem.FullName = ""Subsystems""
		|			THEN &DesktopDescription
		|		ELSE ExtensionsPlacement.Subsystem.Synonym
		|	END
		|FROM
		|	Variants AS ReportsOptions
		|		INNER JOIN Catalog.PredefinedExtensionsReportsOptions.Placement AS ExtensionsPlacement
		|		ON (ReportsOptions.Custom = FALSE)
		|			AND ReportsOptions.PredefinedVariant = ExtensionsPlacement.Ref
		|			AND (NOT &HasFilterBySubsystems
		|				OR ExtensionsPlacement.Subsystem IN (&ReportsSubsystems))
		|
		|INDEX BY
		|	Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	ReportsOptions.Ref AS Ref,
		|	OptionsPlacement.Use AS Use,
		|	OptionsPlacement.Subsystem AS Subsystem,
		|	CASE
		|		WHEN &DontGetDetails
		|			THEN UNDEFINED
		|		WHEN OptionsPlacement.Subsystem.FullName = ""Subsystems""
		|			THEN &DesktopDescription
		|		ELSE OptionsPlacement.Subsystem.Synonym
		|	END AS SubsystemDescription
		|INTO OptionsPlacement
		|FROM
		|	Variants AS ReportsOptions
		|		INNER JOIN Catalog.ReportsOptions.Placement AS OptionsPlacement
		|		ON (ReportsOptions.DeletionMark = FALSE
		|				OR &NoFilterByDeletionMark)
		|			AND ReportsOptions.Ref = OptionsPlacement.Ref
		|			AND (NOT &HasFilterBySubsystems
		|				OR OptionsPlacement.Subsystem IN (&ReportsSubsystems))
		|
		|INDEX BY
		|	Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ISNULL(OptionsPlacement.Ref, PlacementPredefined.Ref) AS Ref,
		|	ISNULL(OptionsPlacement.Subsystem, PlacementPredefined.Subsystem) AS Subsystem,
		|	ISNULL(OptionsPlacement.SubsystemDescription, PlacementPredefined.SubsystemDescription) AS SubsystemDescription,
		|	ISNULL(OptionsPlacement.Use, TRUE) AS Use,
		|	CASE
		|		WHEN OptionsPlacement.Ref IS NULL
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS ThisIsDeveloperSettingItem
		|INTO PlacementAll
		|FROM
		|	PlacementPredefined AS PlacementPredefined
		|		FULL JOIN OptionsPlacement AS OptionsPlacement
		|		ON (OptionsPlacement.Ref = PlacementPredefined.Ref)
		|			AND (OptionsPlacement.Subsystem = PlacementPredefined.Subsystem)
		|WHERE
		|	ISNULL(OptionsPlacement.Use, TRUE)
		|
		|INDEX BY
		|	Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED DISTINCT
		|	PlacementAll.Ref AS Ref,
		|	PlacementAll.Subsystem AS Subsystem,
		|	PlacementAll.SubsystemDescription AS SubsystemDescription
		|INTO PlacementVisible
		|FROM
		|	PlacementAll AS PlacementAll
		|		LEFT JOIN InformationRegister.ReportOptionsSettings AS PersonalSettings
		|		ON PlacementAll.Subsystem = PersonalSettings.Subsystem
		|			AND PlacementAll.Ref = PersonalSettings.Variant
		|			AND (PersonalSettings.User = &CurrentUser)
		|		LEFT JOIN Variants AS Variants
		|		ON PlacementAll.Ref = Variants.Ref
		|WHERE
		|	ISNULL(PersonalSettings.Visible, Variants.VisibleByDefault)
		|	AND (Variants.DeletionMark = FALSE
		|			OR &NoFilterByDeletionMark)
		|
		|INDEX BY
		|	Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	ReportsOptions.Ref AS Ref,
		|	ReportsOptions.Parent AS Parent,
		|	ReportsOptions.OptionDescription AS OptionDescription,
		|	ReportsOptions.AvailableToAuthorOnly AS AvailableToAuthorOnly,
		|	CASE
		|		WHEN &HasRightToReadAuthors
		|				AND &GetSummaryTable
		|			THEN ReportsOptions.Author
		|		ELSE UNDEFINED
		|	END AS Author,
		|	CASE
		|		WHEN &HasRightToReadAuthors
		|				AND &GetSummaryTable
		|			THEN ISNULL(ReportsOptions.Author.Description, """")
		|		ELSE """"
		|	END AS AuthorPresentation,
		|	ReportsOptions.Report AS Report,
		|	CASE
		|		WHEN &GetSummaryTable
		|			THEN ReportsOptions.Report.Name
		|		ELSE UNDEFINED
		|	END AS ReportName,
		|	ReportsOptions.VariantKey AS VariantKey,
		|	ReportsOptions.ReportType AS ReportType,
		|	ReportsOptions.Custom AS Custom,
		|	ReportsOptions.PredefinedVariant AS PredefinedVariant,
		|	ReportsOptions.FilterParameterDescriptions AS FilterParameterDescriptions,
		|	ReportsOptions.FieldDescriptions AS FieldDescriptions,
		|	ReportsOptions.Keywords AS Keywords,
		|	ReportsOptions.Details AS Details,
		|	Placement.Subsystem AS Subsystem,
		|	Placement.SubsystemDescription AS SubsystemDescription,
		|	UNDEFINED AS UserSettingKey,
		|	UNDEFINED AS UserSettingPresentation,
		|	ReportsOptions.DeletionMark AS DeletionMark
		|FROM
		|	Variants AS ReportsOptions
		|		INNER JOIN PlacementVisible AS Placement
		|		ON ReportsOptions.Ref = Placement.Ref
		|WHERE
		|	(ReportsOptions.DeletionMark = FALSE
		|			OR &NoFilterByDeletionMark)
		|	AND &OptionsAndSubsystemsBySearchString
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	UserSettings.Variant,
		|	Variants.Parent,
		|	UNDEFINED,
		|	UNDEFINED,
		|	UNDEFINED,
		|	UNDEFINED,
		|	UNDEFINED,
		|	UNDEFINED,
		|	UNDEFINED,
		|	UNDEFINED,
		|	UNDEFINED,
		|	UNDEFINED,
		|	UNDEFINED,
		|	UNDEFINED,
		|	UNDEFINED,
		|	UNDEFINED,
		|	UNDEFINED,
		|	UNDEFINED,
		|	UserSettings.UserSettingKey,
		|	UserSettings.Description,
		|	UNDEFINED
		|FROM
		|	Variants AS Variants
		|		INNER JOIN Catalog.UserReportSettings AS UserSettings
		|		ON Variants.Ref = UserSettings.Variant
		|WHERE
		|	UserSettings.User = &CurrentUser
		|	AND &UserSettingsBySearchString
		|	AND (UserSettings.DeletionMark = FALSE
		|			OR &NoFilterByDeletionMark)
		|	AND (Variants.DeletionMark = FALSE
		|			OR &NoFilterByDeletionMark)";
		
		If Not HasFilterByVisibility Then
			// Deleting a temporary table for a filter by visibility.
			DeleteTemporaryTable(QueryText, "PlacementVisible");
			// Substituting a name of the temporary table to select from.
			QueryText = StrReplace(QueryText, "PlacementVisible", "PlacementAll");
		EndIf;
		
		If HasFilterBySubsystems Then
			If TypeOf(SearchParameters.Subsystems) = Type("Array") Then
				ReportsSubsystems = SearchParameters.Subsystems;
			Else
				ReportsSubsystems = New Array;
				ReportsSubsystems.Add(SearchParameters.Subsystems);
			EndIf;
		Else
			ReportsSubsystems = New Array;
		EndIf;
		Query.SetParameter("ReportsSubsystems", ReportsSubsystems);
		
		If HasSearchString AND Not ExactFilterBySubsystems Then
			// Information about placement is additional for the search, not the key one.
			If HasFilterByVisibility Then
				QueryText = StrReplace(QueryText,
					"INNER JOIN PlacementVisible AS Placement",
					"LEFT JOIN PlacementVisible AS Placement");
			Else
				QueryText = StrReplace(QueryText,
					"INNER JOIN PlacementAll AS Placement",
					"LEFT JOIN PlacementAll AS Placement");
			EndIf;	
		EndIf;
		
		SearchWords = PrepareSearchConditionByRow(Query, QueryText, HasSearchString, SearchParameters, 
			HasRightToReadAuthors);
	Else
		PrepareReportsQueryWithSimpleFilters(Query, QueryText, HasFilterByReportTypes, SearchParameters);
	EndIf;
	
	Query.Text = QueryText;
	SourceTable = Query.Execute().Unload();
	
	If GetSummaryTable Then
		Result.ValueTable = SourceTable;
	EndIf;
	If SourceTable.Count() = 0 Then
		Return Result;
	EndIf;
	
	If HasSearchString AND GetHighlight Then
		GenerateSearchResults(SearchWords, SourceTable, Result);
	Else	
		GenerateRefsList(SourceTable, Result.References);
	EndIf;
	
	Return Result;
	
EndFunction

Function PrepareSearchConditionByRow(Val Query, QueryText, Val HasSearchString, Val SearchParameters, Val AuthorsReadRight)
	
	If HasSearchString Then
		SearchString = Upper(TrimAll(SearchParameters.SearchString));
		SearchWords = ReportsOptionsClientServer.ParseSearchStringIntoWordArray(SearchString);
		SearchTemplates = New Array;
		For WordNumber = 1 To SearchWords.Count() Do
			Word = SearchWords[WordNumber - 1];
			WordName = "Word" + Format(WordNumber, "NG=");
			Query.SetParameter(WordName, "%" + Word + "%");
			SearchTemplates.Add("<TableName.FieldName> LIKE &" + WordName);
		EndDo;
		SearchTemplate = StrConcat(SearchTemplates, " OR "); // it is not localised (query text fragment)
		
		SearchTexts = New Array;
		SearchTexts.Add("ReportsOptions.OptionDescription"); 
		SearchTexts.Add("Placement.SubsystemDescription"); 
		SearchTexts.Add("ReportsOptions.FieldDescriptions"); 
		SearchTexts.Add("ReportsOptions.FilterParameterDescriptions"); 
		SearchTexts.Add("ReportsOptions.Details"); 
		SearchTexts.Add("ReportsOptions.Keywords"); 
		If AuthorsReadRight Then
			SearchTexts.Add("ReportsOptions.Author.Description"); 
		EndIf;
		
		For Index = 0 To SearchTexts.Count() - 1 Do
			SearchTexts[Index] = StrReplace(SearchTemplate, "<TableName.FieldName>", SearchTexts[Index]);
		EndDo;
		OptionsAndSubsystemsBySearchString = "(" + StrConcat(SearchTexts, " OR ") + ")"; // it is not localised (query text fragment)
		QueryText = StrReplace(QueryText, "&OptionsAndSubsystemsBySearchString", OptionsAndSubsystemsBySearchString);
		
		UserSettingsBySearchString = "(" + StrReplace(SearchTemplate, "<TableName.FieldName>", "UserSettings.Description") + ")";
		QueryText = StrReplace(QueryText, "&UserSettingsBySearchString", UserSettingsBySearchString);
		
	Else
		// Deleting a filter to search in data of report options subsystems.
		QueryText = StrReplace(QueryText, "AND &OptionsAndSubsystemsBySearchString", "");
		// Deleting a table to search in user settings.
		StartOfSelectionFromTable = (
		"UNION ALL
		|
		|SELECT DISTINCT
		|	UserSettings.Variant,");
		QueryText = TrimR(Left(QueryText, StrFind(QueryText, StartOfSelectionFromTable) - 1));
	EndIf;
	Return SearchWords;

EndFunction

Procedure PrepareReportsQueryWithSimpleFilters(Val Query, QueryText, Val HasFilterByReportTypes, Val SearchParameters)
	
	QueryText = "
	|SELECT ALLOWED
	|	ReportsOptions.Ref AS Ref,
	|	ReportsOptions.Parent AS Parent,
	|	CASE
	|		WHEN &DontGetDetails
	|			THEN UNDEFINED
	|		WHEN &IsMainLanguage
	|			THEN CAST(ISNULL(ISNULL(ConfigurationOptions.Description, ExtensionOptions.Description), ReportsOptions.Description) AS STRING(1000))
	|		ELSE CAST(ISNULL(ISNULL(PresentationsFromConfiguration.Description, PresentationsFromExtensions.Description), UserOptionsPresentations.Description) AS STRING(1000))
	|	END AS Description,
	|	ReportsOptions.AvailableToAuthorOnly AS AvailableToAuthorOnly,
	|	CASE
	|		WHEN &HasRightToReadAuthors
	|				AND &GetSummaryTable
	|			THEN ReportsOptions.Author
	|		ELSE UNDEFINED
	|	END AS Author,
	|	ReportsOptions.VisibleByDefault,
	|	CASE
	|		WHEN &HasRightToReadAuthors
	|				AND &GetSummaryTable
	|			THEN PRESENTATION(ReportsOptions.Author)
	|		ELSE """"
	|	END AS AuthorPresentation,
	|	ReportsOptions.Report AS Report,
	|	CASE
	|		WHEN &GetSummaryTable
	|			THEN ReportsOptions.Report.Name
	|		ELSE UNDEFINED
	|	END AS ReportName,
	|	ReportsOptions.VariantKey AS VariantKey,
	|	ReportsOptions.ReportType AS ReportType,
	|	ReportsOptions.Custom AS Custom,
	|	ReportsOptions.PredefinedVariant AS PredefinedVariant,
	|	ReportsOptions.FilterParameterDescriptions AS FilterParameterDescriptions,
	|	ReportsOptions.FieldDescriptions AS FieldDescriptions,
	|	ReportsOptions.Keywords AS Keywords,
	|	CASE
	|		WHEN &DontGetDetails
	|			THEN UNDEFINED
	|		WHEN &IsMainLanguage AND SUBSTRING(ReportsOptions.Details, 1, 1) <> """"
	|			THEN CAST(ReportsOptions.Details AS STRING(1000))
	|		WHEN &IsMainLanguage
	|			THEN CAST(ISNULL(ConfigurationOptions.Details, ExtensionOptions.Details) AS STRING(1000))
	|		WHEN NOT &IsMainLanguage AND SUBSTRING(ISNULL(UserOptionsPresentations.Details, """"), 1, 1) <> """"
	|			THEN CAST(UserOptionsPresentations.Details AS STRING(1000))
	|		WHEN NOT &IsMainLanguage
	|			THEN CAST(ISNULL(PresentationsFromConfiguration.Details, PresentationsFromExtensions.Details) AS STRING(1000))
	|		ELSE CAST("""" AS STRING(1000))
	|	END AS Details,
	|	UNDEFINED AS Subsystem,
	|	"""" AS SubsystemDescription,
	|	UNDEFINED AS UserSettingKey,
	|	UNDEFINED AS UserSettingPresentation,
	|	ReportsOptions.DeletionMark AS DeletionMark
	|FROM
	|	Catalog.ReportsOptions AS ReportsOptions
	|	LEFT JOIN Catalog.PredefinedReportsOptions AS ConfigurationOptions
	|		ON ReportsOptions.PredefinedVariant = ConfigurationOptions.Ref
	|	LEFT JOIN Catalog.PredefinedExtensionsReportsOptions AS ExtensionOptions
	|		ON ReportsOptions.PredefinedVariant = ExtensionOptions.Ref
	|	LEFT JOIN Catalog.ReportsOptions.Presentations AS UserOptionsPresentations
	|		ON ReportsOptions.Ref = UserOptionsPresentations.Ref
	|		AND (UserOptionsPresentations.LanguageCode = &LanguageCode)
	|	LEFT JOIN Catalog.PredefinedReportsOptions.Presentations AS PresentationsFromConfiguration
	|		ON ReportsOptions.PredefinedVariant = PresentationsFromConfiguration.Ref
	|		AND (PresentationsFromConfiguration.LanguageCode = &LanguageCode)
	|	LEFT JOIN Catalog.PredefinedExtensionsReportsOptions.Presentations AS PresentationsFromExtensions
	|		ON ReportsOptions.PredefinedVariant = PresentationsFromExtensions.Ref
	|		AND (PresentationsFromExtensions.LanguageCode = &LanguageCode)
	|WHERE
	|	ReportsOptions.Report IN (&UserReports)
	|	AND (NOT &HasFilterByReportTypes
	|		OR ReportsOptions.ReportType IN (&ReportTypes))
	|	AND NOT ReportsOptions.PredefinedVariant IN (&DIsabledApplicationOptions)
	|	AND (NOT ReportsOptions.Custom
	|		OR &NoFilterByDeletionMark
	|		OR NOT ReportsOptions.InteractiveSetDeletionMark)
	|	AND (ReportsOptions.Custom
	|		OR &NoFilterByDeletionMark
	|		OR NOT ReportsOptions.DeletionMark)
	|	AND (&ShowPersonalReportsOptionsByOtherAuthors
	|		OR NOT ReportsOptions.AvailableToAuthorOnly
	|		OR ReportsOptions.Author = &CurrentUser)";
	
EndProcedure

Procedure GenerateSearchResults(Val WordArray, Val SourceTable, Result)
	
	SourceTable.Sort("Ref");
	TableRow = SourceTable[0];
	
	SearchAreaTemplate = New FixedStructure("Value, FoundWordsCount, WordHighlighting", "", 0, New ValueList);
    Option = ReportOptionInfo(TableRow.Ref, TableRow.Parent, SearchAreaTemplate);
	
	PresentationSeparator = PresentationSeparator();
	FoundWords = New Map;
	
	Count = SourceTable.Count();
	For Index = 1 To Count Do
		// Filling in variables.
		If Not ValueIsFilled(Option.OptionDescription.Value) AND ValueIsFilled(TableRow.OptionDescription) Then
			Option.OptionDescription.Value = TableRow.OptionDescription;
		EndIf;
		If Not ValueIsFilled(Option.Details.Value) AND ValueIsFilled(TableRow.Details) Then
			Option.Details.Value = TableRow.Details;
		EndIf;
		If Not ValueIsFilled(Option.FieldDescriptions.Value) AND ValueIsFilled(TableRow.FieldDescriptions) Then
			Option.FieldDescriptions.Value = TableRow.FieldDescriptions;
		EndIf;
		If Not ValueIsFilled(Option.FilterParameterDescriptions.Value) AND ValueIsFilled(TableRow.FilterParameterDescriptions) Then
			Option.FilterParameterDescriptions.Value = TableRow.FilterParameterDescriptions;
		EndIf;
		If Not ValueIsFilled(Option.Keywords.Value) AND ValueIsFilled(TableRow.Keywords) Then
			Option.Keywords.Value = TableRow.Keywords;
		EndIf;
		If Not ValueIsFilled(Option.AuthorPresentation.Value) AND ValueIsFilled(TableRow.AuthorPresentation) Then
			Option.AuthorPresentation.Value = TableRow.AuthorPresentation;
		EndIf;
		If ValueIsFilled(TableRow.UserSettingPresentation) Then
			If Option.UserSettingsDescriptions.Value = "" Then
				Option.UserSettingsDescriptions.Value = TableRow.UserSettingPresentation;
			Else
				Option.UserSettingsDescriptions.Value = Option.UserSettingsDescriptions.Value
				+ PresentationSeparator
				+ TableRow.UserSettingPresentation;
			EndIf;
		EndIf;
		
		If ValueIsFilled(TableRow.SubsystemDescription)
			AND Option.Subsystems.Find(TableRow.Subsystem) = Undefined Then
			
			Option.Subsystems.Add(TableRow.Subsystem);
			Subsystem = Result.SubsystemsHighlight.Get(TableRow.Subsystem);
			If Subsystem = Undefined Then
				Subsystem = New Structure;
				Subsystem.Insert("Ref", TableRow.Subsystem);
				Subsystem.Insert("SubsystemDescription", New Structure(SearchAreaTemplate));
				Subsystem.SubsystemDescription.Value = TableRow.SubsystemDescription;
				
				AllWordsFound = True;
				FoundWords.Insert(TableRow.Subsystem, New Map);
				
				For Each Word In WordArray Do
					If MarkWord(Subsystem.SubsystemDescription, Word) Then
						FoundWords[TableRow.Subsystem].Insert(Word, True);
					Else
						AllWordsFound = False;
					EndIf;
				EndDo;
				If AllWordsFound Then
					Result.Subsystems.Add(Subsystem.Ref);
				EndIf;
				Result.SubsystemsHighlight.Insert(Subsystem.Ref, Subsystem);
			EndIf;
			SubsystemsDescriptions = Option.SubsystemsDescriptions.Value;
			Option.SubsystemsDescriptions.Value = ?(IsBlankString(SubsystemsDescriptions), 
				TableRow.SubsystemDescription, 
				SubsystemsDescriptions + PresentationSeparator + TableRow.SubsystemDescription);
		EndIf;
		
		If Index < Count Then
			TableRow = SourceTable[Index];
		EndIf;
		
		If Index = Count Or TableRow.Ref <> Option.Ref Then
			// Analyzing collected information about the option.
			AllWordsFound = True;
			LinkedSubsystems = New Array;
			For Each Word In WordArray Do
				WordFound = MarkWord(Option.OptionDescription, Word) 
					Or MarkWord(Option.Details, Word)
					Or MarkWord(Option.FieldDescriptions, Word, True)
					Or MarkWord(Option.AuthorPresentation, Word, True)
					Or MarkWord(Option.FilterParameterDescriptions, Word, True)
					Or MarkWord(Option.Keywords, Word, True)
					Or MarkWord(Option.UserSettingsDescriptions, Word, True);
				
				If Not WordFound Then
					For Each SubsystemRef In Option.Subsystems Do
						If FoundWords[SubsystemRef] <> Undefined Then
							WordFound = True;
							LinkedSubsystems.Add(SubsystemRef);
						EndIf;
					EndDo;
				EndIf;
				
				If Not WordFound Then
					AllWordsFound = False;
					Break;
				EndIf;
			EndDo;
			
			If AllWordsFound Then // Register the result.
				Result.References.Add(Option.Ref);
				Result.OptionsHighlight.Insert(Option.Ref, Option);
				If LinkedSubsystems.Count() > 0 Then
					Result.OptionsLinkedWithSubsystems.Insert(Option.Ref, LinkedSubsystems);
				EndIf;
				// Deleting the "from subordinate" connection if a parent is found independently.
				ParentIndex = Result.ParentsLinkedWithOptions.Find(Option.Ref);
				If ParentIndex <> Undefined Then
					Result.ParentsLinkedWithOptions.Delete(ParentIndex);
				EndIf;
				If ValueIsFilled(Option.Parent) AND Result.References.Find(Option.Parent) = Undefined Then
					Result.References.Add(Option.Parent);
					Result.ParentsLinkedWithOptions.Add(Option.Parent);
				EndIf;
			EndIf;
			
			If Index = Count Then
				Break;
			EndIf;
			
		    Option = ReportOptionInfo(TableRow.Ref, TableRow.Parent, SearchAreaTemplate);
		EndIf;
		
	EndDo;

EndProcedure

Function ReportOptionInfo(ReportOptionRef, ParentRef, SearchAreaTemplate)
	
	Option = New Structure;
	Option.Insert("Ref", ReportOptionRef);
	Option.Insert("Parent", ParentRef);
	Option.Insert("OptionDescription",                 New Structure(SearchAreaTemplate));
	Option.Insert("Details",                             New Structure(SearchAreaTemplate));
	Option.Insert("FieldDescriptions",                    New Structure(SearchAreaTemplate));
	Option.Insert("FilterParameterDescriptions",       New Structure(SearchAreaTemplate));
	Option.Insert("Keywords",                        New Structure(SearchAreaTemplate));
	Option.Insert("UserSettingsDescriptions", New Structure(SearchAreaTemplate));
	Option.Insert("SubsystemsDescriptions",                New Structure(SearchAreaTemplate));
	Option.Insert("Subsystems",                           New Array);
	Option.Insert("AuthorPresentation",                  New Structure(SearchAreaTemplate));
	Return Option;
	
EndFunction

Procedure GenerateRefsList(Val ValueTable, RefsList)
	
	Duplicates = New Map;
	OptionsTable = ValueTable.Copy(, "Ref, Parent");
	OptionsTable.GroupBy("Ref, Parent");
	For Each TableRow In OptionsTable Do
		ReportOptionRef = TableRow.Ref;
		If ValueIsFilled(ReportOptionRef) AND Duplicates[ReportOptionRef] = Undefined Then
			RefsList.Add(ReportOptionRef);
			Duplicates.Insert(ReportOptionRef);
			ReportOptionRef = TableRow.Parent;
			If ValueIsFilled(ReportOptionRef) AND Duplicates[ReportOptionRef] = Undefined Then
				RefsList.Add(ReportOptionRef);
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

Function DisabledReportOptions(Val UserReports = Undefined) Export
	
	If UserReports = Undefined Then
		UserReports = New Array(ReportsOptionsCached.AvailableReports());
	EndIf;
	
	// Get options that are unavailable by functional options.
	
	OptionsTable = ReportsOptionsCached.Parameters().FunctionalOptionsTable;
	ReportOptionsTable = OptionsTable.CopyColumns("PredefinedVariant, FunctionalOptionName");
	ReportOptionsTable.Columns.Add("OptionValue", New TypeDescription("Number"));
	
	For Each ReportRef In UserReports Do
		FoundItems = OptionsTable.FindRows(New Structure("Report", ReportRef));
		For Each TableRow In FoundItems Do
			RowOption = ReportOptionsTable.Add();
			FillPropertyValues(RowOption, TableRow);
			Value = GetFunctionalOption(TableRow.FunctionalOptionName);
			If Value = True Then
				RowOption.OptionValue = 1;
			EndIf;
		EndDo;
	EndDo;
	
	ReportOptionsTable.GroupBy("PredefinedVariant", "OptionValue");
	DisabledItemsTable = ReportOptionsTable.Copy(New Structure("OptionValue", 0));
	DisabledItemsTable.GroupBy("PredefinedVariant");
	DisabledItemsByFunctionalOptions = DisabledItemsTable.UnloadColumn("PredefinedVariant");
	
	// Add options disabled by the developer.
	Query = New Query;
	Query.SetParameter("UserReports", UserReports);
	Query.SetParameter("ExtensionsVersion", SessionParameters.ExtensionsVersion);
	
	Query.Text =
	"SELECT ALLOWED
	|	ConfigurationOptions.Ref
	|FROM
	|	Catalog.PredefinedReportsOptions AS ConfigurationOptions
	|WHERE
	|	(ConfigurationOptions.Enabled = FALSE
	|		OR ConfigurationOptions.DeletionMark = TRUE)
	|	AND ConfigurationOptions.Report IN (&UserReports)
	|
	|UNION ALL
	|
	|SELECT
	|	ExtensionOptions.Ref
	|FROM
	|	Catalog.PredefinedExtensionsReportsOptions AS ExtensionOptions
	|		LEFT JOIN InformationRegister.PredefinedExtensionsVersionsReportsOptions AS Versions
	|		ON ExtensionOptions.Ref = Versions.Variant
	|			AND ExtensionOptions.Report = Versions.Report
	|			AND (Versions.ExtensionsVersion = &ExtensionsVersion)
	|WHERE
	|	(ExtensionOptions.Enabled = FALSE
	|		OR Versions.Variant IS NULL)
	|	AND ExtensionOptions.Report IN (&UserReports)";
	
	DisabledForced = Query.Execute().Unload().UnloadColumn(0);
	CommonClientServer.SupplementArray(DisabledItemsByFunctionalOptions, DisabledForced);
	
	Return DisabledItemsByFunctionalOptions;
	
EndFunction

// Finds a word and marks a place where it was found. Returns True if the word is found.
Function MarkWord(StructureWhere, Word, UseSeparator = False) Export
	If StrStartsWith(StructureWhere.Value, "#") Then
		StructureWhere.Value = Mid(StructureWhere.Value, 2);
	EndIf;
	RemainderInReg = Upper(StructureWhere.Value);
	Position = StrFind(RemainderInReg, Word);
	If Position = 0 Then
		Return False;
	EndIf;
	If StructureWhere.FoundWordsCount = 0 Then
		// Initializing a variable that contains directives for highlighting words.
		StructureWhere.WordHighlighting = New ValueList;
		// Scrolling focus to a meaningful word (of the found information).
		If UseSeparator Then
			StorageSeparator = Chars.LF;
			PresentationSeparator = PresentationSeparator();
			SeparatorLength = StrLen(StorageSeparator);
			While Position > 10 Do
				SeparatorPosition = StrFind(RemainderInReg, StorageSeparator);
				If SeparatorPosition = 0 Then
					Break;
				EndIf;
				If SeparatorPosition < Position Then
					// Moving a fragment to the separator at the end of area.
					StructureWhere.Value = (
						Mid(StructureWhere.Value, SeparatorPosition + SeparatorLength)
						+ StorageSeparator
						+ Left(StructureWhere.Value, SeparatorPosition - 1));
					RemainderInReg = (
						Mid(RemainderInReg, SeparatorPosition + SeparatorLength)
						+ StorageSeparator
						+ Left(RemainderInReg, SeparatorPosition - 1));
					// Updating information on word location.
					Position = Position - SeparatorPosition - SeparatorLength + 1;
				Else
					Break;
				EndIf;
			EndDo;
			StructureWhere.Value = StrReplace(StructureWhere.Value, StorageSeparator, PresentationSeparator);
			RemainderInReg = StrReplace(RemainderInReg, StorageSeparator, PresentationSeparator);
			Position = StrFind(RemainderInReg, Word);
		EndIf;
	EndIf;
	// Registering a found word.
	StructureWhere.FoundWordsCount = StructureWhere.FoundWordsCount + 1;
	// Marking words.
	LeftPartLength = 0;
	WordLength = StrLen(Word);
	While Position > 0 Do
		StructureWhere.WordHighlighting.Add(LeftPartLength + Position, "+");
		StructureWhere.WordHighlighting.Add(LeftPartLength + Position + WordLength, "-");
		RemainderInReg = Mid(RemainderInReg, Position + WordLength);
		LeftPartLength = LeftPartLength + Position + WordLength - 1;
		Position = StrFind(RemainderInReg, Word);
	EndDo;
	Return True;
EndFunction

// Deletes a temporary table from the query text.
Procedure DeleteTemporaryTable(QueryText, TempTableName)
	TemporaryTablePosition = StrFind(QueryText, "INTO " + TempTableName); // it is not localised (query fragment)
	LeftPart = "";
	RightPart = QueryText;
	While True Do
		SemicolonPosition = StrFind(RightPart, Chars.LF + ";");
		If SemicolonPosition = 0 Then
			Break;
		ElsIf SemicolonPosition > TemporaryTablePosition Then
			RightPart = Mid(RightPart, SemicolonPosition + 2);
			Break;
		Else
			LeftPart = LeftPart + Left(RightPart, SemicolonPosition + 1);
			RightPart = Mid(RightPart, SemicolonPosition + 2);
			TemporaryTablePosition = TemporaryTablePosition - SemicolonPosition - 1;
		EndIf;
	EndDo;
	QueryText = LeftPart + RightPart;
EndProcedure

Procedure FindReportOptionsForOutput(FillingParameters, ResultAddress) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Subsystems.Ref AS Subsystem,
	|	Subsystems.SectionRef AS SectionRef,
	|	Subsystems.Presentation AS Presentation,
	|	Subsystems.Priority AS Priority
	|INTO ttSubsystems
	|FROM
	|	&SubsystemsTable AS Subsystems
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	ReportsOptions.Ref AS Ref,
	|	PredefinedPlacement.Subsystem AS Subsystem,
	|	PredefinedPlacement.Important AS Important,
	|	PredefinedPlacement.SeeAlso AS SeeAlso,
	|	CASE
	|		WHEN &IsMainLanguage
	|			THEN CAST(ISNULL(ConfigurationOptions.Description, ReportsOptions.Description) AS STRING(1000))
	|		ELSE CAST(ISNULL(PresentationsFromConfiguration.Description, OptionPresentations.Description) AS STRING(1000))
	|	END AS Description,
	|	CASE
	|		WHEN &IsMainLanguage
	|				AND SUBSTRING(ReportsOptions.Details, 1, 1) = """"
	|			THEN CAST(ConfigurationOptions.Details AS STRING(1000))
	|		WHEN NOT &IsMainLanguage
	|				AND SUBSTRING(ReportsOptions.Details, 1, 1) = """"
	|			THEN CAST(PresentationsFromConfiguration.Details AS STRING(1000))
	|		ELSE CAST(ReportsOptions.Details AS STRING(1000))
	|	END AS Details,
	|	ReportsOptions.Report AS Report,
	|	ReportsOptions.ReportType AS ReportType,
	|	ReportsOptions.VariantKey AS VariantKey,
	|	ReportsOptions.Author AS Author,
	|	CASE
	|		WHEN ReportsOptions.DefaultVisibilityOverridden
	|			THEN ReportsOptions.VisibleByDefault
	|		ELSE ConfigurationOptions.VisibleByDefault
	|	END AS VisibleByDefault,
	|	ReportsOptions.Parent AS Parent,
	|	ReportsOptions.PredefinedVariant.MeasurementsKey AS MeasurementsKey
	|INTO ttPredefined
	|FROM
	|	Catalog.ReportsOptions AS ReportsOptions
	|		INNER JOIN Catalog.PredefinedReportsOptions.Placement AS PredefinedPlacement
	|		ON (ReportsOptions.Ref IN (&OptionsFoundBySearch)
	|				OR (&NoFilterBySubsystemsAndReports
	|					OR PredefinedPlacement.Subsystem IN (&SubsystemsFoundBySearch)))
	|			AND ReportsOptions.PredefinedVariant = PredefinedPlacement.Ref
	|			AND (PredefinedPlacement.Subsystem IN (&SubsystemsArray))
	|			AND (ReportsOptions.DeletionMark = FALSE)
	|			AND (&NoFilterBySubsystemsAndReports
	|				OR ReportsOptions.Report IN (&UserReports))
	|			AND (NOT PredefinedPlacement.Ref IN (&DIsabledApplicationOptions))
	|		LEFT JOIN Catalog.PredefinedReportsOptions AS ConfigurationOptions
	|		ON ReportsOptions.PredefinedVariant = ConfigurationOptions.Ref
	|		LEFT JOIN Catalog.PredefinedReportsOptions.Presentations AS PresentationsFromConfiguration
	|		ON ReportsOptions.PredefinedVariant = PresentationsFromConfiguration.Ref
	|			AND (PresentationsFromConfiguration.LanguageCode = &LanguageCode)
	|		LEFT JOIN Catalog.ReportsOptions.Presentations AS OptionPresentations
	|		ON ReportsOptions.Ref = OptionPresentations.Ref
	|			AND (OptionPresentations.LanguageCode = &LanguageCode)
	|WHERE
	|	NOT ReportsOptions.DeletionMark
	|
	|UNION ALL
	|
	|SELECT
	|	ReportsOptions.Ref,
	|	PredefinedPlacement.Subsystem,
	|	PredefinedPlacement.Important,
	|	PredefinedPlacement.SeeAlso,
	|	CASE
	|		WHEN &IsMainLanguage
	|			THEN CAST(ISNULL(ExtensionOptions.Description, ReportsOptions.Description) AS STRING(1000))
	|		ELSE CAST(ISNULL(PresentationsFromExtensions.Description, OptionPresentations.Description) AS STRING(1000))
	|	END,
	|	CASE
	|		WHEN &IsMainLanguage
	|				AND SUBSTRING(ReportsOptions.Details, 1, 1) = """"
	|			THEN CAST(ReportsOptions.PredefinedVariant.Details AS STRING(1000))
	|		ELSE CAST(ISNULL(PresentationsFromExtensions.Details, OptionPresentations.Details) AS STRING(1000))
	|	END,
	|	ReportsOptions.Report,
	|	ReportsOptions.ReportType,
	|	ReportsOptions.VariantKey,
	|	ReportsOptions.Author,
	|	CASE
	|		WHEN ReportsOptions.DefaultVisibilityOverridden
	|			THEN ReportsOptions.VisibleByDefault
	|		ELSE ExtensionOptions.VisibleByDefault
	|	END,
	|	ReportsOptions.Parent,
	|	ReportsOptions.PredefinedVariant.MeasurementsKey
	|FROM
	|	Catalog.ReportsOptions AS ReportsOptions
	|		INNER JOIN Catalog.PredefinedExtensionsReportsOptions.Placement AS PredefinedPlacement
	|		ON (ReportsOptions.Ref IN (&OptionsFoundBySearch)
	|				OR (&NoFilterBySubsystemsAndReports
	|					OR PredefinedPlacement.Subsystem IN (&SubsystemsFoundBySearch)))
	|			AND ReportsOptions.PredefinedVariant = PredefinedPlacement.Ref
	|			AND (PredefinedPlacement.Subsystem IN (&SubsystemsArray))
	|			AND (&NoFilterBySubsystemsAndReports
	|				OR ReportsOptions.Report IN (&UserReports))
	|			AND (NOT PredefinedPlacement.Ref IN (&DIsabledApplicationOptions))
	|		LEFT JOIN Catalog.PredefinedExtensionsReportsOptions AS ExtensionOptions
	|		ON ReportsOptions.PredefinedVariant = ExtensionOptions.Ref
	|		LEFT JOIN Catalog.PredefinedExtensionsReportsOptions.Presentations AS PresentationsFromExtensions
	|		ON ReportsOptions.PredefinedVariant = PresentationsFromExtensions.Ref
	|			AND (PresentationsFromExtensions.LanguageCode = &LanguageCode)
	|		LEFT JOIN Catalog.ReportsOptions.Presentations AS OptionPresentations
	|		ON ReportsOptions.Ref = OptionPresentations.Ref
	|			AND (OptionPresentations.LanguageCode = &LanguageCode)
	|WHERE
	|	NOT ReportsOptions.DeletionMark
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	OptionsPlacement.Ref AS Ref,
	|	OptionsPlacement.Subsystem AS Subsystem,
	|	OptionsPlacement.Use AS Use,
	|	OptionsPlacement.Important AS Important,
	|	OptionsPlacement.SeeAlso AS SeeAlso,
	|	CASE
	|		WHEN &IsMainLanguage
	|			THEN CAST(ISNULL(ISNULL(ConfigurationOptions.Description, ExtensionOptions.Description), ReportsOptions.Description) AS STRING(1000))
	|		ELSE CAST(ISNULL(ISNULL(PresentationsFromConfiguration.Description, PresentationsFromExtensions.Description), PresentationOptions.Description) AS STRING(1000))
	|	END AS Description,
	|	CASE
	|		WHEN &IsMainLanguage
	|			THEN CAST(ISNULL(ISNULL(ConfigurationOptions.Details, ExtensionOptions.Details), ReportsOptions.Details) AS STRING(1000))
	|		ELSE CAST(ISNULL(ISNULL(PresentationsFromConfiguration.Details, PresentationsFromExtensions.Details), PresentationOptions.Details) AS STRING(1000))
	|	END AS Details,
	|	ReportsOptions.Report AS Report,
	|	ReportsOptions.ReportType AS ReportType,
	|	ReportsOptions.VariantKey AS VariantKey,
	|	ReportsOptions.Author AS Author,
	|	CASE
	|		WHEN ReportsOptions.Parent = VALUE(Catalog.ReportsOptions.EmptyRef)
	|			THEN VALUE(Catalog.ReportsOptions.EmptyRef)
	|		WHEN ReportsOptions.Parent.Parent = VALUE(Catalog.ReportsOptions.EmptyRef)
	|			THEN ReportsOptions.Parent
	|		ELSE ReportsOptions.Parent.Parent
	|	END AS Parent,
	|	ReportsOptions.VisibleByDefault AS VisibleByDefault,
	|	ReportsOptions.PredefinedVariant.MeasurementsKey AS MeasurementsKey
	|INTO ttOptions
	|FROM
	|	Catalog.ReportsOptions.Placement AS OptionsPlacement
	|		LEFT JOIN Catalog.ReportsOptions AS ReportsOptions
	|		ON (ReportsOptions.Ref = OptionsPlacement.Ref)
	|		LEFT JOIN Catalog.ReportsOptions.Presentations AS PresentationOptions
	|		ON (ReportsOptions.Ref = PresentationOptions.Ref)
	|			AND (PresentationOptions.LanguageCode = &LanguageCode)
	|		LEFT JOIN Catalog.PredefinedReportsOptions AS ConfigurationOptions
	|		ON ReportsOptions.PredefinedVariant = ConfigurationOptions.Ref
	|		LEFT JOIN Catalog.PredefinedReportsOptions.Presentations AS PresentationsFromConfiguration
	|		ON (ReportsOptions.PredefinedVariant = PresentationsFromConfiguration.Ref)
	|			AND (PresentationsFromConfiguration.LanguageCode = &LanguageCode)
	|		LEFT JOIN Catalog.PredefinedExtensionsReportsOptions AS ExtensionOptions
	|		ON ReportsOptions.PredefinedVariant = ExtensionOptions.Ref
	|		LEFT JOIN Catalog.PredefinedExtensionsReportsOptions.Presentations AS PresentationsFromExtensions
	|		ON (ReportsOptions.PredefinedVariant = PresentationsFromExtensions.Ref)
	|			AND (PresentationsFromExtensions.LanguageCode = &LanguageCode)
	|WHERE
	|	(OptionsPlacement.Ref IN (&OptionsFoundBySearch)
	|			OR (&NoFilterBySubsystemsAndReports
	|				OR OptionsPlacement.Subsystem IN (&SubsystemsFoundBySearch)))
	|	AND (NOT ReportsOptions.AvailableToAuthorOnly
	|			OR ReportsOptions.Author = &CurrentUser)
	|	AND OptionsPlacement.Subsystem IN(&SubsystemsArray)
	|	AND (&NoFilterBySubsystemsAndReports
	|			OR ReportsOptions.Report IN (&UserReports))
	|	AND NOT ReportsOptions.PredefinedVariant IN (&DIsabledApplicationOptions)
	|	AND (NOT ReportsOptions.Custom
	|			OR NOT ReportsOptions.InteractiveSetDeletionMark)
	|	AND (ReportsOptions.Custom
	|			OR NOT ReportsOptions.DeletionMark)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED DISTINCT
	|	ISNULL(ttOptions.Ref, ttPredefined.Ref) AS Ref,
	|	ISNULL(ttOptions.Subsystem, ttPredefined.Subsystem) AS Subsystem,
	|	ISNULL(ttOptions.Important, ttPredefined.Important) AS Important,
	|	ISNULL(ttOptions.SeeAlso, ttPredefined.SeeAlso) AS SeeAlso,
	|	ISNULL(ttOptions.Description, ttPredefined.Description) AS Description,
	|	ISNULL(ttOptions.Details, ttPredefined.Details) AS Details,
	|	ISNULL(ttOptions.Author, ttPredefined.Author) AS Author,
	|	ISNULL(ttOptions.Report, ttPredefined.Report) AS Report,
	|	ISNULL(ttOptions.ReportType, ttPredefined.ReportType) AS ReportType,
	|	ISNULL(ttOptions.VariantKey, ttPredefined.VariantKey) AS VariantKey,
	|	ISNULL(ttOptions.VisibleByDefault, ttPredefined.VisibleByDefault) AS VisibleByDefault,
	|	ISNULL(ttOptions.Parent, ttPredefined.Parent) AS Parent,
	|	CASE
	|		WHEN ISNULL(ttOptions.Parent, ttPredefined.Parent) = VALUE(Catalog.ReportsOptions.EmptyRef)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS TopLevel,
	|	ISNULL(ttOptions.MeasurementsKey, ttPredefined.MeasurementsKey) AS MeasurementsKey
	|INTO ttAllOptions
	|FROM
	|	ttPredefined AS ttPredefined
	|		FULL JOIN ttOptions AS ttOptions
	|		ON ttPredefined.Ref = ttOptions.Ref
	|			AND ttPredefined.Subsystem = ttOptions.Subsystem
	|WHERE
	|	ISNULL(ttOptions.Use, TRUE)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	ttAllOptions.Ref AS Ref,
	|	ttAllOptions.Subsystem AS Subsystem,
	|	ttSubsystems.Presentation AS SubsystemPresentation,
	|	ISNULL(ttSubsystems.Priority, """") AS SubsystemPriority,
	|	ttSubsystems.SectionRef AS SectionRef,
	|	CASE
	|		WHEN ttAllOptions.Subsystem = ttSubsystems.SectionRef
	|				AND ttAllOptions.SeeAlso = FALSE
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS NoGroup,
	|	ttAllOptions.Important AS Important,
	|	ttAllOptions.SeeAlso AS SeeAlso,
	|	CASE
	|		WHEN ttAllOptions.ReportType = VALUE(Enum.ReportTypes.Additional)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS Additional,
	|	ISNULL(PersonalSettings.Visible, ttAllOptions.VisibleByDefault) AS Visible,
	|	ISNULL(PersonalSettings.QuickAccess, FALSE) AS QuickAccess,
	|	CASE
	|		WHEN ttAllOptions.ReportType = VALUE(Enum.ReportTypes.Internal)
	|				OR ttAllOptions.ReportType = VALUE(Enum.ReportTypes.Extension)
	|			THEN ttAllOptions.Report.Name
	|		WHEN ttAllOptions.ReportType = VALUE(Enum.ReportTypes.Additional)
	|			THEN """"
	|		ELSE SUBSTRING(CAST(ttAllOptions.Report AS STRING(150)), 14, 137)
	|	END AS ReportName,
	|	ISNULL(ttAllOptions.Description, """") AS Description,
	|	ttAllOptions.Details AS Details,
	|	ttAllOptions.Author AS Author,
	|	ttAllOptions.Report AS Report,
	|	ttAllOptions.ReportType AS ReportType,
	|	ttAllOptions.VariantKey AS VariantKey,
	|	ttAllOptions.Parent AS Parent,
	|	ttAllOptions.TopLevel AS TopLevel,
	|	ttAllOptions.MeasurementsKey AS MeasurementsKey
	|FROM
	|	ttAllOptions AS ttAllOptions
	|		LEFT JOIN ttSubsystems AS ttSubsystems
	|		ON ttAllOptions.Subsystem = ttSubsystems.Subsystem
	|		LEFT JOIN InformationRegister.ReportOptionsSettings AS PersonalSettings
	|		ON ttAllOptions.Subsystem = PersonalSettings.Subsystem
	|			AND ttAllOptions.Ref = PersonalSettings.Variant
	|			AND (PersonalSettings.User = &CurrentUser)
	|WHERE
	|	(&NoFilterByVisibility
	|			OR ISNULL(PersonalSettings.Visible, ttAllOptions.VisibleByDefault))
	|
	|ORDER BY
	|	SubsystemPriority,
	|	Description";
	
	SearchByRow = ValueIsFilled(FillingParameters.SearchString);
	CurrentSectionOnly = FillingParameters.SetupMode Or Not SearchByRow Or FillingParameters.SearchInAllSections = 0;
	SubsystemsTable = FillingParameters.ApplicationSubsystems;
	SubsystemsTable.Indexes.Add("Ref");
	SubsystemsArray = SubsystemsTable.UnloadColumn("Ref");
	
	SearchParameters = New Structure;
	If SearchByRow Then
		SearchParameters.Insert("SearchString", FillingParameters.SearchString);
	EndIf;
	If CurrentSectionOnly Then
		SearchParameters.Insert("Subsystems", SubsystemsArray);
	EndIf;
	SearchResult = FindReportsOptions(SearchParameters, False, True);
	
	Query.SetParameter("CurrentUser", Users.AuthorizedUser());
	Query.SetParameter("SubsystemsArray", SubsystemsArray);
	Query.SetParameter("SubsystemsTable", SubsystemsTable);
	Query.SetParameter("SectionRef", FillingParameters.CurrentSectionRef);
	Query.SetParameter("IsMainLanguage", CurrentLanguage() = Metadata.DefaultLanguage);
	Query.SetParameter("LanguageCode", CurrentLanguage().LanguageCode);
	Query.SetParameter("OptionsFoundBySearch", SearchResult.References);
	Query.SetParameter("SubsystemsFoundBySearch", SearchResult.Subsystems);
	Query.SetParameter("UserReports", SearchParameters.UserReports);
	Query.SetParameter("DIsabledApplicationOptions", SearchParameters.DIsabledApplicationOptions);
	Query.SetParameter("NoFilterBySubsystemsAndReports", Not SearchByRow AND SearchParameters.Subsystems.Count() = 0);
	Query.SetParameter("NoFilterByVisibility", FillingParameters.SetupMode Or SearchByRow);
	
	ResultTable = Query.Execute().Unload();
	FillReportsNames(ResultTable);
	
	ResultTable.Columns.Add("OutputWithMainReport", New TypeDescription("Boolean"));
	ResultTable.Columns.Add("SubordinateCount", New TypeDescription("Number"));
	ResultTable.Indexes.Add("Ref");
	
	If SearchByRow Then
		// Delete records about options that are linked to subsystems if a record is not mentioned in the link.
		For Each KeyAndValue In SearchResult.OptionsLinkedWithSubsystems Do
			OptionRef = KeyAndValue.Key;
			LinkedSubsystems = KeyAndValue.Value;
			FoundItems = ResultTable.FindRows(New Structure("Ref", OptionRef));
			For Each TableRow In FoundItems Do
				If LinkedSubsystems.Find(TableRow.Subsystem) = Undefined Then
					ResultTable.Delete(TableRow);
				EndIf;
			EndDo;
		EndDo;
		// Delete records about parents that are linked to options if a parent attempts to output without options.
		For Each ParentRef In SearchResult.ParentsLinkedWithOptions Do
			OutputLocation = ResultTable.FindRows(New Structure("Ref", ParentRef));
			For Each TableRow In OutputLocation Do
				FoundItems = ResultTable.FindRows(New Structure("Subsystem, Parent", TableRow.Subsystem, ParentRef));
				If FoundItems.Count() = 0 Then
					ResultTable.Delete(TableRow);
				EndIf;
			EndDo;
		EndDo;
	EndIf;
	
	If CurrentSectionOnly Then
		OtherSections = New Array;
	Else
		TableCopy = ResultTable.Copy();
		TableCopy.GroupBy("SectionRef");
		OtherSections = TableCopy.UnloadColumn("SectionRef");
		Index = OtherSections.Find(FillingParameters.CurrentSectionRef);
		If Index <> Undefined Then
			OtherSections.Delete(Index);
		EndIf;
	EndIf;
	
	WordArray = ?(SearchByRow, 
		ReportsOptionsClientServer.ParseSearchStringIntoWordArray(Upper(TrimAll(FillingParameters.SearchString))),
		Undefined);
	
	Result = New Structure;
	Result.Insert("CurrentSectionOnly", CurrentSectionOnly);
	Result.Insert("SubsystemsTable", SubsystemsTable);
	Result.Insert("OtherSections", OtherSections);
	Result.Insert("Variants", ResultTable);
	Result.Insert("UseHighlighting", SearchByRow);
	Result.Insert("SearchResult", SearchResult);
	Result.Insert("WordArray", WordArray);
	
	PutToTempStorage(Result, ResultAddress);
EndProcedure

Procedure FillReportsNames(ResultTable)
	
	ReportsIDs = New Array;
	For Each ReportRow In ResultTable Do
		If Not ReportRow.Additional Then
			ReportsIDs.Add(ReportRow.Report);
		EndIf;
	EndDo;
	ReportsObjects = Common.MetadataObjectsByIDs(ReportsIDs, False);
	NonexistentAndUnavailable = New Array;
	
	For Each ReportForOutput In ResultTable Do
		If ReportForOutput.ReportType = Enums.ReportTypes.Internal
			Or ReportForOutput.ReportType = Enums.ReportTypes.Extension Then
			MetadataOfReport = ReportsObjects[ReportForOutput.Report];
			If MetadataOfReport = Undefined Or MetadataOfReport = Null Then
				NonexistentAndUnavailable.Add(ReportForOutput);
			ElsIf ReportForOutput.ReportName <> MetadataOfReport.Name Then
				ReportForOutput.ReportName = MetadataOfReport.Name;
			EndIf;
		EndIf;
	EndDo;
	
	For each UnavailableReport In NonexistentAndUnavailable Do
		ResultTable.Delete(UnavailableReport);
	EndDo;
	
	ReportsWithDescription = ResultTable.FindRows(New Structure("Description", ""));
	For Each ReportDetails In ReportsWithDescription Do
		If ValueIsFilled(ReportDetails.ReportName) Then 
			ReportDetails.Description = ReportDetails.ReportName;
		EndIf;
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Defining tabled to be used.

// Registers tables used in data sets in the array.
Procedure RegisterDataSetsTables(Tables, DataSets)
	For Each Set In DataSets Do
		If TypeOf(Set) = Type("DataCompositionSchemaDataSetQuery") Then
			RegisterQueryTables(Tables, Set.Query);
		ElsIf TypeOf(Set) = Type("DataCompositionSchemaDataSetUnion") Then
			RegisterDataSetsTables(Tables, Set.Items);
		ElsIf TypeOf(Set) = Type("DataCompositionSchemaDataSetObject") Then
			// Nothing to register.
		EndIf;
	EndDo;
EndProcedure

// Registers tables used in the query in the array.
Procedure RegisterQueryTables(Tables, QueryText)
	If Not ValueIsFilled(QueryText) Then
		Return;
	EndIf;
	QuerySchema = New QuerySchema;
	QuerySchema.SetQueryText(QueryText);
	For Each Query In QuerySchema.QueryBatch Do
		If TypeOf(Query) = Type("QuerySchemaSelectQuery") Then
			RegisterQueryOperatorsTables(Tables, Query.Operators);
		ElsIf TypeOf(Query) = Type("QuerySchemaTableDropQuery") Then
			// Nothing to register.
		EndIf;
	EndDo;
EndProcedure

// Continuation of the procedure (see above).
Procedure RegisterQueryOperatorsTables(Tables, Operators)
	For Each Operator In Operators Do
		For Each Source In Operator.Sources Do
			Source = Source.Source;
			If TypeOf(Source) = Type("QuerySchemaTable") Then
				If Tables.Find(Source.TableName) = Undefined Then
					Tables.Add(Source.TableName);
				EndIf;
			ElsIf TypeOf(Source) = Type("QuerySchemaNestedQuery") Then
				RegisterQueryOperatorsTables(Tables, Source.Query.Operators);
			ElsIf TypeOf(Source) = Type("QuerySchemaTempTableDescription") Then
				// Nothing to register.
			EndIf;
		EndDo;
	EndDo;
EndProcedure

// Returns a message text that the report data is still being updated.
Function DataIsBeingUpdatedMessage() Export
	Return NStr("ru = 'Отчет может содержать некорректные данные, так как не завершен переход на новую версию программы. Если отчет долгое время недоступен, необходимо обратиться к администратору.'; en = 'The report might contain invalid data since migration to the new version is not completed. If the report is not available for a while, contact the administrator.'; pl = 'Raport może zawierać niepoprawne dane, ponieważ nie zakończono przejścia na nową wersję programu. Jeżeli raport jest niedostępny przez długi czas, należy zwrócić się do administratora.';de = 'Der Bericht kann falsche Daten enthalten, da die Umstellung auf die neue Version des Programms nicht abgeschlossen ist. Wenn der Bericht längere Zeit nicht verfügbar ist, sollten Sie sich an den Administrator wenden.';ro = 'Raportul poate conține date incorecte, deoarece nu este finalizată trecerea la versiunea nouă a programului. Adresați-vă administratorului, dacă raportul este inaccesibil prea mult timp.';tr = 'Rapor, programın yeni sürümüne geçiş tamamlanmadığı için hatalı veriler içerebilir. Rapor uzun süre kullanılamıyorsa, yöneticinize başvurun.'; es_ES = 'El informe puede contener datos incorrectos porque no está terminado el paso a la nueva versión del programa. Si el informe no está disponible durante mucho tiempo, es necesario dirigirse al administrador.'");
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Reports submenu.

// Called from OnDefineCommandsAttachedToObject.
Procedure OnAddReportsCommands(Commands, ObjectInfo, FormSettings)
	ObjectInfo.Manager.AddReportCommands(Commands, FormSettings);
	AddedCommands = Commands.FindRows(New Structure("Processed", False));
	For Each Command In AddedCommands Do
		If Not ValueIsFilled(Command.Manager) Then
			Command.Manager = ObjectInfo.FullName;
		EndIf;
		If Not ValueIsFilled(Command.ParameterType) Then
			If TypeOf(ObjectInfo.DataRefType) = Type("Type") Then
				Command.ParameterType = New TypeDescription(CommonClientServer.ValueInArray(ObjectInfo.DataRefType));
			Else // Type("TypesDetails") or Undefined.
				Command.ParameterType = ObjectInfo.DataRefType;
			EndIf;
		EndIf;
		Command.Processed = True;
	EndDo;
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Auxiliary for the internal

// Handler determining whether configuration reports and extensions are available.
Procedure OnDefineReportsAvailability(ReportsReferences, Result)
	ReportsNames = Common.ObjectsAttributeValue(ReportsReferences, "Name", True);
	For Each Report In ReportsReferences Do
		NameOfReport = ReportsNames[Report];
		AvailableByRLS = True;
		AvailableByRights = True;
		AvailableByOptions = True;
		FoundInApplication = True;
		If NameOfReport = Undefined Then
			AvailableByRLS = False;
		Else
			ReportMetadata = Metadata.Reports.Find(NameOfReport);
			If ReportMetadata = Undefined Then
				FoundInApplication = False;
			ElsIf Not AccessRight("View", ReportMetadata) Then
				AvailableByRights = False;
			ElsIf Not Common.MetadataObjectAvailableByFunctionalOptions(ReportMetadata) Then
				AvailableByOptions = False;
			EndIf;
		EndIf;
		FoundItems = Result.FindRows(New Structure("Report", Report));
		For Each TableRow In FoundItems Do
			If Not AvailableByRLS Then
				TableRow.Presentation = NStr("ru = '<Недостаточно прав для работы с вариантом отчета>'; en = '<Insufficient rights to access the report option>'; pl = '<Niewystarczające uprawnienia do pracy z wariantem raportu>';de = '<Unzureichende Rechte, um mit der Berichtsvariante zu arbeiten>';ro = '<Drepturi insuficiente pentru lucrul cu varianta raportului>';tr = '<Rapor seçeneği ile çalışma hakları yetersiz>'; es_ES = '<Insuficientes derechos para usar la variante del informe>'");
			ElsIf Not FoundInApplication Then
				TableRow.Presentation = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = '<Отчет ""%1"" не найден в программе>'; en = '<Cannot find report %1>'; pl = '<Nie znaleziono raportu ""%1"" w programie>';de = '<Bericht ""%1"" nicht im Programm gefunden>';ro = '<Raportul ""%1"" nu a fost găsit în program>';tr = '<""%1"" raporu uygulamada bulunamadı>'; es_ES = '<Informe ""%1"" no encontrado en el programa>'"),
					NameOfReport);
			ElsIf Not AvailableByRights Then
				TableRow.Presentation = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = '<Недостаточно прав для работы с отчетом ""%1"">'; en = '<Insufficient rights to access report %1>'; pl = '<Niewystarczające uprawnienia do pracy z raportem ""%1"">';de = '<Unzureichende Rechte, um mit dem Bericht ""%1"" zu arbeiten>';ro = '<Drepturi insuficiente pentru lucrul cu raportul ""%1"">';tr = '<""%1"" rapor seçeneği ile çalışma hakları yetersiz>'; es_ES = '<Insuficientes derechos para usar la variante del informe ""%1"">'"),
					NameOfReport);
			ElsIf Not AvailableByOptions Then
				TableRow.Presentation = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = '<Отчет ""%1"" отключен в настройках программы>'; en = '<Report %1 is disabled in settings>'; pl = '<Raport ""%1"" jest odłączony w ustawieniach programu>';de = '<Bericht ""%1"" ist in den Programmeinstellungen deaktiviert>';ro = '<Raportul ""%1"" este dezactivat în setările programului>';tr = '<""%1"" rapor uygulama ayarlarında kapalı>'; es_ES = '<El informe ""%1"" está declinado en los ajustes del programa>'"),
					NameOfReport);
			Else
				TableRow.Available = True;
			EndIf;
		EndDo;
	EndDo;
EndProcedure

// Determines the attachment method of the common report form.
Function ByDefaultAllConnectedToMainForm()
	MetadataForm = Metadata.DefaultReportForm;
	Return (MetadataForm <> Undefined AND MetadataForm = Metadata.CommonForms.ReportForm);
EndFunction

// Defines an attachement method of the common report settings form.
Function ByDefaultAllConnectedToSettingsForm()
	MetadataForm = Metadata.DefaultReportSettingsForm;
	Return (MetadataForm <> Undefined AND MetadataForm = Metadata.CommonForms.ReportSettingsForm);
EndFunction

// Defines an attachment method of the report option storage.
Function ByDefaultAllConnectedToStorage()
	Return (Metadata.ReportsVariantsStorage <> Undefined AND Metadata.ReportsVariantsStorage.Name = "ReportsVariantsStorage");
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Filters.

// Sets filters based on extended information from the structure.
Procedure ComplementFiltersFromStructure(Filter, Structure, DisplayMode = Undefined) Export
	If DisplayMode = Undefined Then
		DisplayMode = DataCompositionSettingsItemViewMode.Inaccessible;
	EndIf;
	For Each KeyAndValue In Structure Do
		FieldName = KeyAndValue.Key;
		FieldFilter = KeyAndValue.Value;
		Type = TypeOf(FieldFilter);
		If Type = Type("Structure") Then
			Condition = DataCompositionComparisonType[FieldFilter.Kind];
			Value = FieldFilter.Value;
		ElsIf Type = Type("Array") Then
			Condition = DataCompositionComparisonType.InList;
			Value = FieldFilter;
		ElsIf Type = Type("ValueList") Then
			Condition = DataCompositionComparisonType.InList;
			Value = FieldFilter.UnloadValues();
		ElsIf Type = Type("DataCompositionComparisonType") Then
			Condition = FieldFilter;
			Value = Undefined;
		Else
			Condition = DataCompositionComparisonType.Equal;
			Value = FieldFilter;
		EndIf;
		CommonClientServer.SetFilterItem(
			Filter,
			FieldName,
			Value,
			Condition,
			,
			True,
			DisplayMode);
	EndDo;
EndProcedure

#EndRegion
