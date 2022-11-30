///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Generates a list of configuration reports available for the current user.
// Use it in all queries to the table of the "ReportsOptions" catalog as a filter for the "Report" 
// attribute.
//
// Returns:
//   Array - references to reports the current user can access.
//            See the item type in the Catalogs.ReportOptions.Attributes.Report.
//
Function AvailableReports(CheckFunctionalOptions = True) Export
	Result = New Array;
	FullReportsNames = New Array;
	
	AllAttachedByDefault = Undefined;
	For Each ReportMetadata In Metadata.Reports Do
		If Not AccessRight("View", ReportMetadata)
			Or Not ReportsOptions.ReportAttachedToStorage(ReportMetadata, AllAttachedByDefault) Then
			Continue;
		EndIf;
		If CheckFunctionalOptions
			AND Not Common.MetadataObjectAvailableByFunctionalOptions(ReportMetadata) Then
			Continue;
		EndIf;
		FullReportsNames.Add(ReportMetadata.FullName());
	EndDo;
	
	ReportsIDs = Common.MetadataObjectIDs(FullReportsNames);
	For Each ReportID In ReportsIDs Do
		Result.Add(ReportID.Value);
	EndDo;
	
	Return New FixedArray(Result);
EndFunction

// Generates a list of configuration report option unavailable for the current user by functional options.
// Use in all queries to the table of the "ReportsOptions" catalog as an excluding filter for the 
// "PredefinedOption" attribute.
//
// Returns:
//   Array - report options that are disabled by functional options.
//            Item type - CatalogRef.PredefinedReportOptions,
//            CatalogRef.PredefinedReportOptionsOfExtensions.
//
Function DIsabledApplicationOptions() Export
	Return New FixedArray(ReportsOptions.DisabledReportOptions());
EndFunction

#EndRegion

#Region Private

