﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Object.Predefined Or Object.DenayEditingByUser Then
		Items.Description.ReadOnly = True;
		Items.Parent.ReadOnly     = True;
		Items.Type.ReadOnly          = True;
		Items.TypeCommonGroup.ReadOnly = Object.DenayEditingByUser;
	Else
		// Object attribute lock subsystem handler.
		If Common.SubsystemExists("StandardSubsystems.ObjectAttributesLock") Then
			ModuleObjectAttributesLock = Common.CommonModule("ObjectAttributesLock");
			ModuleObjectAttributesLock.LockAttributes(ThisObject,, NStr("ru = 'Разрешить редактирование типа и группы'; en = 'Allow edit type and group'; pl = 'Zezwalaj na edycję typu i grupy';de = 'Bearbeitungstyp und -gruppe zulassen';ro = 'Permiteți tipul și grupul de editare';tr = 'Tür ve grubun düzenlenmesine izin ver'; es_ES = 'Permitir el tipo de edición y el grupo'"));
			
		Else
			Items.Parent.ReadOnly = True;
			Items.Type.ReadOnly = True;
		EndIf;
	EndIf;
	
	ParentRef = Object.Parent;
	Items.StoreChangeHistory.Enabled         = Object.EditInDialogOnly;
	Items.AllowMultipleValueInput.Enabled = NOT Object.StoreChangeHistory;
	
	If Not Object.CanChangeEditMethod Then
		Items.EditInDialogOnly.Enabled       = False;
		Items.AllowMultipleValueInput.Enabled    = False;
		Items.SettingDescriptionByTypeGroup.Enabled = False;
		Items.StoreChangeHistory.Enabled            = False;
	EndIf;
	
	Items.StoreChangeHistoryGroup.Visible = False;
	
	If Object.Type = Enums.ContactInformationTypes.Address
		OR NOT ParentRef.IsEmpty()
		OR ParentRef.Level() = 0 Then
		TabularSection = Undefined;
		
		ParentAttributes = Common.ObjectAttributesValues(ParentRef, "PredefinedDataName, PredefinedKindName");
		PredefinedKindName = ?(ValueIsFilled(ParentAttributes.PredefinedKindName),
			ParentAttributes.PredefinedKindName, ParentAttributes.PredefinedDataName);
		
		If StrStartsWith(PredefinedKindName, "Catalog") Then
			ObjectName = Mid(PredefinedKindName, StrLen("Catalog") + 1);
			If Metadata.Catalogs.Find(ObjectName) <> Undefined Then
				TabularSection = Metadata.Catalogs[ObjectName].TabularSections.Find("ContactInformation");
			EndIf;
		ElsIf StrStartsWith(PredefinedKindName, "Document") Then
			ObjectName = Mid(PredefinedKindName, StrLen("Document") + 1);
			If Metadata.Documents.Find(ObjectName) <> Undefined Then
				TabularSection = Metadata.Documents[ObjectName].TabularSections.Find("ContactInformation");
			EndIf;
		EndIf;
		
		If TabularSection <> Undefined Then
			If TabularSection.Attributes.Find("ValidFrom") <> Undefined Then
				Items.StoreChangeHistoryGroup.Visible = True;
			EndIf;
		EndIf;
	EndIf;
	
	AdditionalAddressSettingsAvailable = (Metadata.DataProcessors.Find("AdvancedContactInformationInput") <> Undefined
		AND Metadata.DataProcessors["AdvancedContactInformationInput"].Forms.Find("AddressSettings") <> Undefined);
		
	LocalizationServer.OnCreateAtServer(Items.Description);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	ChangeDisplayOnTypeChange();
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	LocalizationServer.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If Not CurrentObject.CheckFilling() Then
		Cancel = True;
	EndIf;
	
	LocalizationServer.BeforeWriteAtServer(CurrentObject);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	If Not CurrentObject.Predefined Then
		// Object attribute lock subsystem handler.
		If Common.SubsystemExists("StandardSubsystems.ObjectAttributesLock") Then
			ModuleObjectAttributesLock = Common.CommonModule("ObjectAttributesLock");
			ModuleObjectAttributesLock.LockAttributes(ThisObject);
		EndIf;
	EndIf;
	
	LocalizationServer.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	CheckedAttributes.Clear();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure TypeOnChange(Item)
	
	ChangeAttributesOnTypeChange();
	ChangeDisplayOnTypeChange();
	
EndProcedure

