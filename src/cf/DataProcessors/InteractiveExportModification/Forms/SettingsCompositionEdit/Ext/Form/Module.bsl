///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers
//

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	FillPropertyValues(Object, Parameters.Object , , "AllDocumentsFilterComposer, AdditionalRegistration, AdditionalNodeScenarioRegistration");
	For Each Row In Parameters.Object.AdditionalRegistration Do
		FillPropertyValues(Object.AdditionalRegistration.Add(), Row);
	EndDo;
	For Each Row In Parameters.Object.AdditionalNodeScenarioRegistration Do
		FillPropertyValues(Object.AdditionalNodeScenarioRegistration.Add(), Row);
	EndDo;
	
	// Initializing composer manually.
	DataProcessorObject = FormAttributeToValue("Object");
	
	Data = GetFromTempStorage(Parameters.Object.AllDocumentsComposerAddress);
	DataProcessorObject.AllDocumentsFilterComposer = New DataCompositionSettingsComposer;
	DataProcessorObject.AllDocumentsFilterComposer.Initialize(
		New DataCompositionAvailableSettingsSource(Data.CompositionSchema));
	DataProcessorObject.AllDocumentsFilterComposer.LoadSettings(Data.Settings);
	
	ValueToFormAttribute(DataProcessorObject, "Object");
	
	CurrentSettingsItemPresentation = Parameters.CurrentSettingsItemPresentation;
	ReadSavedSettings();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSettingsOptions
//

&AtClient
Procedure SettingsOptionsChoice(Item, RowSelected, Field, StandardProcessing)
	CurrentData = SettingVariants.FindByID(RowSelected);
	If CurrentData<>Undefined Then
		CurrentSettingsItemPresentation = CurrentData.Presentation;
	EndIf;
EndProcedure

&AtClient
Procedure SettingsOptionsBeforeAdd(Item, Cancel, Clone, Parent, Folder)
	Cancel = True;
EndProcedure

&AtClient
Procedure SettingsOptionsBeforeDelete(Item, Cancel)
	Cancel = True;
	
	SettingPresentation = Item.CurrentData.Presentation;
	
	TitleText = NStr("ru='Подтверждение'; en = 'Confirm operation'; pl = 'Potwierdzenie';de = 'Bestätigung';ro = 'Confirmare';tr = 'Onay'; es_ES = 'Confirmación'");
	QuestionText   = NStr("ru='Удалить настройку ""%1""?'; en = 'Do you want to delete setting ""%1""?'; pl = 'Usuń ustawienie ""%1""?';de = 'Einstellung ""%1"" entfernen?';ro = 'Ștergeți setarea ""%1""?';tr = '""%1"" ayarı kaldırılsın mı?'; es_ES = '¿Eliminar la configuración ""%1""?'");
	
	QuestionText = StrReplace(QuestionText, "%1", SettingPresentation);
	
	AdditionalParameters = New Structure("SettingPresentation", SettingPresentation);
	NotifyDescription = New NotifyDescription("DeleteSettingsVariantRequestNotification", ThisObject, 
		AdditionalParameters);
	
	ShowQueryBox(NotifyDescription, QuestionText, QuestionDialogMode.YesNo,,,TitleText);
EndProcedure

#EndRegion

#Region FormCommandHandlers
//

