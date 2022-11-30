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
	
	Value = Common.CommonSettingsStorageLoad(
		"TemplateOpeningSettings", 
		"PromptForTemplateOpeningMode");
	
	If Value = Undefined Then
		DontAskAgain = False;
	Else
		DontAskAgain = NOT Value;
	EndIf;
	
	Value = Common.CommonSettingsStorageLoad(
		"TemplateOpeningSettings", 
		"TemplateOpeningModeView");
	
	If Value = Undefined Then
		HowToOpen = 0;
	Else
		If Value Then
			HowToOpen = 0;
		Else
			HowToOpen = 1;
		EndIf;
	EndIf;
	
	If Common.IsMobileClient() Then
		Items.HowToOpen.ChoiceList.Clear();
		Items.HowToOpen.ChoiceList.Add(0, NStr("ru = 'Для просмотра'; en = 'View only'; pl = 'Do obejrzenia';de = 'Zur Ansicht';ro = 'Pentru vizualizare';tr = 'Görüntülemek için'; es_ES = 'Para ver'"));
		Items.HowToOpen.ChoiceList.Add(1, NStr("ru = 'Для редактирования'; en = 'Edit'; pl = 'Do edycji';de = 'Zur Bearbeitung';ro = 'Pentru editare';tr = 'Düzenleme için'; es_ES = 'Para editar'"));
		CommandBarLocation = FormCommandBarLabelLocation.Top;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure OK(Command)
	
	PromptForTemplateOpeningMode = NOT DontAskAgain;
	TemplateOpeningModeView = ?(HowToOpen = 0, True, False);
	
	SaveTemplateOpeningModeSettings(PromptForTemplateOpeningMode, TemplateOpeningModeView);
	
	NotifyChoice(New Structure("DontAskAgain, OpeningModeView",
							DontAskAgain,
							TemplateOpeningModeView) );
	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Procedure SaveTemplateOpeningModeSettings(PromptForTemplateOpeningMode, TemplateOpeningModeView)
	
	Common.CommonSettingsStorageSave(
		"TemplateOpeningSettings", 
		"PromptForTemplateOpeningMode", 
		PromptForTemplateOpeningMode);
	
	Common.CommonSettingsStorageSave(
		"TemplateOpeningSettings", 
		"TemplateOpeningModeView", 
		TemplateOpeningModeView);
	
EndProcedure

#EndRegion