// Generates a tree of subsystems available for the current user.
//
// Returns:
//   Result - ValueTree -
//       * SectionRef - CatalogRef.MetadataObjectIDs - a section reference.
//       * Ref       - CatalogRef.MetadataObjectIDs - a subsystem reference.
//       * Name           - String - a subsystem name.
//       * FullName     - String - the full name of the subsystem.
//       * Presentation - String - a subsystem presentation.
//       * Priority     - String - a subsystem priority.
//
Function CurrentUserSubsystems() Export
	
	IDTypesDetails = New TypeDescription;
	IDTypesDetails.Types().Add("CatalogRef.MetadataObjectIDs");
	IDTypesDetails.Types().Add("CatalogRef.ExtensionObjectIDs");
	
	Result = New ValueTree;
	Result.Columns.Add("Ref",              IDTypesDetails);
	Result.Columns.Add("Name",                 ReportsOptions.TypesDetailsString(150));
	Result.Columns.Add("FullName",           ReportsOptions.TypesDetailsString(510));
	Result.Columns.Add("Presentation",       ReportsOptions.TypesDetailsString(150));
	Result.Columns.Add("SectionRef",        IDTypesDetails);
	Result.Columns.Add("SectionFullName",     ReportsOptions.TypesDetailsString(510));
	Result.Columns.Add("Priority",           ReportsOptions.TypesDetailsString(100));
	Result.Columns.Add("FullPresentation", ReportsOptions.TypesDetailsString(300));
	
	RootRow = Result.Rows.Add();
	RootRow.Ref = Catalogs.MetadataObjectIDs.EmptyRef();
	RootRow.Presentation = NStr("ru = 'Все разделы'; en = 'All sections'; pl = 'Wszystkie sekcje';de = 'Alle Abschnitte';ro = 'Toate secțiunile';tr = 'Tüm bölümler'; es_ES = 'Todas secciones'");
	
	FullSubsystemsNames = New Array;
	TreeRowsFullNames = New Map;
	
	HomePageID = ReportsOptionsClientServer.HomePageID();
	SectionsList = ReportsOptions.SectionsList();
	
	Priority = 0;
	For Each ListItem In SectionsList Do
		
		MetadataSection = ListItem.Value;
		If NOT (TypeOf(MetadataSection) = Type("MetadataObject") AND StrStartsWith(MetadataSection.FullName(), "Subsystem"))
			AND NOT (TypeOf(MetadataSection) = Type("String") AND MetadataSection = HomePageID) Then
			
			Raise NStr("ru='Некорректно определены значения разделов в процедуре ВариантыОтчетовПереопределяемый.ОпределитьРазделыСВариантамиОтчетов'; en = 'Invalid section values in ReportOptionsOverridable.DefineSectionsWithReportOptions procedure.'; pl = 'Wartości rozdziałów są określone nie poprawnie w procedurze ReportOptionsOverridable.DefineSectionsWithReportOptions';de = 'Die Werte von Abschnitten sind in der Prozedur ReportOptionsOverridable.DefineSectionsWithReportOptions';ro = 'Valorile compartimentelor în procedura ReportOptionsOverridable.DefineSectionsWithReportOptions au fost determinate incorect';tr = 'ReportOptionsOverridable.DefineSectionsWithReportOptions prosedürümdeki bölümlerin değerleri yanlış tanımlanmıştır.'; es_ES = 'Los valores de secciones en el procedimiento ReportOptionsOverridable.DefineSectionsWithReportOptions están determinados incorrectamente'");
			
		EndIf;
		
		If ValueIsFilled(ListItem.Presentation) Then
			CaptionPattern = ListItem.Presentation;
		Else
			CaptionPattern = NStr("ru = 'Отчеты раздела ""%1""'; en = '%1 section reports'; pl = 'Sprawozdania ""%1""';de = 'Berichte von ""%1""';ro = '""%1"" rapoarte';tr = '""%1"" raporlar'; es_ES = 'Informes ""%1""'");
		EndIf;
		IsHomePage = (MetadataSection = HomePageID);
		
		If Not IsHomePage
			AND (Not AccessRight("View", MetadataSection)
				Or Not Common.MetadataObjectAvailableByFunctionalOptions(MetadataSection)) Then
			Continue; // The subsystem is unavailable by FR or by rights.
		EndIf;
		
		TreeRow = RootRow.Rows.Add();
		If IsHomePage Then
			TreeRow.Name           = HomePageID;
			TreeRow.FullName     = HomePageID;
			TreeRow.Presentation = NStr("ru = 'Начальная страница'; en = 'Home page'; pl = 'Strona podstawowa';de = 'Startseite';ro = 'Pagina principală';tr = 'Ana sayfa'; es_ES = 'Página principal'");
		Else
			TreeRow.Name           = MetadataSection.Name;
			TreeRow.FullName     = MetadataSection.FullName();
			TreeRow.Presentation = MetadataSection.Presentation();
		EndIf;
		FullSubsystemsNames.Add(TreeRow.FullName);
		If TreeRowsFullNames[TreeRow.FullName] = Undefined Then
			TreeRowsFullNames.Insert(TreeRow.FullName, TreeRow);
		Else
			TreeRowsFullNames.Insert(TreeRow.FullName, True); // A search in the tree is required.
		EndIf;
		TreeRow.SectionFullName = TreeRow.FullName;
		TreeRow.FullPresentation = StringFunctionsClientServer.SubstituteParametersToString(
			CaptionPattern,
			TreeRow.Presentation);
		
		Priority = Priority + 1;
		TreeRow.Priority = Format(Priority, "ND=4; NFD=0; NLZ=; NG=0");
		If Not IsHomePage Then
			AddCurrentUserSubsystems(TreeRow, MetadataSection, FullSubsystemsNames, TreeRowsFullNames);
		EndIf;
	EndDo;
	
	SubsystemsReferences = Common.MetadataObjectIDs(FullSubsystemsNames);
	For Each KeyAndValue In SubsystemsReferences Do
		TreeRow = TreeRowsFullNames[KeyAndValue.Key];
		If TreeRow = True Then // A search in the tree is required.
			FoundItems = Result.Rows.FindRows(New Structure("FullName", KeyAndValue.Key), True);
			For Each TreeRow In FoundItems Do
				TreeRow.Ref = KeyAndValue.Value;
				TreeRow.SectionRef = SubsystemsReferences[TreeRow.SectionFullName];
			EndDo;
		Else
			TreeRow.Ref = KeyAndValue.Value;
			TreeRow.SectionRef = SubsystemsReferences[TreeRow.SectionFullName];
		EndIf;
	EndDo;
	TreeRowsFullNames.Clear();
	
	Return Result;
EndFunction

