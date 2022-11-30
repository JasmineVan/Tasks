///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var TextTemplates;

#EndRegion

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	DefineBehaviorInMobileClient();
	
	IsCustomSettings = Parameters.Property("Settings", Settings);
	If Not IsCustomSettings Then 
		Items.FormOK.Title = "Save";
	EndIf;
	Items.FormCancel.Visible = Not IsCustomSettings;
	Items.FormApplyStandardSettings.Visible = IsCustomSettings;
	
	SetStandardSettingsServer();
	
	CurrentUser = Users.CurrentUser();
	
	PagePreview = 1;
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	TextTemplates = New Structure;
	
	TextTemplates.Insert("Date" , "[&Date]");
	TextTemplates.Insert("Time" , "[&Time]");
	TextTemplates.Insert("PageNumber" , "[&PageNumber]");
	TextTemplates.Insert("PagesTotal" , "[&PagesTotal]");
	TextTemplates.Insert("User" , "[&User]");
	TextTemplates.Insert("ReportDescription", "[&ReportDescription]");
	
	UpdatePreview();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure TextOnChange(Item)
	UpdatePreview();
EndProcedure

&AtClient
Procedure OutputHeaderFromPageOnChange(Item)
	
	UpdatePreview();
	
EndProcedure

&AtClient
Procedure OutputFooterFromPageOnChange(Item)
	
	UpdatePreview();
	
EndProcedure

&AtClient
Procedure PageExampleOnChange(Item)
	
	UpdatePreview();
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure InsertTemplate(Command)
	
	If TypeOf(CurrentItem) = Type("FormField")
		AND CurrentItem.Type = FormFieldType.InputField
		AND StrFind(CurrentItem.Name, "Text") = 1 Then
		InsertText(CurrentItem, TextTemplates[Command.Name]);	
		
		UpdatePreview();
	EndIf;
			
EndProcedure

&AtClient
Procedure CustomizeHeaderFont(Command)
	
	FontChoiceDialog = New FontChooseDialog;
	#If Not WebClient Then
	FontChoiceDialog.Font = FontHeader;
	#EndIf
	
	NotifyDescription = New NotifyDescription("HeaderFontSettingCompletion", ThisObject);
	
	FontChoiceDialog.Show(NotifyDescription);
	
EndProcedure

&AtClient
Procedure CustomizeFooterFont(Command)
	
	FontChoiceDialog = New FontChooseDialog;
	#If Not WebClient Then
	FontChoiceDialog.Font = FontFooter;
	#EndIf
	
	NotifyDescription = New NotifyDescription("FooterFontSettingCompletion", ThisObject);
	
	FontChoiceDialog.Show(NotifyDescription);
	
EndProcedure

&AtClient
Procedure HeaderVerticalAlignTop(Command)
	
	VerticalAlignTop = VerticalAlign.Top;
	Items.HeaderVerticalAlignTop.Check  = True;
	Items.HeaderVerticalAlignCenter.Check = False;
	Items.HeaderVerticalAlignBottom.Check   = False;
	
	UpdatePreview();
	
EndProcedure

&AtClient
Procedure HeaderVerticalAlignCenter(Command)
	
	VerticalAlignTop = VerticalAlign.Center;
	Items.HeaderVerticalAlignTop.Check  = False;
	Items.HeaderVerticalAlignCenter.Check = True;
	Items.HeaderVerticalAlignBottom.Check   = False;
	
	UpdatePreview();
	
EndProcedure

&AtClient
Procedure HeaderVerticalAlignBottom(Command)
	
	VerticalAlignTop = VerticalAlign.Bottom;
	Items.HeaderVerticalAlignTop.Check  = False;
	Items.HeaderVerticalAlignCenter.Check = False;
	Items.HeaderVerticalAlignBottom.Check   = True;
	
	UpdatePreview();
	
EndProcedure

&AtClient
Procedure FooterVerticalAlignTop(Command)
	
	VerticalAlignBottom = VerticalAlign.Top;
	Items.FooterVerticalAlignTop.Check  = True;
	Items.FooterVerticalAlignCenter.Check = False;
	Items.FooterVerticalAlignBottom.Check   = False;
	
	UpdatePreview();
	
