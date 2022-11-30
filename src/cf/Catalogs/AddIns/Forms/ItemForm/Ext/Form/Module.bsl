///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var AdditionalInformation;

#EndRegion

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	IsNew = Object.Ref.IsEmpty();
	
	If IsNew Then
		Parameters.ShowImportFromFileDialogOnOpen = True;
	EndIf;
	
	SetVisibilityAvailability();
	
	If Not AccessRight("Edit", Metadata.Catalogs.AddIns) Then
		
		Items.FormUpdateFromFile.Visible = False;
		Items.FormSaveAs.Visible = False;
		Items.PerformUpdateFrom1CITSPortal.Visible = False;
		
	EndIf;
	
	If Not AddInsInternal.ImportFromPortalIsAvailable() Then 
		
		Items.UpdateFrom1CITSPortal.Visible = False;
		Items.PerformUpdateFrom1CITSPortal.Visible = False;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Parameters.ShowImportFromFileDialogOnOpen Then
		AttachIdleHandler("ImportAddInFromFile", 0.1, True);
	EndIf
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// If the "Reread" command is called, delete add-in data clipboard
	If IsTempStorageURL(ComponentBinaryDataAddress) Then
		DeleteFromTempStorage(ComponentBinaryDataAddress);
	EndIf;
	
	ComponentBinaryDataAddress = Undefined;
	SetVisibilityAvailability();
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// If there is binary add-in data to be saved, add them to AdditionalProperties.
	If IsTempStorageURL(ComponentBinaryDataAddress) Then
		ComponentBinaryData = GetFromTempStorage(ComponentBinaryDataAddress);
		CurrentObject.AdditionalProperties.Insert("ComponentBinaryData", ComponentBinaryData);
	EndIf;
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	Saved = True; // Saving means successful closing,
	Parameters.ShowImportFromFileDialogOnOpen = False; // Preventing closing form on error.
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	SetVisibilityAvailability();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit Then 
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	CloseParameter = AddInsInternalClient.AddInImportResult();
	CloseParameter.Imported = Saved;
	CloseParameter.ID = Object.ID;
	CloseParameter.Version = Object.Version;
	CloseParameter.Description  = Object.Description;
	CloseParameter.AdditionalInformation = AdditionalInformation;
	
	Close(CloseParameter);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UsingOnChange(Item)
	
	SetVisibilityAvailability();
	
EndProcedure

&AtClient
Procedure UpdateUpdateFrom1CITSPortalOnChange(Item)
	
	SetVisibilityAvailability();
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure UpdateFromThePortal(Command)
	
	If Modified Then
		Notification = New NotifyDescription("AfterCloseQuestionWriteObject", ThisObject);
		ShowQueryBox(Notification, 
			NStr("ru = 'Для проверки обновления необходимо записать объект. Записать?'; en = 'Before checking for update, you need to write the item. Do you want to write it?'; pl = 'Before checking for update, you need to write the item. Do you want to write it?';de = 'Before checking for update, you need to write the item. Do you want to write it?';ro = 'Before checking for update, you need to write the item. Do you want to write it?';tr = 'Before checking for update, you need to write the item. Do you want to write it?'; es_ES = 'Before checking for update, you need to write the item. Do you want to write it?'"),
			QuestionDialogMode.YesNo);
	Else 
		StartAddInUpdateFromPortal();
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateFromFile(Command)
	
	ClearMessages();
	ImportAddInFromFile();
	
EndProcedure

&AtClient
Procedure SaveAs(Command)
	
	If IsTempStorageURL(ComponentBinaryDataAddress) Then
		ShowMessageBox(, NStr("ru = 'Перед сохранение компоненты в файл элемент справочника нужно записать.'; en = 'Please write the catalog item before saving the add-in to a file.'; pl = 'Please write the catalog item before saving the add-in to a file.';de = 'Please write the catalog item before saving the add-in to a file.';ro = 'Please write the catalog item before saving the add-in to a file.';tr = 'Please write the catalog item before saving the add-in to a file.'; es_ES = 'Please write the catalog item before saving the add-in to a file.'"));
	Else 
		ClearMessages();
		AddInsInternalClient.SaveAddInToFile(Object.Ref);
	EndIf;
	
EndProcedure

