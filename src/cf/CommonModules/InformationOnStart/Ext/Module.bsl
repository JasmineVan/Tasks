///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// The function updates subsystem data considering the application mode.
//   Usage example: after clearing settings storage.
//
// Parameters:
//   Settings - Structure - optional. Update settings.
//       * SharedData       - Boolean - optional. Update shared data.
//       * SeparatedData - Boolean - optional. Update separated data.
//       * RealTime - Boolean - optional. Real-time data update.
//       * Deferred  - Boolean - optional. Deferred data update.
//       * Full      - Boolean - optional. Do not consider hash during the deferred data update.
//
Function Refresh(Settings = Undefined) Export
	
	If Settings = Undefined Then
		Settings = New Structure;
	EndIf;
	
	Default = New Structure("SharedData, SeparatedData, Nonexclusive, Deferred, Full");
	If Settings.Count() < Default.Count() Then
		If Common.DataSeparationEnabled() Then
			If Common.SeparatedDataUsageAvailable() Then
				Default.SharedData       = False;
				Default.SeparatedData = True;
			Else // Shared session.
				Default.SharedData       = True;
				Default.SeparatedData = False;
			EndIf;
		Else
			If Common.IsStandaloneWorkplace() Then // SWP.
				Default.SharedData       = False;
				Default.SeparatedData = True;
			Else // Box.
				Default.SharedData       = True;
				Default.SeparatedData = True;
			EndIf;
		EndIf;
		Default.Nonexclusive  = True;
		Default.Deferred   = False;
		Default.Full       = False;
		CommonClientServer.SupplementStructure(Settings, Default, False);
	EndIf;
	
	Result = New Structure;
	Result.Insert("HasChanges", False);
	
	If Settings.Nonexclusive AND Settings.SharedData Then
		
		Query = New Query("SELECT * FROM InformationRegister.InformationPackagesOnStart ORDER BY Number");
		TableBeforeUpdate = Query.Execute().Unload();
		
		CommonDataNonexclusiveUpdate();
		
		TableAfterUpdate = Query.Execute().Unload();
		
		If Not Common.DataMatch(TableBeforeUpdate, TableAfterUpdate) Then
			Result.HasChanges = True;
		EndIf;
		
	EndIf;
	
	Return Result;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Configuration subsystems event handlers.

// See InfobaseUpdateSSL.OnAddUpdateHandlers. 
Procedure OnAddUpdateHandlers(Handlers) Export
	Handler = Handlers.Add();
	Handler.ExecuteInMandatoryGroup = True;
	Handler.SharedData                  = True;
	Handler.HandlerManagement      = False;
	Handler.ExecutionMode              = "Seamless";
	Handler.Version      = "*";
	Handler.Procedure   = "InformationOnStart.CommonDataNonexclusiveUpdate";
	Handler.Comment = NStr("ru = 'Актуализирует данные первого показа.'; en = 'Updates data of the first show.'; pl = 'Updates data of the first show.';de = 'Updates data of the first show.';ro = 'Updates data of the first show.';tr = 'Updates data of the first show.'; es_ES = 'Updates data of the first show.'");
	Handler.Priority   = 100;
EndProcedure

// See InfobaseUpdateSSL.AfterUpdateInfobase. 
Procedure AfterUpdateInfobase(Val PreviousVersion, Val CurrentVersion,
		Val CompletedHandlers, OutputUpdatesDetails, ExclusiveMode) Export
	
	Common.CommonSettingsStorageDelete("InformationOnStart", Undefined, Undefined);
	
EndProcedure

// See CommonOverridable.OnAddClientParametersOnStart. 
Procedure OnAddClientParametersOnStart(Parameters) Export
	Parameters.Insert("InformationOnStart", New FixedStructure(GlobalSettings()));
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Updating an infobase.

// Updates data of the first show.
Procedure CommonDataNonexclusiveUpdate() Export
	
	UpdateFirstShowCache(DataProcessors.InformationOnStart.Create());
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Internal procedures and functions.

