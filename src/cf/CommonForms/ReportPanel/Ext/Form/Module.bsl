﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables
&AtClient
Var Msrmnt;
#EndRegion

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	DefineBehaviorInMobileClient();
	If Not ValueIsFilled(Parameters.SubsystemPath) Then
		Parameters.SubsystemPath = ReportsOptionsClientServer.HomePageID();
	EndIf;
	
	ClientParameters = ReportsOptions.ClientParameters();
	ClientParameters.Insert("SubsystemPath", Parameters.SubsystemPath);
	
	QuickAccessPicture = PictureLib.QuickAccess;
	HiddenOptionsColor = StyleColors.ReportHiddenColorVariant;
	VisibleOptionsColor = StyleColors.HyperlinkColor;
	SearchResultsHighlightColor = WebColors.Yellow;
	TooltipColor = StyleColors.NoteText;
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.CommandBar.Width = 25;
		Items.SearchString.Width = 35;
		ReportsOptionsGroupColor = StyleColors.ReportOptionsGroupColor82;
		ImportantGroupFont  = New Font("MS Shell Dlg", 10, True, False, False, False, 100);
		NormalGroupFont = New Font("MS Shell Dlg", 8, True, False, False, False, 100);
		SectionFont       = New Font("MS Shell Dlg", 12, True, False, False, False, 100);
		ImportantLabelFont = New Font(, , True);
	Else // Taxi.
		ReportsOptionsGroupColor = StyleColors.ReportOptionsGroupColor;
		ImportantGroupFont  = New Font("Arial", 12, False, False, False, False, 100);
		NormalGroupFont = New Font("Arial", 12, False, False, False, False, 90);
		SectionFont       = New Font("Arial", 12, True, False, False, False, 100);
		ImportantLabelFont = New Font("Arial", 10, True, False, False, False, 100);
	EndIf;
	If Not AccessRight("SaveUserData", Metadata) Then
		Items.Customize.Visible = False;
		Items.ResetMySettings.Visible = False;
	EndIf;
	
	GlobalSettings = ReportsOptions.GlobalSettings();
	Items.SearchString.InputHint = GlobalSettings.Search.InputHint;
	
	MobileApplicationDetails = CommonClientServer.StructureProperty(GlobalSettings, "MobileApplicationDescription");
	If MobileApplicationDetails = Undefined Then
		Items.MobileApplicationDescription.Visible = False;
	Else
		ClientParameters.Insert("MobileApplicationDescription", MobileApplicationDetails);
	EndIf;
	
	SectionColor = ReportsOptionsGroupColor;
	
	Items.QuickAccessHeaderLabel.Font      = ImportantGroupFont;
	Items.QuickAccessHeaderLabel.TextColor = ReportsOptionsGroupColor;
	Items.SeeAlso.TitleFont      = ImportantGroupFont;
	Items.SeeAlso.TitleTextColor = ReportsOptionsGroupColor;
	
	AttributesSet = GetAttributes();
	For Each Attribute In AttributesSet Do
		ConstantAttributes.Add(Attribute.Name);
	EndDo;
	
	For Each Command In Commands Do
		ConstantCommands.Add(Command.Name);
	EndDo;
	
	// Reading a user setting common to all report panels.
	ImportAllSettings();
	
	If Parameters.Property("SearchString") Then
		SearchString = Parameters.SearchString;
	EndIf;
	If Parameters.Property("SearchInAllSections") Then
		SearchInAllSections = Parameters.SearchInAllSections;
	Else
		SearchInAllSections = True;
	EndIf;
	
	// Filling in a panel.
	DefineSubsystemsAndTitle(Parameters);
	TimeConsumingOperation = UpdateReportPanelAtServer();
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	If ShowTooltipsNotification AND ShowTooltips Then
		ShowUserNotification(
			NStr("ru = 'Новая возможность'; en = 'New feature'; pl = 'Nowa możliwość';de = 'Neue Möglichkeiten';ro = 'Funcționalitate nouă';tr = 'Yeni imkan'; es_ES = 'Nueva posibilidad'"),
			"e1cib/data/SettingsStorage.ReportsVariantsStorage.Form.DetailsDisplayNewFeatureDetails",
			NStr("ru = 'Вывод описаний в панелях отчетов'; en = 'Show descriptions in report panels'; pl = 'Pokazywanie opisów w panelach sprawozdań';de = 'Zeigt Beschreibungen in Berichtsbereichen an';ro = 'Afișarea descrierilor în panourile rapoartelor';tr = 'Rapor panellerindeki açıklamaları görüntüleme'; es_ES = 'Mostrar las descripciones en las barras de informes'"),
			PictureLib.Information32);
	EndIf;
	If TimeConsumingOperation.Status = "Running" Then
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = False;
		Completion = New NotifyDescription("UpdateReportPanelCompletion", ThisObject);
		TimeConsumingOperationsClient.WaitForCompletion(TimeConsumingOperation, Completion, IdleParameters);
	EndIf;	
EndProcedure

&AtClient
Procedure UpdateReportPanelCompletion(Result, AdditionalParameters) Export
	
	TimeConsumingOperation = Undefined;
	If Result = Undefined Then
		Return;
	EndIf;
	If Result.Status = "Error" Then
		Raise Result.BriefErrorPresentation;
	EndIf;
	If Result.Status = "Completed" Then
		FillReportPanel(Result.ResultAddress);
		If ClientParameters.RunMeasurements Then
			EndMeasurement(Msrmnt);
		EndIf;
	EndIf;
	
EndProcedure 

&AtClient
Procedure OnReopen()
	If SetupMode Or ValueIsFilled(SearchString) Then
		SetupMode = False;
		SearchString = "";
		UpdateReportPanelAtClient("OnReopen");
	EndIf;
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Changes, Source)
	If Source = ThisObject Then
		Return;
	EndIf;
	If ClientParameters.Property("Update") Then
		DetachIdleHandler("UpdateReportPanelByTimer");
	Else
		ClientParameters.Insert("Update", False)
	EndIf;
	If EventName = ReportsOptionsClient.EventNameChangingOption()
		Or EventName = "Write_ConstantsSet" Then
		ClientParameters.Update = True;
	ElsIf EventName = ReportsOptionsClient.EventNameChangingCommonSettings() Then
		If Changes.ShowTooltips <> ShowTooltips
			Or Changes.SearchInAllSections <> SearchInAllSections Then
			ClientParameters.Update = True;
		EndIf;
		FillPropertyValues(ThisObject, Changes, "ShowTooltips, SearchInAllSections, ShowTooltipsNotification");
	EndIf;
	If ClientParameters.Update Then
		AttachIdleHandler("UpdateReportPanelByTimer", 1, True);
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure Attachable_OptionClick(Item)
	Option = FindOptionByItemName(Item.Name);
	If Option = Undefined Then
		Return;
	EndIf;
	ReportFormParameters = New Structure;
	Subsystem = FindSubsystemByRef(ThisObject, Option.Subsystem);
	If Subsystem.VisibleOptionsCount > 1 Then
		ReportFormParameters.Insert("Subsystem", Option.Subsystem);
	EndIf;
	ReportsOptionsClient.OpenReportForm(ThisObject, Option, ReportFormParameters);
EndProcedure

&AtClient
Procedure Attachable_OptionVisibilityOnChange(Item)
	CheckBox = Item;
	Show = ThisObject[CheckBox.Name];
	
	LabelName = Mid(CheckBox.Name, StrLen("CheckBox_")+1);
	Option = FindOptionByItemName(LabelName);
	Item = Items.Find(LabelName);
	If Option = Undefined Or Item = Undefined Then
		Return;
	EndIf;
	
	ShowHideOption(Option, Item, Show);
EndProcedure

&AtClient
Procedure SearchStringTextInputEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	If Not IsBlankString(Text) AND SearchStringIsTooShort(Text) Then
		StandardProcessing = False;
	EndIf;
EndProcedure

&AtClient
Function SearchStringIsTooShort(Text)
	Text = TrimAll(Text);
	If StrLen(Text) < 2 Then
		ShowMessageBox(, NStr("ru = 'Введена слишком короткая строка поиска.'; en = 'Search string is too short.'; pl = 'Wprowadzony zbyt krótki ciąg wyszukiwania';de = 'Suchzeichenfolge ist zu kurz.';ro = 'Șirul de căutare este prea scurt.';tr = 'Arama dizesi çok kısa.'; es_ES = 'Línea de búsqueda es demasiado corta.'"));
		Return True;
	EndIf;
	
	HasNormalWord = False;
	WordArray = ReportsOptionsClientServer.ParseSearchStringIntoWordArray(Text);
	For Each Word In WordArray Do
		If StrLen(Word) >= 2 Then
			HasNormalWord = True;
			Break;
		EndIf;
	EndDo;
	If Not HasNormalWord Then
		ShowMessageBox(, NStr("ru = 'Введены слишком короткие слова для поиска.'; en = 'Search words are too short.'; pl = 'Słowa do wyszukania są za krótkie.';de = 'Wörter für die Suche sind zu kurz.';ro = 'Cuvintele pentru căutare sunt prea scurte.';tr = 'Arama için kelimeler çok kısa.'; es_ES = 'Palabras de búsqueda son demasiado cortas.'"));
		Return True;
	EndIf;
	
	Return False;
EndFunction

&AtClient
Procedure SearchStringOnChange(Item)
	If Not IsBlankString(SearchString) AND SearchStringIsTooShort(SearchString) Then
		SearchString = "";
		CurrentItem = Items.SearchString;
		Return;
	EndIf;
	
	UpdateReportPanelAtClient("SearchStringOnChange");
	
	If ValueIsFilled(SearchString) Then
		CurrentItem = Items.SearchString;
	EndIf;
EndProcedure

&AtClient
Procedure Attachable_SectionTitleClick(Item)
	SectionGroupName = Item.Parent.Name;
	Substrings = StrSplit(SectionGroupName, "_");
	SectionPriority = Substrings[1];
	FoundItems = ApplicationSubsystems.FindRows(New Structure("Priority", SectionPriority));
	If FoundItems.Count() = 0 Then
		Return;
	EndIf;
	Section = FoundItems[0];
	
	SubsystemPath = StrReplace(Section.FullName, "Subsystem.", "");
	
	ParametersForm = New Structure;
	ParametersForm.Insert("SubsystemPath",      SubsystemPath);
	ParametersForm.Insert("SearchString",         SearchString);
	
	OwnerForm     = ThisObject;
	FormUniqueness = True;
	
	If ClientParameters.RunMeasurements Then
		Msrmnt = StartMeasurement("ReportPanel.Opening", ClientParameters.MeasurementsPrefix + "; " + SubsystemPath);
	EndIf;
	
	OpenForm("CommonForm.ReportPanel", ParametersForm, OwnerForm, FormUniqueness);
	
	If ClientParameters.RunMeasurements Then
		EndMeasurement(Msrmnt);
	EndIf;
EndProcedure

&AtClient
Procedure ShowTooltipsOnChange(Item)
	UpdateReportPanelAtClient("ShowTooltipsOnChange");
	
	CommonSettings = New Structure;
	CommonSettings.Insert("ShowTooltips",           ShowTooltips);
	CommonSettings.Insert("SearchInAllSections",          SearchInAllSections);
	CommonSettings.Insert("ShowTooltipsNotification", ShowTooltipsNotification);
	
	Notify(
		ReportsOptionsClient.EventNameChangingCommonSettings(),
		CommonSettings,
		ThisObject);
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Customize(Command)
	SetupMode = Not SetupMode;
	UpdateReportPanelAtClient(?(SetupMode, "EnableSetupMode", "DisableSetupMode"));
EndProcedure

&AtClient
Procedure MoveToQuickAccess(Command)
	
#If WebClient Then
	Item = Items.Find(Mid(Command.Name, StrFind(Command.Name, "_")+1));
#Else
	Item = CurrentItem;
#EndIf

	If TypeOf(Item) <> Type("FormDecoration") Then
		Return;
	EndIf;
	
	Option = FindOptionByItemName(Item.Name);
	If Option = Undefined Then
		Return;
	EndIf;
	
	AddRemoveOptionFromQuickAccess(Option, Item, True);
EndProcedure

&AtClient
Procedure RemoveFromQuickAccess(Command)
	
#If WebClient Then
	Item = Items.Find(Mid(Command.Name, StrFind(Command.Name, "_")+1));
#Else
	Item = CurrentItem;
#EndIf

	If TypeOf(Item) <> Type("FormDecoration") Then
		Return;
	EndIf;
	
	Option = FindOptionByItemName(Item.Name);
	If Option = Undefined Then
		Return;
	EndIf;
	
	AddRemoveOptionFromQuickAccess(Option, Item, False);