&AtClient
Procedure SupportedClientApplications(Command)
	
	Attributes = New Structure;
	Attributes.Insert("Windows_x86");
	Attributes.Insert("Windows_x86_64");
	Attributes.Insert("Linux_x86");
	Attributes.Insert("Linux_x86_64");
	Attributes.Insert("Windows_x86_Firefox");
	Attributes.Insert("Linux_x86_Firefox");
	Attributes.Insert("Linux_x86_64_Firefox");
	Attributes.Insert("Windows_x86_MSIE");
	Attributes.Insert("Windows_x86_64_MSIE");
	Attributes.Insert("Windows_x86_Chrome");
	Attributes.Insert("Linux_x86_Chrome");
	Attributes.Insert("Linux_x86_64_Chrome");
	Attributes.Insert("MacOS_x86_64_Safari");
	
	FillPropertyValues(Attributes, Object);
	
	FormParameters = New Structure;
	FormParameters.Insert("SupportedClients", Attributes);
	
	OpenForm("CommonForm.SupportedClientApplications", FormParameters);
	
EndProcedure

#EndRegion

#Region Private

#Region ClientLogic

// Creates add-in import from file dialog.
&AtClient
Procedure ImportAddInFromFile()
	
	Notification = New NotifyDescription("ImportAddInAfterSecurityWarning", ThisObject);
	FormParameters = New Structure("Key", "BeforeAddAddIn");
	OpenForm("CommonForm.SecurityWarning", FormParameters,,,,, Notification);
	
EndProcedure

// ImportAComponentFromAFile procedure continuation.
&AtClient
Procedure ImportAddInAfterSecurityWarning(Response, Context) Export
	
	// Answer:
	// - Continue 
	// - DialogReturnCode.Cancel - Cancel
	// - Undefined - the dialog box is closed.
	If Response <> "Continue" Then
		ImportAddInOnErrorDisplay();
		Return;
	EndIf;
	
	Notification = New NotifyDescription("ImportAddInAfterPutFile", ThisObject, Context);
	
	ImportParameters = FileSystemClient.FileImportParameters();
	ImportParameters.Dialog.Filter = NStr("ru = 'Внешняя компонента (*.zip)|*.zip|Все файлы(*.*)|*.*'; en = 'Add-in (*.zip)|*.zip|All files(*.*)|*.*'; pl = 'Add-in (*.zip)|*.zip|All files(*.*)|*.*';de = 'Add-in (*.zip)|*.zip|All files(*.*)|*.*';ro = 'Add-in (*.zip)|*.zip|All files(*.*)|*.*';tr = 'Add-in (*.zip)|*.zip|All files(*.*)|*.*'; es_ES = 'Add-in (*.zip)|*.zip|All files(*.*)|*.*'");
	ImportParameters.Dialog.Title = NStr("ru = 'Выберите файл внешней компоненты'; en = 'Select an add-in file'; pl = 'Select an add-in file';de = 'Select an add-in file';ro = 'Select an add-in file';tr = 'Select an add-in file'; es_ES = 'Select an add-in file'");
	ImportParameters.FormID = UUID;
	
	FileSystemClient.ImportFile(Notification, ImportParameters, Object.FileName);
	
EndProcedure

// ImportAComponentFromAFile procedure continuation.
&AtClient
Procedure ImportAddInAfterPutFile(FileThatWasPut, Context) Export
	
	If FileThatWasPut = Undefined Then
		ImportAddInOnErrorDisplay(NStr("ru = 'Файл не удалось загрузить на сервер.'; en = 'Cannot upload the file to the server.'; pl = 'Cannot upload the file to the server.';de = 'Cannot upload the file to the server.';ro = 'Cannot upload the file to the server.';tr = 'Cannot upload the file to the server.'; es_ES = 'Cannot upload the file to the server.'"));
		Return;
	EndIf;
	
	ImportParameters = New Structure;
	ImportParameters.Insert("FileStorageAddress", FileThatWasPut.Location);
	ImportParameters.Insert("FileName",            FileNameOnly(FileThatWasPut.Name));
	
	Result = ImportAddInFromFileOnServer(ImportParameters);
	If Result.Imported AND IsTempStorageURL(ComponentBinaryDataAddress)Then
		AdditionalInformation = Result.AdditionalInformation;
	Else 
		ImportAddInOnErrorDisplay(Result.ErrorDescription);
	EndIf;
	
