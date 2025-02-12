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
	
	FilesOperationsInternal.ItemFormOnCreateAtServer(
		ThisObject, Cancel, StandardProcessing, Parameters, ReadOnly);
		
	SendOptions = ?(ValueIsFilled(Parameters.SendOptions),
		Parameters.SendOptions, FilesOperationsInternal.PrepareSendingParametersStructure());
		
	// StandardSubsystems.Properties
	If Common.SubsystemExists("StandardSubsystems.Properties") Then
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("ItemForPlacementName", "AdditionalAttributesGroup");
		AdditionalParameters.Insert("Object", Object);
		AdditionalParameters.Insert("DeferredInitialization", True);
		ModulePropertyManager = Common.CommonModule("PropertyManager");
		ModulePropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	EndIf;
	// End StandardSubsystems.Properties
	
	SetButtonsAvailability(ThisObject, Items);
	
	PrintWithStampAvailable =
		  Common.SubsystemExists("StandardSubsystems.DigitalSignature")
		AND ThisObject.Object.Extension = "mxl"
		AND ThisObject.Object.SignedWithDS;
	
	Items.PrintWithStamp.Visible = PrintWithStampAvailable;
	If Not PrintWithStampAvailable Then
		Items.PrintSubmenu.Type = FormGroupType.ButtonGroup;
		Items.Print.Title = NStr("ru = 'Печать'; en = 'Print'; pl = 'Wydruki';de = 'Drucken';ro = 'Forme de listare';tr = 'Yazdır'; es_ES = 'Impresión'");
	EndIf;
	
	RefreshTitle();
	RefreshFullPath();
	UpdateCloudServiceNote(Object.Ref);
	
	If Common.IsMobileClient() Then
		
		Items.Details.Height = 0;
		Items.Description.TitleLocation = FormItemTitleLocation.Top;
		Items.InfoGroupPart1.ItemsAndTitlesAlign =
			ItemsAndTitlesAlignVariant.ItemsRightTitlesLeft;
		Items.InfoGroupPart2.ItemsAndTitlesAlign =
			ItemsAndTitlesAlignVariant.ItemsRightTitlesLeft;
		Items.FileCharacteristicsGroup.ItemsAndTitlesAlign =
			ItemsAndTitlesAlignVariant.ItemsRightTitlesLeft;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	DescriptionBeforeWrite = Object.Description;
	
	ModificationDate = ToLocalTime(ThisObject.Object.UniversalModificationDate);
	
	SetAvaliabilityOfDSCommandsList();
	SetAvaliabilityOfEncryptionList();
	
	ReadSignaturesCertificates();
	DisplayAdditionalDataTabs();
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	UnlockObject(ThisObject.Object.Ref, UUID);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If Upper(EventName) = Upper("Write_ConstantsSet") AND (Upper(Source) = Upper("UseDigitalSignature")
		Or Upper(Source) = Upper("UseEncryption")) Then
		AttachIdleHandler("OnChangeSigningOrEncryptionUsage", 0.3, True);
	EndIf;
	
	If EventName = "Write_File"
		AND Source = Object.Ref
		AND Parameter <> Undefined
		AND TypeOf(Parameter) = Type("Structure")
		AND Parameter.Property("Event")
		AND (Parameter.Event = "EditFinished"
		   Or Parameter.Event = "EditingCanceled") Then
		Read();
	EndIf;
	
	// StandardSubsystems.Properties
	If CommonClient.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManagerClient = CommonClient.CommonModule("PropertyManagerClient");
		If ModulePropertyManagerClient.ProcessNofifications(ThisObject, EventName, Parameter) Then
			UpdateAdditionalAttributesItems();
			ModulePropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
			DisplayAdditionalDataTabs();
		EndIf;
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	If Common.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManager = Common.CommonModule("PropertyManager");
		ModulePropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	CurrentUser = Users.AuthorizedUser();
	
	FilesOperationsInternal.FillSignatureList(ThisObject);
	FilesOperationsInternal.FillEncryptionList(ThisObject);
	
	// StandardSubsystems.Properties
	If Common.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManager = Common.CommonModule("PropertyManager");
		ModulePropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	SetButtonsAvailability(ThisObject, Items);
	RefreshTitle();
	
	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.AccessManagement

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.Properties
	If Common.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManager = Common.CommonModule("PropertyManager");
		ModulePropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If ValueIsFilled(CopyingValue) Then
		
		BinaryData = FilesOperations.FileBinaryData(CopyingValue);
		If FilesOperationsInternal.FilesStorageTyoe() = Enums.FileStorageTypes.InInfobase Then
			FilesOperationsInternal.WriteFileToInfobase(CurrentObject.Ref, BinaryData);
		Else
			FileInfo = FilesOperationsInternal.AddFileToVolume(BinaryData, CurrentObject.UniversalModificationDate,
			CurrentObject.Description, CurrentObject.Extension); 
			CurrentObject.Volume = FileInfo.Volume;
			CurrentObject.PathToFile = FileInfo.PathToFile;
		EndIf;
		
		CurrentObject.FileStorageType = FilesOperationsInternal.FilesStorageTyoe();
		
		FilesOperationsInternal.MoveSignaturesCheckResults(DigitalSignatures, CopyingValue);
		
		If Common.SubsystemExists("StandardSubsystems.DigitalSignature") Then
			ModuleDigitalSignature = Common.CommonModule("DigitalSignature");
			
			SourceCertificates = ModuleDigitalSignature.EncryptionCertificates(CopyingValue);
			ModuleDigitalSignature.WriteEncryptionCertificates(CurrentObject, SourceCertificates);
			
			SetSignatures = ModuleDigitalSignature.SetSignatures(CopyingValue);
			ModuleDigitalSignature.AddSignature(CurrentObject, SetSignatures);
		EndIf;
	Else
		FilesOperationsInternal.MoveSignaturesCheckResults(DigitalSignatures, CurrentObject.Ref);
	EndIf;
	
	If DescriptionBeforeWrite <> CurrentObject.Description Then
		If CurrentObject.CurrentVersion.FileStorageType = Enums.FileStorageTypes.InVolumesOnHardDrive Then
			FilesOperationsInternal.RenameVersionFileOnHardDrive(
				CurrentObject.CurrentVersion,
				DescriptionBeforeWrite,
				CurrentObject.Description,
				UUID);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	EndIf;
	// End StandardSubsystems.AccessManagement
	
	If ValueIsFilled(CopyingValue) Then
		CreateVersionCopy(CurrentObject.Ref, CopyingValue);
		CopyingValue = Catalogs[CatalogName].EmptyRef();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OwnerOnChange(Item)
	
	If TypeOf(Object.FileOwner) = Type("CatalogRef.FilesFolders") Then
		RefreshFullPath();
	EndIf;
	
	OwnerType = TypeOf(Object.FileOwner);
	Items.FileOwner.Title = OwnerType;
	
EndProcedure