// Updates data of the first show.
Procedure UpdateFirstShowCache(TemplatesMedia)
	
	// Generating the general information about pages packages.
	PagesPackages = PagesPackages(TemplatesMedia);
	
	// Extracting packages data and recording them to the register.
	SetPrivilegedMode(True);
	RecordSet = InformationRegisters.InformationPackagesOnStart.CreateRecordSet();
	For Each Package In PagesPackages Do
		PackageKit = ExtractPackageFiles(TemplatesMedia, Package.TemplateName);
		
		Record = RecordSet.Add();
		Record.Number  = Package.NumberInRegister;
		Record.Content = New ValueStorage(PackageKit);
	EndDo;
	
	// Metadata is recorded to the register under number 0.
	Record = RecordSet.Add();
	Record.Number  = 0;
	Record.Content = New ValueStorage(PagesPackages);
	
	InfobaseUpdate.WriteData(RecordSet, False, False);
	SetPrivilegedMode(False);
	
EndProcedure

// Global subsystem settings.
Function GlobalSettings()
	Settings = New Structure;
	Settings.Insert("Show", True);
	
	If Metadata.DataProcessors.InformationOnStart.Templates.Count() = 0 Then
		Settings.Show = False;
	ElsIf Not StandardSubsystemsServer.IsBaseConfigurationVersion() AND Not ShowAtStartup() Then
		// Disabling information in the PRO version if the user cleared the check box.
		Settings.Show = False;
	EndIf;
	
	If Settings.Show Then
		// Disabling information if changes details are displayed.
		If Common.SubsystemExists("StandardSubsystems.IBVersionUpdate") Then
			ModuleInfobaseUpdateInternal = Common.CommonModule("InfobaseUpdateInternal");
			If ModuleInfobaseUpdateInternal.ShowChangeHistory() Then
				Settings.Show = False;
			EndIf;
		EndIf;
	EndIf;
	
	If Settings.Show Then
		// Disabling information if the assistant of setting completion of the subordinate DIB node is displayed.
		If Common.SubsystemExists("StandardSubsystems.DataExchange") Then
			ModuleDataExchangeServer = Common.CommonModule("DataExchangeServer");
			If ModuleDataExchangeServer.OpenDataExchangeCreationWizardForSubordinateNodeSetup() Then
				Settings.Show = False;
			EndIf;
		EndIf;
	EndIf;
	
	If Settings.Show Then
		SetPrivilegedMode(True);
		RegisterRecord = InformationRegisters.InformationPackagesOnStart.Get(New Structure("Number", 0));
		PagesPackages = RegisterRecord.Content.Get();
		SetPrivilegedMode(False);
		If PagesPackages = Undefined Then
			Settings.Show = False;
		Else
			Information = PreparePagesPackageForOutput(PagesPackages, BegOfDay(CurrentSessionDate()));
			If Information.PreparedPackages.Count() = 0
				Or Information.MinimumPriority = 100 Then
				Settings.Show = False;
			EndIf;
		EndIf;
	EndIf;
	
	// Overriding.
	InformationOnStartOverridable.DefineSettings(Settings);
	
	Return Settings;
EndFunction

// Read the stored value of the "Show on startup" check box.
Function ShowAtStartup() Export
	Show = Common.CommonSettingsStorageLoad("InformationOnStart", "Show", True);
	If Not Show Then
		NextShowDate = Common.CommonSettingsStorageLoad("InformationOnStart", "NextShowDate");
		If NextShowDate <> Undefined
			AND NextShowDate > CurrentSessionDate() Then
			Return False;
		EndIf;
	EndIf;
	Return True;
EndFunction