EndProcedure

&AtClient
Procedure FooterVerticalAlignCenter(Command)
	
	VerticalAlignBottom = VerticalAlign.Center;
	Items.FooterVerticalAlignTop.Check  = False;
	Items.FooterVerticalAlignCenter.Check = True;
	Items.FooterVerticalAlignBottom.Check   = False;
	
	UpdatePreview();
	
EndProcedure

&AtClient
Procedure FooterVerticalAlignBottom(Command)
	
	VerticalAlignBottom = VerticalAlign.Bottom;
	Items.FooterVerticalAlignTop.Check  = False;
	Items.FooterVerticalAlignCenter.Check = False;
	Items.FooterVerticalAlignBottom.Check   = True;
	
	UpdatePreview();
	
EndProcedure

&AtClient
Procedure OK(Command)
	UpdateSettings();
	Close(?(Not SettingsStatus.Standard AND Not SettingsStatus.Empty, Settings, Undefined));
EndProcedure

&AtClient
Procedure CustomizeStandardSettings(Command)
	
	Settings = Undefined;
	SetStandardSettingsServer();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure DefineBehaviorInMobileClient()
	IsMobileClient = Common.IsMobileClient();
	If Not IsMobileClient Then 
		Return;
	EndIf;
	
	Items.HeaderTextGroup.Group = ChildFormItemsGroup.HorizontalIfPossible;
	Items.FooterTextGroup.Group = ChildFormItemsGroup.HorizontalIfPossible;
	
	Items.TopLeftText.InputHint = NStr("ru = 'Слева сверху'; en = 'Top left'; pl = 'Po lewej na górze';de = 'Links oben';ro = 'În stânga sus';tr = 'Sol üst'; es_ES = 'A la izquierda arriba'");
	Items.TopMiddleText.InputHint = NStr("ru = 'В центре сверху'; en = 'Top center'; pl = 'W centrum na górze';de = 'In der Mitte oben';ro = 'În centru sus';tr = 'Üst ortasında'; es_ES = 'En el centro arriba'");
	Items.TopRightText.InputHint = NStr("ru = 'Справа сверху'; en = 'Top right'; pl = 'Z prawej u góry';de = 'Rechts oben';ro = 'În dreapta sus';tr = 'Sağ üst'; es_ES = 'A la derecha arriba'");
	
	Items.BottomLeftText.InputHint = NStr("ru = 'Слева снизу'; en = 'Bottom left'; pl = 'Po lewej na dole';de = 'Links unten';ro = 'În stânga jos';tr = 'Sol alt'; es_ES = 'A la izquierda abajo'");
	Items.BottomCenterText.InputHint = NStr("ru = 'В центре снизу'; en = 'Bottom center'; pl = 'W środku na dole';de = 'In der Mitte unten';ro = 'În centru jos';tr = 'Orta alt'; es_ES = 'En el centro abajo'");
	Items.BottomRightText.InputHint = NStr("ru = 'Справа снизу'; en = 'Bottom right'; pl = 'Po prawej na dole';de = 'Rechts unten';ro = 'În dreapta jos';tr = 'Sağ alt'; es_ES = 'A la derecha abajo'");
	
	Items.TopLeftText.Height = 1;
	Items.TopMiddleText.Height = 1;
	Items.TopRightText.Height = 1;
	
	Items.BottomLeftText.Height = 1;
	Items.BottomCenterText.Height = 1;
	Items.BottomRightText.Height = 1;
EndProcedure

&AtClientAtServerNoContext
Function HeaderAndFooterRowHeight()
	Return 10;
EndFunction

&AtClient
Procedure InsertText(CurrentItem, Text)
	ThisObject[CurrentItem.Name] = ThisObject[CurrentItem.Name] + Text;
EndProcedure