EndProcedure

&AtClient
Procedure Change(Command)
	
#If WebClient Then
	Item = Items.Find(Mid(Command.Name, StrFind(Command.Name, "_")+1));
#Else
	Item = CurrentItem;
#EndIf

	If TypeOf(Item) <> Type("FormDecoration") Then
		Return;
	EndIf;
	
	Option = FindOptionByItemName(Item.Name);
	If Option = Undefined Then
		Return;
	EndIf;
	
	ReportsOptionsClient.ShowReportSettings(Option.Ref);
EndProcedure

&AtClient
Procedure ClearSettings(Command)
	QuestionText = NStr("ru = 'Сбросить настройки расположения отчетов?'; en = 'Do you want to reset report assignment settings?'; pl = 'Zresetować ustawienia rozmieszczania sprawozdań?';de = 'Einstellungen für die Berichtsplatzierung zurücksetzen?';ro = 'Resetați setările de plasare a rapoartelor?';tr = 'Rapor yerleşimi ayarları sıfırlansın mı?'; es_ES = '¿Restablecer las configuraciones de la colocación del informe?'");
	Handler = New NotifyDescription("ClearSettingsCompletion", ThisObject);
	ShowQueryBox(Handler, QuestionText, QuestionDialogMode.YesNo, 60, DialogReturnCode.No);
EndProcedure

&AtClient
Procedure AllReports(Command)
	ParametersForm = New Structure;
	If ValueIsFilled(SearchString) Then
		ParametersForm.Insert("SearchString", SearchString);
	EndIf;
	If ValueIsFilled(SearchString) AND Not SetupMode AND SearchInAllSections = 1 Then
		// Position on a tree root.
		SectionRef = PredefinedValue("Catalog.MetadataObjectIDs.EmptyRef");
	Else
		SectionRef = CurrentSectionRef;
	EndIf;
	ParametersForm.Insert("SectionRef", SectionRef);
	
	If ClientParameters.RunMeasurements Then
		Msrmnt = StartMeasurement("ReportsList.Opening");
	EndIf;
	
	OpenForm("Catalog.ReportsOptions.ListForm", ParametersForm, , "ReportsOptions.AllReports");
	
	If ClientParameters.RunMeasurements Then
		EndMeasurement(Msrmnt);
	EndIf;
EndProcedure

&AtClient
Procedure Update(Command)
	UpdateReportPanelAtClient("Refresh");
EndProcedure

&AtClient
Procedure RunSearch(Command)
	UpdateReportPanelAtClient("RunSearch");
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Client

&AtClient
Procedure ShowHideOption(Option, Item, Show)
	Option.Visible = Show;
	Item.TextColor = ?(Show, VisibleOptionsColor, HiddenOptionsColor);
	ThisObject["CheckBox_"+ Option.LabelName] = Show;
	If Option.Important Then
		If Show Then
			Item.Font = ImportantLabelFont;
		Else
			Item.Font = New Font;
		EndIf;
	EndIf;
	Subsystem = FindSubsystemByRef(ThisObject, Option.Subsystem);
	Subsystem.VisibleOptionsCount = Subsystem.VisibleOptionsCount + ?(Show, 1, -1);
	While Subsystem.Ref <> Subsystem.SectionRef Do
		Subsystem = FindSubsystemByRef(ThisObject, Subsystem.SectionRef);
		Subsystem.VisibleOptionsCount = Subsystem.VisibleOptionsCount + ?(Show, 1, -1);
	EndDo;
	SaveUserSettingsSSL(Option.Ref, Option.Subsystem, Option.Visible, Option.QuickAccess);
EndProcedure

&AtClient
Procedure AddRemoveOptionFromQuickAccess(Option, Item, QuickAccess)
	If Option.QuickAccess = QuickAccess Then
		Return;
	EndIf;
	
	// Registering a result for writing.
	Option.QuickAccess = QuickAccess;
	
	// Related action: if the option to be added to the quick access list is hidden, showing this option.
	If QuickAccess AND Not Option.Visible Then
		ShowHideOption(Option, Item, True);
	EndIf;
	
	// Visual result
	MoveQuickAccessOption(Option.GetID(), QuickAccess);
EndProcedure

&AtClient
Procedure ClearSettingsCompletion(Response, AdditionalParameters) Export
	If Response = DialogReturnCode.Yes Then
		SetupMode = False;
		UpdateReportPanelAtClient("ClearSettings");
	EndIf;
EndProcedure

&AtClient
Procedure UpdateReportPanelByTimer()
	If ClientParameters.Update Then
		ClientParameters.Update = False;
		UpdateReportPanelAtClient("");
	EndIf;
EndProcedure

&AtClient
Function UpdateReportPanelAtClient(Event = "")
	If ClientParameters.RunMeasurements Then
		Msrmnt = StartMeasurement(Event);
	EndIf;
	
	Items.Pages.CurrentPage = Items.Wait;
	TimeConsumingOperation = UpdateReportPanelAtServer(Event);
	If TimeConsumingOperation <> Undefined AND TimeConsumingOperation.Status = "Running" Then
		Completion = New NotifyDescription("UpdateReportPanelCompletion", ThisObject);
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = False;
		TimeConsumingOperationsClient.WaitForCompletion(TimeConsumingOperation, Completion);
		Return True;
	EndIf;
	
	If ClientParameters.RunMeasurements Then
		EndMeasurement(Msrmnt);
	EndIf;
	
	If TimeConsumingOperation = Undefined Then
		Return False;
	EndIf;
	
	Return True;
EndFunction

&AtClient
Function StartMeasurement(Event, Comment = Undefined)
	If Comment = Undefined Then
		Comment = ClientParameters.MeasurementsPrefix;
	EndIf;
	
	Msrmnt = New Structure("Name, ID, ModulePerformanceMonitorClient");
	If Event = "ReportsList.Opening" Or Event = "ReportPanel.Opening" Then
		Msrmnt.Name = Event;
		Comment = Comment + "; " + NStr("ru = 'Из панели отчетов:'; en = 'From report panel:'; pl = 'Z panelu sprawozdań:';de = 'Aus dem Berichtsfenster:';ro = 'Din panoul rapoartelor:';tr = 'Rapor panelinden:'; es_ES = 'De la barra de informes:'") + " " + ClientParameters.SubsystemPath;
	Else
		If SetupMode Or Event = "DisableSetupMode" Then
			Msrmnt.Name = "ReportPanel.SetupMode";
		ElsIf ValueIsFilled(SearchString) Then
			Msrmnt.Name = "ReportPanel.Search"; // Search itself is interesting only in view mode.
		EndIf;
		Comment = Comment + "; " + ClientParameters.SubsystemPath;
		Comment = Comment + "; " + NStr("ru = 'Подсказки:'; en = 'Tooltips:'; pl = 'Podpowiedzi:';de = 'Hinweise:';ro = 'Sugestii:';tr = 'İpucular:'; es_ES = 'Pistas:'") + " " + String(ShowTooltips);
	EndIf;
	
	If Msrmnt.Name = Undefined Then
		Return Undefined;
	EndIf;
	
	If ValueIsFilled(SearchString) Then
		Comment = Comment
			+ "; " + NStr("ru = 'Поиск:'; en = 'Search:'; pl = 'Wyszukiwanie:';de = 'Suche:';ro = 'Căutare:';tr = 'Arama:'; es_ES = 'Búsqueda:'") + " " + String(SearchString)
			+ "; " + NStr("ru = 'Во всех разделах:'; en = 'In all sections:'; pl = 'We wszystkich rozdziałach:';de = 'In allen Bereichen:';ro = 'În toate compartimentele:';tr = 'Tüm bölümlerde:'; es_ES = 'En todas las secciones:'") + " " + String(SearchInAllSections);
	Else
		Comment = Comment + "; " + NStr("ru = 'Без поиска'; en = 'No search'; pl = 'Bez wyszukiwania';de = 'Ohne Suche';ro = 'Fără căutare';tr = 'Aramadan'; es_ES = 'Sin buscar'");
	EndIf;
	
	If Event = "DisableSetupMode" Then
		Comment = Comment + "; " + NStr("ru = 'Выход из режима настройки'; en = 'Quit setup mode'; pl = 'Wyjście z trybu ustawień';de = 'Verlassen des Einstellungsmodus';ro = 'Ieșire din regimul de configurare';tr = 'Ayarlar modundan çıkış'; es_ES = 'Salir del modo de ajustes'");
	EndIf;
	Msrmnt.ModulePerformanceMonitorClient = CommonClient.CommonModule("PerformanceMonitorClient");
	Msrmnt.ID = Msrmnt.ModulePerformanceMonitorClient.TimeMeasurement(Msrmnt.Name);
	Msrmnt.ModulePerformanceMonitorClient.SetMeasurementComment(Msrmnt.ID, Comment);
	Return Msrmnt;
EndFunction

&AtClient
Procedure EndMeasurement(Msrmnt)
	If Msrmnt <> Undefined Then
		Msrmnt.ModulePerformanceMonitorClient.StopTimeMeasurement(Msrmnt.ID);
	EndIf;
EndProcedure

&AtClient
Function FindOptionByItemName(LabelName)
	ID = ReportOptionByItemName[LabelName];
	If ID <> Undefined Then
		Return AddedOptions.FindByID(ID);
	Else
		FoundItems = AddedOptions.FindRows(New Structure("LabelName", LabelName));
		If FoundItems.Count() = 1 Then
			Return FoundItems[0];
		EndIf;
	EndIf;
	Return Undefined;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Server call

&AtClientAtServerNoContext
Function FindSubsystemByRef(Form, Ref)
	ID = Form.SubsystemByReference[Ref];
	If ID <> Undefined Then
		Return Form.ApplicationSubsystems.FindByID(ID);
	EndIf;
	
	FoundItems = Form.ApplicationSubsystems.FindRows(New Structure("Ref", Ref));
	If FoundItems.Count() = 1 Then
		Return FoundItems[0];
	EndIf;
	Return Undefined;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Server call

&AtServer
Procedure MoveQuickAccessOption(Val OptionID, Val QuickAccess)
	Option = AddedOptions.FindByID(OptionID);
	Item = Items.Find(Option.LabelName);
	
	If QuickAccess Then
		Item.Font = New Font;
		GroupToTransfer = SubgroupWithMinimalItemsCount(Items.QuickAccess);
	ElsIf Option.SeeAlso Then
		Item.Font = New Font;
		GroupToTransfer = SubgroupWithMinimalItemsCount(Items.SeeAlso);
	ElsIf Option.NoGroup Then
		Item.Font = ?(Option.Important, ImportantLabelFont, New Font);
		GroupToTransfer = SubgroupWithMinimalItemsCount(Items.NoGroup);
	Else
		Item.Font = ?(Option.Important, ImportantLabelFont, New Font);
		Subsystem = FindSubsystemByRef(ThisObject, Option.Subsystem);
		
		GroupToTransfer = Items.Find(Subsystem.ItemName + "_1");
		If GroupToTransfer = Undefined Then
			Return;
		EndIf;
	EndIf;
	
	BeforeWhichItem = Undefined;
	If GroupToTransfer.ChildItems.Count() > 0 Then
		BeforeWhichItem = GroupToTransfer.ChildItems.Get(0);
	EndIf;
	
	Items.Move(Item.Parent, GroupToTransfer, BeforeWhichItem);
	
	If QuickAccess Then
		Items.QuickAccessTooltipWhenNotConfigured.Visible = False;
	Else
		QuickAccessOptions = AddedOptions.FindRows(New Structure("QuickAccess", True));
		If QuickAccessOptions.Count() = 0 Then
			Items.QuickAccessTooltipWhenNotConfigured.Visible = True;
		Else
			Items.QuickAccessTooltipWhenNotConfigured.Visible = False;
		EndIf;
	EndIf;
	
	CheckBoxName = "CheckBox_" + Option.LabelName;
	CheckBox = Items.Find(CheckBoxName);
	CheckBoxIsDisplayed = (CheckBox.Visible = True);
	If CheckBoxIsDisplayed = QuickAccess Then
		CheckBox.Visible = Not QuickAccess;
	EndIf;
	
	LabelContextMenu = Item.ContextMenu;
	If LabelContextMenu <> Undefined Then
		ButtonRemove = Items.Find("RemoveFromQuickAccess_" + Option.LabelName);
		ButtonRemove.Visible = QuickAccess;
		ButtonMove = Items.Find("MoveToQuickAccess_" + Option.LabelName);
		ButtonMove.Visible = Not QuickAccess;
	EndIf;
	
	SaveUserSettingsSSL(Option.Ref, Option.Subsystem, Option.Visible, Option.QuickAccess);
