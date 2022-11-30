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
	
	Var PrintFormsCollection;
	
	SetConditionalAppearance();
	
	If Not AccessRight("Update", Metadata.InformationRegisters.UserPrintTemplates) Then
		Items.GoToTemplateManagementButton.Visible = False;
	EndIf;
	
	// Checking input parameters.
	If Not ValueIsFilled(Parameters.DataSource) Then 
		CommonClientServer.Validate(TypeOf(Parameters.CommandParameter) = Type("Array") Or Common.RefTypeValue(Parameters.CommandParameter),
			StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Недопустимое значение параметра ПараметрКоманды при вызове метода УправлениеПечатьюКлиент.ВыполнитьКомандуПечати.
				|Ожидалось: Массив, ЛюбаяСсылка.
				|Передано: %1'; 
				|en = 'Invalid value type. CommandParameter parameter, PrintManagerClient.ExecutePrintCommand method.
				|Expected type: Array or AnyRef.
				|Passed type: %1.'; 
				|pl = 'Niedozwolona wartość parametru ParametrPolecenia przy wywoływaniu metody ZarządzanieDrukowaniemKlient.WykonajPolecenieDrukowania.
				|Oczekiwano: Tablica, DowolnyLink.
				|Przekazano:%1';
				|de = 'Ungültiger Wert für den Parameter ParameterBefehle beim Aufruf der Methode DruckManagerClient.AusführenDruckBefehl.
				|Erwartet: Array, JederLink.
				|Gesendet: %1';
				|ro = 'Valoare inadmisibilă a parametrului CommandParameter la apelarea metodei PrintManagementClient.ExecutePrintCommand.
				|Se aștepta: Array, AnyRef.
				|A fost transmis:%1';
				|tr = 'PrintManagerClient.ExecutePrintCommand yöntemi çağrıldığında CommandParameter geçersiz değeri. 
				|Beklenen: Dizilim, AnyRef. 
				|Verildi: %1'; 
				|es_ES = 'Valor inválido del parámetro CommandParameter al llamar el método PrintManagementClient.ExecutePrintCommand.
				|Esperado: Matriz, AnyRef.
				|Actual: %1'"), TypeOf(Parameters.CommandParameter)));
	EndIf;

	// Support of backward compatibility with version 2.1.3.
	PrintParameters = Parameters.PrintParameters;
	If Parameters.PrintParameters = Undefined Then
		PrintParameters = New Structure;
	EndIf;
	If Not PrintParameters.Property("AdditionalParameters") Then
		Parameters.PrintParameters = New Structure("AdditionalParameters", PrintParameters);
		For Each PrintParameter In PrintParameters Do
			Parameters.PrintParameters.Insert(PrintParameter.Key, PrintParameter.Value);
		EndDo;
	EndIf;
	
	If Parameters.PrintFormsCollection = Undefined Then
		PrintFormsCollection = GeneratePrintForms(Parameters.TemplatesNames, Cancel);
		If Cancel Then
			Return;
		EndIf;
	Else
		PrintFormsCollection = Parameters.PrintFormsCollection;
		PrintObjects = Parameters.PrintObjects;
		OutputParameters = PrintManagement.PrepareOutputParametersStructure();
	EndIf;
	
	CreateAttributesAndFormItemsForPrintForms(PrintFormsCollection);
	SaveDefaultSetSettings();
	ImportCopiesCountSettings();
	HasOutputAllowed = HasOutputAllowed();
	SetUpFormItemsVisibility(HasOutputAllowed);
	SetOutputAvailabilityFlagInPrintFormsPresentations(HasOutputAllowed);
	SetPrinterNameInPrintButtonTooltip();
	SetFormHeader();
	If Not Common.IsMobileClient() AND IsSetPrinting() Then
		Items.Copies.Title = NStr("ru = 'Копий комплекта'; en = 'Set copies'; pl = 'Kopie zestawu';de = 'Legen Sie Kopien an';ro = 'Copii ale setului';tr = 'Kopyaları ayarlayın'; es_ES = 'Establecer copias'");
	EndIf;
	
	AdditionalInformation = New Structure("Picture, Text", New Picture, "");
	RefsArray = Parameters.CommandParameter;
	If Common.RefTypeValue(RefsArray) Then
		RefsArray = CommonClientServer.ValueInArray(RefsArray);
	EndIf;
	If TypeOf(RefsArray) = Type("Array")
		AND RefsArray.Count() > 0
		AND Common.RefTypeValue(RefsArray[0]) Then
			If Common.SubsystemExists("OnlineInteraction") Then 
				ModuleOnlineInteraction = Common.CommonModule("OnlineInteraction");
				ModuleOnlineInteraction.OnDisplayURLInIBObjectForm(AdditionalInformation, RefsArray);
			EndIf;
	EndIf;
	Items.AdditionalInformation.Title = StringFunctionsClientServer.FormattedString(AdditionalInformation.Text);
	Items.InformationPicture.Picture = AdditionalInformation.Picture;
	Items.AdditionalInformationGroup.Visible = Not IsBlankString(Items.AdditionalInformation.Title);
	Items.InformationPicture.Visible = Items.InformationPicture.Picture.Type <> PictureType.Empty;
	
	If Common.IsMobileClient() Then
		Items.CommandBarLeftPart.Visible = False;
		Items.CommandBarRightPart.Visible = False;
		Items.PrintFormsSettings.TitleLocation = FormItemTitleLocation.Auto;
		Items.SendButtonAllActions.DefaultButton = True;
		Items.Help.OnlyInAllActions= True;
		Items.ChangeTemplateButton.Visible = False;
	EndIf;
	
	If PrintManagement.PrintSettings().HideSignaturesAndSealsForEditing Then
		DrawingsStorageAddress = PutToTempStorage(SignaturesAndSealsOfSpreadsheetDocuments(), UUID);
	EndIf;
	RemoveSignatureAndSeal();
	
	PrintManagementOverridable.PrintDocumentsOnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	PrintManagementOverridable.PrintDocumentsOnImportDataFromSettingsAtServer(ThisObject, Settings);
	
EndProcedure

&AtServer
Procedure OnSaveDataInSettingsAtServer(Settings)
	
	PrintManagementOverridable.PrintDocumentsOnSaveDataInSettingsAtServer(ThisObject, Settings);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If FormOwner = Undefined Then
		StorageUUID = New UUID;
	Else
		StorageUUID = FormOwner.UUID;
	EndIf;
	
	If ValueIsFilled(SaveFormatSettings) Then
		Cancel = True; // cancel the form opening
		SavePrintFormToFile();
		Return;
	EndIf;
	
	AttachIdleHandler("AfterOpen", 0.1, True);
	
EndProcedure

&AtClient
Procedure AfterOpen()
	
	If Items.SignedAndSealedFlag.Visible Then
		AddDeleteSignatureSeal();
	EndIf;
	SetCurrentPage();
	CalculateIndicators();
	
	PrintManagementClientOverridable.PrintDocumentsAfterOpen(ThisObject);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectedValue, ChoiceSource)
	
	If Upper(ChoiceSource.FormName) = Upper("CommonForm.SavePrintForm") Then
		
		If SelectedValue <> Undefined AND SelectedValue <> DialogReturnCode.Cancel Then
			FilesInTempStorage = PutSpreadsheetDocumentsInTempStorage(SelectedValue);
			If SelectedValue.SavingOption = "SaveToFolder" Then
				SavePrintFormsToFolder(FilesInTempStorage, SelectedValue.FolderForSaving);
			Else
				WrittenObjects = AttachPrintFormsToObject(FilesInTempStorage, SelectedValue.ObjectForAttaching);
				If WrittenObjects.Count() > 0 Then
					NotifyChanged(TypeOf(WrittenObjects[0]));
				EndIf;
				For Each WrittenObject In WrittenObjects Do
					Notify("Write_File", New Structure, WrittenObject);
				EndDo;
				ShowUserNotification(, , NStr("ru = 'Сохранение завершено'; en = 'Saved'; pl = 'Zapisz ukończone';de = 'Speichern abgeschlossen';ro = 'Salvare';tr = 'Kayıt tamamlandı'; es_ES = 'Se ha guardado'"), PictureLib.Information32);
			EndIf;
		EndIf;
		
	ElsIf Upper(ChoiceSource.FormName) = Upper("CommonForm.SelectAttachmentFormat")
		Or Upper(ChoiceSource.FormName) = Upper("CommonForm.ComposeNewMessage") Then
		
		If SelectedValue <> Undefined AND SelectedValue <> DialogReturnCode.Cancel Then
			SendOptions = EmailSendOptions(SelectedValue);
			
			ModuleEmailOperationsClient = CommonClient.CommonModule("EmailOperationsClient");
			ModuleEmailOperationsClient.CreateNewEmailMessage(SendOptions);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	PrintFormSetting = CurrentPrintFormSetup();
	
	If EventName = "Write_UserPrintTemplates" 
		AND Source.FormOwner = ThisObject
		AND Parameter.TemplateMetadataObjectName = PrintFormSetting.PathToTemplate Then
			AttachIdleHandler("RefreshCurrentPrintForm",0.1,True);
	ElsIf (EventName = "CancelTemplateChange"
		Or EventName = "CancelEditSpreadsheetDocument"
		AND Parameter.TemplateMetadataObjectName = PrintFormSetting.PathToTemplate)
		AND Source.FormOwner = ThisObject Then
			DisplayCurrentPrintFormState();
	ElsIf EventName = "Write_SpreadsheetDocument" 
		AND Parameter.TemplateMetadataObjectName = PrintFormSetting.PathToTemplate 
		AND Source.FormOwner = ThisObject Then
			Template = Parameter.SpreadsheetDocument;
			TemplateAddressInTempStorage = PutToTempStorage(Template);
			WriteTemplate(Parameter.TemplateMetadataObjectName, TemplateAddressInTempStorage);
			AttachIdleHandler("RefreshCurrentPrintForm",0.1,True);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CopiesOnChange(Item)
	If PrintFormsSettings.Count() = 1 Then
		PrintFormsSettings[0].Count = Copies;
		StartSaveSettings();
	EndIf;