EndProcedure

// ImportAComponentFromAFile procedure continuation.
&AtClient
Procedure ImportAddInOnErrorDisplay(ErrorDescription = "")
	
	If IsBlankString(ErrorDescription) Then 
		ImportAddInAfterErrorDisplay(Undefined);
	Else 
		Notification = New NotifyDescription("ImportAddInAfterErrorDisplay", ThisObject);
		
		StringWithWarning = New FormattedString(
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = '%1
				           |Необходимо указать zip-архив с внешней компонентой.
				           |Подробнее:'; 
				           |en = '%1
				           |Specify a ZIP archive containing the add-in.
				           |Details:'; 
				           |pl = '%1
				           |Specify a ZIP archive containing the add-in.
				           |Details:';
				           |de = '%1
				           |Specify a ZIP archive containing the add-in.
				           |Details:';
				           |ro = '%1
				           |Specify a ZIP archive containing the add-in.
				           |Details:';
				           |tr = '%1
				           |Specify a ZIP archive containing the add-in.
				           |Details:'; 
				           |es_ES = '%1
				           |Specify a ZIP archive containing the add-in.
				           |Details:'"),
				ErrorDescription),
			New FormattedString("https://its.1c.ru/db/metod8dev/content/3221",,,, 
				"https://its.1c.ru/db/metod8dev/content/3221"), ".");
			
		ShowMessageBox(Notification, StringWithWarning);
	EndIf;
	
EndProcedure

// ImportAComponentFromAFile procedure continuation.
&AtClient
Procedure ImportAddInAfterErrorDisplay(AdditionalParameters) Export
	
	// Opened via application interface.
	If Parameters.ShowImportFromFileDialogOnOpen Then 
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterCloseQuestionWriteObject(QuestionResult, Context) Export 
	
	If QuestionResult = DialogReturnCode.Yes Then 
		Write();
		StartAddInUpdateFromPortal();
	EndIf;
	
EndProcedure

&AtClient
Procedure StartAddInUpdateFromPortal()
	
	IsNew = Object.Ref.IsEmpty();
	If IsNew Then 
		Return;
	EndIf;
	
	RefsArray = New Array;
	RefsArray.Add(Object.Ref);
	
	Notification = New NotifyDescription("AfterUpdateAddInFromPortal", ThisObject);
	
	AddInsInternalClient.UpdateAddInsFromPortal(Notification, RefsArray);
	
EndProcedure

&AtClient
Procedure AfterUpdateAddInFromPortal(Result, AdditionalParameters) Export
	
	UpdateCardAfterAddInUpdateFromPortal();
	
EndProcedure

#EndRegion

#Region ServerLogic