EndProcedure

&AtServer
Function UpdateReportPanelAtServer(Val Event = "")
	
	If ValueIsFilled(Event) AND TimeConsumingOperation <> Undefined AND TimeConsumingOperation.Status = "Running" Then 
		Return Undefined;
	EndIf;
	
	If Event = "ClearSettings" Then
		InformationRegisters.ReportOptionsSettings.ResetUserSettingsInSection(CurrentSectionRef);
	EndIf;
	
	If Event = "" Or Event = "SearchStringOnChange" Or Event = "ClearSettings" Then
		If ValueIsFilled(SearchString) Then
			ChoiceList = Items.SearchString.ChoiceList;
			ListItem = ChoiceList.FindByValue(SearchString);
			If ListItem = Undefined Then
				ChoiceList.Insert(0, SearchString);
				If ChoiceList.Count() > 10 Then
					ChoiceList.Delete(10);
				EndIf;
			Else
				Index = ChoiceList.IndexOf(ListItem);
				If Index <> 0 Then
					ChoiceList.Move(Index, -Index);
				EndIf;
			EndIf;
			If Event = "SearchStringOnChange" Then
				SaveSettingsOfThisReportPanel();
			EndIf;
		EndIf;
	ElsIf Event = "ShowTooltipsOnChange"
		Or Event = "SearchInAllSectionsOnChange" Then
		
		CommonSettings = New Structure;
		CommonSettings.Insert("ShowTooltips",           ShowTooltips);
		CommonSettings.Insert("SearchInAllSections",          SearchInAllSections);
		CommonSettings.Insert("ShowTooltipsNotification", ShowTooltipsNotification);
		
		ReportsOptions.SaveCommonPanelSettings(CommonSettings);
		
	EndIf;
	
	Items.ShowTooltips.Visible = SetupMode;
	Items.QuickAccessHeaderLabel.ToolTipRepresentation = ?(SetupMode, ToolTipRepresentation.Button, ToolTipRepresentation.None);
	Items.OtherSectionsSearchResultsGroup.Visible = (SearchInAllSections = 1);
	Items.Customize.Check = SetupMode;
	
	// Title.
	SetupModeSuffix = " (" + NStr("ru = 'настройка'; en = 'setting'; pl = 'ustawienia';de = 'einstellung';ro = 'setare';tr = 'ayarlar'; es_ES = 'configuración'") + ")";
	SuffixIsDisplayed = (Right(Title, StrLen(SetupModeSuffix)) = SetupModeSuffix);
	If SuffixIsDisplayed <> SetupMode Then
		If SetupMode Then
			Title = Title + SetupModeSuffix;
		Else
			Title = StrReplace(Title, SetupModeSuffix, "");
		EndIf;
	EndIf;
	
	// Removing items.
	ClearFormFromAddedItems();
	
	// Removing commands
	If Common.IsWebClient() Then
		CommandsToRemove = New Array;
		For Each Command In Commands Do
			If ConstantCommands.FindByValue(Command.Name) = Undefined Then
				CommandsToRemove.Add(Command);
			EndIf;
		EndDo;
		For Each Command In CommandsToRemove Do
			Commands.Delete(Command);
		EndDo;
	EndIf;
	
	// Reset the number of the last added item.
	For Each TableRow In ApplicationSubsystems Do
		TableRow.ItemNumber = 0;
		TableRow.VisibleOptionsCount = 0;
	EndDo;
	
	// Filling in the report panel
	Return FillReportPanelInBackground();
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Server

&AtServer
Procedure DefineBehaviorInMobileClient()
	If Not Common.IsMobileClient() Then 
		Return;
	EndIf;
	
	Items.SearchString.TitleLocation = FormItemTitleLocation.None;
	Items.SearchString.DropListButton = False;
	Items.RunSearch.Representation = ButtonRepresentation.Picture;
	Items.Move(Items.ShowTooltips, Items.TopBarMobileClient);
	Items.CommandBarRightGroup.Visible = False;
	Items.MobileApplicationDescription.Visible = False;
	
	SearchSubstring = NStr("ru = 'нажмите на отчете правой кнопкой мыши и'; en = 'right-click the report and'; pl = 'kliknij na raport prawym przyciskiem myszy i';de = 'Rechtsklick auf den Bericht und';ro = 'tastați cu butonul drept al mausului pe raport și';tr = 'raporu sağ tıklayın ve'; es_ES = 'pulse en el informe con el botón derecho de ratón y'");
	ReplacementSubstring = NStr("ru = 'в контекстном меню'; en = 'in the context menu'; pl = 'w menu kontekstowym';de = 'im Kontextmenü';ro = 'în meniul de context';tr = 'bağlam menüsünde'; es_ES = 'en el menú contextual'");
	
	Items.QuickAccessTooltipWhenNotConfigured.Title =
		StrReplace(Items.QuickAccessTooltipWhenNotConfigured.Title, SearchSubstring, ReplacementSubstring);
	
	Items.QuickAccessHeaderLabel.ExtendedTooltip.Title =
		StrReplace(Items.QuickAccessHeaderLabel.ExtendedTooltip.Title, SearchSubstring, ReplacementSubstring);
EndProcedure

&AtServer
Procedure ClearFormFromAddedItems()
	ItemsToRemove = New Array;
	For Each Level3Item In Items.QuickAccess.ChildItems Do
		For Each Level4Item In Level3Item.ChildItems Do
			ItemsToRemove.Add(Level4Item);
		EndDo;
	EndDo;
	For Each Level3Item In Items.NoGroup.ChildItems Do
		For Each Level4Item In Level3Item.ChildItems Do
			ItemsToRemove.Add(Level4Item);
		EndDo;
	EndDo;
	For Each Level3Item In Items.WithGroup.ChildItems Do
		For Each Level4Item In Level3Item.ChildItems Do
			ItemsToRemove.Add(Level4Item);
		EndDo;
	EndDo;
	For Each Level3Item In Items.SeeAlso.ChildItems Do
		For Each Level4Item In Level3Item.ChildItems Do
			ItemsToRemove.Add(Level4Item);
		EndDo;
	EndDo;
	For Each Level4Item In Items.OtherSectionsSearchResults.ChildItems Do
		ItemsToRemove.Add(Level4Item);
	EndDo;
	For Each ItemToRemove In ItemsToRemove Do
		Items.Delete(ItemToRemove);
	EndDo;
EndProcedure

&AtServerNoContext
Procedure SaveUserSettingsSSL(Option, Subsystem, Visibility, QuickAccess)
	SettingsPackage = New ValueTable;
	SettingsPackage.Add();
	Dimensions = New Structure;
	Dimensions.Insert("User", Users.AuthorizedUser());
	Dimensions.Insert("Variant", Option);
	Dimensions.Insert("Subsystem", Subsystem);
	Resources = New Structure;
	Resources.Insert("Visible", Visibility);
	Resources.Insert("QuickAccess", QuickAccess);
	InformationRegisters.ReportOptionsSettings.WriteSettingsPackage(SettingsPackage, Dimensions, Resources, True);
EndProcedure

&AtServer
Function SubgroupWithMinimalItemsCount(Folder)
	SubgroupMin = Undefined;
	NestedItemsMin = 0;
	For Each Subgroup In Folder.ChildItems Do
		NestedItems = Subgroup.ChildItems.Count();
		If NestedItems < NestedItemsMin Or SubgroupMin = Undefined Then
			SubgroupMin          = Subgroup;
			NestedItemsMin = NestedItems;
		EndIf;
	EndDo;
	Return SubgroupMin;
EndFunction

&AtServer
Procedure DefineSubsystemsAndTitle(Parameters)
	
	TitleIsSet = Not IsBlankString(Parameters.Title);
	PanelTitle = ?(TitleIsSet, Parameters.Title, NStr("ru = 'Отчеты'; en = 'Reports'; pl = 'Raporty';de = 'Weitere Berichte...';ro = 'Rapoarte';tr = 'Daha fazla rapor ...'; es_ES = 'Informes'"));
	
	If Parameters.SubsystemPath = ReportsOptionsClientServer.HomePageID() Then
		CurrentSectionFullName = Parameters.SubsystemPath;
	Else
		CurrentSectionFullName = "Subsystem." + StrReplace(Parameters.SubsystemPath, ".", ".Subsystem.");
	EndIf;
	
	ApplicationSubsystems.Clear();
	AllSubsystems = ReportsOptionsCached.CurrentUserSubsystems();
	AllSections = AllSubsystems.Rows[0].Rows;
	SubsystemsByRef = New Map;
	
	For Each RowSection In AllSections Do
		TableRow = ApplicationSubsystems.Add();
		FillPropertyValues(TableRow, RowSection);
		TableRow.ItemName    = StrReplace(RowSection.FullName, ".", "_");
		TableRow.ItemNumber  = 0;
		TableRow.SectionRef   = RowSection.Ref;
		
		SubsystemsByRef[TableRow.Ref] = TableRow.GetID();
		
		If RowSection.FullName = CurrentSectionFullName Then
			CurrentSectionRef = RowSection.Ref;
			If TitleIsSet Then
				RowSection.FullPresentation = Parameters.Title;
			Else
				PanelTitle = RowSection.FullPresentation;
			EndIf;
		EndIf;
		
		FoundItems = RowSection.Rows.FindRows(New Structure("SectionRef", RowSection.Ref), True);
		For Each TreeRow In FoundItems Do
			TableRow = ApplicationSubsystems.Add();
			FillPropertyValues(TableRow, TreeRow);
			TableRow.ItemName    = StrReplace(TableRow.FullName, ".", "_");
			TableRow.ItemNumber  = 0;
			TableRow.ParentRef = TreeRow.Parent.Ref;
			TableRow.SectionRef   = RowSection.Ref;
			
			SubsystemsByRef[TableRow.Ref] = TableRow.GetID();
			If TreeRow.FullName = CurrentSectionFullName Then
				CurrentSectionRef = TreeRow.Ref;
				If TitleIsSet Then
					TreeRow.FullPresentation = Parameters.Title;
				Else
					PanelTitle = TreeRow.FullPresentation;
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	
	If CurrentSectionRef = Undefined Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Для панели отчетов указан несуществующий раздел ""%1"" (см. ВариантыОтчетовПереопределяемый.ОпределитьРазделыСВариантамиОтчетов).'; en = 'Non-existent section ""%1"" provided for the report panel. See ReportOptionsOverridable.DefineSectionsWithReportOptions.'; pl = 'Dla panelu sprawozdań wskazano nieistniejący rozdział ""%1"" (zob. ReportOptionsOverridable.DefineSectionsWithReportOptions).';de = 'Der Berichtsbereich enthält einen nicht vorhandenen Abschnitt ""%1"" (siehe ReportOptionsOverridable.DefineSectionsWithReportOptions).';ro = 'Pentru panoul rapoartelor este indicat compartimentul inexistent ""%1"" (vezi. ReportOptionsOverridable.DefineSectionsWithReportOptions).';tr = 'Rapor paneli için var olmayan bir ""%1"" bölümü listelenir (bkz. ReportOptionsOverridable.DefineSectionsWithReportOptions).'; es_ES = 'Para la barra de informes se ha indicado una sección inexistente ""%1"" (véase ReportOptionsOverridable.DefineSectionsWithReportOptions).'"),
			Parameters.SubsystemPath);
	EndIf;
	
	PurposeUseKey = "Section_" + String(CurrentSectionRef.UUID());
	Title = PanelTitle;
	SubsystemByReference = New FixedMap(SubsystemsByRef);
	
EndProcedure

&AtServer
Procedure ImportAllSettings()
	CommonSettings = ReportsOptions.CommonPanelSettings();
	FillPropertyValues(ThisObject, CommonSettings, "ShowTooltipsNotification, ShowTooltips, SearchInAllSections");
	
	LocalSettings = Common.CommonSettingsStorageLoad(
		ReportsOptionsClientServer.FullSubsystemName(),
		PurposeUseKey);
	If LocalSettings <> Undefined Then
		Items.SearchString.ChoiceList.LoadValues(LocalSettings.SearchStringSelectionList);
	EndIf;
EndProcedure

&AtServer
Procedure SaveSettingsOfThisReportPanel()
	LocalSettings = New Structure;
	LocalSettings.Insert("SearchStringSelectionList", Items.SearchString.ChoiceList.UnloadValues());
	
	Common.CommonSettingsStorageSave(
		ReportsOptionsClientServer.FullSubsystemName(),
		PurposeUseKey,
		LocalSettings);
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Server / filling in a report panel.