&AtClient
Procedure DecorationSynchronizationDateURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	If FormattedStringURL = "OpenJournal" Then
		
		StandardProcessing = False;
		FilterParameters      = EventLogFilterData(Account);
		EventLogClient.OpenEventLog(FilterParameters, ThisObject);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region DigitalSignaturesFormTableItemsEventHandlers

&AtClient
Procedure DigitalSIgnaturesChoice(Item, RowSelected, Field, StandardProcessing)
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	ModuleDigitalSignatureClient.OpenSignature(Items.DigitalSignatures.CurrentData);
	
EndProcedure

&AtClient
Procedure InstructionClick(Item)
	
	If CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
		ModuleDigitalSignatureClient.OpenInstructionOnTypicalProblemsOnWorkWithApplications();
	EndIf;
	
EndProcedure

#EndRegion

#Region EncryptionCertificatesFormTableItemsEventHandlers

&AtClient
Procedure EncryptionCertificatesSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	OpenEncryptionCertificate(Undefined);
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

///////////////////////////////////////////////////////////////////////////////////
// File command handlers

&AtClient
Procedure ShowInList(Command)
	StandardSubsystemsClient.ShowInList(ThisObject["Object"].Ref, Undefined);
EndProcedure

&AtClient
Procedure UpdateFromFileOnHardDrive(Command)
	
	If IsNew()
		OR ThisObject.Object.Encrypted
		OR ThisObject.Object.SignedWithDS
		OR ValueIsFilled(ThisObject.Object.BeingEditedBy) Then
		Return;
	EndIf;
	
	FileData = FilesOperationsInternalServerCall.FileData(ThisObject.Object.Ref);
	Handler = New NotifyDescription("UpdateFromFileOnHardDriveCompletion", ThisObject);
	FilesOperationsInternalClient.UpdateFromFileOnHardDriveWithNotification(Handler, FileData, UUID);
	
EndProcedure

&AtClient
Procedure StandardWriteAndClose(Command)
	
	If HandleFileRecordCommand() Then
		
		Result = New Structure();
		Result.Insert("ErrorText", "");
		Result.Insert("FileAdded", True);
		Result.Insert("FileRef", ThisObject.Object.Ref);
		
		Close(Result);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure StandardWrite(Command)
	
	HandleFileRecordCommand();
	
EndProcedure

