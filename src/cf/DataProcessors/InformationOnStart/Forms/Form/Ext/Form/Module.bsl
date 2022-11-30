///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	CurrentLineIndex = -1;
	BaseConfiguration = StandardSubsystemsServer.IsBaseConfigurationVersion();
	
	StandardPrefix = GetInfoBaseURL() + "/";
	IsWebClient = StrFind(StandardPrefix, "http://") > 0;
	If IsWebClient Then
		LocalizationCode = CurrentLocaleCode();
		StandardPrefix = StandardPrefix + LocalizationCode + "/";
	EndIf;
	
	DataSaveRight = AccessRight("SaveUserData", Metadata);
	
	If BaseConfiguration Or Not DataSaveRight Then
		Items.ShowAtStartup.Visible = False;
	Else
		ShowAtStartup = InformationOnStart.ShowAtStartup();
	EndIf;
	
	If Not PrepareFormData() Then
		OpeningDenied = True;
	EndIf;
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	If OpeningDenied Then
		Cancel = True;
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure WebContentOnClick(Item, EventData, StandardProcessing)
	If EventData.Property("href") AND ValueIsFilled(EventData.href) Then
		PageNameToOpen = TrimAll(EventData.href);
		Protocol = Upper(StrLeftBeforeChar(PageNameToOpen, ":"));
		If Protocol <> "HTTP" AND Protocol <> "HTTPS" AND Protocol <> "E1C" Then
			Return; // Not a reference
		EndIf;
		
		If StrFind(PageNameToOpen, StandardPrefix) > 0 Then
			PageNameToOpen = StrReplace(PageNameToOpen, StandardPrefix, "");
			If StrStartsWith(PageNameToOpen, "#") Then
				Return;
			EndIf;
			ViewPage("ByInternalRef", PageNameToOpen);
		ElsIf StrFind(PageNameToOpen, StrReplace(StandardPrefix, " ", "%20")) > 0 Then
			PageNameToOpen = StrReplace(PageNameToOpen, "%20", " ");
			PageNameToOpen = StrReplace(PageNameToOpen, StandardPrefix, "");
			If StrStartsWith(PageNameToOpen, "#") Then
				Return;
			EndIf;
			ViewPage("ByInternalRef", PageNameToOpen);
		Else
			FileSystemClient.OpenURL(PageNameToOpen);
		EndIf;
		StandardProcessing = False;
	EndIf;
EndProcedure

&AtClient
Procedure ShowOnStartOnChange(Item)
	If Not BaseConfiguration AND DataSaveRight Then
		SaveCheckBoxState(ShowAtStartup);
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Forward(Command)
	ViewPage("Forward", Undefined);
EndProcedure

&AtClient
Procedure Back(Command)
	ViewPage("Back", Undefined);
EndProcedure

&AtClient
Procedure Attachable_GoToPage(Command)
	ViewPage("CommandFromCommandBar", Command.Name);
EndProcedure

#EndRegion

#Region Private