// Global subsystem settings.
Function PagesPackages(TemplatesMedia) Export
	Result = New ValueTable;
	Result.Columns.Add("NumberInRegister",                New TypeDescription("Number"));
	Result.Columns.Add("ID",                 New TypeDescription("String"));
	Result.Columns.Add("TemplateName",                     New TypeDescription("String"));
	Result.Columns.Add("Section",                        New TypeDescription("String"));
	Result.Columns.Add("StartPageDescription", New TypeDescription("String"));
	Result.Columns.Add("HomePageFileName",     New TypeDescription("String"));
	Result.Columns.Add("ShowFrom",              New TypeDescription("Date"));
	Result.Columns.Add("ShowTill",           New TypeDescription("Date"));
	Result.Columns.Add("Priority",                     New TypeDescription("Number"));
	Result.Columns.Add("ShowInProf",               New TypeDescription("Boolean"));
	Result.Columns.Add("ShowInBasic",            New TypeDescription("Boolean"));
	Result.Columns.Add("ShowInSaaS",      New TypeDescription("Boolean"));
	
	NUmberInRegister = 0;
	
	// Read the Specifier template.
	SpreadsheetDocument = TemplatesMedia.GetTemplate("Specifier");
	For RowNumber = 3 To SpreadsheetDocument.TableHeight Do
		RowPrefix = "R"+ RowNumber +"C";
		
		// Read the first column data.
		TemplateName = CellData(SpreadsheetDocument, RowPrefix, 1, , "TableEnd");
		If Upper(TemplateName) = Upper("TableEnd") Then
			Break;
		EndIf;
		
		StartPageDescription = CellData(SpreadsheetDocument, RowPrefix, 3);
		If Not ValueIsFilled(StartPageDescription) Then
			Continue;
		EndIf;
		
		NUmberInRegister = NUmberInRegister + 1;
		
		// Registering command information.
		TableRow = Result.Add();
		TableRow.NumberInRegister                = NUmberInRegister;
		TableRow.TemplateName                     = TemplateName;
		TableRow.ID                 = String(RowNumber - 2);
		TableRow.Section                        = CellData(SpreadsheetDocument, RowPrefix, 2);
		TableRow.StartPageDescription = StartPageDescription;
		TableRow.HomePageFileName     = CellData(SpreadsheetDocument, RowPrefix, 4);
		TableRow.ShowFrom              = CellData(SpreadsheetDocument, RowPrefix, 5, "Date", '00010101');
		TableRow.ShowTill           = CellData(SpreadsheetDocument, RowPrefix, 6, "Date", '29990101');
		
		If Lower(TableRow.Section) = Lower(NStr("ru = 'Реклама'; en = 'Ads'; pl = 'Ads';de = 'Ads';ro = 'Ads';tr = 'Ads'; es_ES = 'Ads'")) Then
			TableRow.Priority = 0;
		Else
			TableRow.Priority = CellData(SpreadsheetDocument, RowPrefix, 7, "Number", 0);
			If TableRow.Priority = 0 Then
				TableRow.Priority = 99;
			EndIf;
		EndIf;
		
		TableRow.ShowInProf          = CellData(SpreadsheetDocument, RowPrefix, 8, "Boolean", True);
		TableRow.ShowInBasic       = CellData(SpreadsheetDocument, RowPrefix, 9, "Boolean", True);
		TableRow.ShowInSaaS = CellData(SpreadsheetDocument, RowPrefix, 10, "Boolean", True);
		
	EndDo;
	
	Return Result;
EndFunction

// Reads the contents of a cell from a spreadsheet document and converts to the specified type.
Function CellData(SpreadsheetDocument, RowPrefix, ColumnNumber, Type = "String", DefaultValue = "")
	Result = TrimAll(SpreadsheetDocument.Area(RowPrefix + String(ColumnNumber)).Text);
	If IsBlankString(Result) Then
		Return DefaultValue;
	ElsIf Type = "Number" Then
		Return Number(Result);
	ElsIf Type = "Date" Then
		Return Date(Result);
	ElsIf Type = "Boolean" Then
		Return Result <> "0";
	Else
		Return Result;
	EndIf;
EndFunction

// Global subsystem settings.
Function PreparePagesPackageForOutput(PagesPackages, CurrentDate) Export
	Result = New Structure;
	Result.Insert("MinimumPriority", 100);
	Result.Insert("PreparedPackages", Undefined);
	
	If Common.DataSeparationEnabled()
		Or GetFunctionalOption("StandaloneMode") Then
		ColumnShow = PagesPackages.Columns.ShowInSaaS;
	Else
		If StandardSubsystemsServer.IsBaseConfigurationVersion() Then
			ColumnShow = PagesPackages.Columns.ShowInBasic;
		Else
			ColumnShow = PagesPackages.Columns.ShowInProf;
		EndIf;
	EndIf;
	
	ColumnShow.Name = "Show";
	Filter = New Structure("Show", True);
	FoundItems = PagesPackages.FindRows(Filter);
	For Each Package In FoundItems Do
		If Package.ShowFrom > CurrentDate Or Package.ShowTill < CurrentDate Then
			Package.Show = False;
			Continue;
		EndIf;
		
		If Result.MinimumPriority > Package.Priority Then
			Result.MinimumPriority = Package.Priority;
		EndIf;
	EndDo;
	
	ColumnNames = "NumberInRegister, ID, TemplateName, Section, StartPageDescription, HomePageFileName, Priority";
	Result.PreparedPackages = PagesPackages.Copy(Filter, ColumnNames);
	Return Result;