// Adds parent subsystems with a filter by access rights and functional options.
Procedure AddCurrentUserSubsystems(ParentLevelRow, ParentMetadata, FullSubsystemsNames, TreeRowsFullNames)
	ParentPriority = ParentLevelRow.Priority;
	
	Priority = 0;
	For Each SubsystemMetadata In ParentMetadata.Subsystems Do
		Priority = Priority + 1;
		
		If Not SubsystemMetadata.IncludeInCommandInterface
			Or Not AccessRight("View", SubsystemMetadata)
			Or Not Common.MetadataObjectAvailableByFunctionalOptions(SubsystemMetadata) Then
			Continue; // The subsystem is unavailable by FR or by rights.
		EndIf;
		
		TreeRow = ParentLevelRow.Rows.Add();
		TreeRow.Name           = SubsystemMetadata.Name;
		TreeRow.FullName     = SubsystemMetadata.FullName();
		TreeRow.Presentation = SubsystemMetadata.Presentation();
		FullSubsystemsNames.Add(TreeRow.FullName);
		If TreeRowsFullNames[TreeRow.FullName] = Undefined Then
			TreeRowsFullNames.Insert(TreeRow.FullName, TreeRow);
		Else
			TreeRowsFullNames.Insert(TreeRow.FullName, True); // A search in the tree is required.
		EndIf;
		TreeRow.SectionFullName = ParentLevelRow.SectionFullName;
		
		If StrLen(ParentPriority) > 12 Then
			TreeRow.FullPresentation = ParentLevelRow.Presentation + ": " + TreeRow.Presentation;
		Else
			TreeRow.FullPresentation = TreeRow.Presentation;
		EndIf;
		TreeRow.Priority = ParentPriority + Format(Priority, "ND=4; NFD=0; NLZ=; NG=0");
		
		AddCurrentUserSubsystems(TreeRow, SubsystemMetadata, FullSubsystemsNames, TreeRowsFullNames);
	EndDo;
EndProcedure

// Returns True if the user has the right to read report options.
Function ReadRight() Export
	Return AccessRight("Read", Metadata.Catalogs.ReportsOptions);
EndFunction

// Returns True if the user has the right to save report options.
Function InsertRight() Export
	Return AccessRight("SaveUserData", Metadata) AND AccessRight("Insert", Metadata.Catalogs.ReportsOptions);
EndFunction

// Subsystem parameters cached upon update (see ReportsOptions.WriteReportsOptionsParameters).
//
// Returns:
//   Structure - with the following properties:
//     * FunctionalOptionsTable - ValueTable - a connection of functional options and predefined report options:
//       ** Report - CalalogRef.MetadataObjectsIDs
//       ** PredefinedOption - CatalogRef.PredefinedReportsOptions.
//       ** FunctionalOptionName - String
//     * ReportsWithSettings - Array from CatalogRef.MetadataObjectIDs - reports whose object module 
//          contains procedures of integration with the common report form.
// 
Function Parameters() Export
	
	FullSubsystemName = ReportsOptionsClientServer.FullSubsystemName();
	Parameters = StandardSubsystemsServer.ApplicationParameter(FullSubsystemName);
	If Parameters = Undefined Then
		ReportsOptions.ConfigurationCommonDataNonexclusiveUpdate(New Structure("SeparatedHandlers"));
		Parameters = StandardSubsystemsServer.ApplicationParameter(FullSubsystemName);
	EndIf;
	
	If ValueIsFilled(SessionParameters.ExtensionsVersion) Then
		ExtensionParameters = StandardSubsystemsServer.ExtensionParameter(FullSubsystemName);
		If ExtensionParameters = Undefined Then
			SetSafeModeDisabled(True);
			SetPrivilegedMode(True);
			ReportsOptions.OnFillAllExtensionsParameters();
			SetPrivilegedMode(False);
			SetSafeModeDisabled(False);
			ExtensionParameters = StandardSubsystemsServer.ExtensionParameter(FullSubsystemName);
		EndIf;
		If ExtensionParameters <> Undefined Then
			CommonClientServer.SupplementArray(Parameters.ReportsWithSettings, ExtensionParameters.ReportsWithSettings);
			CommonClientServer.SupplementTable(Parameters.FunctionalOptionsTable, ExtensionParameters.FunctionalOptionsTable);
		EndIf;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.AdditionalReportsAndDataProcessors") Then
		ModuleAdditionalReportsAndDataProcessors = Common.CommonModule("AdditionalReportsAndDataProcessors");
		ModuleAdditionalReportsAndDataProcessors.OnDetermineReportsWithSettings(Parameters.ReportsWithSettings);
	EndIf;
	
	Return Parameters;
EndFunction

#EndRegion