&AtServer
Function PrepareFormData()
	CurrentSectionDescription = "-";
	CurrentSubmenu = Undefined;
	SubmenuAdded = 0;
	PackagesWithMinimumPriority = New Array;
	MainLocked = False;
	
	UseRegisterCache = True;
	If Common.DebugMode()
		Or Lower(StrLeftBeforeChar(ThisObject.FormName, ".")) = Lower("ExternalDataProcessor") Then
		UseRegisterCache = False;
	EndIf;
	
	If UseRegisterCache Then
		SetPrivilegedMode(True);
		RegisterRecord = InformationRegisters.InformationPackagesOnStart.Get(New Structure("Number", 0));
		PagesPackages = RegisterRecord.Content.Get();
		SetPrivilegedMode(False);
		If PagesPackages = Undefined Then
			UseRegisterCache = False;
		EndIf;
	EndIf;
	
	If Not UseRegisterCache Then
		PagesPackages = InformationOnStart.PagesPackages(FormAttributeToValue("Object"));
	EndIf;
	
	Information = InformationOnStart.PreparePagesPackageForOutput(PagesPackages, BegOfDay(CurrentSessionDate()));
	If Information.PreparedPackages.Count() = 0
		Or Information.MinimumPriority = 100 Then
		Return False;
	EndIf;
	
	PreparedPackages.Load(Information.PreparedPackages);
	PreparedPackages.Sort("Section");
	For Each PagesPackage In PreparedPackages Do
		PagesPackage.FormCaption = NStr("ru = 'Информация'; en = 'Information'; pl = 'Information';de = 'Information';ro = 'Information';tr = 'Information'; es_ES = 'Information'");
		
		If PagesPackage.Priority = Information.MinimumPriority Then
			PackagesWithMinimumPriority.Add(PagesPackage);
		EndIf;
		
		If StrStartsWith(PagesPackage.Section, "_") Then
			SubmenuNumber = Mid(PagesPackage.Section, 2);
			If SubmenuNumber = "0" Then
				PagesPackage.Section = "";
				If Not MainLocked Then
					PagesPackage.ID = "MainPage";
					MainLocked = True;
					Continue;
				EndIf;
				CurrentSubmenu = Items.NoSubmenu;
			Else
				SubmenuName = "Popup" + SubmenuNumber;
				CurrentSubmenu = Items.Find(SubmenuName);
				If CurrentSubmenu = Undefined Then
					Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Не найдена группа ""%1""'; en = 'Group ""%1"" is not found'; pl = 'Group ""%1"" is not found';de = 'Group ""%1"" is not found';ro = 'Group ""%1"" is not found';tr = 'Group ""%1"" is not found'; es_ES = 'Group ""%1"" is not found'"), SubmenuName);
				EndIf;
				PagesPackage.Section = CurrentSubmenu.Title;
			EndIf;
		ElsIf CurrentSectionDescription <> PagesPackage.Section Then
			CurrentSectionDescription = PagesPackage.Section;
			
			IsMain = (PagesPackage.Section = NStr("ru = 'Главная'; en = 'Main'; pl = 'Main';de = 'Main';ro = 'Main';tr = 'Main'; es_ES = 'Main'"));
			If IsMain AND Not MainLocked Then
				PagesPackage.ID = "MainPage";
				MainLocked = True;
				Continue;
			EndIf;
			
			If IsMain Or PagesPackage.Section = "" Then
				CurrentSubmenu = Items.NoSubmenu;
			Else
				SubmenuAdded = SubmenuAdded + 1;
				SubmenuName = "Popup" + String(SubmenuAdded);
				CurrentSubmenu = Items.Find(SubmenuName);
				If CurrentSubmenu = Undefined Then
					CurrentSubmenu = Items.Add(SubmenuName, Type("FormGroup"), Items.TopBar);
					CurrentSubmenu.Type = FormGroupType.Popup;
				EndIf;
				CurrentSubmenu.Title = PagesPackage.Section;
			EndIf;
		EndIf;
		
		If CurrentSubmenu <> Items.NoSubmenu Then
			PagesPackage.FormCaption = PagesPackage.FormCaption + ": " + PagesPackage.Section +" / "+ PagesPackage.StartPageDescription;
		EndIf;
		
		CommandName = "AddedItem_" + PagesPackage.ID;
		
		Command = Commands.Add(CommandName);
		Command.Action = "Attachable_GoToPage";
		Command.Title = PagesPackage.StartPageDescription;
		
		Button = Items.Add(CommandName, Type("FormButton"), CurrentSubmenu);
		Button.CommandName = CommandName;
		
	EndDo;
	
	Items.MainPage.Visible = MainLocked;
	
	// Determine a package for display.
	RNG = New RandomNumberGenerator;
	RowNumber = RNG.RandomNumber(1, PackagesWithMinimumPriority.Count());
	StartPagesPackage = PackagesWithMinimumPriority[RowNumber-1];
	
	// Read package from the register.
	If UseRegisterCache Then
		Filter = New Structure("Number", StartPagesPackage.NumberInRegister);
		SetPrivilegedMode(True);
		RegisterRecord = InformationRegisters.InformationPackagesOnStart.Get(Filter);
		PackageFiles = RegisterRecord.Content.Get();
		SetPrivilegedMode(False);
	Else
		PackageFiles = Undefined;
	EndIf;
	If PackageFiles = Undefined Then
		PackageFiles = InformationOnStart.ExtractPackageFiles(FormAttributeToValue("Object"), StartPagesPackage.TemplateName);
	EndIf;
	
	// Preparing package for display.
	PlacePackagePages(StartPagesPackage, PackageFiles);
	
	// Displaying the first page.
	If Not ViewPage("CommandFromAddedItemsTable", StartPagesPackage) Then
		Return False;
	EndIf;
	
	Return True;