&AtClient
Procedure SaveSetting(Command)
	
	If IsBlankString(CurrentSettingsItemPresentation) Then
		CommonClient.MessageToUser(
			NStr("ru='Не заполнено имя для текущей настройки.'; en = 'Please enter the setting name.'; pl = 'Nazwa bieżącego ustawienia nie została wpisana.';de = 'Der Name für die aktuelle Einstellung wurde nicht eingegeben.';ro = 'Numele pentru setarea curentă nu este completat.';tr = 'Mevcut ayarın adı girilmemiş.'; es_ES = 'Nombre para la configuración actual no se ha introducido.'"), , "CurrentSettingsItemPresentation");
		Return;
	EndIf;
		
	If SettingVariants.FindByValue(CurrentSettingsItemPresentation)<>Undefined Then
		TitleText = NStr("ru='Подтверждение'; en = 'Confirm operation'; pl = 'Potwierdzenie';de = 'Bestätigung';ro = 'Confirmare';tr = 'Onay'; es_ES = 'Confirmación'");
		QuestionText   = NStr("ru='Перезаписать существующую настройку ""%1""?'; en = 'Do you want to overwrite setting ""%1""?'; pl = 'Przepisz istniejące ustawienie ""%1""?';de = 'Bestehende Einstellung ""%1"" neu schreiben?';ro = 'Reînregistrați setarea curentă ""%1""?';tr = 'Mevcut ayarı yeniden yaz ""%1""?'; es_ES = '¿Volver a grabar la configuración existente ""%1""?'");
		QuestionText = StrReplace(QuestionText, "%1", CurrentSettingsItemPresentation);
		
		AdditionalParameters = New Structure("SettingPresentation", CurrentSettingsItemPresentation);
		NotifyDescription = New NotifyDescription("SaveSettingsVariantRequestNotification", ThisObject, 
			AdditionalParameters);
			
		ShowQueryBox(NotifyDescription, QuestionText, QuestionDialogMode.YesNo,,,TitleText);
		Return;
	EndIf;
	
	// Saving without displaying a question
	SaveAndExecuteCurrentSettingSelection();
EndProcedure
	
&AtClient
Procedure MakeChoice(Command)
	ExecuteSelection(CurrentSettingsItemPresentation);
EndProcedure

#EndRegion

#Region Private
//

&AtServer
Function ThisObject(NewObject=Undefined)
	If NewObject=Undefined Then
		Return FormAttributeToValue("Object");
	EndIf;
	ValueToFormAttribute(NewObject, "Object");
	Return Undefined;
EndFunction

&AtServer
Procedure DeleteSettingsServer(SettingPresentation)
	ThisObject().DeleteSettingsOption(SettingPresentation);
EndProcedure

&AtServer
Procedure ReadSavedSettings()
	ThisDataProcessor = ThisObject();
	
	VariantFilter = DataExchangeServer.InteractiveExportModificationVariantFilter(Object);
	SettingVariants = ThisDataProcessor.ReadSettingsListPresentations(Object.InfobaseNode, VariantFilter);
	
	ListItem = SettingVariants.FindByValue(CurrentSettingsItemPresentation);
	Items.SettingVariants.CurrentRow = ?(ListItem=Undefined, Undefined, ListItem.GetID())
EndProcedure

&AtServer
Procedure SaveCurrentSettings()
	ThisObject().SaveCurrentValuesInSettings(CurrentSettingsItemPresentation);
EndProcedure

&AtClient
Procedure ExecuteSelection(Presentation)
	If SettingVariants.FindByValue(Presentation)<>Undefined AND CloseOnChoice Then 
		NotifyChoice( New Structure("ChoiceAction, SettingPresentation", 3, Presentation) );
	EndIf;
EndProcedure

&AtClient
Procedure DeleteSettingsVariantRequestNotification(Result, AdditionalParameters) Export
	If Result<>DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	DeleteSettingsServer(AdditionalParameters.SettingPresentation);
	ReadSavedSettings();
EndProcedure

&AtClient
Procedure SaveSettingsVariantRequestNotification(Result, AdditionalParameters) Export
	If Result<>DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	CurrentSettingsItemPresentation = AdditionalParameters.SettingPresentation;
	SaveAndExecuteCurrentSettingSelection();
EndProcedure

&AtClient
Procedure SaveAndExecuteCurrentSettingSelection()
	
	SaveCurrentSettings();
	ReadSavedSettings();
	
	CloseOnChoice = True;
	ExecuteSelection(CurrentSettingsItemPresentation);
EndProcedure;

#EndRegion