&AtServer
Procedure UpdateSettings()
	Header = New Structure();
	Header.Insert("LeftText", TopLeftText);
	Header.Insert("CenterText", TopMiddleText);
	Header.Insert("RightText", TopRightText);
	Header.Insert("Font", FontHeader);
	Header.Insert("VerticalAlign", VerticalAlignTop);
	Header.Insert("HomePage", HeaderStartPage);
	
	Footer = New Structure();
	Footer.Insert("LeftText", BottomLeftText);
	Footer.Insert("CenterText", BottomCenterText);
	Footer.Insert("RightText", BottomRightText);
	Footer.Insert("Font", FontFooter);
	Footer.Insert("VerticalAlign", VerticalAlignBottom);
	Footer.Insert("HomePage", FooterStartPage);
	
	Settings = New Structure("Header, Footer", Header, Footer);
	SettingsStatus = HeaderFooterManagement.HeadersAndFootersSettingsStatus(Settings);
	
	If Not IsCustomSettings Then 
		HeaderFooterManagement.SaveHeadersAndFootersSettings(Settings);
	EndIf;
EndProcedure

// Sets the last saved common settings.
//
&AtServer
Procedure SetStandardSettingsServer()
	If Settings = Undefined Then 
		Settings = HeaderFooterManagement.HeaderOrFooterSettings();
	EndIf;
	
	HeaderStartPage = Settings.Header.HomePage;
	TopLeftText = Settings.Header.LeftText;
	TopMiddleText = Settings.Header.CenterText;
	TopRightText = Settings.Header.RightText;
	FontHeader = Settings.Header.Font;
	VerticalAlignTop = Settings.Header.VerticalAlign;
	
	FooterStartPage = Settings.Footer.HomePage;
	BottomLeftText = Settings.Footer.LeftText;
	BottomCenterText = Settings.Footer.CenterText;
	BottomRightText = Settings.Footer.RightText;
	FontFooter = Settings.Footer.Font;
	VerticalAlignBottom = Settings.Footer.VerticalAlign;
	
	Items.HeaderVerticalAlignTop.Check = 
		VerticalAlignTop = VerticalAlign.Top;
	Items.HeaderVerticalAlignCenter.Check = 
		VerticalAlignTop = VerticalAlign.Center;
	Items.HeaderVerticalAlignBottom.Check = 
		VerticalAlignTop = VerticalAlign.Bottom;
		
	Items.FooterVerticalAlignTop.Check = 
		VerticalAlignBottom = VerticalAlign.Top;
	Items.FooterVerticalAlignCenter.Check = 
		VerticalAlignBottom = VerticalAlign.Center;
	Items.FooterVerticalAlignBottom.Check = 
		VerticalAlignBottom = VerticalAlign.Bottom;
	
	PreparePreview();
EndProcedure

&AtServer
Procedure PreparePreview()
	Preview.Area(1, 1).RowHeight  = 5;
	Preview.Area(1, 1).ColumnWidth = 1;
	
	Preview.Area(2, 2, 4, 4).BorderColor = New Color(128, 128, 128);
	Preview.Area(2, 2, 4, 4).TextPlacement = SpreadsheetDocumentTextPlacementType.Block;
	
	Line = New Line(SpreadsheetDocumentCellLineType.Solid, 1);
	
	Preview.Area(2, 2).Outline(Line, Line,, Line);
	Preview.Area(2, 3).Outline(, Line,, Line);
	Preview.Area(2, 4).Outline(, Line, Line, Line);
	
	Preview.Area(4, 2).Outline(Line, Line,, Line);
	Preview.Area(4, 3).Outline(, Line, , Line);
	Preview.Area(4, 4).Outline(, Line, Line, Line);
	
	
	Preview.Area(2, 2).HorizontalAlign = HorizontalAlign.Left;
	Preview.Area(2, 3).HorizontalAlign = HorizontalAlign.Center;
	Preview.Area(2, 4).HorizontalAlign = HorizontalAlign.Right;
	
	Preview.Area(4, 2).HorizontalAlign = HorizontalAlign.Left;
	Preview.Area(4, 3).HorizontalAlign = HorizontalAlign.Center;
	Preview.Area(4, 4).HorizontalAlign = HorizontalAlign.Right;
	
	Preview.Area(2, 2).ColumnWidth = 40;
	Preview.Area(2, 3).ColumnWidth = 40;
	Preview.Area(2, 4).ColumnWidth = 40;
	
	Preview.Area(3, 2).Text      = Chars.LF + NStr("ru = 'Образец отчета'; en = 'Report preview'; pl = 'Przykładowy raport';de = 'Musterbericht';ro = 'Modelul raportului';tr = 'Örnek rapor'; es_ES = 'Modelo de informe'") + Chars.LF + " ";
	Preview.Area(3, 2).Font      = New Font("Arial", 20);
	Preview.Area(3, 2).TextColor = New Color(128, 128, 128);
	
	Preview.Area(3, 2).HorizontalAlign = HorizontalAlign.Center;
		
	Preview.Area(3, 2, 3, 4).Merge();
	Preview.Area(3, 2, 3, 4).Outline(Line, Line, Line, Line);