// Server logic of the ImportAddInFromFile procedure.
&AtServer
Function ImportAddInFromFileOnServer(ImportParameters)
	
	If Not Users.IsFullUser(,, False) Then
		Raise NStr("ru = 'Недостаточно прав для совершения операции.'; en = 'Insufficient rights to perform the operation.'; pl = 'Insufficient rights to perform the operation.';de = 'Insufficient rights to perform the operation.';ro = 'Insufficient rights to perform the operation.';tr = 'Insufficient rights to perform the operation.'; es_ES = 'Insufficient rights to perform the operation.'");
	EndIf;
	
	CatalogObject = FormAttributeToValue("Object");
	
	Information = AddInsInternal.InformationOnAddInFromFile(ImportParameters.FileStorageAddress,, 
		Parameters.AdditionalInformationSearchParameters);
	
	Result = AddInImportResult();
	
	If Not Information.Disassembled Then 
		Result.ErrorDescription = Information.ErrorDescription;
		Return Result;
	EndIf;
	
	If ValueIsFilled(CatalogObject.ID)
		AND ValueIsFilled(Information.Attributes.ID) Then 
		
		If CatalogObject.ID <> Information.Attributes.ID Then 
			Result.ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru='Текущий идентификатор %1 отличается от загружаемого %2
				         |Обновление невозможно.'; 
				         |en = 'The current ID %1 differs from the imported one %2
				         |Cannot update.'; 
				         |pl = 'The current ID %1 differs from the imported one %2
				         |Cannot update.';
				         |de = 'The current ID %1 differs from the imported one %2
				         |Cannot update.';
				         |ro = 'The current ID %1 differs from the imported one %2
				         |Cannot update.';
				         |tr = 'The current ID %1 differs from the imported one %2
				         |Cannot update.'; 
				         |es_ES = 'The current ID %1 differs from the imported one %2
				         |Cannot update.'"),
				CatalogObject.ID,
				Information.Attributes.ID);
			Return Result;
		EndIf;
		
	EndIf;
	
	FillPropertyValues(CatalogObject, Information.Attributes,, "ID"); // By manifest data.
	If Not ValueIsFilled(CatalogObject.ID) Then 
		CatalogObject.ID = Information.Attributes.ID;
	EndIf;
	CatalogObject.FileName =  ImportParameters.FileName;          // Set file name.
	ComponentBinaryDataAddress = PutToTempStorage(Information.BinaryData,
		UUID);
	
	CatalogObject.ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Загружена из файла %1. %2.'; en = 'Imported from file %1.%2.'; pl = 'Imported from file %1.%2.';de = 'Imported from file %1.%2.';ro = 'Imported from file %1.%2.';tr = 'Imported from file %1.%2.'; es_ES = 'Imported from file %1.%2.'"),
		CatalogObject.FileName,
		CurrentSessionDate());
	
	ValueToFormAttribute(CatalogObject, "Object");
	
	Modified = True;
	SetVisibilityAvailability();
	
	Result.Imported = True;
	Result.AdditionalInformation = Information.AdditionalInformation;
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function AddInImportResult()
	
	Result = New Structure;
	Result.Insert("Imported", False);
	Result.Insert("ErrorDescription", "");
	Result.Insert("AdditionalInformation", New Map);
	
	Return Result;
	
EndFunction

// Server logic of add-in update from the website.
&AtServer
Procedure UpdateCardAfterAddInUpdateFromPortal()
	
	ThisObject.Read();
	Modified = False;
	SetVisibilityAvailability();
	
EndProcedure

#EndRegion

#Region Presentation

&AtServer
Procedure SetVisibilityAvailability()
	
	CatalogObject = FormAttributeToValue("Object");
	IsNew = Object.Ref.IsEmpty();
	
	Items.Information.Visible = Not IsNew AND ValueIsFilled(Object.ErrorDescription);
	
	// WarningDisplayOnEditParameters
	DisplayWarning = WarningOnEditRepresentation.Show;
	DontDisplayWarning = WarningOnEditRepresentation.DontShow;
	If ValueIsFilled(Object.Description) Then
		Items.Description.WarningOnEditRepresentation = DisplayWarning;
	Else
		Items.Description.WarningOnEditRepresentation = DontDisplayWarning;
	EndIf;
	If ValueIsFilled(Object.ID) Then 
		Items.ID.WarningOnEditRepresentation = DisplayWarning;
	Else 
		Items.ID.WarningOnEditRepresentation = DontDisplayWarning;
	EndIf;
	If ValueIsFilled(Object.Version) Then 
		Items.Version.WarningOnEditRepresentation = DisplayWarning;
	Else 
		Items.Version.WarningOnEditRepresentation = DontDisplayWarning;
	EndIf;
	
	// Save to file button availability
	Items.FormSaveAs.Enabled = Not IsNew;
	
	// Dependence of using and automatic update.
	ComponentIsDisabled = (Object.Use = Enums.AddInUsageOptions.Disabled);
	Items.UpdateFrom1CITSPortal.Enabled = Not ComponentIsDisabled AND CatalogObject.ThisIsTheLatestVersionComponent();
	
	Items.PerformUpdateFrom1CITSPortal.Enabled = Object.UpdateFrom1CITSPortal;
	
EndProcedure

#EndRegion

#Region OtherMethods

&AtClient
Function FileNameOnly(SelectedFileName)
	
	// It is critical to use on client as GetPathSeparator() on the server can be different.
	SubstringsArray = StrSplit(SelectedFileName, GetPathSeparator(), False);
	Return SubstringsArray.Get(SubstringsArray.UBound());
	
EndFunction

#EndRegion

#EndRegion