EndProcedure

&AtClient
Procedure AdditionalInformationURLProcessing(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	RefsArray = Parameters.CommandParameter;
	If TypeOf(RefsArray) <> Type("Array") Then
		RefsArray = CommonClientServer.ValueInArray(RefsArray);
	EndIf;
	If CommonClient.SubsystemExists("OnlineInteraction") Then 
		ModuleOnlineInteractionClient = CommonClient.CommonModule("OnlineInteractionClient");
		ModuleOnlineInteractionClient.URLProcessingInPrintFormSSL(FormattedStringURL, RefsArray);
	EndIf;
EndProcedure

&AtClient
Procedure CurrentPrintFormOnActivateArea(Item)
	AttachIdleHandler("CalculateIndicatorsDynamically", 0.2, True);
EndProcedure

&AtClient
Procedure FlagSignatureAndSealOnChange(Item)
	AddDeleteSignatureSeal();
	SetCurrentPage();
EndProcedure

&AtClient
Procedure Attachable_URLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	PrintManagementClientOverridable.PrintDocumentsURLProcessing(ThisObject, Item, FormattedStringURL, StandardProcessing);
	
EndProcedure

#EndRegion

#Region PrintFormsSettingsFormTableItemsEventHandlers

&AtClient
Procedure PrintFormsSettingsOnChange(Item)
	CanPrint = False;
	CanSave = False;
	
	For Each PrintFormSetting In PrintFormsSettings Do
		PrintForm = ThisObject[PrintFormSetting.AttributeName];
		SpreadsheetDocumentField = Items[PrintFormSetting.AttributeName];
		
		CanPrint = CanPrint Or PrintFormSetting.Print AND PrintForm.TableHeight > 0
			AND SpreadsheetDocumentField.Output = UseOutput.Enable;
		
		CanSave = CanSave Or PrintFormSetting.Print AND PrintForm.TableHeight > 0
			AND SpreadsheetDocumentField.Output = UseOutput.Enable AND Not SpreadsheetDocumentField.Protection;
	EndDo;
	
	Items.PrintButtonCommandBar.Enabled = CanPrint;
	Items.PrintButtonAllActions.Enabled = CanPrint;
	
	Items.SaveButton.Enabled = CanSave;
	Items.SaveButtonAllActions.Enabled = CanSave;
	
	Items.SendButton.Enabled = CanSave;
	Items.SendButtonAllActions.Enabled = CanSave;
	
	StartSaveSettings();
EndProcedure

&AtClient
Procedure PrintFormSettingsOnActivateRow(Item)
	DetachIdleHandler("SetCurrentPage");
	AttachIdleHandler("SetCurrentPage", 0.1, True);
EndProcedure

&AtClient
Procedure PrintFormSettingsCountTracking(Item, Direction, StandardProcessing)
	PrintFormSetting = CurrentPrintFormSetup();
	PrintFormSetting.Print = PrintFormSetting.Count + Direction > 0;
EndProcedure

&AtClient
Procedure PrintFormSettingsPrintOnChange(Item)
	PrintFormSetting = CurrentPrintFormSetup();
	If PrintFormSetting.Print AND PrintFormSetting.Count = 0 Then
		PrintFormSetting.Count = 1;
	EndIf;
EndProcedure

&AtClient
Procedure PrintFormSettingsBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
	Cancel = True;
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Save(Command)
	FormParameters = New Structure;
	FormParameters.Insert("PrintObjects", PrintObjects);
	OpenForm("CommonForm.SavePrintForm", FormParameters, ThisObject);
EndProcedure

&AtClient
Procedure Send(Command)
	SendPrintFormsByEmail();
EndProcedure

&AtClient
Procedure GoToDocument(Command)
	
	ChoiceList = New ValueList;
	For Each PrintObject In PrintObjects Do
		ChoiceList.Add(PrintObject.Presentation, String(PrintObject.Value));
	EndDo;
	
	NotifyDescription = New NotifyDescription("GoToDocumentCompletion", ThisObject);
	ChoiceList.ShowChooseItem(NotifyDescription, NStr("ru = 'Перейти к печатной форме'; en = 'Go to print form'; pl = 'Przejść do formularza wydruku';de = 'Gehe zum Druckformular';ro = 'Accesați forma de listare';tr = 'Yazdırma formuna git'; es_ES = 'Ir a la versión impresa'"));
	
EndProcedure

&AtClient
Procedure GoToTemplatesManagement(Command)
	OpenForm("InformationRegister.UserPrintTemplates.Form.PrintFormTemplates");
EndProcedure

&AtClient
Procedure PrintSpreadsheetDocuments(Command)
	
	SpreadsheetDocuments = SpreadsheetDocumentsToPrint();
	PrintManagementClient.PrintSpreadsheetDocuments(SpreadsheetDocuments, PrintObjects,
		SpreadsheetDocuments.Count() > 1, ?(PrintFormsSettings.Count() > 1, Copies, 1));
	
EndProcedure

&AtClient
Procedure ShowHideCopiesCountSettings(Command)
	SetCopiesCountSettingsVisibility();
EndProcedure

&AtClient
Procedure SelectAll(Command)
	SelectOrClearAll(True);
EndProcedure

&AtClient
Procedure ClearAll(Command)
	SelectOrClearAll(False);
EndProcedure

&AtClient
Procedure ClearSettings(Command)
	RestorePrintFormsSettings();
	StartSaveSettings();
EndProcedure

&AtClient
Procedure ChangeTemplate(Command)
	OpenTemplateForEditing();
EndProcedure

&AtClient
Procedure ToggleEditing(Command)
	SwitchCurrentPrintFormEditing();
EndProcedure

&AtClient
Procedure CalculateAmount(Command)
	CalculateIndicators(Command.Name);
EndProcedure

&AtClient
Procedure CalculateCount(Command)
	CalculateIndicators(Command.Name);
EndProcedure

&AtClient
Procedure CalculateAverage(Command)
	CalculateIndicators(Command.Name);
EndProcedure

&AtClient
Procedure CalculateMin(Command)
	CalculateIndicators(Command.Name);
EndProcedure

&AtClient
Procedure CalculateMax(Command)
	CalculateIndicators(Command.Name);
EndProcedure

&AtClient
Procedure CalculateAllIndicators(Command)
	SetIndicatorsVisibility(Not Items.CalculateAllIndicators.Check);
EndProcedure

&AtClient
Procedure CollapseIndicators(Command)
	SetIndicatorsVisibility(False);
EndProcedure

&AtClient
Procedure Attachable_ExecuteCommand(Command)
	
	ContinueExecutionAtServer = False;
	AdditionalParameters = Undefined;
	
	PrintManagementClientOverridable.PrintDocumentsExecuteCommand(
		ThisObject, Command, ContinueExecutionAtServer, AdditionalParameters);
	
	If ContinueExecutionAtServer Then
		OnExecuteCommandAtServer(AdditionalParameters);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PrintFormsSettings.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PrintFormsSettings.Print");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);

EndProcedure

&AtServer
Function GeneratePrintForms(TemplatesNames, Cancel)
	
	Result = Undefined;
	// Generating spreadsheet documents.
	If ValueIsFilled(Parameters.DataSource) Then
		PrintManagement.PrintByExternalSource(
			Parameters.DataSource,
			Parameters.SourceParameters,
			Result,
			PrintObjects,
			OutputParameters);
	Else
		PrintObjectsTypes = New Array;
		Parameters.PrintParameters.Property("PrintObjectsTypes", PrintObjectsTypes);
		PrintForms = PrintManagement.GeneratePrintForms(Parameters.PrintManagerName, TemplatesNames,
			Parameters.CommandParameter, Parameters.PrintParameters.AdditionalParameters, PrintObjectsTypes);
		PrintObjects = PrintForms.PrintObjects;
		OutputParameters = PrintForms.OutputParameters;
		Result = PrintForms.PrintFormsCollection;
	EndIf;
	
	// Setting the flag of saving print forms to a file (do not open the form, save it directly to a file).
	If TypeOf(Parameters.PrintParameters) = Type("Structure") AND Parameters.PrintParameters.Property("SaveFormat")
		AND ValueIsFilled(Parameters.PrintParameters.SaveFormat) Then
		FoundFormat = PrintManagement.SpreadsheetDocumentSaveFormatsSettings().Find(SpreadsheetDocumentFileType[Parameters.PrintParameters.SaveFormat], "SpreadsheetDocumentFileType");
		If FoundFormat <> Undefined Then
			SaveFormatSettings = New Structure("SpreadsheetDocumentFileType,Presentation,Extension,Filter");
			FillPropertyValues(SaveFormatSettings, FoundFormat);
			SaveFormatSettings.Filter = SaveFormatSettings.Presentation + "|*." + SaveFormatSettings.Extension;
			SaveFormatSettings.SpreadsheetDocumentFileType = Parameters.PrintParameters.SaveFormat;
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Procedure ImportCopiesCountSettings()
	
	SavedPrintFormsSettings = New Array;
	
	UseSavedSettings = True;
	If TypeOf(Parameters.PrintParameters) = Type("Structure") AND Parameters.PrintParameters.Property("OverrideCopiesUserSetting") Then
		UseSavedSettings = Not Parameters.PrintParameters.OverrideCopiesUserSetting;
	EndIf;
	
	If UseSavedSettings Then
		If ValueIsFilled(Parameters.DataSource) Then
			SettingsKey = String(Parameters.DataSource.UUID()) + "-" + Parameters.SourceParameters.CommandID;
		Else
			TemplatesNames = Parameters.TemplatesNames;
			If TypeOf(TemplatesNames) = Type("Array") Then
				TemplatesNames = StrConcat(TemplatesNames, ",");
			EndIf;
			
			SettingsKey = Parameters.PrintManagerName + "-" + TemplatesNames;
		EndIf;
		SavedPrintFormsSettings = Common.CommonSettingsStorageLoad("PrintFormsSettings", SettingsKey, New Array);
	EndIf;

	
	RestorePrintFormsSettings(SavedPrintFormsSettings);
	
	If IsSetPrinting() Then
		Copies = 1;
	Else
		If PrintFormsSettings.Count() > 0 Then
			Copies = PrintFormsSettings[0].Count;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure CreateAttributesAndFormItemsForPrintForms(PrintFormsCollection)
	
	// Creating attributes for spreadsheet documents.
	NewFormAttributes = New Array;
	For PrintFormNumber = 1 To PrintFormsCollection.Count() Do
		AttributeName = "PrintForm" + Format(PrintFormNumber,"NG=0");
		FormAttribute = New FormAttribute(AttributeName, New TypeDescription("SpreadsheetDocument"),,PrintFormsCollection[PrintFormNumber - 1].TemplateSynonym);
		NewFormAttributes.Add(FormAttribute);
	EndDo;
	ChangeAttributes(NewFormAttributes);
	
	// Creating pages with spreadsheet documents on a form.
	PrintFormNumber = 0;
	PrintOfficeDocuments = False;
	AddedPrintFormsSettings = New Map;
	For Each FormAttribute In NewFormAttributes Do
		PrintFormDetails = PrintFormsCollection[PrintFormNumber];
		
		// Print form settings table (beginning).
		NewPrintFormSetting = PrintFormsSettings.Add();
		NewPrintFormSetting.Presentation = PrintFormDetails.TemplateSynonym;
		NewPrintFormSetting.Print = PrintFormDetails.Copies > 0;
		NewPrintFormSetting.Count = PrintFormDetails.Copies;
		NewPrintFormSetting.TemplateName = PrintFormDetails.TemplateName;
		NewPrintFormSetting.DefaultPosition = PrintFormNumber;
		NewPrintFormSetting.Name = PrintFormDetails.TemplateSynonym;
		NewPrintFormSetting.PathToTemplate = PrintFormDetails.FullTemplatePath;
		NewPrintFormSetting.PrintFormFileName = Common.ValueToXMLString(PrintFormDetails.PrintFormFileName);
		NewPrintFormSetting.OfficeDocuments = ?(IsBlankString(PrintFormDetails.OfficeDocuments), "", Common.ValueToXMLString(PrintFormDetails.OfficeDocuments));
		NewPrintFormSetting.SignatureAndSeal = HasSignatureAndSeal(PrintFormDetails.SpreadsheetDocument);
		
		PrintOfficeDocuments = PrintOfficeDocuments OR NOT IsBlankString(NewPrintFormSetting.OfficeDocuments);
		
		PreviouslyAddedPrintFormSetting = AddedPrintFormsSettings[PrintFormDetails.TemplateName];
		If PreviouslyAddedPrintFormSetting = Undefined Then
			// Copying a spreadsheet document to a form attribute.
			AttributeName = FormAttribute.Name;
			ThisObject[AttributeName] = PrintFormDetails.SpreadsheetDocument;
			
			// Creating pages for spreadsheet documents.
			PageName = "Page" + AttributeName;
			Page = Items.Add(PageName, Type("FormGroup"), Items.Pages);
			Page.Type = FormGroupType.Page;
			Page.Picture = PictureLib.SpreadsheetInsertPageBreak;
			Page.Title = PrintFormDetails.TemplateSynonym;
			Page.ToolTip = PrintFormDetails.TemplateSynonym;
			Page.Visible = ThisObject[AttributeName].TableHeight > 0;
			
			// Creating items for displaying spreadsheet documents.
			NewItem = Items.Add(AttributeName, Type("FormField"), Page);
			NewItem.Type = FormFieldType.SpreadsheetDocumentField;
			NewItem.TitleLocation = FormItemTitleLocation.None;
			NewItem.DataPath = AttributeName;
			NewItem.Output = EvalOutputUsage(PrintFormDetails.SpreadsheetDocument);
			NewItem.Edit = NewItem.Output = UseOutput.Enable AND Not PrintFormDetails.SpreadsheetDocument.ReadOnly;
			NewItem.Protection = PrintFormDetails.SpreadsheetDocument.Protection Or Not Users.RolesAvailable("PrintFormsEdit");
			
			// Print form settings table (continued).
			NewPrintFormSetting.PageName = PageName;
			NewPrintFormSetting.AttributeName = AttributeName;
			
			AddedPrintFormsSettings.Insert(NewPrintFormSetting.TemplateName, NewPrintFormSetting);
		Else
			NewPrintFormSetting.PageName = PreviouslyAddedPrintFormSetting.PageName;
			NewPrintFormSetting.AttributeName = PreviouslyAddedPrintFormSetting.AttributeName;
		EndIf;
		
		PrintFormNumber = PrintFormNumber + 1;
	EndDo;
	
	If PrintOfficeDocuments AND NOT ValueIsFilled(SaveFormatSettings) Then
		SaveFormatSettings = New Structure("SpreadsheetDocumentFileType,Presentation,Extension,Filter")
	EndIf;
	
EndProcedure

&AtServer
Procedure SaveDefaultSetSettings()
	For Each PrintFormSetting In PrintFormsSettings Do
		FillPropertyValues(DefaultSetSettings.Add(), PrintFormSetting);
	EndDo;
EndProcedure

&AtServer
Procedure SetUpFormItemsVisibility(Val HasOutputAllowed)
	
	HasEditingAllowed = HasEditingAllowed();
	
	CanSendEmails = False;
	If Common.SubsystemExists("StandardSubsystems.EmailOperations") Then
		ModuleEmailOperations = Common.CommonModule("EmailOperations");
		CanSendEmails = ModuleEmailOperations.CanSendEmails();
	EndIf;
	CanSendByEmail = HasOutputAllowed AND CanSendEmails;
	
	HasDataToPrint = HasDataToPrint();
	
	Items.GoToDocumentButton.Visible = PrintObjects.Count() > 1;
	
	Items.SaveButton.Visible = HasDataToPrint AND HasOutputAllowed AND HasEditingAllowed;
	Items.SaveButtonAllActions.Visible = Items.SaveButton.Visible;
	
	Items.SendButton.Visible = CanSendByEmail AND HasDataToPrint AND HasEditingAllowed;
	Items.SendButtonAllActions.Visible = Items.SendButton.Visible;
	
	Items.PrintButtonCommandBar.Visible = HasOutputAllowed AND HasDataToPrint;
	Items.PrintButtonAllActions.Visible = Items.PrintButtonCommandBar.Visible;
	
	Items.Copies.Visible = HasOutputAllowed AND HasDataToPrint;
	Items.EditButton.Visible = HasOutputAllowed AND HasDataToPrint AND HasEditingAllowed;
	
	If Items.Find("PreviewButton") <> Undefined Then
		Items.PreviewButton.Visible = HasOutputAllowed;
	EndIf;
	If Items.Find("PreviewButtonAllActions") <> Undefined Then
		Items.PreviewButtonAllActions.Visible = HasOutputAllowed;
	EndIf;
	If Items.Find("AllActionsPageParametersButton") <> Undefined Then
		Items.AllActionsPageParametersButton.Visible = HasOutputAllowed;
	EndIf;
	
	If Not HasDataToPrint Then
		Items.CurrentPrintForm.SetAction("OnActivateArea", "");
	EndIf;
	
	Items.ShowHideSetSettingsButton.Visible = IsSetPrinting();
	Items.PrintFormsSettings.Visible = IsSetPrinting();
	
	SetSettingsAvailable = True;
	If TypeOf(Parameters.PrintParameters) = Type("Structure") AND Parameters.PrintParameters.Property("FixedSet") Then
		SetSettingsAvailable = Not Parameters.PrintParameters.FixedSet;
	EndIf;
	
	Items.SetSettingsGroupContextMenu.Visible = SetSettingsAvailable;
	Items.SetSettingsGroupCommandBar.Visible = IsSetPrinting() AND SetSettingsAvailable;
	Items.PrintFormsSettingsPrint.Visible = SetSettingsAvailable;
	Items.PrintFormsSettingsCount.Visible = SetSettingsAvailable;
	Items.PrintFormsSettings.Header = SetSettingsAvailable;
	Items.PrintFormsSettings.HorizontalLines = SetSettingsAvailable;
	
	If Not SetSettingsAvailable Then
		AddCopiesCountToPrintFormsPresentations();
	EndIf;
	
	CanEditTemplates = AccessRight("Update", Metadata.InformationRegisters.UserPrintTemplates) AND HasTemplatesToEdit();
	Items.ChangeTemplateButton.Visible = CanEditTemplates AND HasDataToPrint;
	
	Items.SignedAndSealedFlag.Visible = HasPrintFormsWithSignatureAndSeal() AND HasSignaturesAndSealsForPrintObjects();
	
EndProcedure

&AtServer
Procedure AddCopiesCountToPrintFormsPresentations()
	For Each PrintFormSetting In PrintFormsSettings Do
		If PrintFormSetting.Count <> 1 Then
			PrintFormSetting.Presentation = PrintFormSetting.Presentation 
				+ " (" + PrintFormSetting.Count + " " + NStr("ru = 'экз.'; en = 'copies'; pl = 'kopii';de = 'Kopien';ro = 'copii';tr = 'kopyalar'; es_ES = 'copias'") + ")";
		EndIf;
	EndDo;
EndProcedure

&AtServer
Procedure SetOutputAvailabilityFlagInPrintFormsPresentations(HasOutputAllowed)
	If HasOutputAllowed Then
		For Each PrintFormSetting In PrintFormsSettings Do
			SpreadsheetDocumentField = Items[PrintFormSetting.AttributeName];
			If SpreadsheetDocumentField.Output = UseOutput.Disable Then
				PrintFormSetting.Presentation = PrintFormSetting.Presentation + " (" + NStr("ru = 'вывод не доступен'; en = 'output is not available'; pl = 'dane wyjściowe nie są dostępne';de = 'die Ausgabe ist nicht verfügbar';ro = 'Ieșirea nu este disponibilă';tr = 'çıkış mevcut değil'; es_ES = 'no se puede imprimir'") + ")";
			ElsIf SpreadsheetDocumentField.Protection Then
				PrintFormSetting.Presentation = PrintFormSetting.Presentation + " (" + NStr("ru = 'только печать'; en = 'print only'; pl = 'tylko drukowanie';de = 'nur drucken';ro = 'imprimare numai';tr = 'sadece yazdırma'; es_ES = 'solo imprimir'") + ")";
			EndIf;
		EndDo;
	EndIf;	
EndProcedure

&AtClient
Procedure SetCopiesCountSettingsVisibility(Val Visibility = Undefined)
	If Visibility = Undefined Then
		Visibility = Not Items.PrintFormsSettings.Visible;
	EndIf;
	
	Items.PrintFormsSettings.Visible = Visibility;
	Items.SetSettingsGroupCommandBar.Visible = Visibility AND SetSettingsAvailable;
EndProcedure

&AtServer
Procedure SetPrinterNameInPrintButtonTooltip()
	If PrintFormsSettings.Count() > 0 Then
		PrinterName = ThisObject[PrintFormsSettings[0].AttributeName].PrinterName;
		If Not IsBlankString(PrinterName) Then
			ThisObject.Commands["Print"].ToolTip = NStr("ru = 'Напечатать на принтере'; en = 'Printer:'; pl = 'Drukowanie przy użyciu drukarki';de = 'Drucken mit Drucker';ro = 'Utilizați imprimanta:';tr = 'Yazıcı ile yazdırma'; es_ES = 'Imprimir utilizando la impresora'") + " (" + PrinterName + ")";
		EndIf;
	EndIf;
EndProcedure

&AtServer
Procedure SetFormHeader()
	Var FormHeader;
	
	If TypeOf(Parameters.PrintParameters) = Type("Structure") Then
		Parameters.PrintParameters.Property("FormCaption", FormHeader);
	EndIf;
	
	If ValueIsFilled(FormHeader) Then
		Title = FormHeader;
	Else
		If IsSetPrinting() Then
			Title = NStr("ru = 'Печать комплекта'; en = 'Print set'; pl = 'Drukowanie zestawu';de = 'Drucksatz';ro = 'Setul de imprimare';tr = 'Küme yazdırma'; es_ES = 'Conjunto de impresión'");
		ElsIf TypeOf(Parameters.CommandParameter) <> Type("Array") Or Parameters.CommandParameter.Count() > 1 Then
			Title = NStr("ru = 'Печать документов'; en = 'Print documents'; pl = 'Wydrukuj dokumenty';de = 'Dokumente drucken';ro = 'Imprimați documente';tr = 'Belge yazdır'; es_ES = 'Imprimir los documentos'");
		Else
			Title = NStr("ru = 'Печать документа'; en = 'Print document'; pl = 'Drukowanie dokumentu';de = 'Dokument drucken';ro = 'Imprimați documentul';tr = 'Belgeyi yazdır'; es_ES = 'Imprimir el documento'");
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure SetCurrentPage()
	
	PrintFormSetting = CurrentPrintFormSetup();
	
	CurrentPage = Items.PrintFormUnavailablePage;
	PrintFormAvailable = PrintFormSetting <> Undefined AND ThisObject[PrintFormSetting.AttributeName].TableHeight > 0;
	If PrintFormAvailable Then
		SetCurrentSpreadsheetDocument(PrintFormSetting.AttributeName);
		FillPropertyValues(Items.CurrentPrintForm, Items[PrintFormSetting.AttributeName], 
			"Output, Protection, Edit");
			
		CurrentPage = Items.CurrentPrintFormPage;
	EndIf;
	Items.Pages.CurrentPage = CurrentPage;
	
	SwitchEditingButtonMark();
	SetTemplateChangeAvailability();
	SetOutputCommandsAvailability();
	
EndProcedure

&AtServer
Procedure SetCurrentSpreadsheetDocument(AttributeName)
	CurrentPrintForm = ThisObject[AttributeName];
EndProcedure

&AtClient
Procedure SelectOrClearAll(Checkmark)
	For Each PrintFormSetting In PrintFormsSettings Do
		PrintFormSetting.Print = Checkmark;
		If Checkmark AND PrintFormSetting.Count = 0 Then
			PrintFormSetting.Count = 1;
		EndIf;
	EndDo;
	StartSaveSettings();
EndProcedure

&AtServer
Function EvalOutputUsage(SpreadsheetDocument)
	If SpreadsheetDocument.Output = UseOutput.Auto Then
		Return ?(AccessRight("Output", Metadata), UseOutput.Enable, UseOutput.Disable);
	Else
		Return SpreadsheetDocument.Output;
	EndIf;
EndFunction

&AtServerNoContext
Procedure SavePrintFormsSettings(SettingsKey, PrintFormsSettingsToSave)
	Common.CommonSettingsStorageSave("PrintFormsSettings", SettingsKey, PrintFormsSettingsToSave);
EndProcedure

&AtServer
Procedure RestorePrintFormsSettings(SavedPrintFormsSettings = Undefined)
	If SavedPrintFormsSettings = Undefined Then
		SavedPrintFormsSettings = DefaultSetSettings;
	EndIf;
	
	If SavedPrintFormsSettings = Undefined Then
		Return;
	EndIf;
	
	For Each SavedSetting In SavedPrintFormsSettings Do
		FoundSettings = PrintFormsSettings.FindRows(New Structure("DefaultPosition", SavedSetting.DefaultPosition));
		For Each PrintFormSetting In FoundSettings Do
			RowIndex = PrintFormsSettings.IndexOf(PrintFormSetting);
			PrintFormsSettings.Move(RowIndex, PrintFormsSettings.Count()-1 - RowIndex); // Moving to the end
			PrintFormSetting.Count = SavedSetting.Count;
			PrintFormSetting.Print = PrintFormSetting.Count > 0;
		EndDo;
	EndDo;
EndProcedure

&AtServer
Function PutSpreadsheetDocumentsInTempStorage(PassedSettings)
	Var ZipFileWriter, ArchiveName;
	
	SettingsForSaving = SettingsForSaving();
	FillPropertyValues(SettingsForSaving, PassedSettings);
	
	Result = New Array;
	
	// Preparing the archive
	If SettingsForSaving.PackToArchive Then
		ArchiveName = GetTempFileName("zip");
		ZipFileWriter = New ZipFileWriter(ArchiveName);
	EndIf;
	
	// preparing a temporary folder
	TempFolderName = GetTempFileName();
	CreateDirectory(TempFolderName);
	
	SelectedSaveFormats = SettingsForSaving.SaveFormats;
	TransliterateFilesNames = SettingsForSaving.TransliterateFilesNames;
	FormatsTable = PrintManagement.SpreadsheetDocumentSaveFormatsSettings();
	
	// Saving print forms
	ProcessedPrintForms = New Array;
	For Each PrintFormSetting In PrintFormsSettings Do
		
		If NOT IsBlankString(PrintFormSetting.OfficeDocuments) Then
			
			OfficeDocumentsFiles = Common.ValueFromXMLString(PrintFormSetting.OfficeDocuments);
			
			For Each OfficeDocumentFile In OfficeDocumentsFiles Do
				FileName = PrintManagement.OfficeDocumentFileName(OfficeDocumentFile.Value);
				If ZipFileWriter <> Undefined Then 
					FullFileName = UniqueFileName(CommonClientServer.AddLastPathSeparator(TempFolderName) 
						+ FileName);
					BinaryData = GetFromTempStorage(OfficeDocumentFile.Key);
					BinaryData.Write(FullFileName);
					ZipFileWriter.Add(FullFileName);
				Else
					FileDetails = New Structure;
					FileDetails.Insert("Presentation", FileName);
					FileDetails.Insert("AddressInTempStorage", OfficeDocumentFile.Key);
					FileDetails.Insert("IsOfficeDocument", True);
					Result.Add(FileDetails);
				EndIf;
				
			EndDo;
			
			Continue;
			
		EndIf;
		
		If Not PrintFormSetting.Print Then
			Continue;
		EndIf;
		
		PrintForm = ThisObject[PrintFormSetting.AttributeName];
		If ProcessedPrintForms.Find(PrintForm) = Undefined Then
			ProcessedPrintForms.Add(PrintForm);
		Else
			Continue;
		EndIf;
		
		If EvalOutputUsage(PrintForm) = UseOutput.Disable Then
			Continue;
		EndIf;
		
		If PrintForm.Protection Then
			Continue;
		EndIf;
		
		If PrintForm.TableHeight = 0 Then
			Continue;
		EndIf;
		
		PrintFormsByObjects = PrintManagement.PrintFormsByObjects(PrintForm, PrintObjects);
		For Each MapBetweenObjectAndPrintForm In PrintFormsByObjects Do
			PrintObject = MapBetweenObjectAndPrintForm.Key;
			PrintForm = MapBetweenObjectAndPrintForm.Value;
			
			For Each SelectedFormat In SelectedSaveFormats Do
				FileType = SpreadsheetDocumentFileType[SelectedFormat];
				FormatSettings = FormatsTable.FindRows(New Structure("SpreadsheetDocumentFileType", FileType))[0];
				SpecifiedPrintFormsNames = Common.ValueFromXMLString(PrintFormSetting.PrintFormFileName);
				
				FileName = PrintManagement.ObjectPrintFormFileName(PrintObject, SpecifiedPrintFormsNames, PrintFormSetting.Name);
				FileName = CommonClientServer.ReplaceProhibitedCharsInFileName(FileName);
				
				If TransliterateFilesNames Then
					FileName = StringFunctionsClientServer.LatinString(FileName);
				EndIf;
				
				FileName = FileName + "." + FormatSettings.Extension;
				
				FullFileName = UniqueFileName(CommonClientServer.AddLastPathSeparator(TempFolderName) + FileName);
				PrintForm.Write(FullFileName, FileType);
				
				If FileType = SpreadsheetDocumentFileType.HTML Then
					PrintManagement.InsertPicturesToHTML(FullFileName);
				EndIf;
				
				If ZipFileWriter <> Undefined Then 
					ZipFileWriter.Add(FullFileName);
				Else
					BinaryData = New BinaryData(FullFileName);
					PathInTempStorage = PutToTempStorage(BinaryData, StorageUUID);
					FileDetails = New Structure;
					FileDetails.Insert("Presentation", FileName);
					FileDetails.Insert("AddressInTempStorage", PathInTempStorage);
					If FileType = SpreadsheetDocumentFileType.ANSITXT Then
						FileDetails.Insert("Encoding", "windows-1251");
					EndIf;
					Result.Add(FileDetails);
				EndIf;
			EndDo;
		EndDo;
	EndDo;
	
	// If the archive is prepared, writing it and putting in the temporary storage.
	If ZipFileWriter <> Undefined Then 
		ZipFileWriter.Write();
		BinaryData = New BinaryData(ArchiveName);
		PathInTempStorage = PutToTempStorage(BinaryData, StorageUUID);
		FileDetails = New Structure;
		FileDetails.Insert("Presentation", GetFileNameForArchive(TransliterateFilesNames));
		FileDetails.Insert("AddressInTempStorage", PathInTempStorage);
		Result.Add(FileDetails);
	EndIf;
	
	DeleteFiles(TempFolderName);
	If ValueIsFilled(ArchiveName) Then
		DeleteFiles(ArchiveName);
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Function GetFileNameForArchive(TransliterateFilesNames)
	
	Result = "";
	
	For Each PrintFormSetting In PrintFormsSettings Do
		
		If Not PrintFormSetting.Print Then
			Continue;
		EndIf;
		
		PrintForm = ThisObject[PrintFormSetting.AttributeName];
		
		If EvalOutputUsage(PrintForm) = UseOutput.Disable Then
			Continue;
		EndIf;
		
		If IsBlankString(Result) Then
			Result = PrintFormSetting.Name;
		Else
			Result = NStr("ru = 'Документы'; en = 'Documents'; pl = 'Dokumenty';de = 'Dokumente';ro = 'Documente';tr = 'Belgeler'; es_ES = 'Documentos'");
			Break;
		EndIf;
	EndDo;
	
	If TransliterateFilesNames Then
		Result = StringFunctionsClientServer.LatinString(Result);
	EndIf;
	
	Return Result + ".zip";
	
EndFunction

&AtClient
Procedure SavePrintFormToFile()
	
	SettingsForSaving = New Structure("SaveFormats", CommonClientServer.ValueInArray(
		SaveFormatSettings.SpreadsheetDocumentFileType));
	
	FilesInTempStorage = PutSpreadsheetDocumentsInTempStorage(SettingsForSaving);
	
	For Each FileToWrite In FilesInTempStorage Do
		FileSystemClient.OpenFile(FileToWrite.AddressInTempStorage, , FileToWrite.Presentation);
	EndDo;
	
EndProcedure

&AtClient
Procedure SavePrintFormsToFolder(FilesListInTempStorage, Val Folder = "")
	
	#If WebClient Then
		For Each FileToWrite In FilesListInTempStorage Do
			GetFile(FileToWrite.AddressInTempStorage, FileToWrite.Presentation);
		EndDo;
		Return;
	#EndIf
	
	Folder = CommonClientServer.AddLastPathSeparator(Folder);
	For Each FileToWrite In FilesListInTempStorage Do
		BinaryData = GetFromTempStorage(FileToWrite.AddressInTempStorage);
		BinaryData.Write(UniqueFileName(Folder + FileToWrite.Presentation));
	EndDo;
	
	ShowUserNotification(NStr("ru = 'Сохранение успешно завершено'; en = 'Saved successfully'; pl = 'Zapisz zakończono pomyślnie';de = 'Speichern erfolgreich abgeschlossen';ro = 'Salvarea este finalizată cu succes';tr = 'Kayıt başarı ile tamamlandı'; es_ES = 'Se ha guardado con éxito'"), "file:///" + Folder, NStr("ru = 'в папку:'; en = 'to folder:'; pl = 'do folderu:';de = 'zum Ordner:';ro = 'la dosar:';tr = 'klasöre:'; es_ES = 'a la carpeta:'") + " " + Folder, PictureLib.Information32);

EndProcedure

&AtClientAtServerNoContext
Function UniqueFileName(FileName)
	
	File = New File(FileName);
	NameWithoutExtension = File.BaseName;
	Extension = File.Extension;
	Folder = File.Path;
	
	Counter = 1;
	While File.Exist() Do
		Counter = Counter + 1;
		File = New File(Folder + NameWithoutExtension + " (" + Counter + ")" + Extension);
	EndDo;
	
	Return File.FullName;

EndFunction

&AtServer
Function AttachPrintFormsToObject(FilesInTempStorage, ObjectToAttach)
	Result = New Array;
	If Common.SubsystemExists("StandardSubsystems.FilesOperations") Then
		ModuleFilesOperations = Common.CommonModule("FilesOperations");
		For Each File In FilesInTempStorage Do
			FileParameters = New Structure;
			FileParameters.Insert("FilesOwner", ObjectToAttach);
			FileParameters.Insert("Author", Undefined);
			FileParameters.Insert("BaseName", File.Presentation);
			FileParameters.Insert("ExtensionWithoutPoint", Undefined);
			FileParameters.Insert("Modified", Undefined);
			FileParameters.Insert("ModificationTimeUniversal", Undefined);
			Result.Add(ModuleFilesOperations.AppendFile(
				FileParameters, File.AddressInTempStorage, , NStr("ru = 'Печатная форма'; en = 'Print form'; pl = 'Formularz wydruku';de = 'Formular drucken';ro = 'Formă de listare';tr = 'Yazdırma formu'; es_ES = 'Versión impresa'")));
		EndDo;
	EndIf;
	Return Result;
EndFunction

&AtServer
Function IsSetPrinting()
	Return PrintFormsSettings.Count() > 1;
EndFunction

&AtServer
Function HasOutputAllowed()
	
	For Each PrintFormSetting In PrintFormsSettings Do
		If Items[PrintFormSetting.AttributeName].Output = UseOutput.Enable Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

&AtServer
Function HasEditingAllowed()
	
	For Each PrintFormSetting In PrintFormsSettings Do
		If Items[PrintFormSetting.AttributeName].Protection = False Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

&AtClient
Function MoreThanOneRecipient(Recipient)
	If TypeOf(Recipient) = Type("Array") Or TypeOf(Recipient) = Type("ValueList") Then
		Return Recipient.Count() > 1;
	Else
		Return CommonClientServer.EmailsFromString(Recipient).Count() > 1;
	EndIf;
EndFunction

&AtServer
Function HasDataToPrint()
	Result = False;
	For Each PrintFormSetting In PrintFormsSettings Do
		Result = Result Or ThisObject[PrintFormSetting.AttributeName].TableHeight > 0;
	EndDo;
	Return Result;
EndFunction

&AtServer
Function HasTemplatesToEdit()
	Result = False;
	For Each PrintFormSetting In PrintFormsSettings Do
		Result = Result Or Not IsBlankString(PrintFormSetting.PathToTemplate);
	EndDo;
	Return Result;
EndFunction

&AtServer
Function HasPrintFormsWithSignatureAndSeal()
	Result = False;
	For Each PrintFormSetting In PrintFormsSettings Do
		Result = Result Or PrintFormSetting.SignatureAndSeal;
	EndDo;
	Return Result;
EndFunction

&AtServer
Function HasSignaturesAndSealsForPrintObjects()
	
	Result = False;
	
	ObjectsSignaturesAndSeals = PrintManagement.ObjectsSignaturesAndSeals(PrintObjects);
	For Each ObjectSignaturesAndSeals In ObjectsSignaturesAndSeals Do
		SignaturesAndSealsCollection = ObjectSignaturesAndSeals.Value;
		For Each SignatureSeal In SignaturesAndSealsCollection Do
			Picture = SignatureSeal.Value;
			If Picture.Kind <> PictureType.Empty Then
				Return True;
			EndIf;
		EndDo;
	EndDo;
	
	Return Result;
	
EndFunction

&AtClient
Procedure OpenTemplateForEditing()
	
	PrintFormSetting = CurrentPrintFormSetup();
	
	DisplayCurrentPrintFormState(NStr("ru = 'Макет редактируется'; en = 'Layout is being edited'; pl = 'Szablon jest edytowany';de = 'Die Vorlage wird bearbeitet';ro = 'Macheta se editează';tr = 'Şablon düzenleniyor'; es_ES = 'El modelo se está editando'"));
	
	TemplateMetadataObjectName = PrintFormSetting.PathToTemplate;
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("TemplateMetadataObjectName", TemplateMetadataObjectName);
	OpeningParameters.Insert("WindowOpeningMode", FormWindowOpeningMode.LockOwnerWindow);
	OpeningParameters.Insert("DocumentName", PrintFormSetting.Presentation);
	OpeningParameters.Insert("TemplateType", "MXL");
	OpeningParameters.Insert("Edit", True);
	
	OpenForm("CommonForm.EditSpreadsheetDocument", OpeningParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure DisplayCurrentPrintFormState(StateText = "")
	
	DisplayState = Not IsBlankString(StateText);
	
	SpreadsheetDocumentField = Items.CurrentPrintForm;
	
	StatePresentation = SpreadsheetDocumentField.StatePresentation;
	StatePresentation.Text = StateText;
	StatePresentation.Visible = DisplayState;
	StatePresentation.AdditionalShowMode = 
		?(DisplayState, AdditionalShowMode.Irrelevance, AdditionalShowMode.DontUse);
		
	SpreadsheetDocumentField.ReadOnly = DisplayState Or SpreadsheetDocumentField.Output = UseOutput.Disable;
	
EndProcedure

&AtClient
Procedure SwitchCurrentPrintFormEditing()
	PrintFormSetting = CurrentPrintFormSetup();
	If PrintFormSetting <> Undefined Then
		SpreadsheetDocumentField = Items[PrintFormSetting.AttributeName];
		SpreadsheetDocumentField.Edit = Not SpreadsheetDocumentField.Edit;
		Items.CurrentPrintForm.Edit = SpreadsheetDocumentField.Edit;
		SwitchEditingButtonMark();
	EndIf;
EndProcedure

&AtClient
Procedure SwitchEditingButtonMark()
	
	PrintFormAvailable = Items.Pages.CurrentPage <> Items.PrintFormUnavailablePage;
	
	CanEdit = False;
	Checkmark = False;
	
	PrintFormSetting = CurrentPrintFormSetup();
	If PrintFormSetting <> Undefined Then
		SpreadsheetDocumentField = Items[PrintFormSetting.AttributeName];
		CanEdit = PrintFormAvailable AND Not SpreadsheetDocumentField.Protection;
		Checkmark = SpreadsheetDocumentField.Edit AND CanEdit;
	EndIf;
	
	Items.EditButton.Check = Checkmark;
	Items.EditButton.Enabled = CanEdit;
	
EndProcedure

&AtClient
Procedure SetTemplateChangeAvailability()
	PrintFormAvailable = Items.Pages.CurrentPage <> Items.PrintFormUnavailablePage;
	PrintFormSetting = CurrentPrintFormSetup();
	Items.ChangeTemplateButton.Enabled = PrintFormAvailable AND Not IsBlankString(PrintFormSetting.PathToTemplate);
EndProcedure

&AtClient
Procedure SetOutputCommandsAvailability()
	
	PrintFormSetting = CurrentPrintFormSetup();
	SpreadsheetDocumentField = Items[PrintFormSetting.AttributeName];
	PrintFormAvailable = Items.Pages.CurrentPage <> Items.PrintFormUnavailablePage;
	
	CanPrint = PrintFormAvailable AND SpreadsheetDocumentField.Output = UseOutput.Enable;
	
	If Items.Find("PreviewButton") <> Undefined Then
		Items.PreviewButton.Enabled = CanPrint;
	EndIf;
	If Items.Find("PreviewButtonAllActions") <> Undefined Then
		Items.PreviewButtonAllActions.Enabled = CanPrint;
	EndIf;
	If Items.Find("AllActionsPageParametersButton") <> Undefined Then
		Items.AllActionsPageParametersButton.Enabled = CanPrint;
	EndIf;
	
EndProcedure

&AtClient
Procedure RefreshCurrentPrintForm()
	
	PrintFormSetting = CurrentPrintFormSetup();
	If PrintFormSetting = Undefined Then
		Return;
	EndIf;
	
	RegeneratePrintForm(PrintFormSetting.TemplateName, PrintFormSetting.AttributeName);
	DisplayCurrentPrintFormState();
	
EndProcedure

&AtServer
Procedure RegeneratePrintForm(TemplateName, AttributeName)
	
	Cancel = False;
	PrintFormsCollection = GeneratePrintForms(TemplateName, Cancel);
	If Cancel Then
		Raise NStr("ru = 'Печатная форма не была переформирована.'; en = 'Print form is not generated.'; pl = 'Formularz wydruku nie został zregenerowany.';de = 'Das Druckformular wurde nicht neu generiert.';ro = 'Forma de tipar nu a fost regenerată.';tr = 'Yazdırma formu tekrar oluşturulmadı.'; es_ES = 'Versión impresa no se ha regenerado.'");
	EndIf;
	
	For Each PrintForm In PrintFormsCollection Do
		If PrintForm.TemplateName = TemplateName Then
			ThisObject[AttributeName] = PrintForm.SpreadsheetDocument;
		EndIf;
	EndDo;
	
	SetCurrentSpreadsheetDocument(AttributeName);
	
EndProcedure

&AtClient
Function CurrentPrintFormSetup()
	Return PrintManagementClient.CurrentPrintFormSetup(ThisObject);
EndFunction

&AtServerNoContext
Procedure WriteTemplate(TemplateMetadataObjectName, TemplateAddressInTempStorage)
	PrintManagement.WriteTemplate(TemplateMetadataObjectName, TemplateAddressInTempStorage);
EndProcedure

&AtClient
Procedure GoToDocumentCompletion(SelectedItem, AdditionalParameters) Export
	
	If SelectedItem = Undefined Then
		Return;
	EndIf;
	
	SpreadsheetDocumentField = Items.CurrentPrintForm;
	SpreadsheetDocument = CurrentPrintForm;
	SelectedDocumentArea = SpreadsheetDocument.Areas.Find(SelectedItem.Value);
	
	SpreadsheetDocumentField.CurrentArea = SpreadsheetDocument.Area("R1C1"); // Moving to the beginning
	
	If SelectedDocumentArea <> Undefined Then
		SpreadsheetDocumentField.CurrentArea = SpreadsheetDocument.Area(SelectedDocumentArea.Top,,SelectedDocumentArea.Bottom,);
	EndIf;
	
EndProcedure

&AtClient
Procedure SendPrintFormsByEmail()
	NotifyDescription = New NotifyDescription("SendPrintFormsByEmailAccountSetupOffered", ThisObject);
	If CommonClient.SubsystemExists("StandardSubsystems.EmailOperations") Then
		ModuleEmailOperationsClient = CommonClient.CommonModule("EmailOperationsClient");
		ModuleEmailOperationsClient.CheckAccountForSendingEmailExists(NotifyDescription);
	EndIf;
EndProcedure

&AtServer
Function EmailSendOptions(SelectedOptions)
	
	AttachmentsList = PutSpreadsheetDocumentsInTempStorage(SelectedOptions);
	
	// Control of name uniqueness.
	FileNameTemplate = "%1%2.%3";
	UsedFilesNames = New Map;
	For Each Attachment In AttachmentsList Do
		FileName = Attachment.Presentation;
		UsageNumber = ?(UsedFilesNames[FileName] <> Undefined,
			UsedFilesNames[FileName] + 1, 1);
		UsedFilesNames.Insert(FileName, UsageNumber);
		If UsageNumber > 1 Then
			File = New File(FileName);
			FileName = StringFunctionsClientServer.SubstituteParametersToString(FileNameTemplate,
				File.BaseName, " (" + UsageNumber + ")", File.Extension);
		EndIf;
		Attachment.Presentation = FileName;
	EndDo;
	
	Recipients = OutputParameters.SendOptions.Recipient;
	If SelectedOptions.Property("Recipients") Then
		Recipients = SelectedOptions.Recipients;
	EndIf;
	
	Result = New Structure;
	Result.Insert("Recipient", Recipients);
	Result.Insert("Subject", OutputParameters.SendOptions.Subject);
	Result.Insert("Text", OutputParameters.SendOptions.Text);
	Result.Insert("Attachments", AttachmentsList);
	Result.Insert("DeleteFilesAfterSending", True);
	
	PrintForms = New ValueTable;
	PrintForms.Columns.Add("Name");
	PrintForms.Columns.Add("SpreadsheetDocument");
	
	For Each PrintFormSetting In PrintFormsSettings Do
		If Not PrintFormSetting.Print Then
			Continue;
		EndIf;
		
		SpreadsheetDocument = ThisObject[PrintFormSetting.AttributeName];
		If PrintForms.FindRows(New Structure("SpreadsheetDocument", SpreadsheetDocument)).Count() > 0 Then
			Continue;
		EndIf;
		
		If EvalOutputUsage(SpreadsheetDocument) = UseOutput.Disable Then
			Continue;
		EndIf;
		
		If SpreadsheetDocument.Protection Then
			Continue;
		EndIf;
		
		If SpreadsheetDocument.TableHeight = 0 Then
			Continue;
		EndIf;
		
		PrintFormDetails = PrintForms.Add();
		PrintFormDetails.Name = PrintFormSetting.Name;
		PrintFormDetails.SpreadsheetDocument = SpreadsheetDocument;
	EndDo;
	
	ObjectsList = Parameters.CommandParameter;
	If Common.RefTypeValue(Parameters.CommandParameter) Then
		ObjectsList = CommonClientServer.ValueInArray(Parameters.CommandParameter);
	EndIf;
	
	PrintManagementOverridable.BeforeSendingByEmail(Result, OutputParameters, ObjectsList, PrintForms);
	
	Return Result;
	
EndFunction

&AtClient
Procedure SendPrintFormsByEmailAccountSetupOffered(AccountSetUp, AdditionalParameters) Export
	
	If AccountSetUp <> True Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	NameOfFormToOpen = "CommonForm.SelectAttachmentFormat";
	If CommonClient.SubsystemExists("StandardSubsystems.Interactions") 
		AND StandardSubsystemsClient.ClientRunParameters().UseEmailClient Then
			If MoreThanOneRecipient(OutputParameters.SendOptions.Recipient) Then
				FormParameters.Insert("Recipients", OutputParameters.SendOptions.Recipient);
				NameOfFormToOpen = "CommonForm.ComposeNewMessage";
			EndIf;
	EndIf;
	
	OpenForm(NameOfFormToOpen, FormParameters, ThisObject);
	
EndProcedure

&AtServer
Function SpreadsheetDocumentsToPrint()
	SpreadsheetDocuments = New ValueList;
	
	For Each PrintFormSetting In PrintFormsSettings Do
		If Items[PrintFormSetting.AttributeName].Output = UseOutput.Enable AND PrintFormSetting.Print Then
			PrintForm = ThisObject[PrintFormSetting.AttributeName];
			SpreadsheetDocument = New SpreadsheetDocument;
			SpreadsheetDocument.Put(PrintForm);
			FillPropertyValues(SpreadsheetDocument, PrintForm, PrintManagement.SpreadsheetDocumentPropertiesToCopy());
			SpreadsheetDocument.Copies = PrintFormSetting.Count;
			SpreadsheetDocuments.Add(SpreadsheetDocument, PrintFormSetting.Presentation);
		EndIf;
	EndDo;
	
	Return SpreadsheetDocuments;
EndFunction

&AtClient
Procedure SaveSettings()
	PrintFormsSettingsToSave = New Array;
	For Each PrintFormSetting In PrintFormsSettings Do
		SettingToSave = New Structure;
		SettingToSave.Insert("TemplateName", PrintFormSetting.TemplateName);
		SettingToSave.Insert("Count", ?(PrintFormSetting.Print,PrintFormSetting.Count, 0));
		SettingToSave.Insert("DefaultPosition", PrintFormSetting.DefaultPosition);
		PrintFormsSettingsToSave.Add(SettingToSave);
	EndDo;
	SavePrintFormsSettings(SettingsKey, PrintFormsSettingsToSave);
EndProcedure

&AtClient
Procedure StartSaveSettings()
	DetachIdleHandler("SaveSettings");
	If IsBlankString(SettingsKey) Then
		Return;
	EndIf;
	AttachIdleHandler("SaveSettings", 2, True);
EndProcedure

&AtServerNoContext
Function SettingsForSaving()
	SettingsForSaving = New Structure;
	SettingsForSaving.Insert("SaveFormats", New Array);
	SettingsForSaving.Insert("PackToArchive", False);
	SettingsForSaving.Insert("TransliterateFilesNames", False);
	Return SettingsForSaving;
EndFunction

&AtServerNoContext
Function HasSignatureAndSeal(SpreadsheetDocument)
	
	If Not PrintManagement.PrintSettings().UseSignaturesAndSeals Then
		Return False;
	EndIf;
	
	For Each Drawing In SpreadsheetDocument.Drawings Do
		For Each Prefix In PrintManagement.AreaNamesPrefixesWithSignatureAndSeal() Do
			If StrStartsWith(Drawing.Name, Prefix) Then
				Return True;
			EndIf;
		EndDo;
	EndDo;
	
	Return False;
	
EndFunction

&AtServer
Procedure AddSignatureAndSeal()
	
	AreasSignaturesAndSeals = PrintManagement.AreasSignaturesAndSeals(PrintObjects);
	
	SignaturesAndSeals = Undefined;
	If IsTempStorageURL(DrawingsStorageAddress) Then
		SignaturesAndSeals = GetFromTempStorage(DrawingsStorageAddress);
	EndIf;
	
	ProcessedSpreadsheetDocuments = New Map;
	
	For Each PrintFormSetting In PrintFormsSettings Do
		If Not PrintFormSetting.SignatureAndSeal Then
			Continue;
		EndIf;
		
		NameOfAttributeWithSpreadsheetDocument = PrintFormSetting.AttributeName;
		If ProcessedSpreadsheetDocuments[NameOfAttributeWithSpreadsheetDocument] <> Undefined Then
			Continue;
		Else
			ProcessedSpreadsheetDocuments.Insert(NameOfAttributeWithSpreadsheetDocument, True);
		EndIf;
		
		SpreadsheetDocument = ThisObject[NameOfAttributeWithSpreadsheetDocument];
		
		If SignaturesAndSeals <> Undefined Then
			SpreadsheetDocumentDrawings = SignaturesAndSeals[NameOfAttributeWithSpreadsheetDocument];
			For Each SavedDrawing In SpreadsheetDocumentDrawings Do
				NewDrawing = SpreadsheetDocument.Drawings.Add(SpreadsheetDocumentDrawingType.Picture);
				FillPropertyValues(NewDrawing, SavedDrawing);
			EndDo;
		EndIf;
		
		PrintManagement.AddSignatureAndSeal(SpreadsheetDocument, AreasSignaturesAndSeals);
	EndDo;
	
EndProcedure

&AtServer
Procedure RemoveSignatureAndSeal()
	
	SignaturesAndSeals = New Structure;
	HideSignaturesAndSeals = PrintManagement.PrintSettings().HideSignaturesAndSealsForEditing;
	
	For Each PrintFormSetting In PrintFormsSettings Do
		If Not PrintFormSetting.SignatureAndSeal Then
			Continue;
		EndIf;
		
		SpreadsheetDocument = ThisObject[PrintFormSetting.AttributeName];
		PrintManagement.RemoveSignatureAndSeal(SpreadsheetDocument, HideSignaturesAndSeals);
	EndDo;
	
EndProcedure

&AtServerNoContext
Function SpreadsheetDocumentSignaturesAndSeals(SpreadsheetDocument)
	
	SpreadsheetDocumentDrawings = New Array;
	
	For Each Drawing In SpreadsheetDocument.Drawings Do
		If PrintManagement.IsSignatureOrSeal(Drawing) Then
			DrawingDetails = New Structure("Left,Top,Width,Height,Picture,Owner,BackColor,Name,Line");
			FillPropertyValues(DrawingDetails, Drawing);
			SpreadsheetDocumentDrawings.Add(DrawingDetails);
		EndIf;
	EndDo;
	
	Return SpreadsheetDocumentDrawings;
	
EndFunction

&AtServer
Function SignaturesAndSealsOfSpreadsheetDocuments()
	
	SignaturesAndSeals = New Structure;
	
	For Each PrintFormSetting In PrintFormsSettings Do
		If Not PrintFormSetting.SignatureAndSeal Then
			Continue;
		EndIf;
		
		SpreadsheetDocument = ThisObject[PrintFormSetting.AttributeName];
		SpreadsheetDocumentDrawings = SpreadsheetDocumentSignaturesAndSeals(SpreadsheetDocument);
		
		If Not SignaturesAndSeals.Property(PrintFormSetting.AttributeName) Then
			SignaturesAndSeals.Insert(PrintFormSetting.AttributeName, SpreadsheetDocumentDrawings);
		EndIf;
	EndDo;
	
	Return SignaturesAndSeals;
	
EndFunction

&AtClient
Procedure AddDeleteSignatureSeal()
	
	If SignatureAndSeal Then
		AddSignatureAndSeal();
	Else
		RemoveSignatureAndSeal();
	EndIf;

EndProcedure

&AtServer
Procedure OnExecuteCommandAtServer(AdditionalParameters)
	PrintManagementOverridable.PrintDocumentsOnExecuteCommand(ThisObject, AdditionalParameters);
EndProcedure

#Region CalculateSelectedCellsIndicators

// Calculate functions for the selected cell range.
// See the ReportSpreadsheetDocumentOnActivateArea event handler.
//
&AtClient
Procedure CalculateIndicatorsDynamically()
	Var CurrentCommand;
	
	IndicatorsCommands = IndicatorsCommands();
	For Each Command In IndicatorsCommands Do 
		If Items[Command.Key].Check Then 
			CurrentCommand = Command.Key;
			Break;
		EndIf;
	EndDo;
	
	CalculateIndicators(CurrentCommand);
EndProcedure

// Calculates and displays indicators of the selected spreadsheet document cell areas.
//
// Parameters:
//  CurrentCommand - String - an indicator calculation command name, for example, "CalculateAmount".
//                      Defines which indicator is the main one.
//
&AtClient
Procedure CalculateIndicators(CurrentCommand = "CalculateAmount")
	// Calculating indicators.
	CalculationParameters = CommonInternalClient.CellsIndicatorsCalculationParameters(CurrentPrintForm);
	If CalculationParameters.CalculateAtServer Then 
		CalculationIndicators = CalculationIndicatorsServer(CalculationParameters);
	Else
		CalculationIndicators = CommonInternalClientServer.CalculationCellsIndicators(
			CurrentPrintForm, CalculationParameters.SelectedAreas);
	EndIf;
	
	// Setting indicator values.
	FillPropertyValues(ThisObject, CalculationIndicators);
	
	// Switching and formatting indicators.
	IndicatorsCommands = IndicatorsCommands();
	For Each Command In IndicatorsCommands Do 
		Items[Command.Key].Check = False;
		
		IndicatorValue = CalculationIndicators[Command.Value];
		IndicatorDigitCapacity = Min(StrLen(Max(IndicatorValue, -IndicatorValue) % 1) - 2, 4);
		
		Items[Command.Value].EditFormat = "NFD=" + IndicatorDigitCapacity + "; NGS=' '; NZ=0";
	EndDo;
	Items[CurrentCommand].Check = True;
	
	// Main indicator output.
	CurrentIndicator = IndicatorsCommands[CurrentCommand];
	Indicator = ThisObject[CurrentIndicator];
	Items.Indicator.EditFormat = Items[CurrentIndicator].EditFormat;
	Items.IndicatorsKindsCommands.Picture = PictureLib[CurrentIndicator];
EndProcedure

// Calculates indicators of numeric cells in a spreadsheet document.
//  see ReportsClientServer.CellsCalculationIndicators. 
//
&AtServer
Function CalculationIndicatorsServer(CalculationParameters)
	Return CommonInternalClientServer.CalculationCellsIndicators(CurrentPrintForm, CalculationParameters.SelectedAreas);
EndFunction

// Defines the correspondence between indicator calculation commands and indicators.
//
// Returns:
//   Map - Key - a command name, Value - an indicator name.
//
&AtClient
Function IndicatorsCommands()
	IndicatorsCommands = New Map();
	IndicatorsCommands.Insert("CalculateAmount", "Sum");
	IndicatorsCommands.Insert("CalculateCount", "Count");
	IndicatorsCommands.Insert("CalculateAverage", "Mean");
	IndicatorsCommands.Insert("CalculateMin", "Minimum");
	IndicatorsCommands.Insert("CalculateMax", "Maximum");
	
	Return IndicatorsCommands;
EndFunction

// Controls whether a calculation indicator panel is visible.
//
// Parameters:
//  Visibility - Boolean - indicates whether an indicator panel is visible.
//              See also Syntax Assistant: FormGroup.Visibility.
//
&AtClient
Procedure SetIndicatorsVisibility(Visibility)
	Items.IndicatorsArea.Visible = Visibility;
	Items.CalculateAllIndicators.Check = Visibility;
EndProcedure

#EndRegion

#EndRegion