&AtClient
Procedure ClearType(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure EditOnlyInDialogOnChange(Item)
	
	If Object.EditInDialogOnly Then
		Items.StoreChangeHistory.Enabled = True;
	Else
		Items.StoreChangeHistory.Enabled = False;
		Object.StoreChangeHistory               = False;
	EndIf;
	
	Items.AllowMultipleValueInput.Enabled = NOT Object.StoreChangeHistory;
	
EndProcedure

&AtClient
Procedure StoreChangesHistoryOnChange(Item)
	
	If Object.StoreChangeHistory Then
		Object.AllowMultipleValueInput = False;
	EndIf;
	
	Items.AllowMultipleValueInput.Enabled = Not Object.StoreChangeHistory;
	
EndProcedure

&AtClient
Procedure AllowMultipleValuesInputOnChange(Item)
	
	If Object.AllowMultipleValueInput Then
		Object.StoreChangeHistory = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure ParentClear(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure InternationalAddressFormatOnChange(Item)
	
	ChangeDisplayOnTypeChange();
	
EndProcedure

&AtClient
Procedure DescriptionOpen(Item, StandardProcessing)
	
	LocalizationClient.OnOpen(Object, Item, "Description", StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Attachable_AllowObjectAttributesEditing(Command)
	
	If Not Object.Predefined Then
		If CommonClient.SubsystemExists("StandardSubsystems.ObjectAttributesLock") Then
			ModuleObjectAttributesLockClient = CommonClient.CommonModule("ObjectAttributesLockClient");
			ModuleObjectAttributesLockClient.AllowObjectAttributeEdit(ThisObject);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure AdditionalAddressSettings(Command)
	ClosingNotification = New NotifyDescription("AfterCloseAddressSettingsForm", ThisObject);
	FormParameters = New Structure();
	FormParameters.Insert("Object", Object);
	FormParameters.Insert("ReadOnly", ThisObject.ReadOnly);
	AddressSettingsFormName = "DataProcessor.AdvancedContactInformationInput.Form.AddressSettings";
	OpenForm(AddressSettingsFormName, FormParameters,,,,, ClosingNotification);
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ChangeDisplayOnTypeChange()
	
	If Object.Type = PredefinedValue("Enum.ContactInformationTypes.Address") Then
		Items.Validation.CurrentPage = Items.Validation.ChildItems.Address;
		Items.EditInDialogOnly.Enabled  = Object.CanChangeEditMethod;
		Items.AdditionalAddressSettings.Visible   = AdditionalAddressSettingsAvailable;
		Items.AdditionalAddressSettings.Enabled = Not Object.InternationalAddressFormat;
	Else
		Items.AdditionalAddressSettings.Visible = False;
		If Object.Type = PredefinedValue("Enum.ContactInformationTypes.EmailAddress") Then
			Items.Validation.CurrentPage = Items.Validation.ChildItems.EmailAddress;
			Items.EditInDialogOnly.Enabled = False;
		ElsIf Object.Type = PredefinedValue("Enum.ContactInformationTypes.Skype") Then
			Items.Validation.CurrentPage = Items.Validation.ChildItems.Skype;
			Items.EditInDialogOnly.Enabled = False;
			Items.AllowMultipleValueInput.Enabled = True;
		ElsIf Object.Type = PredefinedValue("Enum.ContactInformationTypes.Phone")
			Or Object.Type = PredefinedValue("Enum.ContactInformationTypes.Fax") Then
			Items.Validation.CurrentPage = Items.Validation.ChildItems.Phone;
			Items.EditInDialogOnly.Enabled = Object.CanChangeEditMethod;
		ElsIf Object.Type = PredefinedValue("Enum.ContactInformationTypes.Other") Then
			Items.Validation.CurrentPage = Items.Validation.ChildItems.Other;
			Items.EditInDialogOnly.Enabled = False;
		ElsIf Object.Type = PredefinedValue("Enum.ContactInformationTypes.WebPage") Then
			Items.Validation.CurrentPage = Items.Validation.ChildItems.OtherItems;
			Items.EditInDialogOnly.Visible  = False;
			Items.StoreChangeHistoryGroup.Visible = False;
		Else
			Items.Validation.CurrentPage = Items.Validation.ChildItems.OtherItems;
			Items.EditInDialogOnly.Enabled = False;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeAttributesOnTypeChange()
	
	If Object.Type = PredefinedValue("Enum.ContactInformationTypes.Address") Then
		Items.StoreChangeHistory.Enabled = True;
	Else
		
		Object.StoreChangeHistory               = False;
		Items.StoreChangeHistory.Enabled = False;
		
		If Object.Type = PredefinedValue("Enum.ContactInformationTypes.EmailAddress") Then
			Object.EditInDialogOnly = False;
		ElsIf Object.Type = PredefinedValue("Enum.ContactInformationTypes.Phone")
			Or Object.Type = PredefinedValue("Enum.ContactInformationTypes.Fax") Then
			// No changes
		Else
			Object.EditInDialogOnly = False;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterCloseAddressSettingsForm(Result, AdditionalParameters) Export
	If TypeOf(Result) = Type("Structure") Then
		FillPropertyValues(Object, Result);
	EndIf;
EndProcedure

#EndRegion

