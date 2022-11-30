///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var ChoiceContext;

#EndRegion

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	FillPrintFormsTemplatesTable();
	If Parameters.Property("ShowOnlyUserChanges") Then
		FilterByTemplateUsage = "UsedModifiedItems";
	Else
		FilterByTemplateUsage = Items.FilterByTemplateUsage.ChoiceList[0].Value;
	EndIf;
	
	HasUpdateRight = AccessRight("Update", Metadata.InformationRegisters.UserPrintTemplates);
	ReadOnly = Not HasUpdateRight;
	Items.PrintFormsTemplatesChangeTemplate.Visible = HasUpdateRight;
	Items.PrintFormsTemplatesSwitchUsedTemplateGroup.Visible = HasUpdateRight;
	Items.PrintFormsTemplatesDeleteModifiedTemplate.Visible = HasUpdateRight;
	
	If Common.IsMobileClient() Then
		
		PromptForTemplateOpeningMode = False;
		TemplateOpeningModeView = True;
		
	Else
		
		PromptForTemplateOpeningMode = HasUpdateRight;
		TemplateOpeningModeView = Not HasUpdateRight;
		
		If HasUpdateRight Then
			PromptForTemplateOpeningMode = Common.CommonSettingsStorageLoad(
				"TemplateOpeningSettings", "PromptForTemplateOpeningMode", True);
			TemplateOpeningModeView = Common.CommonSettingsStorageLoad(
				"TemplateOpeningSettings", "TemplateOpeningModeView", False);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_UserPrintTemplates" Then
		RefreshTemplatesDisplay();
	ElsIf EventName = "Write_SpreadsheetDocument" AND Source.FormOwner = ThisObject Then
		If Not ReadOnly Then
			Template = Parameter.SpreadsheetDocument;
			TemplateAddressInTempStorage = PutToTempStorage(Template);
			WriteTemplate(Parameter.TemplateMetadataObjectName, TemplateAddressInTempStorage);
		EndIf;
		RefreshTemplatesDisplay()
	EndIf;
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectedValue, ChoiceSource)
	
	If Upper(ChoiceSource.FormName) = Upper("InformationRegister.UserPrintTemplates.Form.SelectTemplateOpeningMode") Then
		
		If TypeOf(SelectedValue) <> Type("Structure") Then
			Return;
		EndIf;
		
		TemplateOpeningModeView = SelectedValue.OpeningModeView;
		PromptForTemplateOpeningMode = NOT SelectedValue.DontAskAgain;
		
		If ChoiceContext = "OpenPrintFormTemplate" Then
			
			If SelectedValue.DontAskAgain Then
				SaveTemplateOpeningModeSettings(PromptForTemplateOpeningMode, TemplateOpeningModeView);
			EndIf;
			
			If TemplateOpeningModeView Then
				OpenPrintFormTemplateForView();
			Else
				OpenPrintFormTemplateForEdit();
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit Then
		Return;
	EndIf;
	
	Parameter = New Structure("Cancel", False);
	Notify("OwnerFormClosing", Parameter, ThisObject);
	
	If Parameter.Cancel Then
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	SetTemplatesFilter();
EndProcedure

#EndRegion

#Region PrintFormsTemplatesFormTableItemsEventHandlers

&AtClient
Procedure PrintFormsTemplatesSelection(Item, RowSelected, Field, StandardProcessing)
	OpenPrintFormTemplate();
EndProcedure

&AtClient
Procedure PrintFormsTemplatesOnActivateRow(Item)
	SetCommandBarButtonsEnabled();
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure ChangeTemplate(Command)
	OpenPrintFormTemplateForEdit();
EndProcedure

&AtClient
Procedure OpenTemplate(Command)
	OpenPrintFormTemplateForView();
EndProcedure

&AtClient
Procedure UseModifiedTemplate(Command)
	SwitchSelectedTemplatesUsage(True);