&AtClient
Procedure StandardSetDeletionMark(Command)
	
	If IsNew() Then
		Return;
	EndIf;
	
	If Modified Then
		If ThisObject.Object.DeletionMark Then
			QuestionText = NStr(
				"ru = 'Для выполнения действия требуется записать изменения файла.
				      |Записать изменения и снять пометку на удаление с файла
				      |""%1""?'; 
				      |en = 'To proceed, please save the file changes.
				      |Do you want to save the changes and clear the deletion mark from file
				      |""%1""?'; 
				      |pl = 'Zmiany w plikach muszą zostać zapisane w celu uruchomienia.
				      |Czy zapisać zmiany i usunąć znacznik usunięcia
				      |z %1 pliku?';
				      |de = 'Um die Aktion auszuführen, müssen Sie die Änderungen in der Datei aufzeichnen.
				      |Die Änderungen aufschreiben und die Löschmarkierung aus der Datei
				      |""%1"" entfernen?';
				      |ro = 'Pentru executarea acțiunii trebuie să înregistrați modificările fișierului.
				      |Înregistrați modificările și scoateți marcajul la ștergere de pe fișierul
				      |""%1""?';
				      |tr = 'Eylem için dosya değişikliklerinin yazılması gerekiyor. 
				      |Değişiklikler yazılsın ve %1 dosyadan silme işleminin 
				      | işareti kaldırılsın mı?'; 
				      |es_ES = 'Cambios del archivo tienen que ser guardados para realizar la acción.
				      |¿Guardar los cambios y quitar la marca de borrar del archivo 
				      |""%1""?'");
		Else
			QuestionText = NStr(
				"ru = 'Для выполнения действия требуется записать изменения файла.
				      |Записать изменения и пометить на удаление файл
				      |""%1""?'; 
				      |en = 'To perform the operation, please save the file changes.
				      |Do you want to save the changes and mark file
				      |""%1"" for deletion?'; 
				      |pl = 'Zmiany w plikach muszą zostać zapisane w celu uruchomienia.
				      |Czy zapisać zmiany i zaznaczyć
				      |%1 plik do usunięcia?';
				      |de = 'Um die Aktion auszuführen, müssen Sie die Änderungen in der Datei aufzeichnen.
				      |Die Änderungen aufschreiben und die Datei zum Löschen markieren
				      |""%1""?';
				      |ro = 'Pentru executarea acțiunii trebuie să înregistrați modificările fișierului.
				      |Înregistrați modificările și marcați la ștergere fișierul
				      |""%1""?';
				      |tr = 'İşlem için dosya değişiklikleri yazılmalıdır. 
				      |Değişiklikler kaydedilsin 
				      | %1 ve dosya silinmek üzere işaretlensin mi?'; 
				      |es_ES = 'Cambios del archivo tienen que ser guardados para realizar la acción.
				      |¿Guardar los cambios y marcar el archivo 
				      |""%1"" para borrar?'");
		EndIf;
	Else
		If ThisObject.Object.DeletionMark Then
			QuestionText = NStr("ru = 'Снять пометку на удаление с файла
			                          |""%1""?'; 
			                          |en = 'Do you want to clear the deletion mark from file
			                          |""%1""?'; 
			                          |pl = 'Usunąć %1 znacznik usunięcia
			                          |z pliku?';
			                          |de = 'Markierung aufheben, um Datei 
			                          |""%1"" zu löschen?';
			                          |ro = 'Scoate marcajul la ștergere de pe fișierul
			                          |""%1""?';
			                          |tr = '
			                          |""%1"" Dosya silme işareti kaldırılsın mı?'; 
			                          |es_ES = '¿Desmarcar el %1 archivo
			                          | desde para borrar?'");
		Else
			QuestionText = NStr("ru = 'Пометить на удаление файл
			                          |""%1""?'; 
			                          |en = 'Do you want to mark file
			                          |""%1"" for deletion?'; 
			                          |pl = 'Zaznacz, aby usunąć plik
			                          |""%1""?';
			                          |de = 'Datei 
			                          |""%1"" zum Löschen markieren?';
			                          |ro = 'Marcați la ștergere fișierul
			                          |""%1""?';
			                          |tr = '
			                          |""%1"" Dosya silinmek üzere işaretlensin mi?'; 
			                          |es_ES = '¿Marcar para borrar el archivo
			                          |""%1""?'");
		EndIf;
	EndIf;
	
	QuestionText = StringFunctionsClientServer.SubstituteParametersToString(
		QuestionText, ThisObject.Object.Ref);
		
	NotifyDescription = New NotifyDescription("StandardSetDeletionMarkAnswerReceived", ThisObject);
	ShowQueryBox(NotifyDescription, QuestionText, QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
EndProcedure

&AtClient
Procedure StandardSetDeletionMarkAnswerReceived(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		ThisObject.Object.DeletionMark = NOT ThisObject.Object.DeletionMark;
		HandleFileRecordCommand();
	EndIf;
	
EndProcedure

// StandardSubsystems.Properties

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, URL = Undefined, StandardProcessing = Undefined)
	
	If CommonClient.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManagerClient = CommonClient.CommonModule("PropertyManagerClient");
		ModulePropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
	EndIf;
	
EndProcedure

// End StandardSubsystems.Properties

///////////////////////////////////////////////////////////////////////////////////
// Digital signature and encryption command handlers.

&AtClient
Procedure Sign(Command)
	
	If IsNew()
		Or ValueIsFilled(Object.BeingEditedBy)
		Or Object.Encrypted Then
		Return;
	EndIf;
	
	If Modified Then
		Write();
	EndIf;
	
	NotifyDescription      = New NotifyDescription("OnGetSignature", ThisObject);
	AdditionalParameters = New Structure("ResultProcessing", NotifyDescription);
	FilesOperationsClient.SignFile(Object.Ref, UUID, AdditionalParameters);
	
EndProcedure

&AtClient
Procedure AddDSFromFile(Command)
	
	If IsNew()
		Or ValueIsFilled(ThisObject.Object.BeingEditedBy)
		Or ThisObject.Object.Encrypted Then
		Return;
	EndIf;
	
	AttachedFile = ThisObject.Object.Ref;
	FilesOperationsInternalClient.AddSignatureFromFile(
		AttachedFile,
		UUID,
		New NotifyDescription("OnGetSignatures", ThisObject));
	
EndProcedure

&AtClient
Procedure SaveWithDigitalSignature(Command)
	
	If IsNew()
		OR ValueIsFilled(ThisObject.Object.BeingEditedBy)
		OR ThisObject.Object.Encrypted Then
		Return;
	EndIf;
	
	FilesOperationsClient.SaveWithDigitalSignature(
		ThisObject.Object.Ref,
		UUID);
	
EndProcedure

&AtClient
Procedure Encrypt(Command)
	
	If IsNew() Or ValueIsFilled(ThisObject.Object.BeingEditedBy) Or ThisObject.Object.Encrypted Then
		Return;
	EndIf;
	
	If Modified Then
		Write();
	EndIf;
	
	FileData = FilesOperationsInternalServerCall.GetFileDataAndVersionsCount(ThisObject.Object.Ref);
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("FileData", FileData);
	Handler = New NotifyDescription("EncryptAfterEncryptAtClient", ThisObject, HandlerParameters);
	
	FilesOperationsInternalClient.Encrypt(
		Handler,
		FileData,
		UUID);
		
EndProcedure

&AtClient
Procedure EncryptAfterEncryptAtClient(Result, ExecutionParameters) Export
	If Not Result.Success Then
		Return;
	EndIf;
	
	WorkingDirectoryName = FilesOperationsInternalClient.UserWorkingDirectory();
	
	FilesArrayInWorkingDirectoryToDelete = New Array;
	
	EncryptServer(
		Result.DataArrayToStoreInDatabase,
		Result.ThumbprintsArray,
		FilesArrayInWorkingDirectoryToDelete,
		WorkingDirectoryName);
	
	FilesOperationsInternalClient.InformOfEncryption(
		FilesArrayInWorkingDirectoryToDelete,
		ExecutionParameters.FileData.Owner,
		ThisObject.Object.Ref);
		
	NotifyChanged(ThisObject.Object.Ref);
	Notify("Write_File", New Structure, ThisObject.Object.Ref);
	
	SetAvaliabilityOfEncryptionList();
	
EndProcedure

&AtClient
Procedure Decrypt(Command)
	
	If IsNew() Or Not ThisObject.Object.Encrypted Then
		Return;
	EndIf;
	
	FileData = FilesOperationsInternalServerCall.GetFileDataAndVersionsCount(ThisObject.Object.Ref);
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("FileData", FileData);
	Handler = New NotifyDescription("DecryptAfterDecryptAtClient", ThisObject, HandlerParameters);
	
	FilesOperationsInternalClient.Decrypt(
		Handler,
		FileData.Ref,
		UUID,
		FileData);
	
EndProcedure

&AtClient
Procedure DecryptAfterDecryptAtClient(Result, ExecutionParameters) Export
	
	If Not Result.Success Then
		Return;
	EndIf;
	WorkingDirectoryName = FilesOperationsInternalClient.UserWorkingDirectory();
	
	DecryptServer(Result.DataArrayToStoreInDatabase, WorkingDirectoryName);
	
	FilesOperationsInternalClient.InformOfDecryption(
		ExecutionParameters.FileData.Owner,
		ThisObject.Object.Ref);
	
	FillEncryptionListAtServer();
	SetAvaliabilityOfEncryptionList();
	
EndProcedure

&AtServer
Procedure FillEncryptionListAtServer()
	FilesOperationsInternal.FillEncryptionList(ThisObject);
EndProcedure

&AtClient
Procedure DigitalSignatureCommandListOpenSignature(Command)
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	ModuleDigitalSignatureClient.OpenSignature(Items.DigitalSignatures.CurrentData);
	
EndProcedure

&AtClient
Procedure VerifyDigitalSignature(Command)
	
	If Items.DigitalSignatures.SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	FileData = FileData(ThisObject.Object.Ref, UUID);
	
	FilesOperationsInternalClient.CheckSignatures(ThisObject,
		FileData.BinaryFileDataRef,
		Items.DigitalSignatures.SelectedRows);
	
EndProcedure

&AtClient
Procedure CheckAll(Command)
	
	FileData = FileData(ThisObject.Object.Ref, UUID);
	
	FilesOperationsInternalClient.CheckSignatures(ThisObject, FileData.BinaryFileDataRef);
	
EndProcedure

&AtClient
Procedure SaveSignature(Command)
	
	If Items.DigitalSignatures.CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Items.DigitalSignatures.CurrentData;
	
	If CurrentData.Object = Undefined Or CurrentData.Object.IsEmpty() Then
		Return;
	EndIf;
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	ModuleDigitalSignatureClient.SaveSignature(CurrentData.SignatureAddress);
	
EndProcedure

&AtClient
Procedure DeleteDS(Command)
	
	NotifyDescription = New NotifyDescription("DeleteDigitalSignatureAnswerReceived", ThisObject);
	ShowQueryBox(NotifyDescription, NStr("ru = 'Удалить выделенные подписи?'; en = 'Do you want to delete the selected signatures?'; pl = 'Usunąć zaznaczone podpisy?';de = 'Löschen Sie die ausgewählten Signaturen?';ro = 'Ștergeți semnăturile selectate?';tr = 'Seçilen imzaları silinsin mi?'; es_ES = '¿Borrar las firmas seleccionadas?'"), QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure DeleteDigitalSignatureAnswerReceived(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.No Then
		Return;
	EndIf;
	
	Write();
	DeleteFromSignatureListAndWriteFile();
	NotifyChanged(ThisObject.Object.Ref);
	Notify("Write_File", New Structure, ThisObject.Object.Ref);
	SetAvaliabilityOfDSCommandsList();
	
EndProcedure

&AtClient
Procedure OpenEncryptionCertificate(Command)
	
	CurrentData = Items.EncryptionCertificates.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	
	If IsBlankString(CurrentData.CertificateAddress) Then
		ModuleDigitalSignatureClient.OpenCertificate(CurrentData.Thumbprint);
	Else
		ModuleDigitalSignatureClient.OpenCertificate(CurrentData.CertificateAddress);
	EndIf;
	
EndProcedure

&AtClient
Procedure SetAvaliabilityOfDSCommandsList()
	
	FilesOperationsInternalClient.SetCommandsAvailabilityOfDigitalSignaturesList(ThisObject);
	
EndProcedure

&AtClient
Procedure SetAvaliabilityOfEncryptionList()
	
	FilesOperationsInternalClient.SetCommandsAvailabilityOfEncryptionCertificatesList(ThisObject);
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////
// Command handlers to support collaboration in operations with files.

&AtClient
Procedure Lock(Command)
	
	If Modified AND Not Write() Then
		Return;
	EndIf;
	
	Handler = New NotifyDescription("ReadAndSetFormItemsAvailability", ThisObject);
	FilesOperationsInternalClient.LockWithNotification(Handler, Object.Ref, UUID);
	
EndProcedure

&AtClient
Procedure Edit(Command)
	
	If IsNew() Then
		Return;
	EndIf;
	
	If ValueIsFilled(ThisObject.Object.BeingEditedBy)
	   AND ThisObject.Object.BeingEditedBy <> CurrentUser Then
		Return;
	EndIf;
	
	If Modified AND Not Write() Then
		Return;
	EndIf;
	
	FileData = FileData(ThisObject.Object.Ref, UUID);
	
	If ValueIsFilled(ThisObject.Object.BeingEditedBy) Then
		FilesOperationsInternalClient.EditFile(Undefined,
			FileData, UUID);
	Else
		FilesOperationsInternalClient.EditFile(Undefined,
			FileData, UUID);
		
		UpdateObject();
		
		NotifyChanged(ThisObject.Object.Ref);
		Notify("Write_File", New Structure, ThisObject.Object.Ref);
	EndIf;
	
EndProcedure

&AtClient
Procedure EndEdit(Command)
	
	If IsNew()
		Or Not ValueIsFilled(ThisObject.Object.BeingEditedBy)
		Or ThisObject.Object.BeingEditedBy <> CurrentUser Then
			Return;
	EndIf;
	
	FileData = FilesOperationsInternalServerCall.FileData(ThisObject.Object.Ref);
	
	NotifyDescription = New NotifyDescription("EndEditingPuttingCompleted", ThisObject);
	FileUpdateParameters = FilesOperationsInternalClient.FileUpdateParameters(NotifyDescription, FileData.Ref, UUID);
	FileUpdateParameters.StoreVersions = FileData.StoreVersions;
	If Not CanCreateFileVersions Then
		FileUpdateParameters.Insert("CreateNewVersion", False);
	EndIf;
	FileUpdateParameters.CurrentUserEditsFile = FileData.CurrentUserEditsFile;
	FileUpdateParameters.BeingEditedBy = FileData.BeingEditedBy;
	FilesOperationsInternalClient.EndEditAndNotify(FileUpdateParameters);
	
EndProcedure

&AtClient
Procedure EndEditingPuttingCompleted(FileInfo, AdditionalParameters) Export
	
	NotifyChanged(ThisObject.Object.Ref);
	Notify("Write_File", New Structure, ThisObject.Object.Ref);
	SetButtonsAvailability(ThisObject, Items);
	
EndProcedure

&AtClient
Procedure Unlock(Command)
	
	If IsNew()
	 OR NOT ValueIsFilled(ThisObject.Object.BeingEditedBy)
	 OR ThisObject.Object.BeingEditedBy <> CurrentUser Then
		Return;
	EndIf;
	
	UnlockFile();
	NotifyChanged(ThisObject.Object.Ref);
	Notify("Write_File", New Structure("Event", "EditingCanceled"), ThisObject.Object.Ref);
	
EndProcedure

&AtClient
Procedure SaveChanges(Command)
	
	If Modified Then
		Write();
	EndIf;
	
	Handler = New NotifyDescription("ReadAndSetFormItemsAvailability", ThisObject);
	
	FilesOperationsInternalClient.SaveFileChangesWithNotification(Handler,
		ThisObject.Object.Ref, UUID);
	
EndProcedure

// StandardSubsystems.Properties

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	If Common.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManager = Common.CommonModule("PropertyManager");
		ModulePropertyManager.UpdateAdditionalAttributesItems(ThisObject);
	EndIf;
	
EndProcedure

&AtServer
Procedure PropertiesExecuteDeferredInitialization()
	
	If Common.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManager = Common.CommonModule("PropertyManager");
		ModulePropertyManager.FillAdditionalAttributesInForm(ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	
	If CommonClient.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManagerClient = CommonClient.CommonModule("PropertyManagerClient");
		ModulePropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	
	If CommonClient.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManagerClient = CommonClient.CommonModule("PropertyManagerClient");
		ModulePropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
	EndIf;
	
EndProcedure

// End StandardSubsystems.Properties

&AtClient
Procedure Send(Command)
	
	If ValueIsFilled(ThisObject.Object.Ref)
		Or Write() Then
		Files = CommonClientServer.ValueInArray(ThisObject.Object.Ref);
		FilesOperationsInternalClient.SendFilesViaEmail(Files, UUID, SendOptions, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure PrintFiles(Command)
	
	If Not CommonClient.IsWindowsClient() Then
		ShowMessageBox(, NStr("ru = 'Печать файлов возможна только в Windows.'; en = 'Printing files is available only on Windows.'; pl = 'Drukowanie plików jest możliwe tylko w Windows.';de = 'Dateien können nur unter Windows gedruckt werden.';ro = 'Fișierele pot fi imprimate numai în Windows.';tr = 'Dosya yalnızca Windows''ta yazdırılabilir.'; es_ES = 'Es posible imprimir los archivos solo en Windows.'"));
		Return;
	EndIf;
	
	If ValueIsFilled(ThisObject.Object.Ref)
		Or Write() Then
		Files = CommonClientServer.ValueInArray(ThisObject.Object.Ref);
		FilesOperationsClient.PrintFiles(Files, ThisObject.UUID);
	EndIf;

EndProcedure

&AtClient
Procedure PrintWithStamp(Command)
	
	If ValueIsFilled(ThisObject.Object.Ref)
		Or Write() Then
		DocumentWithStamp = FilesOperationsInternalServerCall.SpreadsheetDocumentWithStamp(ThisObject.Object.Ref, ThisObject.Object.Ref);
		FilesOperationsInternalClient.PrintFileWithStamp(DocumentWithStamp);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure RefreshTitle()
	
	If TypeOf(Object.FileOwner) = Type("CatalogRef.FilesFolders") Then
		FileType = NStr("ru = 'Файл'; en = 'File'; pl = 'Plik';de = 'Datei';ro = 'Fișier';tr = 'Dosya'; es_ES = 'Archivo'");
	Else
		FileType = NStr("ru = 'Присоединенный файл'; en = 'Attached file'; pl = 'Załączony plik';de = 'Angehängte Dateien';ro = 'Fișier atașat';tr = 'Ekli dosya'; es_ES = 'Archivo adjuntado'");
	EndIf;
	
	If ValueIsFilled(ThisObject.Object.Ref) Then
		Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = '%1 (%2)'; en = '%1 (%2)'; pl = '%1 (%2)';de = '%1 (%2)';ro = '%1 (%2)';tr = '%1 (%2)'; es_ES = '%1 (%2)'"), String(ThisObject.Object.Ref), FileType);
	Else
		Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = '%1 (Создание)'; en = '%1 (Create)'; pl = '%1 (Utworzenie)';de = ' %1 (Erstellung)';ro = '%1 (Creare)';tr = '%1 (oluşturma)'; es_ES = '%1 (Creación)'"), FileType);
	EndIf;
	
EndProcedure

&AtClient
Procedure DisplayAdditionalDataTabs()
	
	If Items.AdditionalAttributesGroup.ChildItems.Count() > 0 Then
		BlankDecoration = Items.Find("Properties_EmptyDecoration");
		If BlankDecoration <> Undefined Then
			AdditionalAttributesVisibility = BlankDecoration.Visible;
		Else
			AdditionalAttributesVisibility = True;
		EndIf;
	Else
		AdditionalAttributesVisibility = False;
	EndIf;
	
	UseTabs = AdditionalAttributesVisibility Or Items.DigitalSignaturesGroup.Visible Or Items.EncryptionCertificatesGroup.Visible;
	Items.AdditionalPageDataGroup.PagesRepresentation =
		?(UseTabs , FormPagesRepresentation.TabsOnTop, FormPagesRepresentation.None);

EndProcedure

&AtServerNoContext
Function FileData(Val AttachedFile,
                            Val FormID = Undefined,
                            Val GetBinaryDataRef = True)
	
	Return FilesOperations.FileData(
		AttachedFile, FormID, GetBinaryDataRef);
	
EndFunction

&AtClient
Procedure OpenFileForViewing()
	
	If IsNew() Then
		Return;
	EndIf;
	
	FileBeingEdited = ValueIsFilled(ThisObject.Object.BeingEditedBy)
		AND ThisObject.Object.BeingEditedBy = CurrentUser;
	
	FileData = FilesOperationsInternalServerCall.FileDataToOpen(ThisObject.Object.Ref, Undefined, UUID);
	
	FilesOperationsClient.OpenFile(FileData, FileBeingEdited);
	
EndProcedure

&AtClient
Procedure OpenFileDirectory()
	
	If IsNew()
		OR ThisObject.Object.Encrypted Then
		Return;
	EndIf;
	
	FileData = FilesOperationsInternalServerCall.FileDataToOpen(ThisObject.Object.Ref, Undefined, UUID);
	FilesOperationsClient.OpenFileDirectory(FileData);
	
EndProcedure

&AtClient
Procedure SaveAs()
	
	If IsNew() Then
		Return;
	EndIf;
	
	FileData = FilesOperationsInternalServerCall.FileDataToSave(ThisObject.Object.Ref, Undefined, UUID);
	FilesOperationsInternalClient.SaveAs(Undefined, FileData, Undefined);
	
EndProcedure

&AtServer
Procedure DeleteFromSignatureListAndWriteFile()
	
	If Not Common.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;
	
	ModuleDigitalSignature = Common.CommonModule("DigitalSignature");
	
	RowIndexes = New Array;
	For Each SelectedRowNumber In Items.DigitalSignatures.SelectedRows Do
		RowToDelete = DigitalSignatures.FindByID(SelectedRowNumber);
		RowIndexes.Add(RowToDelete.SequenceNumber);
	EndDo;
	
	ModuleDigitalSignature.DeleteSignature(Object.Ref, RowIndexes, UUID);
	Read();
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetButtonsAvailability(Form, Items)
	
	AllCommandNames = AllFormCommandsNames();
	AvailableCommandsNames = AvailableFormCommands(Form);
		
	If Form.DigitalSignatures.Count() = 0 Then
		MakeCommandUnavailable(AvailableCommandsNames, "OpenSignature");
	EndIf;
	
	For Each FormItem In Items Do
		If TypeOf(FormItem) <> Type("FormButton") Then
			Continue;
		EndIf;
		If AllCommandNames.Find(FormItem.CommandName) <> Undefined Then
			FormItem.Enabled = False;
		EndIf;
	EndDo;
	
	For Each FormItem In Items Do
		If TypeOf(FormItem) <> Type("FormButton") Then
			Continue;
		EndIf;
		If AvailableCommandsNames.Find(FormItem.CommandName) <> Undefined Then
			FormItem.Enabled = True;
		EndIf;
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Function AllFormCommandsNames()
	
	CommandsNames = FileChangeCommandsNames();
	CommonClientServer.SupplementArray(CommandsNames, OtherCommandsNames()); 
	Return CommandsNames;
	
EndFunction

&AtClientAtServerNoContext
Function OtherCommandsNames()
	
	CommandsNames = New Array;
	
	// Simple commands that are available to any user that reads the files
	CommandsNames.Add("SaveWithDigitalSignature");
	
	CommandsNames.Add("OpenCertificate");
	CommandsNames.Add("OpenSignature");
	CommandsNames.Add("VerifyDigitalSignature");
	CommandsNames.Add("CheckAll");
	CommandsNames.Add("SaveSignature");
	
	CommandsNames.Add("OpenFileDirectory");
	CommandsNames.Add("OpenFileForViewing");
	CommandsNames.Add("SaveAs");
	
	Return CommandsNames;
	
EndFunction

&AtClientAtServerNoContext
Function FileChangeCommandsNames()
	
	CommandsNames = New Array;
	
	CommandsNames.Add("Sign");
	CommandsNames.Add("AddDSFromFile");
	
	CommandsNames.Add("DeleteDigitalSignature");
	
	CommandsNames.Add("Edit");
	CommandsNames.Add("Lock");
	CommandsNames.Add("EndEdit");
	CommandsNames.Add("Unlock");
	CommandsNames.Add("SaveChanges");
	
	CommandsNames.Add("Encrypt");
	CommandsNames.Add("Decrypt");
	
	CommandsNames.Add("StandardCopy");
	CommandsNames.Add("UpdateFromFileOnHardDrive");
	
	CommandsNames.Add("StandardWrite");
	CommandsNames.Add("StandardWriteAndClose");
	CommandsNames.Add("StandardSetDeletionMark");
	
	CommandsNames.Add("Copy");
	
	
	Return CommandsNames;
	
EndFunction

&AtClientAtServerNoContext
Function AvailableFormCommands(Form)
	
	IsNewFile = Form.Object.Ref.IsEmpty();
	
	If IsNewFile Then
		CommandsNames = New Array;
		CommandsNames.Add("StandardWrite");
		CommandsNames.Add("StandardWriteAndClose");
		Return CommandsNames;
	EndIf;
	
	CommandsNames = AllFormCommandsNames();
	
	FileToEditInCloud = Form.FileToEditInCloud;
	FileBeingEdited = ValueIsFilled(Form.Object.BeingEditedBy) Or FileToEditInCloud;
	CurrentUserEditsFile = Form.Object.BeingEditedBy = Form.CurrentUser;
	FileSigned = Form.Object.SignedWithDS;
	FileEncrypted = Form.Object.Encrypted;
	
	If FileBeingEdited Then
		If CurrentUserEditsFile Then
			MakeCommandUnavailable(CommandsNames, "UpdateFromFileOnHardDrive");
		Else
			MakeCommandUnavailable(CommandsNames, "EndEdit");
			MakeCommandUnavailable(CommandsNames, "Unlock");
			MakeCommandUnavailable(CommandsNames, "Edit");
		EndIf;
		MakeCommandUnavailable(CommandsNames, "Lock");
		
		MakeDSCommandsUnavailable(CommandsNames);
		
		MakeCommandUnavailable(CommandsNames, "Encrypt");
		MakeCommandUnavailable(CommandsNames, "Decrypt");
	Else
		MakeCommandUnavailable(CommandsNames, "EndEdit");
		MakeCommandUnavailable(CommandsNames, "Unlock");
		MakeCommandUnavailable(CommandsNames, "SaveChanges");
	EndIf;
	
	If FileSigned Then
		MakeCommandUnavailable(CommandsNames, "EndEdit");
		MakeCommandUnavailable(CommandsNames, "Unlock");
		MakeCommandUnavailable(CommandsNames, "Edit");
		MakeCommandUnavailable(CommandsNames, "UpdateFromFileOnHardDrive");
	Else
		MakeCommandUnavailable(CommandsNames, "OpenCertificate");
		MakeCommandUnavailable(CommandsNames, "OpenSignature");
		MakeCommandUnavailable(CommandsNames, "VerifyDigitalSignature");
		MakeCommandUnavailable(CommandsNames, "CheckAll");
		MakeCommandUnavailable(CommandsNames, "SaveSignature");
		MakeCommandUnavailable(CommandsNames, "DeleteDigitalSignature");
		MakeCommandUnavailable(CommandsNames, "SaveWithDigitalSignature");
	EndIf;
	
	If FileEncrypted Then
		MakeDSCommandsUnavailable(CommandsNames);
		If Not FileBeingEdited Then
			MakeCommandUnavailable(CommandsNames, "Unlock");
			MakeCommandUnavailable(CommandsNames, "EndEdit");
		EndIf;
		
		MakeCommandUnavailable(CommandsNames, "UpdateFromFileOnHardDrive");
		MakeCommandUnavailable(CommandsNames, "Encrypt");
		MakeCommandUnavailable(CommandsNames, "OpenFileDirectory");
		MakeCommandUnavailable(CommandsNames, "Sign");
	Else
		MakeCommandUnavailable(CommandsNames, "Decrypt");
	EndIf;
	
	If FileToEditInCloud Then
		MakeCommandUnavailable(CommandsNames, "StandardCopy");
		MakeCommandUnavailable(CommandsNames, "StandardSetDeletionMark");
		
		MakeCommandUnavailable(CommandsNames, "StandardWriteAndClose");
		MakeCommandUnavailable(CommandsNames, "StandardWrite");
		MakeCommandUnavailable(CommandsNames, "Copy");
		MakeCommandUnavailable(CommandsNames, "SaveChanges");
		MakeCommandUnavailable(CommandsNames, "UpdateFromFileOnHardDrive");
		
	EndIf;
	
	If Form.ReadOnly Then
		MakeDSCommandsUnavailable(CommandsNames);
	EndIf;
	
	Return CommandsNames;
	
EndFunction

&AtClientAtServerNoContext
Procedure MakeDSCommandsUnavailable(Val CommandsNames)
	
	MakeCommandUnavailable(CommandsNames, "Sign");
	MakeCommandUnavailable(CommandsNames, "AddDSFromFile");
	MakeCommandUnavailable(CommandsNames, "SaveWithDigitalSignature");
	
EndProcedure

&AtClientAtServerNoContext
Procedure MakeCommandUnavailable(CommandsNames, CommandName)
	
	CommonClientServer.DeleteValueFromArray(CommandsNames, CommandName);
	
EndProcedure

&AtServer
Procedure EncryptServer(DataArrayToStoreInDatabase,
                            ThumbprintsArray,
                            FilesArrayInWorkingDirectoryToDelete,
                            WorkingDirectoryName)
	
	Encrypt = True;
	
	FilesOperationsInternal.WriteEncryptionInformation(
		ThisObject.Object.Ref,
		Encrypt,
		DataArrayToStoreInDatabase,
		UUID,
		WorkingDirectoryName,
		FilesArrayInWorkingDirectoryToDelete,
		ThumbprintsArray);
		
	UpdateInfoOfObjectCertificates();
	
EndProcedure

&AtServer
Procedure DecryptServer(DataArrayToStoreInDatabase,
                             WorkingDirectoryName)
	
	Encrypt = False;
	ThumbprintsArray = New Array;
	FilesArrayInWorkingDirectoryToDelete = New Array;
	
	FilesOperationsInternal.WriteEncryptionInformation(
		ThisObject.Object.Ref,
		Encrypt,
		DataArrayToStoreInDatabase,
		UUID,
		WorkingDirectoryName,
		FilesArrayInWorkingDirectoryToDelete,
		ThumbprintsArray);
		
	UpdateInfoOfObjectCertificates();
	
EndProcedure

&AtServer
Procedure UpdateObject()
	Read();
EndProcedure

&AtServer
Procedure UnlockFile()
	
	ObjectToWrite = FormAttributeToValue("Object");
	FilesOperationsInternal.UnlockFile(ObjectToWrite);
	ValueToFormAttribute(ObjectToWrite, "Object");
	
EndProcedure

&AtClient
Function HandleFileRecordCommand()
	
	If IsBlankString(ThisObject.Object.Description) Then
		CommonClient.MessageToUser(
			NStr("ru = 'Для продолжения укажите имя файла.'; en = 'To proceed, plaese provide the file name.'; pl = 'Aby kontynuować, podaj nazwę pliku.';de = 'Um fortzufahren, geben Sie den Dateinamen an.';ro = 'Pentru a continua, specificați numele fișierului.';tr = 'Devam etmek için dosya adını belirleyin.'; es_ES = 'Para continuar, especificar el nombre del archivo.'"), , "Description", "Object");
		Return False;
	EndIf;
	
	Try
		FilesOperationsInternalClient.CorrectFileName(ThisObject.Object.Description);
	Except
		CommonClient.MessageToUser(
			BriefErrorDescription(ErrorInfo()), ,"Description", "Object");
		Return False;
	EndTry;
	
	Write();

	Modified = False;
	RepresentDataChange(ThisObject.Object.Ref, DataChangeType.Update);
	NotifyChanged(ThisObject.Object.Ref);
	
	Notify("Write_File",
	           New Structure("IsNew", FileCreated),
	           ThisObject.Object.Ref);
	
	SetAvaliabilityOfDSCommandsList();
	SetAvaliabilityOfEncryptionList();
	
	If DescriptionBeforeWrite <> Object.Description Then
		// update file in cache
		If ValueIsFilled(Object.CurrentVersion) Then
			FilesOperationsInternalClient.RefreshInformationInWorkingDirectory(
				Object.CurrentVersion, Object.Description);
		Else
			FilesOperationsInternalClient.RefreshInformationInWorkingDirectory(
				Object.Ref, Object.Description);
		EndIf;
		
		DescriptionBeforeWrite = Object.Description;
	EndIf;
	
	Return True;
	
EndFunction

&AtServerNoContext
Procedure UnlockObject(Val Ref, Val UUID)
	
	UnlockDataForEdit(Ref, UUID);
	
EndProcedure

// Continue the SignDSFile procedure.
// It is called from the DigitalSignature subsystem after signing data for non-standard way of 
// adding a signature to the object.
//
&AtClient
Procedure OnGetSignature(ExecutionParameters, Context) Export
	
	UpdateInfoOfObjectSignature();
	SetAvaliabilityOfDSCommandsList();
	
EndProcedure

// Continue the SignDSFile procedure.
// It is called from the DigitalSignature subsystem after preparing signatures from files for 
// non-standard way of adding a signature to the object.
//
&AtClient
Procedure OnGetSignatures(ExecutionParameters, Context) Export
	
	UpdateInfoOfObjectSignature();
	SetAvaliabilityOfDSCommandsList();
	
EndProcedure

&AtServer
Procedure UpdateInfoOfObjectSignature()
	
	FileObject = ThisObject.Object.Ref.GetObject();
	ValueToFormAttribute(FileObject, "Object");
	FilesOperationsInternal.FillSignatureList(ThisObject);
	SetButtonsAvailability(ThisObject, Items);
	
EndProcedure

&AtServer
Procedure UpdateInfoOfObjectCertificates()
	
	FileObject = ThisObject.Object.Ref.GetObject();
	ValueToFormAttribute(FileObject, "Object");
	FilesOperationsInternal.FillEncryptionList(ThisObject);
	SetButtonsAvailability(ThisObject, Items);
	
EndProcedure

&AtClient
Procedure ReadAndSetFormItemsAvailability(Result, AdditionalParameters) Export
	
	Read();
	SetButtonsAvailability(ThisObject, Items);
	
EndProcedure

&AtClient
Procedure ReadSignaturesCertificates()
	
	If DigitalSignatures.Count() = 0 Then
		Return;
	EndIf;
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;
	
	Context = New Structure;
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	
	If ModuleDigitalSignatureClient.VerifyDigitalSignaturesOnTheServer() Then
		Return;
	EndIf;
	
	BeginAttachingCryptoExtension(New NotifyDescription(
		"ReadSignaturesCertificatesAfterAttachExtension", ThisObject, Context));
	
EndProcedure

// Continue the ReadSignaturesCertificates procedure.
&AtClient
Procedure ReadSignaturesCertificatesAfterAttachExtension(Attached, Context) Export
	
	If Not Attached Then
		Return;
	EndIf;
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	
	ModuleDigitalSignatureClient.CreateCryptoManager(New NotifyDescription(
			"ReadSignaturesCertificatesAfterCreateCryptoManager", ThisObject, Context),
		"GetCertificates", False);
	
EndProcedure

// Continue the ReadSignaturesCertificates procedure.
&AtClient
Procedure ReadSignaturesCertificatesAfterCreateCryptoManager(Result, Context) Export
	
	If TypeOf(Result) <> Type("CryptoManager") Then
		Return;
	EndIf;
	
	Context.Insert("IndexOf", -1);
	Context.Insert("CryptoManager", Result);
	ReadSignaturesCertificatesLoopStart(Context);
	
EndProcedure

// Continue the ReadSignaturesCertificates procedure.
&AtClient
Procedure ReadSignaturesCertificatesLoopStart(Context)
	
	If DigitalSignatures.Count() <= Context.IndexOf + 1 Then
		Return;
	EndIf;
	Context.IndexOf = Context.IndexOf + 1;
	Context.Insert("TableRow", DigitalSignatures[Context.IndexOf]);
	
	If ValueIsFilled(Context.TableRow.Thumbprint) Then
		ReadSignaturesCertificatesLoopStart(Context);
		Return;
	EndIf;
	
	// The signature was not read when writing the object
	Signature = GetFromTempStorage(Context.TableRow.SignatureAddress);
	
	If Not ValueIsFilled(Signature) Then
		ReadSignaturesCertificatesLoopStart(Context);
		Return;
	EndIf;
	
	Context.CryptoManager.BeginGettingCertificatesFromSignature(New NotifyDescription(
			"ReadSignaturesCertificatesLoopAfterGetCertificatesFromSignature", ThisObject, Context,
			"ReadSignatureCertificatesLoopAfterGetCertificatesFromSignatureError", ThisObject),
		Signature);
	
EndProcedure

// Continue the ReadSignaturesCertificates procedure.
&AtClient
Procedure ReadSignatureCertificatesLoopAfterGetCertificatesFromSignatureError(ErrorInformation, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	ReadSignaturesCertificatesLoopStart(Context);
	
EndProcedure

// Continue the ReadSignaturesCertificates procedure.
&AtClient
Procedure ReadSignaturesCertificatesLoopAfterGetCertificatesFromSignature(Certificates, Context) Export
	
	If Certificates.Count() = 0 Then
		ReadSignaturesCertificatesLoopStart(Context);
		Return;
	EndIf;
	
	Context.Insert("Certificate", Certificates[0]);
	
	Context.Certificate.BeginUnloading(New NotifyDescription(
		"ReadSignaturesCertificatesLoopAfterExportCertificate", ThisObject, Context,
		"ReadSignatureCertificatesLoopAfterExportCertificateError", ThisObject));
	
EndProcedure

// Continue the ReadSignaturesCertificates procedure.
&AtClient
Procedure ReadSignatureCertificatesLoopAfterExportCertificateError(ErrorInformation, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	ReadSignaturesCertificatesLoopStart(Context);
	
EndProcedure

// Continue the ReadSignaturesCertificates procedure.
&AtClient
Procedure ReadSignaturesCertificatesLoopAfterExportCertificate(CertificateData, Context) Export
	
	TableRow = Context.TableRow;
	
	TableRow.Thumbprint = Base64String(Context.Certificate.Thumbprint);
	TableRow.CertificateAddress = PutToTempStorage(CertificateData, UUID);
	TableRow.CertificateOwner = Context.ModuleDigitalSignature.SubjectPresentation(Context.Certificate);
	
	ReadSignaturesCertificatesLoopStart(Context);
	
EndProcedure

&AtClient
Function IsNew()
	
	Return ThisObject.Object.Ref.IsEmpty();
	
EndFunction

&AtClient
Procedure UpdateFromFileOnHardDriveCompletion(Result, ExecutionParameters) Export
	UpdateObjectDataAtServer();
	NotifyChanged(ThisObject.Object.Ref);
	Notify("Write_File", New Structure, ThisObject.Object.Ref);
EndProcedure

&AtServer
Procedure UpdateObjectDataAtServer()
	
	ValueToFormAttribute(ThisObject.Object.Ref.GetObject(), "Object");
	ModificationDate = ToLocalTime(ThisObject.Object.UniversalModificationDate);
	
EndProcedure

&AtClient
Procedure OnChangeSigningOrEncryptionUsage()
	
	OnChangeUseSignOrEncryptionAtServer();
	DisplayAdditionalDataTabs();
	
EndProcedure

&AtServer
Procedure OnChangeUseSignOrEncryptionAtServer()
	
	FilesOperationsInternal.CryptographyOnCreateFormAtServer(ThisObject, False);
	
EndProcedure

&AtClient
Procedure GroupAdditionalPageDataOnChangePage(Item, CurrentPage)
	
	If CommonClient.SubsystemExists("StandardSubsystems.Properties")
		AND CurrentPage.Name = "AdditionalAttributesGroup"
		AND Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		ModulePropertyManagerClient = CommonClient.CommonModule("PropertyManagerClient");
		ModulePropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
EndProcedure

&AtServer
Procedure RefreshFullPath()
	If TypeOf(Object.FileOwner) = Type("CatalogRef.FilesFolders") Then
		
		FolderParent = Object.FileOwner;
		
		If ValueIsFilled(FolderParent) Then
			
			FullPath = "";
			
			While ValueIsFilled(FolderParent) Do
				
				If Not IsBlankString(FullPath) Then
					FullPath = "\" + FullPath;
				EndIf;
				
				FullPath = String(FolderParent) + FullPath;
				
				FolderParent = Common.ObjectAttributeValue(FolderParent, "Parent");
				If Not ValueIsFilled(FolderParent) Then
					Break;
				EndIf;
				
			EndDo;
			
			Items.FileOwner.ToolTip = FullPath;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure CreateVersionCopy(Destination, Source)
	
	If Source.CurrentVersion.IsEmpty() Then
		Return;
	EndIf;
		
	FileStorage = Undefined;
	If Source.CurrentVersion.FileStorageType = Enums.FileStorageTypes.InInfobase Then
		FileStorage = FilesOperations.FileFromInfobaseStorage(Source.CurrentVersion);
	EndIf;
	
	FileInfo = FilesOperationsClientServer.FileInfo("FileWithVersion");
	FileInfo.BaseName = Object.Description;
	FileInfo.Size = Source.CurrentVersion.Size;
	FileInfo.ExtensionWithoutPoint = Source.CurrentVersion.Extension;
	FileInfo.TempFileStorageAddress = FileStorage;
	FileInfo.TempTextStorageAddress = Source.CurrentVersion.TextStorage;
	FileInfo.RefToVersionSource = Source.CurrentVersion;
	FileInfo.Encrypted = Source.Encrypted;
	
	Version = FilesOperationsInternal.CreateVersion(Destination, FileInfo);
	FilesOperationsInternal.UpdateVersionInFile(
		Destination, Version, Source.CurrentVersion.TextStorage, UUID);
	Read();
	
EndProcedure

&AtServer
Procedure UpdateCloudServiceNote(AttachedFile)
	
	NoteVisibility = False;
	
	If GetFunctionalOption("UseFileSync") Then
		
		SynchronizationInfo = FilesOperationsInternal.SynchronizationInfo(Object.FileOwner);
		
		If SynchronizationInfo.Count() > 0 Then
			
			Account = SynchronizationInfo.Account;
			NoteVisibility = True;
			
			FolderAddressInCloudService = FilesOperationsInternalClientServer.AddressInCloudService(
				SynchronizationInfo.Service, SynchronizationInfo.Href);
				
			StringParts = New Array;
			StringParts.Add(NStr("ru = 'Файл доступен только для просмотра, работа с ним ведется в облачном сервисе'; en = 'This is a read-only file. It is stored in cloud service'; pl = 'Plik jest dostępny tylko do wglądu, praca z nim jest prowadzona w serwisie w chmurze';de = 'Die Datei steht nur zur Ansicht zur Verfügung, die Bearbeitung erfolgt im Cloud-Service';ro = 'Fișierul este accesibil numai pentru vizualizare, lucrul cu el este ținut în cloud service';tr = 'Dosya yalnızca salt okunur olarak kullanılabilir, bulut hizmeti ile çalışır.'; es_ES = 'El archivo está disponible solo para ver, se usa en el servicio de nube'"));
			StringParts.Add(" ");
			StringParts.Add(New FormattedString(SynchronizationInfo.AccountDescription,,,, FolderAddressInCloudService));
			StringParts.Add(".  ");
			Items.NoteDecoration.Title = New FormattedString(StringParts);
			
			Items.DecorationPictureSyncStatus.Visible = NOT SynchronizationInfo.Synchronized;
			
			
			StringParts.Clear();
			StringParts.Add(NStr("ru = 'Синхронизирован'; en = 'Synchronized on'; pl = 'Synchronizowany';de = 'Synchronisiert';ro = 'Sincronizat';tr = 'Eşleşmiş'; es_ES = 'Sincronizado'"));
			StringParts.Add(": ");
			StringParts.Add(New FormattedString(Format(SynchronizationInfo.SynchronizationDate, "DLF=DD"),,,, "OpenJournal"));
			Items.DecorationSyncDate.Title = New FormattedString(StringParts);
			
		EndIf;
		
	EndIf;
	
	Items.CloudServiceNoteGroup.Visible = NoteVisibility;
	
EndProcedure

&AtServerNoContext
Function EventLogFilterData(Account)
	Return FilesOperationsInternal.EventLogFilterData(Account);
EndFunction

#EndRegion