EndFunction

// Extracts files package from the InformationOnStart processing template.
Function ExtractPackageFiles(TemplatesMedia, TemplateName) Export
	TempFilesDirectory = FileSystem.CreateTemporaryDirectory("extras");
	
	// Page extraction
	ArchiveFullName = TempFilesDirectory + "tmp.zip";
	Try
		TemplatesCollection = TemplatesMedia.Metadata().Templates;
		
		LocalizedTemplateName = TemplateName + "_" + CurrentLanguage().LanguageCode;
		Template                   = TemplatesCollection.Find(LocalizedTemplateName);
		If Template = Undefined Then
			LocalizedTemplateName = TemplateName + "_" + Metadata.DefaultLanguage.LanguageCode;
			Template                   = TemplatesCollection.Find(LocalizedTemplateName);
		EndIf;
		
		If Template = Undefined Then
			LocalizedTemplateName = TemplateName;
		EndIf;
		
		BinaryData = TemplatesMedia.GetTemplate(LocalizedTemplateName);
		BinaryData.Write(ArchiveFullName);
	Except
		WriteLogEvent(
			NStr("ru = 'Информация при запуске'; en = 'Notification at startup'; pl = 'Notification at startup';de = 'Notification at startup';ro = 'Notification at startup';tr = 'Notification at startup'; es_ES = 'Notification at startup'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,
			,
			,
			DetailErrorDescription(ErrorInfo()));
		Return Undefined;
	EndTry;
	
	ZIPFileReader = New ZipFileReader(ArchiveFullName);
	ZIPFileReader.ExtractAll(TempFilesDirectory, ZIPRestoreFilePathsMode.Restore);
	ZIPFileReader.Close();
	ZIPFileReader = Undefined;
	
	DeleteFiles(ArchiveFullName);
	
	Pictures = New ValueTable;
	Pictures.Columns.Add("RelativeName",     New TypeDescription("String"));
	Pictures.Columns.Add("RelativeDirectory", New TypeDescription("String"));
	Pictures.Columns.Add("Data");
	
	WebPages = New ValueTable;
	WebPages.Columns.Add("RelativeName",     New TypeDescription("String"));
	WebPages.Columns.Add("RelativeDirectory", New TypeDescription("String"));
	WebPages.Columns.Add("Data");
	
	// Registering page references and generating a list of pictures.
	FilesDirectories = New ValueList;
	FilesDirectories.Add(TempFilesDirectory, "");
	Left = 1;
	While Left > 0 Do
		Left = Left - 1;
		Directory = FilesDirectories[0];
		DirectoryFullPath        = Directory.Value; // Full path in file system format.
		DirectoryRelativePath = Directory.Presentation; // Relative path in URL format.
		FilesDirectories.Delete(0);
		
		FoundItems = FindFiles(DirectoryFullPath, "*", False);
		For Each File In FoundItems Do
			FileRelativeName = DirectoryRelativePath + File.Name;
			
			If File.IsDirectory() Then
				Left = Left + 1;
				FilesDirectories.Add(File.FullName, FileRelativeName + "/");
				Continue;
			EndIf;
			
			Extension = StrReplace(Lower(File.Extension), ".", "");
			
			If Extension = "htm" OR Extension = "html" Then
				FileLocation = WebPages.Add();
				TextReader = New TextReader(File.FullName);
				Data = TextReader.Read();
				TextReader.Close();
				TextReader = Undefined;
			Else
				FileLocation = Pictures.Add();
				Data = New Picture(New BinaryData(File.FullName));
			EndIf;
			FileLocation.RelativeName     = FileRelativeName;
			FileLocation.RelativeDirectory = DirectoryRelativePath;
			FileLocation.Data               = Data;
		EndDo;
	EndDo;
	
	// Deleting temporary files (all files were placed to the temporary storage).
	FileSystem.DeleteTemporaryDirectory(TempFilesDirectory);
	
	Result = New Structure;
	Result.Insert("Pictures", Pictures);
	Result.Insert("WebPages", WebPages);
	
	Return Result;
EndFunction

#EndRegion