EndProcedure

&AtClient
Procedure UseStandardTemplate(Command)
	SwitchSelectedTemplatesUsage(False);
EndProcedure

&AtClient
Procedure SetActionOnChoosePrintFormTemplate(Command)
	
	ChoiceContext = "SetActionOnChoosePrintFormTemplate";
	OpenForm("InformationRegister.UserPrintTemplates.Form.SelectTemplateOpeningMode", , ThisObject);
	
EndProcedure

#EndRegion

#Region Private

// Initial filling

&AtServer
Procedure FillPrintFormsTemplatesTable()
	
	For Each TemplateDetails In InformationRegisters.SuppliedPrintTemplates.AllConfigurationPrintFormsTemplates() Do
		Owner = TemplateDetails.Value;
		OwnerName = ?(Metadata.CommonTemplates = Owner, "CommonTemplate", Owner.FullName());
		OwnerPresentation = ?(Metadata.CommonTemplates = Owner, NStr("ru = 'Общий макет'; en = 'Common layout'; pl = 'Ogólny układ';de = 'Allgemeines Layout';ro = 'Macheta comună';tr = 'Ortak şablon'; es_ES = 'Plantilla común'"), Owner.Presentation());
		
		Template = TemplateDetails.Key;
		TemplateName = OwnerName + "." + Template.Name;
		TemplatePresentation = Template.Presentation();
		
		TemplateType = TemplateType(Template.Name, OwnerName);
		
		AddTemplateDetails(TemplateName, TemplatePresentation, OwnerPresentation, TemplateType);
	EndDo;
	
	PrintFormTemplates.Sort("TemplatePresentation Asc");
	SetModifiedTemplatesUsageFlags();
EndProcedure

&AtServer
Function AddTemplateDetails(TemplateMetadataObjectName, TemplatePresentation, OwnerPresentation, TemplateType)
	TemplateDetails = PrintFormTemplates.Add();
	TemplateDetails.TemplateType = TemplateType;
	TemplateDetails.TemplateMetadataObjectName = TemplateMetadataObjectName;
	TemplateDetails.OwnerPresentation = OwnerPresentation;
	TemplateDetails.TemplatePresentation = TemplatePresentation;
	TemplateDetails.Picture = PictureIndex(TemplateType);
	TemplateDetails.SearchString = TemplateMetadataObjectName + " "
								+ OwnerPresentation + " "
								+ TemplatePresentation + " "
								+ TemplateType;
	Return TemplateDetails;
EndFunction

&AtServer
Procedure SetModifiedTemplatesUsageFlags()
	
	QueryText =
	"SELECT
	|	ModifiedTemplates.TemplateName,
	|	ModifiedTemplates.Object,
	|	ModifiedTemplates.Use
	|FROM
	|	InformationRegister.UserPrintTemplates AS ModifiedTemplates";
	
	Query = New Query(QueryText);
	ModifiedTemplates = Query.Execute().Unload();
	For Each Template In ModifiedTemplates Do
		TemplateMetadataObjectName = Template.Object + "." + Template.TemplateName;
		FoundRows = PrintFormTemplates.FindRows(New Structure("TemplateMetadataObjectName", TemplateMetadataObjectName));
		For Each TemplateDetails In FoundRows Do
			TemplateDetails.Changed = True;
			TemplateDetails.ChangedTemplateUsed = Template.Use;
			TemplateDetails.UsagePicture = Number(TemplateDetails.Changed) + Number(TemplateDetails.ChangedTemplateUsed);
		EndDo;
	EndDo;
	
EndProcedure