&AtServer
Function FillReportPanelInBackground()
	// Clear information on changes in user settings.
	AddedOptions.Clear();
	
	SearchParameters = New Structure;
	SearchParameters.Insert("SetupMode", SetupMode);
	SearchParameters.Insert("SearchString", SearchString);
	SearchParameters.Insert("SearchInAllSections", SearchInAllSections);
	SearchParameters.Insert("CurrentSectionRef", CurrentSectionRef);
	
	SearchByRow = ValueIsFilled(SearchString);
	CurrentSectionOnly = SetupMode Or Not ValueIsFilled(SearchString) Or SearchInAllSections = 0;	
	If CurrentSectionOnly Then
		SubsystemsTable = ApplicationSubsystems.Unload(New Structure("SectionRef", CurrentSectionRef));
	Else
		SubsystemsTable = ApplicationSubsystems.Unload();
	EndIf;
	SearchParameters.Insert("ApplicationSubsystems", SubsystemsTable);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.RunNotInBackground = (ReportsOptions.PresentationsFilled() = "Filled");
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground("ReportsOptions.FindReportOptionsForOutput", SearchParameters, ExecutionParameters);
	If TimeConsumingOperation.Status = "Error" Then
		Raise TimeConsumingOperation.BriefErrorPresentation;
	EndIf;	
	If TimeConsumingOperation.Status <> "Completed" Then
		Return TimeConsumingOperation;
	EndIf;	
	
	FillReportPanel(TimeConsumingOperation.ResultAddress);
	Return TimeConsumingOperation;
	
EndFunction

&AtServer
Procedure FillReportPanel(FillingParametersTempStorage)
	
	FillingParameters = GetFromTempStorage(FillingParametersTempStorage);
	DeleteFromTempStorage(FillingParametersTempStorage);
	
	InitializeFillingParameters(FillingParameters);
	If SetupMode Then
		FillingParameters.ContextMenu.RemoveFromQuickAccess.Visible = True;
		FillingParameters.ContextMenu.MoveToQuickAccess.Visible = False;
	EndIf;
	
	OutputSectionOptions(FillingParameters, CurrentSectionRef);
	
	If FillingParameters.CurrentSectionOnly Then
		Items.OtherSectionsSearchResultsGroup.Visible = False;
	Else
		Items.OtherSectionsSearchResultsGroup.Visible = True;
		If FillingParameters.OtherSections.Count() = 0 Then
			Label = Items.Insert("InOtherSections", Type("FormDecoration"), Items.OtherSectionsSearchResults);
			Label.Title = NStr("ru = 'Отчеты в других разделах не найдены.'; en = 'Reports not found in other sections.'; pl = 'Nie znaleziono raportów w innych sekcjach.';de = 'Berichte werden in anderen Abschnitten nicht gefunden.';ro = 'Rapoartele nu se găsesc în alte secțiuni.';tr = 'Raporlar diğer bölümlerde bulunmamaktadır.'; es_ES = 'Informes no se han encontrado en otras secciones.'") + Chars.LF;
			Label.Height = 2;
		EndIf;
		For Each SectionRef In FillingParameters.OtherSections Do
			OutputSectionOptions(FillingParameters, SectionRef);
		EndDo;
		If FillingParameters.NotDisplayed > 0 Then // Output information label.
			LabelTitle = NStr("ru = 'Выведены первые %1 отчетов из других разделов, уточните поисковый запрос.'; en = 'The first %1 reports from other sections are shown. Please refine the search.'; pl = 'Wyświetlane są%1pierwsze sprawozdania z innych sekcji, uściślij zapytanie.';de = 'Die ersten%1 Berichte aus anderen Abschnitten werden angezeigt, geben Sie eine Suchanfrage an.';ro = 'Sunt afișate primele %1 rapoarte din alte compartimente, concretizați interogarea de căutare.';tr = 'Diğer bölümlerden ilk %1 raporlar görüntülenir, bir arama sorgusu belirtin.'; es_ES = 'Primeros %1 informes de otras secciones están visualizados, especificar la solicitud de búsqueda.'");
			LabelTitle = StringFunctionsClientServer.SubstituteParametersToString(LabelTitle, FillingParameters.OutputLimit);
			Label = Items.Insert("OutputLimitExceeded", Type("FormDecoration"), Items.OtherSectionsSearchResults);
			Label.Title = LabelTitle;
			Label.Font = ImportantLabelFont;
			Label.Height = 2;
		EndIf;
	EndIf;
	
	If FillingParameters.AttributesToAdd.Count() > 0 Then
		// Registering old attributes for deleting.
		AttributesToDelete = New Array;
		AttributesSet = GetAttributes();
		For Each Attribute In AttributesSet Do
			If ConstantAttributes.FindByValue(Attribute.Name) = Undefined Then
				AttributesToDelete.Add(Attribute.Name);
			EndIf;
		EndDo;
		// Deleting old attributes and adding new ones.
		ChangeAttributes(FillingParameters.AttributesToAdd, AttributesToDelete);
		// Link new attributes to data.
		For Each Attribute In FillingParameters.AttributesToAdd Do
			CheckBox = Items.Find(Attribute.Name);
			CheckBox.DataPath = Attribute.Name;
			LabelName = Mid(Attribute.Name, StrLen("CheckBox_")+1);
			FoundItems = AddedOptions.FindRows(New Structure("LabelName", LabelName));
			If FoundItems.Count() > 0 Then
				Option = FoundItems[0];
				ThisObject[Attribute.Name] = Option.Visible;
			EndIf;
		EndDo;
	EndIf;
	
	ReportOptionByItemName = New FixedMap(FillingParameters.SearchForOptions);
	Items.Pages.CurrentPage = Items.Main;
	
EndProcedure