EndFunction

&AtServer
Function ViewPage(ActionType, Parameter = Undefined)
	Var PagesPackage, PageAddress, NewHistoryRow, NewRowIndex;
	
	If ActionType = "ByInternalRef" Then
		
		PageNameToOpen = Parameter;
		HistoryRow = BrowseHistory.Get(CurrentLineIndex);
		PagesPackage = PreparedPackages.FindByID(HistoryRow.PackageID);
		
		Search = New Structure("RelativeName", StrReplace(PageNameToOpen, "\", "/"));
		
		FoundItems = PagesPackage.WebPages.FindRows(Search);
		If FoundItems.Count() = 0 Then
			Return False;
		EndIf;
		PageAddress = FoundItems[0].Address;
		
	ElsIf ActionType = "Back" Or ActionType = "Forward" Then
		
		HistoryRow = BrowseHistory.Get(CurrentLineIndex);
		
		NewRowIndex = CurrentLineIndex + ?(ActionType = "Back", -1, +1);
		NewHistoryRow = BrowseHistory[NewRowIndex];
		
		PagesPackage = PreparedPackages.FindByID(NewHistoryRow.PackageID);
		PageAddress = NewHistoryRow.PageAddress;
		
	ElsIf ActionType = "CommandFromCommandBar" Then
		
		CommandName = Parameter;
		FoundItems = PreparedPackages.FindRows(New Structure("ID", StrReplace(CommandName, "AddedItem_", "")));
		If FoundItems.Count() = 0 Then
			Return False;
		EndIf;
		PagesPackage = FoundItems[0];
		
	ElsIf ActionType = "CommandFromAddedItemsTable" Then
		
		PagesPackage = Parameter;
		
	Else
		
		Return False;
		
	EndIf;
	
	// Placement in temporary storage.
	If PagesPackage.HomePageURL = "" Then
		PackageFiles = InformationOnStart.ExtractPackageFiles(FormAttributeToValue("Object"), PagesPackage.TemplateName);
		PlacePackagePages(PagesPackage, PackageFiles);
	EndIf;
	
	// Get the address of page placement in the temporary storage.
	If PageAddress = Undefined Then
		PageAddress = PagesPackage.HomePageURL;
	EndIf;
	
	// Registering in view history.
	If NewHistoryRow = Undefined Then
		
		NewHistoryRowStructure = New Structure("PackageID, PageAddress");
		NewHistoryRowStructure.PackageID = PagesPackage.GetID();
		NewHistoryRowStructure.PageAddress = PageAddress;
		
		FoundItems = BrowseHistory.FindRows(NewHistoryRowStructure);
		For Each NewHistoryRowDuplicate In FoundItems Do
			BrowseHistory.Delete(NewHistoryRowDuplicate);
		EndDo;
		
		NewHistoryRow = BrowseHistory.Add();
		FillPropertyValues(NewHistoryRow, NewHistoryRowStructure);
		
	EndIf;
	
	If NewRowIndex = Undefined Then
		NewRowIndex = BrowseHistory.IndexOf(NewHistoryRow);
	EndIf;
	
	If ActionType = "ByInternalRef" AND CurrentLineIndex <> -1 AND CurrentLineIndex <> NewRowIndex - 1 Then
		IndexesDifferences = CurrentLineIndex - NewRowIndex;
		Offset = IndexesDifferences + ?(IndexesDifferences < 0, 1, 0);
		BrowseHistory.Move(NewRowIndex, Offset);
		NewRowIndex = NewRowIndex + Offset;
	EndIf;
	
	CurrentLineIndex = NewRowIndex;
	
	// Visibility and availability.
	Items.FormBack.Enabled = (CurrentLineIndex > 0);
	Items.NextForm.Enabled = (CurrentLineIndex < BrowseHistory.Count() - 1);
	
	// Set web content and form header.
	WebContent = GetFromTempStorage(PageAddress);
	Title = PagesPackage.FormCaption;
	
	Return True;
EndFunction

&AtServer
Procedure PlacePackagePages(PagesPackage, PackageFiles)
	PackageFiles.Pictures.Columns.Add("Address", New TypeDescription("String"));
	
	// Registering pictures and references to the online help page.
	For Each WebPage In PackageFiles.WebPages Do
		HTMLText = WebPage.Data;
		
		// Registering pictures.
		Length = StrLen(WebPage.RelativeDirectory);
		For Each Picture In PackageFiles.Pictures Do
			// Storing pictures to a temporary storage.
			If IsBlankString(Picture.Address) Then
				Picture.Address = PutToTempStorage(Picture.Data, UUID);
			EndIf;
			// Calculate the path from the page to the picture.
			// For example, in the page "/1/a.htm" the path to the picture "/1/2/b.png" will be "2/b.png".
			PathToPicture = Picture.RelativeName;
			If Length > 0 AND StrStartsWith(PathToPicture, WebPage.RelativeDirectory) Then
				PathToPicture = Mid(PathToPicture, Length + 1);
			EndIf;
			// Replacing relative paths of the picture to addresses in temporary storage.
			HTMLText = StrReplace(HTMLText, PathToPicture, Picture.Address);
		EndDo;
		
		// Replacing relative embedded references to absolute ones for this infobase.
		HTMLText = StrReplace(HTMLText, "v8config://", StandardPrefix + "e1cib/helpservice/topics/v8config/");
		
		// Registering online help hyperlinks.
		AddOnlineHelpURLs(HTMLText, PagesPackage.WebPages);
		
		// Placing HTML content in temporary storage.
		WebPageRegistration = PagesPackage.WebPages.Add();
		WebPageRegistration.RelativeName     = WebPage.RelativeName;
		WebPageRegistration.RelativeDirectory = WebPage.RelativeDirectory;
		WebPageRegistration.Address                = PutToTempStorage(HTMLText, UUID);
		
		// Registering home page.
		If WebPageRegistration.RelativeName = PagesPackage.HomePageFileName Then
			PagesPackage.HomePageURL = WebPageRegistration.Address;
		EndIf;
	EndDo;
EndProcedure

&AtServerNoContext
Procedure SaveCheckBoxState(ShowAtStartup)
	Common.CommonSettingsStorageSave("InformationOnStart", "Show", ShowAtStartup);
	If Not ShowAtStartup Then
		NextShowDate = BegOfDay(CurrentSessionDate() + 14*24*60*60);
		Common.CommonSettingsStorageSave("InformationOnStart", "NextShowDate", NextShowDate);
	EndIf;
EndProcedure

&AtServer
Procedure AddOnlineHelpURLs(HTMLText, WebPages)
	OnlineHelpURLPrefix = """" + StandardPrefix + "e1cib/helpservice/topics/v8config/v8cfgHelp/";
	Balance = HTMLText;
	While True Do
		PrefixPosition = StrFind(Balance, OnlineHelpURLPrefix);
		If PrefixPosition = 0 Then
			Break;
		EndIf;
		Balance = Mid(Balance, PrefixPosition + 1);
		
		QuoteCharPosition = StrFind(Balance, """");
		If QuoteCharPosition = 0 Then
			Break;
		EndIf;
		Hyperlink = Left(Balance, QuoteCharPosition - 1);
		Balance = Mid(Balance, QuoteCharPosition + 1);
		
		RelativeName = StrReplace(Hyperlink, StandardPrefix, "");
		Content = Hyperlink;
		
		FileLocation = WebPages.Add();
		FileLocation.RelativeName = RelativeName;
		FileLocation.Address = PutToTempStorage(Content, UUID);
		FileLocation.RelativeDirectory = "";
	EndDo;
EndProcedure

&AtClientAtServerNoContext
Function StrLeftBeforeChar(Row, Separator, Balance = Undefined)
	Position = StrFind(Row, Separator);
	If Position = 0 Then
		StringBeforeDot = Row;
		Balance = "";
	Else
		StringBeforeDot = Left(Row, Position - 1);
		Balance = Mid(Row, Position + StrLen(Separator));
	EndIf;
	Return StringBeforeDot;
EndFunction

#EndRegion