EndProcedure

&AtClient
Procedure UpdatePreview()
	Preview.Area(2, 2, 2, 4).Font = FontHeader;
	Preview.Area(4, 2, 4, 4).Font = FontFooter;
	
	Preview.Area(2, 2, 2, 4).VerticalAlign = VerticalAlignTop;
	Preview.Area(4, 2, 4, 4).VerticalAlign = VerticalAlignBottom;
	
	RowsAboveCount = Max(
		2,
		RowsCountInText(TopLeftText),
		RowsCountInText(TopMiddleText),
		RowsCountInText(TopRightText));
		
	RowsBelowCount = Max(
		2,
		RowsCountInText(BottomLeftText),
		RowsCountInText(BottomCenterText),
		RowsCountInText(BottomRightText));
		
	Preview.Area(2, 2).RowHeight = RowsAboveCount * HeaderAndFooterRowHeight();
	Preview.Area(4, 2).RowHeight = RowsBelowCount * HeaderAndFooterRowHeight();
		
	Preview.Area(2, 2).Text = FillTemplate(TopLeftText, HeaderStartPage);
	Preview.Area(2, 3).Text = FillTemplate(TopMiddleText, HeaderStartPage);
	Preview.Area(2, 4).Text = FillTemplate(TopRightText, HeaderStartPage);
	
	Preview.Area(4, 2).Text = FillTemplate(BottomLeftText, FooterStartPage);
	Preview.Area(4, 3).Text = FillTemplate(BottomCenterText, FooterStartPage);
	Preview.Area(4, 4).Text = FillTemplate(BottomRightText, FooterStartPage);
EndProcedure

&AtClient
Function RowsCountInText(Text)
	Return StrSplit(Text, Chars.LF).Count();
EndFunction

&AtClient
Function FillTemplate(Template, StartPage)
	If StartPage > PagePreview Then
		Result = "";
	Else
		DateToday = CommonClient.SessionDate();
		Result = StrReplace(Template   , "[&Time]"         , Format(DateToday, "DLF=T"));
		Result = StrReplace(Result, "[&Date]"          , Format(DateToday, "DLF=D"));
		Result = StrReplace(Result, "[&ReportDescription]", NStr("ru = 'Стандартный отчет'; en = 'Standard report'; pl = 'Standardowy raport';de = 'Standardbericht';ro = 'Raport standard';tr = 'Standart rapor'; es_ES = 'Informe estándar'"));
		Result = StrReplace(Result, "[&User]"  , String(CurrentUser));
		Result = StrReplace(Result, "[&PageNumber]" , PagePreview);
		Result = StrReplace(Result, "[&PagesTotal]"  , "9");
	EndIf;

	Return Result;
EndFunction

&AtClient
Procedure HeaderFontSettingCompletion (SelectedFont, Parameters) Export
	If SelectedFont = Undefined Then
		Return;
	EndIf;
	
	FontHeader = SelectedFont;
	UpdatePreview();
EndProcedure

&AtClient
Procedure FooterFontSettingCompletion (SelectedFont, Parameters) Export
	If SelectedFont = Undefined Then
		Return;
	EndIf;
	
	FontFooter = SelectedFont;
	UpdatePreview();
EndProcedure

#EndRegion