&AtServer
Procedure InitializeFillingParameters(FillingParameters)
	FillingParameters.Insert("NameOfGroup", "");
	FillingParameters.Insert("AttributesToAdd", New Array);
	FillingParameters.Insert("EmptyDecorationsAdded", 0);
	FillingParameters.Insert("OutputLimit", 20);
	FillingParameters.Insert("RemainsToOutput", FillingParameters.OutputLimit);
	FillingParameters.Insert("NotDisplayed", 0);
	FillingParameters.Insert("OptionItemsDisplayed", 0);
	FillingParameters.Insert("SearchForOptions", New Map);
	
	OptionGroupTemplate = New Structure(
		"Type, HorizontalStretch,
		|Representation, Group, 
		|ShowTitle");
	OptionGroupTemplate.Type = FormGroupType.UsualGroup;
	OptionGroupTemplate.HorizontalStretch = True;
	OptionGroupTemplate.Representation = UsualGroupRepresentation.None;
	OptionGroupTemplate.Group = ChildFormItemsGroup.AlwaysHorizontal;
	OptionGroupTemplate.ShowTitle = False;
	
	QuickAccessPictureTemplate = New Structure(
		"Type, Width, Height, Picture,
		|HorizontalStretch, VerticalStretch");
	QuickAccessPictureTemplate.Type = FormDecorationType.Picture;
	QuickAccessPictureTemplate.Width = 2;
	QuickAccessPictureTemplate.Height = 1;
	QuickAccessPictureTemplate.Picture = QuickAccessPicture;
	QuickAccessPictureTemplate.HorizontalStretch = False;
	QuickAccessPictureTemplate.VerticalStretch = False;
	
	IndentPictureTemplate = New Structure(
		"Type, Width, Height,
		|HorizontalStretch, VerticalStretch");
	IndentPictureTemplate.Type = FormDecorationType.Picture;
	IndentPictureTemplate.Width = 1;
	IndentPictureTemplate.Height = 1;
	IndentPictureTemplate.HorizontalStretch = False;
	IndentPictureTemplate.VerticalStretch = False;
	
	// Templates for filling in control items to be created.
	OptionLabelTemplate = New Structure(
		"Type, Hyperlink, TextColor,
		|VerticalStretch, Height,
		|HorizontalStretch, AutoMaxWidth, MaxWidth");
	OptionLabelTemplate.Type = FormDecorationType.Label;
	OptionLabelTemplate.Hyperlink = True;
	OptionLabelTemplate.TextColor = VisibleOptionsColor;
	OptionLabelTemplate.VerticalStretch = False;
	OptionLabelTemplate.Height = 1;
	OptionLabelTemplate.HorizontalStretch = True;
	OptionLabelTemplate.AutoMaxWidth = False;
	OptionLabelTemplate.MaxWidth = 0;
	
	FillingParameters.Insert("Templates", New Structure);
	FillingParameters.Templates.Insert("OptionGroup", OptionGroupTemplate);
	FillingParameters.Templates.Insert("QuickAccessPicture", QuickAccessPictureTemplate);
	FillingParameters.Templates.Insert("IndentPicture", IndentPictureTemplate);
	FillingParameters.Templates.Insert("OptionLabel", OptionLabelTemplate);
	
	If SetupMode Then
		FillingParameters.Insert("ContextMenu", New Structure("RemoveFromQuickAccess, MoveToQuickAccess, Change"));
		FillingParameters.ContextMenu.RemoveFromQuickAccess   = New Structure("Visible", False);
		FillingParameters.ContextMenu.MoveToQuickAccess = New Structure("Visible", False);
		FillingParameters.ContextMenu.Change                  = New Structure("Visible", True);
	EndIf;
	
	FillingParameters.Insert("ImportanceGroups", New Array);
	FillingParameters.ImportanceGroups.Add("QuickAccess");
	FillingParameters.ImportanceGroups.Add("NoGroup");
	FillingParameters.ImportanceGroups.Add("WithGroup");
	FillingParameters.ImportanceGroups.Add("SeeAlso");
	
	For Each NameOfGroup In FillingParameters.ImportanceGroups Do
		FillingParameters.Insert(NameOfGroup, New Structure("Filter, Variants, Count"));
	EndDo;
	
	FillingParameters.QuickAccess.Filter = New Structure("QuickAccess", True);
	FillingParameters.NoGroup.Filter     = New Structure("QuickAccess, NoGroup", False, True);
	FillingParameters.WithGroup.Filter      = New Structure("QuickAccess, NoGroup, SeeAlso", False, False, False);
	FillingParameters.SeeAlso.Filter       = New Structure("QuickAccess, NoGroup, SeeAlso", False, False, True);
	
EndProcedure

&AtServer
Procedure OutputSectionOptions(FillingParameters, SectionRef)
	FilterBySection = New Structure("SectionRef", SectionRef);
	SectionOptions = FillingParameters.Variants.Copy(FilterBySection);
	FillingParameters.Insert("CurrentSectionOptionsDisplayed", SectionRef = CurrentSectionRef);
	FillingParameters.Insert("SectionOptions",    SectionOptions);
	FillingParameters.Insert("OptionsNumber", SectionOptions.Count());
	If FillingParameters.OptionsNumber = 0 Then
		// Displays a text explaining why there are no options (only for the current section).
		If FillingParameters.CurrentSectionOptionsDisplayed Then
			Label = Items.Insert("ReportListEmpty", Type("FormDecoration"), Items.NoGroupColumn1);
			If ValueIsFilled(SearchString) Then
				If FillingParameters.CurrentSectionOnly Then
					Label.Title = NStr("ru = 'Отчеты не найдены.'; en = 'Reports not found.'; pl = 'Nie znaleziono sprawozdań';de = 'Berichte nicht gefunden.';ro = 'Rapoartele nu au fost găsite.';tr = 'Raporlar bulunamadı.'; es_ES = 'Informes no encontrados.'");
				Else
					Label.Title = NStr("ru = 'Отчеты в текущем разделе не найдены.'; en = 'Reports not found in current section.'; pl = 'Nie znaleziono sprawozdań w bieżącej sekcji.';de = 'Berichte werden im aktuellen Abschnitt nicht gefunden.';ro = 'Rapoartele nu se găsesc în secțiunea curentă.';tr = 'Mevcut bölümde raporlar bulunamadı.'; es_ES = 'Informes no encontrados en la sección actual.'");
					Label.Height = 2;
				EndIf;
			Else
				Label.Title = NStr("ru = 'В панели отчетов этого раздела не размещено ни одного отчета.'; en = 'This section report panel contains no reports.'; pl = 'Panel sprawozdań w tej sekcji nie zawiera żadnych sprawozdań.';de = 'Der Berichtspaneel dieses Abschnitts enthält keine Berichte.';ro = 'Panoul de raport din această secțiune nu conține rapoarte.';tr = 'Bu bölümün rapor paneli herhangi bir rapor içermiyor.'; es_ES = 'Panel de informes de esta sección no contiene ningún informe.'");
			EndIf;
			Items["QuickAccessHeader"].Visible  = False;
			Items["QuickAccessFooter"].Visible = False;
			Items["NoGroupFooter"].Visible     = False;
			Items["WithGroupFooter"].Visible      = False;
			Items["SeeAlsoHeader"].Visible    = False;
			Items["SeeAlsoFooter"].Visible       = False;
			Items.QuickAccessTooltipWhenNotConfigured.Visible = False;
		EndIf;
		Return;
	EndIf;
	
	If FillingParameters.CurrentSectionOnly Then
		SectionSubsystems = FillingParameters.SubsystemsTable;
	Else
		SectionSubsystems = FillingParameters.SubsystemsTable.Copy(FilterBySection);
	EndIf;
	SectionSubsystems.Sort("Priority ASC"); // Sorting by hierarchy
	
	FillingParameters.Insert("SectionRef",      SectionRef);
	FillingParameters.Insert("SectionSubsystems", SectionSubsystems);
	
	DefineGroupsAndDecorationsForOptionsOutput(FillingParameters);
	
	If Not FillingParameters.CurrentSectionOptionsDisplayed
		AND FillingParameters.RemainsToOutput = 0 Then
		FillingParameters.NotDisplayed = FillingParameters.NotDisplayed + FillingParameters.OptionsNumber;
		Return;
	EndIf;
	
	For Each NameOfGroup In FillingParameters.ImportanceGroups Do
		GroupParameters = FillingParameters[NameOfGroup];
		If FillingParameters.RemainsToOutput <= 0 Then
			GroupParameters.Variants   = New Array;
			GroupParameters.Count = 0;
		Else
			GroupParameters.Variants   = FillingParameters.SectionOptions.Copy(GroupParameters.Filter);
			GroupParameters.Count = GroupParameters.Variants.Count();
		EndIf;
		
		If GroupParameters.Count = 0 AND Not (SetupMode AND NameOfGroup = "WithGroup") Then
			Continue;
		EndIf;
		
		If Not FillingParameters.CurrentSectionOptionsDisplayed Then
			// Restriction for options output.
			FillingParameters.RemainsToOutput = FillingParameters.RemainsToOutput - GroupParameters.Count;
			If FillingParameters.RemainsToOutput < 0 Then
				// Removing rows that exceed the limit.
				ExcessiveOptions = -FillingParameters.RemainsToOutput;
				For Number = 1 To ExcessiveOptions Do
					GroupParameters.Variants.Delete(GroupParameters.Count - Number);
				EndDo;
				FillingParameters.NotDisplayed = FillingParameters.NotDisplayed + ExcessiveOptions;
				FillingParameters.RemainsToOutput = 0;
			EndIf;
		EndIf;
		
		If SetupMode Then
			FillingParameters.ContextMenu.RemoveFromQuickAccess.Visible   = (NameOfGroup = "QuickAccess");
			FillingParameters.ContextMenu.MoveToQuickAccess.Visible = (NameOfGroup <> "QuickAccess");
		EndIf;
		
		FillingParameters.NameOfGroup = NameOfGroup;
		OutputOptionsWithGroup(FillingParameters);
	EndDo;
	
	HasQuickAccess     = (FillingParameters.QuickAccess.Count > 0);
	HasOptionsWithoutGroups = (FillingParameters.NoGroup.Count > 0);
	HasOptionsWithGroups  = (FillingParameters.WithGroup.Count > 0);
	HasOptionsSeeAlso   = (FillingParameters.SeeAlso.Count > 0);
	
	Items[FillingParameters.Prefix + "QuickAccessHeader"].Visible  = SetupMode Or HasQuickAccess;
	Items[FillingParameters.Prefix + "QuickAccessFooter"].Visible = (
		SetupMode
		Or (
			HasQuickAccess
			AND (
				HasOptionsWithoutGroups
				Or HasOptionsWithGroups
				Or HasOptionsSeeAlso)));
	Items[FillingParameters.Prefix + "NoGroupFooter"].Visible  = HasOptionsWithoutGroups;
	Items[FillingParameters.Prefix + "WithGroupFooter"].Visible   = HasOptionsWithGroups;
	Items[FillingParameters.Prefix + "SeeAlsoHeader"].Visible = HasOptionsSeeAlso;
	Items[FillingParameters.Prefix + "SeeAlsoFooter"].Visible    = HasOptionsSeeAlso;
	
	If FillingParameters.CurrentSectionOptionsDisplayed Then
		Items.QuickAccessTooltipWhenNotConfigured.Visible = SetupMode AND Not HasQuickAccess;
	EndIf;
	
EndProcedure

&AtServer
Procedure DefineGroupsAndDecorationsForOptionsOutput(FillingParameters)
	// This procedure defines substitutions of standard groups and items.
	FillingParameters.Insert("Prefix", "");
	If FillingParameters.CurrentSectionOptionsDisplayed Then
		Return;
	EndIf;
	
	InformationOnSection = FillingParameters.SubsystemsTable.Find(FillingParameters.SectionRef, "Ref");
	FillingParameters.Prefix = "Section_" + InformationOnSection.Priority + "_";
	
	SectionGroupName = FillingParameters.Prefix + InformationOnSection.Name;
	SectionGroup = Items.Insert(SectionGroupName, Type("FormGroup"), Items.OtherSectionsSearchResults);
	SectionGroup.Type         = FormGroupType.UsualGroup;
	SectionGroup.Representation = UsualGroupRepresentation.None;
	SectionGroup.ShowTitle      = False;
	SectionGroup.ToolTipRepresentation     = ToolTipRepresentation.ShowTop;
	SectionGroup.HorizontalStretch = True;
	
	SectionSuffix = " (" + Format(FillingParameters.OptionsNumber, "NZ=0; NG=") + ")" + Chars.LF;
	If FillingParameters.UseHighlighting Then
		HighlightParameters = FillingParameters.SearchResult.SubsystemsHighlight.Get(FillingParameters.SectionRef);
		If HighlightParameters = Undefined Then
			PresentationHighlighting = New Structure("Value, FoundWordsCount, WordHighlighting", InformationOnSection.Presentation, 0, New ValueList);
			For Each Word In FillingParameters.WordArray Do
				ReportsOptions.MarkWord(PresentationHighlighting, Word);
			EndDo;
		Else
			PresentationHighlighting = HighlightParameters.SubsystemDescription;
		EndIf;
		PresentationHighlighting.Value = PresentationHighlighting.Value + SectionSuffix;
		If PresentationHighlighting.FoundWordsCount > 0 Then
			TitleOfSection = GenerateRowWithHighlighting(PresentationHighlighting);
		Else
			TitleOfSection = PresentationHighlighting.Value;
		EndIf;
	Else
		TitleOfSection = InformationOnSection.Presentation + SectionSuffix;
	EndIf;
	
	SectionTitle = SectionGroup.ExtendedTooltip;
	SectionTitle.Title   = TitleOfSection;
	SectionTitle.Font       = SectionFont;
	SectionTitle.TextColor  = SectionColor;
	SectionTitle.Height      = 2;
	SectionTitle.Hyperlink = True;
	SectionTitle.VerticalAlign = ItemVerticalAlign.Top;
	SectionTitle.HorizontalStretch = True;
	SectionTitle.SetAction("Click", "Attachable_SectionTitleClick");
	
	SectionGroup.Group = ChildFormItemsGroup.AlwaysHorizontal;
	
	IndentDecorationName = FillingParameters.Prefix + "IndentDecoration";
	IndentDecoration = Items.Insert(IndentDecorationName, Type("FormDecoration"), SectionGroup);
	IndentDecoration.Type = FormDecorationType.Label;
	IndentDecoration.Title = " ";
	
	// Previously, an output limit was reached in other groups, so there is no need to generate subordinate items.
	If FillingParameters.RemainsToOutput = 0 Then
		SectionTitle.Height = 1; // The section title is no longer to be separated from options.
		Return;
	EndIf;
	
	CopyItem(FillingParameters.Prefix, SectionGroup, "Columns", 2);
	
	Items.Delete(Items[FillingParameters.Prefix + "QuickAccessTooltipWhenNotConfigured"]);
	Items[FillingParameters.Prefix + "QuickAccessHeader"].ExtendedTooltip.Title = "";
EndProcedure

&AtServer
Function CopyItem(NewItemPrefix, NewItemGroup, NameOfItemToCopy, NestingLevel)
	ItemToCopy = Items.Find(NameOfItemToCopy);
	NewItemName = NewItemPrefix + NameOfItemToCopy;
	NewItem = Items.Find(NewItemName);
	ItemType = TypeOf(ItemToCopy);
	IsFolder = (ItemType = Type("FormGroup"));
	If NewItem = Undefined Then
		NewItem = Items.Insert(NewItemName, ItemType, NewItemGroup);
	EndIf;
	If IsFolder Then
		PropertiesNotToFill = "Name, Parent, Visible, Shortcut, ChildItems, TitleDataPath";
	Else
		PropertiesNotToFill = "Name, Parent, Visible, Shortcut, ExtendedToolTip";
	EndIf;
	FillPropertyValues(NewItem, ItemToCopy, , PropertiesNotToFill);
	If IsFolder AND NestingLevel > 0 Then
		For Each SubordinateItem In ItemToCopy.ChildItems Do
			CopyItem(NewItemPrefix, NewItem, SubordinateItem.Name, NestingLevel - 1);
		EndDo;
	EndIf;
	Return NewItem;
EndFunction

&AtServer
Procedure OutputOptionsWithGroup(FillingParameters)
	GroupParameters = FillingParameters[FillingParameters.NameOfGroup];
	Options = GroupParameters.Variants;
	OptionsCount = GroupParameters.Count;
	If OptionsCount = 0 AND Not (SetupMode AND FillingParameters.NameOfGroup = "WithGroup") Then
		Return;
	EndIf;
	
	// Basic properties of the second-level group.
	Level2GroupName = FillingParameters.NameOfGroup;
	Level2Group = Items.Find(FillingParameters.Prefix + Level2GroupName);
	
	OutputWithoutGroups = (Level2GroupName = "QuickAccess" Or Level2GroupName = "SeeAlso");
	
	// Sorting options (there are groups and important objects).
	Options.Sort("SubsystemPriority ASC, Important DESC, Description ASC");
	ParentsFound = Options.FindRows(New Structure("TopLevel", True));
	For Each ParentOption In ParentsFound Do
		SubordinateItemsFound = Options.FindRows(New Structure("Parent, Subsystem", ParentOption.Ref, ParentOption.Subsystem));
		CurrentIndex = Options.IndexOf(ParentOption);
		For Each SubordinateOption In SubordinateItemsFound Do
			ParentOption.SubordinateCount = ParentOption.SubordinateCount + 1;
			SubordinateOption.OutputWithMainReport = True;
			SubordinateOptionIndex = Options.IndexOf(SubordinateOption);
			If SubordinateOptionIndex < CurrentIndex Then
				Options.Move(SubordinateOptionIndex, CurrentIndex - SubordinateOptionIndex);
			ElsIf SubordinateOptionIndex = CurrentIndex Then
				CurrentIndex = CurrentIndex + 1;
			Else
				Options.Move(SubordinateOptionIndex, CurrentIndex - SubordinateOptionIndex + 1);
				CurrentIndex = CurrentIndex + 1;
			EndIf;
		EndDo;
	EndDo;
	
	IDTypesDetails = New TypeDescription;
	IDTypesDetails.Types().Add("CatalogRef.MetadataObjectIDs");
	IDTypesDetails.Types().Add("CatalogRef.ExtensionObjectIDs");
	
	// Modeling options distribution based on subsystems nesting.
	DistributionTree = New ValueTree;
	DistributionTree.Columns.Add("Subsystem");
	DistributionTree.Columns.Add("SubsystemRef", IDTypesDetails);
	DistributionTree.Columns.Add("Variants", New TypeDescription("Array"));
	DistributionTree.Columns.Add("OptionsCount", New TypeDescription("Number"));
	DistributionTree.Columns.Add("BlankRowsCount", New TypeDescription("Number"));
	DistributionTree.Columns.Add("TotalNestedOptions", New TypeDescription("Number"));
	DistributionTree.Columns.Add("TotalNestedSubsystems", New TypeDescription("Number"));
	DistributionTree.Columns.Add("TotalNestedBlankRows", New TypeDescription("Number"));
	DistributionTree.Columns.Add("NestingLevel", New TypeDescription("Number"));
	DistributionTree.Columns.Add("TopLevel", New TypeDescription("Boolean"));
	
	MaxNestingLevel = 0;
	
	For Each Subsystem In FillingParameters.SectionSubsystems Do
		
		ParentLevelRow = DistributionTree.Rows.Find(Subsystem.ParentRef, "SubsystemRef", True);
		If ParentLevelRow = Undefined Then
			TreeRow = DistributionTree.Rows.Add();
		Else
			TreeRow = ParentLevelRow.Rows.Add();
		EndIf;
		
		TreeRow.Subsystem = Subsystem;
		TreeRow.SubsystemRef = Subsystem.Ref;
		
		If OutputWithoutGroups Then
			If Subsystem.Ref = FillingParameters.SectionRef Then
				For Each Option In Options Do
					TreeRow.Variants.Add(Option);
				EndDo;
			EndIf;
		Else
			TreeRow.Variants = Options.FindRows(New Structure("Subsystem", Subsystem.Ref));
		EndIf;
		TreeRow.OptionsCount = TreeRow.Variants.Count();
		
		HasOptions = TreeRow.OptionsCount > 0;
		If Not HasOptions Then
			TreeRow.BlankRowsCount = -1;
		EndIf;
		
		// Calculating a nesting level. Calculating the count in the hierarchy (if there are options).
		If ParentLevelRow <> Undefined Then
			While ParentLevelRow <> Undefined Do
				If HasOptions Then
					ParentLevelRow.TotalNestedOptions = ParentLevelRow.TotalNestedOptions + TreeRow.OptionsCount;
					ParentLevelRow.TotalNestedSubsystems = ParentLevelRow.TotalNestedSubsystems + 1;
					ParentLevelRow.TotalNestedBlankRows = ParentLevelRow.TotalNestedBlankRows + 1;
				EndIf;
				ParentLevelRow = ParentLevelRow.Parent;
				TreeRow.NestingLevel = TreeRow.NestingLevel + 1;
			EndDo;
		EndIf;
		
		MaxNestingLevel = Max(MaxNestingLevel, TreeRow.NestingLevel);
		
	EndDo;
	
	// Calculating the location column and determining for each subsystem if it is to be moved based on count data.
	FillingParameters.Insert("MaxNestingLevel", MaxNestingLevel);
	DistributionTree.Columns.Add("FormGroup");
	DistributionTree.Columns.Add("OutputStarted", New TypeDescription("Boolean"));
	RootRow = DistributionTree.Rows[0];
	RowsCount = RootRow.OptionsCount + RootRow.TotalNestedOptions + RootRow.TotalNestedSubsystems + Max(RootRow.TotalNestedBlankRows - 2, 0);
	
	// Variables to support dynamics of third-level groups.
	ColumnsCount = Level2Group.ChildItems.Count();
	If RootRow.OptionsCount = 0 Then
		If ColumnsCount > 1 AND RootRow.TotalNestedOptions <= 5 Then
			ColumnsCount = 1;
		ElsIf ColumnsCount > 2 AND RootRow.TotalNestedOptions <= 10 Then
			ColumnsCount = 2;
		EndIf;
	EndIf;
	// Number of options to output in one column.
	Level3GroupCutoff = Max(Int(RowsCount / ColumnsCount), 2);
	
	OutputOrder = New ValueTable;
	OutputOrder.Columns.Add("ColumnNumber", New TypeDescription("Number"));
	OutputOrder.Columns.Add("IsSubsystem", New TypeDescription("Boolean"));
	OutputOrder.Columns.Add("IsFollowUp", New TypeDescription("Boolean"));
	OutputOrder.Columns.Add("IsOption", New TypeDescription("Boolean"));
	OutputOrder.Columns.Add("IsBlankRow", New TypeDescription("Boolean"));
	OutputOrder.Columns.Add("TreeRow");
	OutputOrder.Columns.Add("Subsystem");
	OutputOrder.Columns.Add("SubsystemRef", IDTypesDetails);
	OutputOrder.Columns.Add("SubsystemPriority", New TypeDescription("String"));
	OutputOrder.Columns.Add("Variant");
	OutputOrder.Columns.Add("OptionRef");
	OutputOrder.Columns.Add("NestingLevel", New TypeDescription("Number"));
	
	Recursion = New Structure;
	Recursion.Insert("TotaItemsLeftToOutput", RowsCount);
	Recursion.Insert("FreeColumns", ColumnsCount - 1);
	Recursion.Insert("ColumnsCount", ColumnsCount);
	Recursion.Insert("Level3GroupCutoff", Level3GroupCutoff);
	Recursion.Insert("CurrentColumnNumber", 1);
	Recursion.Insert("IsLastColumn", Recursion.CurrentColumnNumber = Recursion.ColumnsCount Or RowsCount <= 6);
	Recursion.Insert("FreeRows", Level3GroupCutoff);
	Recursion.Insert("OutputInCurrentColumnIsStarted", False);
	
	FillOutputOrder(OutputOrder, Undefined, RootRow, Recursion, FillingParameters);
	
	// Output to the form
	CurrentColumnNumber = 0;
	For Each OutputOrderRow In OutputOrder Do
		
		If CurrentColumnNumber <> OutputOrderRow.ColumnNumber Then
			CurrentColumnNumber = OutputOrderRow.ColumnNumber;
			CurrentNestingLevel = 0;
			CurrentGroup = Level2Group.ChildItems.Get(CurrentColumnNumber - 1);
			CurrentGroupsByNestingLevels = New Map;
			CurrentGroupsByNestingLevels.Insert(0, CurrentGroup);
		EndIf;
		
		If OutputOrderRow.IsSubsystem Then
			
			If OutputOrderRow.SubsystemRef = FillingParameters.SectionRef Then
				CurrentNestingLevel = 0;
				CurrentGroup = CurrentGroupsByNestingLevels.Get(0);
			Else
				CurrentNestingLevel = OutputOrderRow.NestingLevel;
				ToGroup = CurrentGroupsByNestingLevels.Get(OutputOrderRow.NestingLevel - 1);
				CurrentGroup = AddSubsystemsGroup(FillingParameters, OutputOrderRow, ToGroup);
				CurrentGroupsByNestingLevels.Insert(CurrentNestingLevel, CurrentGroup);
			EndIf;
			
		ElsIf OutputOrderRow.IsOption Then
			
			If CurrentNestingLevel <> OutputOrderRow.NestingLevel Then
				CurrentNestingLevel = OutputOrderRow.NestingLevel;
				CurrentGroup = CurrentGroupsByNestingLevels.Get(CurrentNestingLevel);
			EndIf;
			
			AddReportOptionItems(FillingParameters, OutputOrderRow.Variant, CurrentGroup, OutputOrderRow.NestingLevel);
			
			If OutputOrderRow.Variant.SubordinateCount > 0 Then
				CurrentNestingLevel = CurrentNestingLevel + 1;
				CurrentGroup = AddGroupWithIndent(FillingParameters, OutputOrderRow, CurrentGroup);
				CurrentGroupsByNestingLevels.Insert(CurrentNestingLevel, CurrentGroup);
			EndIf;
			
		ElsIf OutputOrderRow.IsBlankRow Then
			
			ToGroup = CurrentGroupsByNestingLevels.Get(OutputOrderRow.NestingLevel - 1);
			AddBlankDecoration(FillingParameters, ToGroup);
			
		EndIf;
		
	EndDo;
	
	For ColumnNumber = 3 To Level2Group.ChildItems.Count() Do
		FoundItems = OutputOrder.FindRows(New Structure("ColumnNumber, IsSubsystem", ColumnNumber, False));
		If FoundItems.Count() = 0 Then
			Level3Group = Level2Group.ChildItems.Get(ColumnNumber - 1);
			AddBlankDecoration(FillingParameters, Level3Group);
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure FillOutputOrder(OutputOrder, ParentLevelRow, TreeRow, Recursion, FillingParameters)
	
	If Not Recursion.IsLastColumn AND Recursion.FreeRows <= 0 Then // the current column is exhausted
		// Going to a new column.
		Recursion.TotaItemsLeftToOutput = Recursion.TotaItemsLeftToOutput - 1; // A blank group that is not to be output.
		Recursion.CurrentColumnNumber = Recursion.CurrentColumnNumber + 1;
		Recursion.IsLastColumn = (Recursion.CurrentColumnNumber = Recursion.ColumnsCount);
		FreeColumns = Recursion.ColumnsCount - Recursion.CurrentColumnNumber + 1;
		// Count of options to output in one column.
		Recursion.Level3GroupCutoff = Max(Int(Recursion.TotaItemsLeftToOutput / FreeColumns), 2);
		Recursion.FreeRows = Recursion.Level3GroupCutoff; // Count of options to output in one column.
		
		// Outputting the hierarchy / Repeating the hierarchy with the "(continue)" addition if output of 
		// rows related to the current parent is started in the previous column.
		CurrentParent = ParentLevelRow;
		While CurrentParent <> Undefined AND CurrentParent.SubsystemRef <> FillingParameters.SectionRef Do
			
			// Recursion.TotalObjectsToOutput will not decrease as continuation output increases the number of rows.
			OutputSubsystem = OutputOrder.Add();
			OutputSubsystem.ColumnNumber        = Recursion.CurrentColumnNumber;
			OutputSubsystem.IsSubsystem       = True;
			OutputSubsystem.IsFollowUp      = ParentLevelRow.OutputStarted;
			OutputSubsystem.TreeRow        = TreeRow;
			OutputSubsystem.SubsystemPriority = TreeRow.Subsystem.Priority;
			FillPropertyValues(OutputSubsystem, CurrentParent, "Subsystem, SubsystemRef, NestingLevel");
			
			CurrentParent = CurrentParent.Parent;
		EndDo;
		
		Recursion.OutputInCurrentColumnIsStarted = False;
		
	EndIf;
	
	If (TreeRow.OptionsCount > 0 Or TreeRow.TotalNestedOptions > 0) AND Recursion.OutputInCurrentColumnIsStarted AND ParentLevelRow.OutputStarted Then
		// Outputting a blank row.
		Recursion.TotaItemsLeftToOutput = Recursion.TotaItemsLeftToOutput - 1;
		OutputBlankRow = OutputOrder.Add();
		OutputBlankRow.ColumnNumber        = Recursion.CurrentColumnNumber;
		OutputBlankRow.IsBlankRow     = True;
		OutputBlankRow.TreeRow        = TreeRow;
		OutputBlankRow.SubsystemPriority = TreeRow.Subsystem.Priority;
		FillPropertyValues(OutputBlankRow, TreeRow, "Subsystem, SubsystemRef, NestingLevel");
		
		// Counting rows occupied by a blank row.
		Recursion.FreeRows = Recursion.FreeRows - 1;
	EndIf;
	
	// Outputting a group.
	If ParentLevelRow <> Undefined Then
		OutputSubsystem = OutputOrder.Add();
		OutputSubsystem.ColumnNumber        = Recursion.CurrentColumnNumber;
		OutputSubsystem.IsSubsystem       = True;
		OutputSubsystem.TreeRow        = TreeRow;
		OutputSubsystem.SubsystemPriority = TreeRow.Subsystem.Priority;
		FillPropertyValues(OutputSubsystem, TreeRow, "Subsystem, SubsystemRef, NestingLevel");
	EndIf;
	
	If TreeRow.OptionsCount > 0 Then
		
		// Counting a row occupied by a group.
		Recursion.TotaItemsLeftToOutput = Recursion.TotaItemsLeftToOutput - 1;
		Recursion.FreeRows = Recursion.FreeRows - 1;
		
		TreeRow.OutputStarted = True;
		Recursion.OutputInCurrentColumnIsStarted = True;
		
		If Recursion.IsLastColumn
			Or ParentLevelRow <> Undefined
			AND (TreeRow.OptionsCount <= 5
			Or TreeRow.OptionsCount - 2 <= Recursion.FreeRows + 2) Then
			
			// Outputting all in the current column.
			CanContinue = False;
			CountToCurrentColumn = TreeRow.OptionsCount;
			
		Else
			
			// Partial output to the current column and proceeding in the next column.
			CanContinue = True;
			CountToCurrentColumn = Max(Recursion.FreeRows + 2, 3);
			
		EndIf;
		
		// Registering options in the current column / Proceeding to output options in a new column.
		OutputOptionsCount = 0;
		VisibleOptionsCount = 0;
		For Each Option In TreeRow.Variants Do
			// TreeRow.Options is a result of search in a value table.
			// The code assumes that sorting of search results does not differ from sorting of rows.
			// If they differ, you need to copy the initial table with a filter by subsystem and sort it by 
			// description.
			
			If CanContinue
				AND Not Recursion.IsLastColumn
				AND Not Option.OutputWithMainReport
				AND OutputOptionsCount >= CountToCurrentColumn Then
				// Going to a new column.
				Recursion.CurrentColumnNumber = Recursion.CurrentColumnNumber + 1;
				Recursion.IsLastColumn = (Recursion.CurrentColumnNumber = Recursion.ColumnsCount);
				FreeColumns = Recursion.ColumnsCount - Recursion.CurrentColumnNumber + 1;
				// Count of options to output in one column.
				Recursion.Level3GroupCutoff = Max(Int(Recursion.TotaItemsLeftToOutput / FreeColumns), 2);
				Recursion.FreeRows = Recursion.Level3GroupCutoff; // Count of options to output in one column.
				
				If Recursion.IsLastColumn Then
					CountToCurrentColumn = -1;
				Else
					CountToCurrentColumn = Max(Min(Recursion.FreeRows, TreeRow.OptionsCount - OutputOptionsCount), 3);
				EndIf;
				OutputOptionsCount = 0;
				
				// Repeating the hierarchy with the "(continue)" addition.
				CurrentParent = ParentLevelRow;
				While CurrentParent <> Undefined AND CurrentParent.SubsystemRef <> FillingParameters.SectionRef Do
					
					// Recursion.TotalObjectsToOutput will not decrease as continuation output increases the number of rows.
					OutputSubsystem = OutputOrder.Add();
					OutputSubsystem.ColumnNumber        = Recursion.CurrentColumnNumber;
					OutputSubsystem.IsSubsystem       = True;
					OutputSubsystem.IsFollowUp      = True;
					OutputSubsystem.TreeRow        = TreeRow;
					OutputSubsystem.SubsystemPriority = TreeRow.Subsystem.Priority;
					FillPropertyValues(OutputSubsystem, CurrentParent, "Subsystem, SubsystemRef, NestingLevel");
					
					CurrentParent = CurrentParent.Parent;
				EndDo;
				
				// Outputting a group with the "(continue)" addition.
				// Recursion.TotalObjectsToOutput will not decrease as continuation output increases the number of rows.
				OutputSubsystem = OutputOrder.Add();
				OutputSubsystem.ColumnNumber        = Recursion.CurrentColumnNumber;
				OutputSubsystem.IsSubsystem       = True;
				OutputSubsystem.IsFollowUp      = True;
				OutputSubsystem.TreeRow        = TreeRow;
				OutputSubsystem.SubsystemPriority = TreeRow.Subsystem.Priority;
				FillPropertyValues(OutputSubsystem, TreeRow, "Subsystem, SubsystemRef, NestingLevel");
				
				// Counting a row occupied by a group.
				Recursion.FreeRows = Recursion.FreeRows - 1;
			EndIf;
			
			Recursion.TotaItemsLeftToOutput = Recursion.TotaItemsLeftToOutput - 1;
			OutputOption = OutputOrder.Add();
			OutputOption.ColumnNumber        = Recursion.CurrentColumnNumber;
			OutputOption.IsOption          = True;
			OutputOption.TreeRow        = TreeRow;
			OutputOption.Variant             = Option;
			OutputOption.OptionRef       = Option.Ref;
			OutputOption.SubsystemPriority = TreeRow.Subsystem.Priority;
			FillPropertyValues(OutputOption, TreeRow, "Subsystem, SubsystemRef, NestingLevel");
			If Option.OutputWithMainReport Then
				OutputOption.NestingLevel = OutputOption.NestingLevel + 1;
			EndIf;
			
			OutputOptionsCount = OutputOptionsCount + 1;
			If Option.Visible Then
				VisibleOptionsCount = VisibleOptionsCount + 1;
			EndIf;
			
			// Counting rows occupied by options.
			Recursion.FreeRows = Recursion.FreeRows - 1;
		EndDo;
		
		If VisibleOptionsCount > 0 Then
			SubsystemForms = FindSubsystemByRef(ThisObject, TreeRow.SubsystemRef);
			SubsystemForms.VisibleOptionsCount = SubsystemForms.VisibleOptionsCount + VisibleOptionsCount;
			While SubsystemForms.Ref <> SubsystemForms.SectionRef Do
				SubsystemForms = FindSubsystemByRef(ThisObject, SubsystemForms.SectionRef);
				SubsystemForms.VisibleOptionsCount = SubsystemForms.VisibleOptionsCount + VisibleOptionsCount;
			EndDo;
		EndIf;
		
	EndIf;
	
	// Registering nested rows.
	For Each SubordinateObjectRow In TreeRow.Rows Do
		FillOutputOrder(OutputOrder, TreeRow, SubordinateObjectRow, Recursion, FillingParameters);
		// Forwarding OutputStarted from the lower level.
		If SubordinateObjectRow.OutputStarted Then
			TreeRow.OutputStarted = True;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Function AddSubsystemsGroup(FillingParameters, OutputOrderRow, ToGroup)
	Subsystem = OutputOrderRow.Subsystem;
	TreeRow = OutputOrderRow.TreeRow;
	If TreeRow.OptionsCount = 0
		AND TreeRow.TotalNestedOptions = 0
		AND Not (SetupMode AND FillingParameters.NameOfGroup = "WithGroup") Then
		Return ToGroup;
	EndIf;
	SubsystemPresentation = Subsystem.Presentation;
	
	Subsystem.ItemNumber = Subsystem.ItemNumber + 1;
	SubsystemsGroupName = Subsystem.ItemName + "_" + Format(Subsystem.ItemNumber, "NG=0");
	
	If Not FillingParameters.CurrentSectionOnly Then
		While Items.Find(SubsystemsGroupName) <> Undefined Do
			Subsystem.ItemNumber = Subsystem.ItemNumber + 1;
			SubsystemsGroupName = Subsystem.ItemName + "_" + Format(Subsystem.ItemNumber, "NG=0");
		EndDo;
	EndIf;
	
	// Add an indent to the left.
	If OutputOrderRow.NestingLevel > 1 Then
		// Group.
		IndentGroup = Items.Insert(SubsystemsGroupName + "_GroupIndent", Type("FormGroup"), ToGroup);
		IndentGroup.Type                      = FormGroupType.UsualGroup;
		IndentGroup.Group              = ChildFormItemsGroup.AlwaysHorizontal;
		IndentGroup.Representation              = UsualGroupRepresentation.None;
		IndentGroup.ShowTitle      = False;
		IndentGroup.HorizontalStretch = True;
		
		// Picture.
		IndentPicture = Items.Insert(SubsystemsGroupName + "_IndentPicture", Type("FormDecoration"), IndentGroup);
		FillPropertyValues(IndentPicture, FillingParameters.Templates.IndentPicture);
		IndentPicture.Width = OutputOrderRow.NestingLevel - 1;
		If OutputOrderRow.TreeRow.OptionsCount = 0 AND OutputOrderRow.TreeRow.TotalNestedOptions = 0 Then
			IndentPicture.Visible = False;
		EndIf;
		
		// Substituting a group of higher level.
		ToGroup = IndentGroup;
		
		TitleFont = NormalGroupFont;
	Else
		TitleFont = ImportantGroupFont;
	EndIf;
	
	SubsystemsGroup = Items.Insert(SubsystemsGroupName, Type("FormGroup"), ToGroup);
	SubsystemsGroup.Type = FormGroupType.UsualGroup;
	SubsystemsGroup.HorizontalStretch = True;
	SubsystemsGroup.Group = ChildFormItemsGroup.Vertical;
	SubsystemsGroup.Representation = UsualGroupRepresentation.None;
	
	HighlightingIsRequired = False;
	If FillingParameters.UseHighlighting Then
		HighlightParameters = FillingParameters.SearchResult.SubsystemsHighlight.Get(Subsystem.Ref);
		If HighlightParameters <> Undefined Then
			PresentationHighlighting = HighlightParameters.SubsystemDescription;
			If PresentationHighlighting.FoundWordsCount > 0 Then
				HighlightingIsRequired = True;
			EndIf;
		EndIf;
	EndIf;
	
	If HighlightingIsRequired Then
		If OutputOrderRow.IsFollowUp Then
			Suffix = NStr("ru = '(продолжение)'; en = '(continue)'; pl = '(ciąg dalszy)';de = '(weiter)';ro = '(continuare)';tr = '(devam)'; es_ES = '(continuar)'");
			If Not StrEndsWith(PresentationHighlighting.Value, Suffix) Then
				PresentationHighlighting.Value = PresentationHighlighting.Value + " " + Suffix;
			EndIf;
		EndIf;
		
		SubsystemsGroup.ShowTitle = False;
		SubsystemsGroup.ToolTipRepresentation = ToolTipRepresentation.ShowTop;
		
		FormattedString = GenerateRowWithHighlighting(PresentationHighlighting);
		
		SubsystemTitle = Items.Insert(SubsystemsGroup.Name + "_ExtendedTooltip", Type("FormDecoration"), SubsystemsGroup);
		SubsystemTitle.Title  = FormattedString;
		SubsystemTitle.TextColor = ReportsOptionsGroupColor;
		SubsystemTitle.Font      = TitleFont;
		SubsystemTitle.HorizontalStretch = True;
		SubsystemTitle.Height = 1;
		
	Else
		If OutputOrderRow.IsFollowUp Then
			SubsystemPresentation = SubsystemPresentation + " " + NStr("ru = '(продолжение)'; en = '(continue)'; pl = '(ciąg dalszy)';de = '(weiter)';ro = '(continuare)';tr = '(devam)'; es_ES = '(continuar)'");
		EndIf;
		
		SubsystemsGroup.ShowTitle = True;
		SubsystemsGroup.Title           = SubsystemPresentation;
		SubsystemsGroup.TitleTextColor = ReportsOptionsGroupColor;
		SubsystemsGroup.TitleFont      = TitleFont;
	EndIf;
	
	TreeRow.FormGroup = SubsystemsGroup;
	
	Return SubsystemsGroup;
EndFunction

&AtServer
Function AddGroupWithIndent(FillingParameters, OutputOrderRow, ToGroup)
	FillingParameters.OptionItemsDisplayed = FillingParameters.OptionItemsDisplayed + 1;
	
	IndentGroupName   = "IndentGroup_" + Format(FillingParameters.OptionItemsDisplayed, "NG=0");
	IndentPictureName = "IndentPicture_" + Format(FillingParameters.OptionItemsDisplayed, "NG=0");
	OutputGroupName    = "OutputGroup_" + Format(FillingParameters.OptionItemsDisplayed, "NG=0");
	
	// Indent.
	IndentGroup = Items.Insert(IndentGroupName, Type("FormGroup"), ToGroup);
	IndentGroup.Type                      = FormGroupType.UsualGroup;
	IndentGroup.Group              = ChildFormItemsGroup.AlwaysHorizontal;
	IndentGroup.Representation              = UsualGroupRepresentation.None;
	IndentGroup.ShowTitle      = False;
	IndentGroup.HorizontalStretch = True;
	
	// Picture.
	IndentPicture = Items.Insert(IndentPictureName, Type("FormDecoration"), IndentGroup);
	FillPropertyValues(IndentPicture, FillingParameters.Templates.IndentPicture);
	IndentPicture.Width = 1;
	
	// Output.
	OutputGroup = Items.Insert(OutputGroupName, Type("FormGroup"), IndentGroup);
	OutputGroup.Type                      = FormGroupType.UsualGroup;
	OutputGroup.Group              = ChildFormItemsGroup.Vertical;
	OutputGroup.Representation              = UsualGroupRepresentation.None;
	OutputGroup.ShowTitle      = False;
	OutputGroup.HorizontalStretch = True;
	
	Return OutputGroup;
EndFunction

&AtServer
Function AddReportOptionItems(FillingParameters, Option, ToGroup, NestingLevel = 0)
	
	// A unique name of an item to be added.
	LabelName = "Option_" + ReportsServer.CastIDToName(Option.Ref.UUID());
	If ValueIsFilled(Option.Subsystem) Then
		LabelName = LabelName
			+ "_Subsystem_"
			+ ReportsServer.CastIDToName(Option.Subsystem.UUID());
	EndIf;
	If Not FillingParameters.CurrentSectionOnly AND Items.Find(LabelName) <> Undefined Then
		If ValueIsFilled(Option.SectionRef) Then
			Number = 0;
			Suffix = "_Section_" + ReportsServer.CastIDToName(Option.SectionRef.UUID());
		Else
			Number = 1;
			Suffix = "_1";
		EndIf;
		While Items.Find(LabelName + Suffix) <> Undefined Do
			Number = Number + 1;
			Suffix = "_" + String(Number);
		EndDo;
		LabelName = LabelName + Suffix;
	EndIf;
	
	If SetupMode Then
		OptionGroupName = "Group_" + LabelName;
		OptionGroup = Items.Insert(OptionGroupName, Type("FormGroup"), ToGroup);
		FillPropertyValues(OptionGroup, FillingParameters.Templates.OptionGroup);
	Else
		OptionGroup = ToGroup;
	EndIf;
	
	// Add a check box (not used for quick access).
	If SetupMode Then
		CheckBoxName = "CheckBox_" + LabelName;
		
		FormAttribute = New FormAttribute(CheckBoxName, New TypeDescription("Boolean"), , , False);
		FillingParameters.AttributesToAdd.Add(FormAttribute);
		
		CheckBox = Items.Insert(CheckBoxName, Type("FormField"), OptionGroup);
		CheckBox.Type = FormFieldType.CheckBoxField;
		CheckBox.TitleLocation = FormItemTitleLocation.None;
		CheckBox.Visible = (FillingParameters.NameOfGroup <> "QuickAccess");
		CheckBox.SetAction("OnChange", "Attachable_OptionVisibilityOnChange");
	EndIf;
	
	// Add a label serving as a hyperlink for the report option.
	Label = Items.Insert(LabelName, Type("FormDecoration"), OptionGroup);
	FillPropertyValues(Label, FillingParameters.Templates.OptionLabel);
	Label.Title = TrimAll(Option.Description);
	If ValueIsFilled(Option.Details) Then
		Label.ToolTip = TrimAll(Option.Details);
	EndIf;
	If ValueIsFilled(Option.Author) Then
		Label.ToolTip = TrimL(Label.ToolTip + Chars.LF) + NStr("ru = 'Автор:'; en = 'Author:'; pl = 'Autor:';de = 'Autor:';ro = 'Autor:';tr = 'Sahip:'; es_ES = 'Autor:'") + " " + TrimAll(String(Option.Author));
	EndIf;
	Label.SetAction("Click", "Attachable_OptionClick");
	If Not Option.Visible Then
		Label.TextColor = HiddenOptionsColor;
	EndIf;
	If Option.Important
		AND FillingParameters.NameOfGroup <> "SeeAlso"
		AND FillingParameters.NameOfGroup <> "QuickAccess" Then
		Label.Font = ImportantLabelFont;
	EndIf;
	Label.AutoMaxWidth = False;
	
	TooltipContent = New Array;
	DefineOptionTooltipContent(FillingParameters, Option, TooltipContent, Label);
	OutputOptionTooltip(Label, TooltipContent);
	
	If SetupMode Then
		For Each KeyAndValue In FillingParameters.ContextMenu Do
			CommandName = KeyAndValue.Key;
			ButtonName = CommandName + "_" + LabelName;
			Button = Items.Insert(ButtonName, Type("FormButton"), Label.ContextMenu);
			If Common.IsWebClient() Then
				Command = Commands.Add(ButtonName);
				FillPropertyValues(Command, Commands[CommandName]);
				Button.CommandName = ButtonName;
			Else
				Button.CommandName = CommandName;
			EndIf;
			FillPropertyValues(Button, KeyAndValue.Value);
		EndDo;
	EndIf;
	
	// Registering the added label.
	TableRow = AddedOptions.Add();
	FillPropertyValues(TableRow, Option);
	TableRow.Level2GroupName     = FillingParameters.NameOfGroup;
	TableRow.LabelName           = LabelName;
	
	FillingParameters.SearchForOptions[LabelName] = TableRow.GetID();
	
	Return Label;
	
EndFunction

&AtServer
Procedure DefineOptionTooltipContent(FillingParameters, Option, TooltipContent, Label)
	TooltipIsOutput = False;
	If FillingParameters.UseHighlighting Then
		HighlightParameters = FillingParameters.SearchResult.OptionsHighlight.Get(Option.Ref);
		If HighlightParameters <> Undefined Then
			If HighlightParameters.OptionDescription.FoundWordsCount > 0 Then
				Label.Title = GenerateRowWithHighlighting(HighlightParameters.OptionDescription);
			EndIf;
			If HighlightParameters.Details.FoundWordsCount > 0 Then
				GenerateRowWithHighlighting(HighlightParameters.Details, TooltipContent);
				TooltipIsOutput = True;
			EndIf;
			If HighlightParameters.AuthorPresentation.FoundWordsCount > 0 Then
				If TooltipContent.Count() > 0 Then
					TooltipContent.Add(Chars.LF);
				EndIf;
				TooltipContent.Add(NStr("ru = 'Автор:'; en = 'Author:'; pl = 'Autor:';de = 'Autor:';ro = 'Autor:';tr = 'Sahip:'; es_ES = 'Autor:'") + " ");
				GenerateRowWithHighlighting(HighlightParameters.AuthorPresentation, TooltipContent);
				TooltipContent.Add(".");
				TooltipIsOutput = True;
			EndIf;
			If HighlightParameters.UserSettingsDescriptions.FoundWordsCount > 0 Then
				If TooltipContent.Count() > 0 Then
					TooltipContent.Add(Chars.LF);
				EndIf;
				TooltipContent.Add(NStr("ru = 'Сохраненные настройки:'; en = 'Saved setting:'; pl = 'Zapisane ustawienia:';de = 'Gespeicherte Einstellungen:';ro = 'Setările salvate:';tr = 'Kaydedilmiş ayarlar:'; es_ES = 'Configuraciones guardadas:'") + " ");
				GenerateRowWithHighlighting(HighlightParameters.UserSettingsDescriptions, TooltipContent);
				TooltipContent.Add(".");
				TooltipIsOutput = True;
			EndIf;
			If HighlightParameters.FieldDescriptions.FoundWordsCount > 0 Then
				If TooltipContent.Count() > 0 Then
					TooltipContent.Add(Chars.LF);
				EndIf;
				TooltipContent.Add(NStr("ru = 'Поля:'; en = 'Fields:'; pl = 'Pola:';de = 'Felder:';ro = 'Câmpuri:';tr = 'Alanlar:'; es_ES = 'Campos:'") + " ");
				GenerateRowWithHighlighting(HighlightParameters.FieldDescriptions, TooltipContent);
				TooltipContent.Add(".");
				TooltipIsOutput = True;
			EndIf;
			If HighlightParameters.FilterParameterDescriptions.FoundWordsCount > 0 Then
				If TooltipContent.Count() > 0 Then
					TooltipContent.Add(Chars.LF);
				EndIf;
				TooltipContent.Add(NStr("ru = 'Настройки:'; en = 'Settings:'; pl = 'Ustawienia:';de = 'Einstellungen:';ro = 'Setări:';tr = 'Ayarlar:'; es_ES = 'Ajustes:'") + " ");
				GenerateRowWithHighlighting(HighlightParameters.FilterParameterDescriptions, TooltipContent);
				TooltipContent.Add(".");
				TooltipIsOutput = True;
			EndIf;
			If HighlightParameters.Keywords.FoundWordsCount > 0 Then
				If TooltipContent.Count() > 0 Then
					TooltipContent.Add(Chars.LF);
				EndIf;
				TooltipContent.Add(NStr("ru = 'Ключевые слова:'; en = 'Keywords:'; pl = 'Słowa kluczowe:';de = 'Schlüsselwörter:';ro = 'Cuvintele-cheie:';tr = 'Anahtar kelimeler:'; es_ES = 'Palabras claves:'") + " ");
				GenerateRowWithHighlighting(HighlightParameters.Keywords, TooltipContent);
				TooltipContent.Add(".");
				TooltipIsOutput = True;
			EndIf;
		EndIf;
	EndIf;
	If Not TooltipIsOutput AND ShowTooltips Then
		TooltipContent.Add(TrimAll(Label.ToolTip));
	EndIf;
EndProcedure

&AtServer
Procedure OutputOptionTooltip(Label, TooltipContent)
	If TooltipContent.Count() = 0 Then
		Return;
	EndIf;
	
	Label.ToolTipRepresentation = ToolTipRepresentation.ShowBottom;
	
	Tooltip = Label.ExtendedTooltip;
	Tooltip.Title                = New FormattedString(TooltipContent);
	Tooltip.TextColor               = TooltipColor;
	Tooltip.AutoMaxHeight   = False;
	Tooltip.MaxHeight       = 3;
	Tooltip.HorizontalStretch = True;
	Tooltip.AutoMaxWidth   = False;
	Tooltip.MaxWidth       = 0;
EndProcedure

&AtServer
Function GenerateRowWithHighlighting(SearchArea, Content = Undefined)
	ReturnFormattedRow = False;
	If Content = Undefined Then
		ReturnFormattedRow = True;
		Content = New Array;
	EndIf;
	
	SourceText = SearchArea.Value;
	TextIsShortened = False;
	TextLength = StrLen(SourceText);
	If TextLength > 150 Then
		TextIsShortened = ShortenText(SourceText, TextLength, 150);
	EndIf;
	
	SearchArea.WordHighlighting.SortByValue(SortDirection.Asc);
	CountOpen = 0;
	NormalTextStartPosition = 1;
	HighlightStartPosition = 0;
	For Each ListItem In SearchArea.WordHighlighting Do
		If TextIsShortened AND ListItem.Value > TextLength Then
			ListItem.Value = TextLength; // If a text was shortened, adjusting highlighting.
		EndIf;
		Highlight = (ListItem.Presentation = "+");
		CountOpen = CountOpen + ?(Highlight, 1, -1);
		If Highlight AND CountOpen = 1 Then
			HighlightStartPosition = ListItem.Value;
			NormalTextFragment = Mid(SourceText, NormalTextStartPosition, HighlightStartPosition - NormalTextStartPosition);
			Content.Add(NormalTextFragment);
		ElsIf Not Highlight AND CountOpen = 0 Then
			NormalTextStartPosition = ListItem.Value;
			FragmentToHighlight = Mid(SourceText, HighlightStartPosition, NormalTextStartPosition - HighlightStartPosition);
			Content.Add(New FormattedString(FragmentToHighlight, , , SearchResultsHighlightColor));
		EndIf;
	EndDo;
	If NormalTextStartPosition <= TextLength Then
		NormalTextFragment = Mid(SourceText, NormalTextStartPosition);
		Content.Add(NormalTextFragment);
	EndIf;
	
	If ReturnFormattedRow Then
		Return New FormattedString(Content);
	Else
		Return Undefined;
	EndIf;
EndFunction

&AtServer
Function ShortenText(Text, CurrentLength, LengthLimit)
	ESPosition = StrFind(Text, Chars.LF, SearchDirection.FromEnd, LengthLimit);
	PointPosition = StrFind(Text, ".", SearchDirection.FromEnd, LengthLimit);
	CommaPosition = StrFind(Text, ",", SearchDirection.FromEnd, LengthLimit);
	SemicolonPosition = StrFind(Text, ",", SearchDirection.FromEnd, LengthLimit);
	Position = Max(ESPosition, PointPosition, CommaPosition, SemicolonPosition);
	If Position = 0 Then
		ESPosition = StrFind(Text, Chars.LF, SearchDirection.FromBegin, LengthLimit);
		PointPosition = StrFind(Text, ".", SearchDirection.FromBegin, LengthLimit);
		CommaPosition = StrFind(Text, ",", SearchDirection.FromBegin, LengthLimit);
		SemicolonPosition = StrFind(Text, ",", SearchDirection.FromBegin, LengthLimit);
		Position = Min(ESPosition, PointPosition, CommaPosition, SemicolonPosition);
	EndIf;
	If Position = 0 Or Position = CurrentLength Then
		Return False;
	EndIf;
	Text = Left(Text, Position) + " ...";
	CurrentLength = Position;
	Return True;
EndFunction

&AtServer
Function AddBlankDecoration(FillingParameters, ToGroup)
	
	FillingParameters.EmptyDecorationsAdded = FillingParameters.EmptyDecorationsAdded + 1;
	DecorationName = "EmptyDecoration_" + Format(FillingParameters.EmptyDecorationsAdded, "NG=0");
	
	Decoration = Items.Insert(DecorationName, Type("FormDecoration"), ToGroup);
	Decoration.Type = FormDecorationType.Label;
	Decoration.Title = " ";
	Decoration.HorizontalStretch = True;
	
	Return Decoration;
	
EndFunction

&AtClient
Procedure MobileApplicationDetailsClick(Item)
	
	FormParameters = ClientParameters.MobileApplicationDescription;
	OpenForm(FormParameters.FormName, FormParameters.FormParameters, ThisObject); 
	
EndProcedure

#EndRegion