&AtServer
Function TemplateType(TemplateMetadataObjectName, ObjectName = "CommonTemplate")
	
	Position = StrFind(TemplateMetadataObjectName, "PF_");
	If Position = 0 Then
		Return Undefined;
	EndIf;
	
	If ObjectName = "CommonTemplate" Then
		PrintFormTemplate = GetCommonTemplate(TemplateMetadataObjectName);
	Else
		SetSafeModeDisabled(True);
		SetPrivilegedMode(True);
		
		PrintFormTemplate = Common.ObjectManagerByFullName(ObjectName).GetTemplate(TemplateMetadataObjectName);
		
		SetPrivilegedMode(False);
		SetSafeModeDisabled(False);
	EndIf;
	
	TemplateType = Undefined;
	
	If TypeOf(PrintFormTemplate) = Type("SpreadsheetDocument") Then
		TemplateType = "MXL";
	ElsIf TypeOf(PrintFormTemplate) = Type("BinaryData") Then
		TemplateType = Upper(PrintManagementInternal.DefineDataFileExtensionBySignature(PrintFormTemplate));
	EndIf;
	
	Return TemplateType;
	
EndFunction

&AtServer
Function PictureIndex(Val TemplateType)
	
	TemplateTypes = New Map;
	TemplateTypes.Insert("DOC", 0);
	TemplateTypes.Insert("ODT", 1);
	TemplateTypes.Insert("MXL", 2);
	
	Result = TemplateTypes[Upper(TemplateType)];
	Return ?(Result = Undefined, -1, Result);
	
EndFunction 

// Filters

&AtClient
Procedure SetTemplatesFilter(Text = Undefined);
	If Text = Undefined Then
		Text = SearchString;
	EndIf;
	
	FilterStructure = New Structure;
	FilterStructure.Insert("SearchString", TrimAll(Text));
	If FilterByTemplateUsage = "Modified" Then
		FilterStructure.Insert("Changed", True);
	ElsIf FilterByTemplateUsage = "NotModified" Then
		FilterStructure.Insert("Changed", False);
	ElsIf FilterByTemplateUsage = "UsedModifiedItems" Then
		FilterStructure.Insert("ChangedTemplateUsed", True);
	ElsIf FilterByTemplateUsage = "NotUsedModifiedItems" Then
		FilterStructure.Insert("ChangedTemplateUsed", False);
		FilterStructure.Insert("Changed", True);
	EndIf;
	
	Items.PrintFormTemplates.RowFilter = New FixedStructure(FilterStructure);
	SetCommandBarButtonsEnabled();
EndProcedure

&AtClient
Procedure SearchStringAutoComplete(Item, Text, ChoiceData, Wait, StandardProcessing)
	SetTemplatesFilter(Text);
EndProcedure

&AtClient
Procedure SearchStringClearing(Item, StandardProcessing)
	SetTemplatesFilter();
EndProcedure

&AtClient
Procedure SearchStringOnChange(Item)
	SetTemplatesFilter();
	If Items.SearchString.ChoiceList.FindByValue(SearchString) = Undefined Then
		Items.SearchString.ChoiceList.Add(SearchString);
	EndIf;
EndProcedure

&AtClient
Procedure FilterByUsedTemplateKindOnChange(Item)
	SetTemplatesFilter();
EndProcedure

&AtClient
Procedure FilterByTemplateUsageClearing(Item, StandardProcessing)
	StandardProcessing = False;
	FilterByTemplateUsage = Items.FilterByTemplateUsage.ChoiceList[0].Value;
	SetTemplatesFilter();
EndProcedure

// Opening a template

&AtClient
Procedure OpenPrintFormTemplate()
	
	If PromptForTemplateOpeningMode Then
		ChoiceContext = "OpenPrintFormTemplate";
		OpenForm("InformationRegister.UserPrintTemplates.Form.SelectTemplateOpeningMode", , ThisObject);
		Return;
	EndIf;
	
	If TemplateOpeningModeView Then
		OpenPrintFormTemplateForView();
	Else
		OpenPrintFormTemplateForEdit();
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenPrintFormTemplateForView()
	
	CurrentData = Items.PrintFormTemplates.CurrentData;
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("TemplateMetadataObjectName", CurrentData.TemplateMetadataObjectName);
	OpeningParameters.Insert("TemplateType", CurrentData.TemplateType);
	OpeningParameters.Insert("OpenOnly", True);
	
	If CurrentData.TemplateType = "MXL" Then
		OpeningParameters.Insert("DocumentName", CurrentData.TemplatePresentation);
		OpenForm("CommonForm.EditSpreadsheetDocument", OpeningParameters, ThisObject);
		Return;
	EndIf;
	
	OpenForm("InformationRegister.UserPrintTemplates.Form.EditTemplate", OpeningParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure OpenPrintFormTemplateForEdit()
	
	CurrentData = Items.PrintFormTemplates.CurrentData;
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("TemplateMetadataObjectName", CurrentData.TemplateMetadataObjectName);
	OpeningParameters.Insert("TemplateType", CurrentData.TemplateType);
	
	If CurrentData.TemplateType = "MXL" Then
		OpeningParameters.Insert("DocumentName", CurrentData.TemplatePresentation);
		OpeningParameters.Insert("Edit", True);
		OpenForm("CommonForm.EditSpreadsheetDocument", OpeningParameters, ThisObject);
		Return;
	EndIf;
	
	OpenForm("InformationRegister.UserPrintTemplates.Form.EditTemplate", OpeningParameters, ThisObject);
	
EndProcedure

&AtServerNoContext
Procedure SaveTemplateOpeningModeSettings(PromptForTemplateOpeningMode, TemplateOpeningModeView)
	
	If NOT Common.IsMobileClient() Then
		
		Common.CommonSettingsStorageSave("TemplateOpeningSettings",
			"PromptForTemplateOpeningMode", PromptForTemplateOpeningMode);
		
		Common.CommonSettingsStorageSave("TemplateOpeningSettings",
			"TemplateOpeningModeView", TemplateOpeningModeView);
		
	EndIf;
	
EndProcedure

// Actions with templates

&AtClient
Procedure SwitchSelectedTemplatesUsage(ChangedTemplateUsed)
	TemplatesToSwitch = New Array;
	For Each SelectedRow In Items.PrintFormTemplates.SelectedRows Do
		CurrentData = Items.PrintFormTemplates.RowData(SelectedRow);
		If CurrentData.Changed Then
			CurrentData.ChangedTemplateUsed = ChangedTemplateUsed;
			SetPictureUsage(CurrentData);
			TemplatesToSwitch.Add(CurrentData.TemplateMetadataObjectName);
		EndIf;
	EndDo;
	SetModifiedTemplatesUsage(TemplatesToSwitch, ChangedTemplateUsed);
	SetCommandBarButtonsEnabled();
EndProcedure

&AtServerNoContext
Procedure SetModifiedTemplatesUsage(Templates, ChangedTemplateUsed)
	
	For Each TemplateMetadataObjectName In Templates Do
		NameParts = StrSplit(TemplateMetadataObjectName, ".");
		TemplateName = NameParts[NameParts.UBound()];
		
		OwnerName = "";
		For PartNumber = 0 To NameParts.UBound()-1 Do
			If Not IsBlankString(OwnerName) Then
				OwnerName = OwnerName + ".";
			EndIf;
			OwnerName = OwnerName + NameParts[PartNumber];
		EndDo;
		
		Record = InformationRegisters.UserPrintTemplates.CreateRecordManager();
		Record.Object = OwnerName;
		Record.TemplateName = TemplateName;
		Record.Read();
		If Record.Selected() Then
			Record.Use = ChangedTemplateUsed;
			Record.Write();
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure DeleteSelectedModifiedTemplates(Command)
	TemplatesToDelete = New Array;
	For Each SelectedRow In Items.PrintFormTemplates.SelectedRows Do
		CurrentData = Items.PrintFormTemplates.RowData(SelectedRow);
		CurrentData.ChangedTemplateUsed = False;
		CurrentData.Changed = False;
		SetPictureUsage(CurrentData);
		TemplatesToDelete.Add(CurrentData.TemplateMetadataObjectName);
	EndDo;
	DeleteModifiedTemplates(TemplatesToDelete);
	SetCommandBarButtonsEnabled();
EndProcedure

&AtServerNoContext
Procedure DeleteModifiedTemplates(TemplatesToDelete)
	
	For Each TemplateMetadataObjectName In TemplatesToDelete Do
		NameParts = StrSplit(TemplateMetadataObjectName, ".");
		TemplateName = NameParts[NameParts.UBound()];
		
		OwnerName = "";
		For PartNumber = 0 To NameParts.UBound()-1 Do
			If Not IsBlankString(OwnerName) Then
				OwnerName = OwnerName + ".";
			EndIf;
			OwnerName = OwnerName + NameParts[PartNumber];
		EndDo;
		
		RecordManager = InformationRegisters.UserPrintTemplates.CreateRecordManager();
		RecordManager.Object = OwnerName;
		RecordManager.TemplateName = TemplateName;
		RecordManager.Delete();
	EndDo;
	
EndProcedure

&AtServerNoContext
Procedure WriteTemplate(TemplateMetadataObjectName, TemplateAddressInTempStorage)
	PrintManagement.WriteTemplate(TemplateMetadataObjectName, TemplateAddressInTempStorage);
EndProcedure

&AtClient
Procedure RefreshTemplatesDisplay();
	
	SetModifiedTemplatesUsageFlags();
	SetCommandBarButtonsEnabled();
	
EndProcedure

// Common

&AtClient
Procedure SetPictureUsage(TemplateDetails)
	TemplateDetails.UsagePicture = Number(TemplateDetails.Changed) + Number(TemplateDetails.ChangedTemplateUsed);
EndProcedure

&AtClient
Procedure SetCommandBarButtonsEnabled()
	
	CurrentTemplate = Items.PrintFormTemplates.CurrentData;
	CurrentTemplateSelected = CurrentTemplate <> Undefined;
	SeveralTemplatesSelected = Items.PrintFormTemplates.SelectedRows.Count() > 1;
	
	Items.PrintFormsTemplatesOpenTemplate.Enabled = CurrentTemplateSelected AND Not SeveralTemplatesSelected;
	Items.PrintFormsTemplatesChangeTemplate.Enabled = CurrentTemplateSelected AND Not SeveralTemplatesSelected;
	
	UseModifiedTemplateEnabled = False;
	UseStandardTemplateEnabled = False;
	DeleteModifiedTemplateEnabled = False;
	
	For Each SelectedRow In Items.PrintFormTemplates.SelectedRows Do
		CurrentTemplate = Items.PrintFormTemplates.RowData(SelectedRow);
		UseModifiedTemplateEnabled = CurrentTemplateSelected AND CurrentTemplate.Changed AND Not CurrentTemplate.ChangedTemplateUsed Or SeveralTemplatesSelected AND UseModifiedTemplateEnabled;
		UseStandardTemplateEnabled = CurrentTemplateSelected AND CurrentTemplate.Changed AND CurrentTemplate.ChangedTemplateUsed Or SeveralTemplatesSelected AND UseStandardTemplateEnabled;
		DeleteModifiedTemplateEnabled = CurrentTemplateSelected AND CurrentTemplate.Changed Or SeveralTemplatesSelected AND DeleteModifiedTemplateEnabled;
	EndDo;
	
	Items.PrintFormsTemplatesUseModifiedTemplate.Enabled = UseModifiedTemplateEnabled;
	Items.PrintFormsTemplatesUseStandardTemplate.Enabled = UseStandardTemplateEnabled;
	Items.PrintFormsTemplatesDeleteModifiedTemplate.Enabled = DeleteModifiedTemplateEnabled;
	
EndProcedure

#EndRegion
