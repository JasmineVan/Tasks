///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var RefreshInterface;

#EndRegion

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not Common.SubsystemExists("StandardSubsystems.FilesOperations") Then
		Raise NStr("ru = 'Не внедрена подсистема Работа с файлами.
			|Рекомендуется отключить видимость этой панели.'; 
			|en = 'The ""Stored files"" subsystem is not implemented.
			|It is recommended that you disable visibility of this panel.'; 
			|pl = 'Nie został wdrożony podsystem Praca z plikami.
			|Zaleca się wyłączyć widoczność tego panelu.';
			|de = 'Das Dateimanagement-Subsystem ist nicht implementiert.
			|Es wird empfohlen, die Sichtbarkeit dieses Bedienfelds zu deaktivieren.';
			|ro = 'Nu este implementat subsistemul Lucrul cu fișierele.
			|Recomandăm să dezactivați vizibilitatea acestei bare.';
			|tr = 'Dosyalarla çalışma alt sistem entegre edilmedi. 
			|Bu panelin görünürlüğünü devre dışı bırakılması önerilir.'; 
			|es_ES = 'No se ha integrado el subsistema Trabajo con archivos.
			|Se recomienda desactivar la visibilidad de esta barra.'");
	EndIf;
	
	IsSystemAdministrator = Users.IsFullUser(, True);
	DataSeparationEnabled = Common.DataSeparationEnabled();
	
	ModuleFilesOperations = Common.CommonModule("FilesOperations");
	DenyUploadFilesByExtension  = ConstantsSet.DenyUploadFilesByExtension;	
	MaxFileSize              = ModuleFilesOperations.MaxFileSizeCommon() / (1024*1024);
	MaxDataAreaFileSize = ModuleFilesOperations.MaxFileSize() / (1024*1024);
	If DataSeparationEnabled Then
		Items.MaxFileSize.MaxValue = MaxFileSize;
	EndIf;

	Items.StoreFilesInVolumesOnDiskGroup.Visible       = IsSystemAdministrator;
	Items.FilesStorageVolumeCatalogGroup.Visible    = IsSystemAdministrator;
	Items.CommonParametersForAllDataAreas.Visible   = IsSystemAdministrator AND DataSeparationEnabled;
	Items.TextFilesExtensionsListGroup.Visible = Not DataSeparationEnabled;
	
	// Update items states.
	SetAvailability();
	
	ApplicationSettingsOverridable.FilesOperationSettingsOnCreateAtServer(ThisObject);
	
	If Common.IsMobileClient() Then
		Items.TestFilesExtensionsList.TitleLocation = FormItemTitleLocation.Top;
		Items.FilesExtensionsListDocumentDataAreas.TitleLocation = FormItemTitleLocation.Top;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	If Exit Then
		Return;
	EndIf;
	UpdateApplicationInterface();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure StoreFilesInVolumesOnHardDiskOnChange(Item)
	
	PreviousValue = Not ConstantsSet.StoreFilesInVolumesOnHardDrive;
	
	Try
		PermissionRequestsToUseExternalResources = 
			PermissionRequestsToUseExternalResourcesOfFilesStorageVolumes(
				ConstantsSet.StoreFilesInVolumesOnHardDrive);
		
		NotificationProcessing = New NotifyDescription("StoreFilesInVolumesOnHardDiskOnChangeCompletion", ThisObject, Item);
		If CommonClient.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
			ModuleSafeModeManagerClient = CommonClient.CommonModule("SafeModeManagerClient");
			ModuleSafeModeManagerClient.ApplyExternalResourceRequests(
				PermissionRequestsToUseExternalResources, ThisObject, NotificationProcessing);
		Else
			ExecuteNotifyProcessing(NotificationProcessing, DialogReturnCode.OK);
		EndIf;
		
		If Not HasFilesStorageVolumes() AND ConstantsSet.StoreFilesInVolumesOnHardDrive Then
			ShowMessageBox(, NStr("ru = 'Включено хранение файлов в томах на диске, но тома еще не настроены.
				|Добавляемые файлы будут сохраняться в информационной базе до тех пор, пока не будет настроен хотя бы один том хранения файлов.'; 
				|en = 'File storage in volumes on the hard drive is enabled but volumes are not configured yet.
				|Added files will be saved to the infobase until at least one file storage volume is configured.'; 
				|pl = 'Włączono przechowywanie plików w woluminach na dysku, ale woluminy nie zostały jeszcze skonfigurowane.
				|Dodawane pliki będą zapisywane w bazie informacyjnej, dopóki nie zostanie skonfigurowany przynajmniej jeden wolumin przechowywania plików.';
				|de = 'Die Dateiablage in Volumen auf der Festplatte ist aktiviert, aber die Volumen sind noch nicht konfiguriert.
				|Hinzugefügte Dateien werden in der Informationsdatenbank gespeichert, bis mindestens ein Dateivolumen konfiguriert ist.';
				|ro = 'Este activată stocarea fișierelor în volume pe disc, dar volumele încă nu sunt setat.
				|Fișierele adăugate vor fi salvate în baza de informații până când nu va fi setat cel puțin un volum de stocare a fișierelor.';
				|tr = 'Dosyaları disk birimlerinde depolamaya izin verilir, ancak birimler henüz yapılandırılmamıştır. 
				|Eklenen dosyalar, en az bir dosya depolama birimi yapılandırılıncaya kadar veritabanında saklanır.'; 
				|es_ES = 'Está activado la guarda de los archivos en los volúmenes en el disco, pero los volúmenes todavía no están ajustados.
				|Los archivos añadidos se guardarán en la base de información hasta que se ajuste aunque sea un volumen de la guarda de archivos.'"));
		EndIf;
	Except
		ConstantsSet.StoreFilesInVolumesOnHardDrive = PreviousValue;
		Raise;
	EndTry;
	
EndProcedure

&AtClient
Procedure ProhibitFilesImportByExtensionOnChange(Item)
	
	If Not DenyUploadFilesByExtension Then
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("Item", Item);
		Notification = New NotifyDescription("ProhibitFilesImportByExtensionAfterConfirm", ThisObject, AdditionalParameters);
		FormParameters = New Structure("Key", "OnChangeDeniedExtensionsList");
		OpenForm("CommonForm.SecurityWarning", FormParameters, , , , , Notification);
		Return;
	EndIf;
	
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure SynchronizeFilesOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure ProhibitedDataAreaExtensionsListOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure MaxDataAreaFileSizeOnChange(Item)
	If MaxDataAreaFileSize = 0 Then
		MessageText = NStr("ru = 'Поле ""Максимальный размер файла"" не заполнено.'; en = 'Please fill the ""File size limit"" field.'; pl = 'Pole ""maksymalny rozmiar pliku"" nie jest wypełnione.';de = 'Das Feld ""Maximale Dateigröße"" ist nicht ausgefüllt.';ro = 'Câmpul ""Dimensiunea maximă a fișierului"" nu este completat.';tr = '""Maksimum dosya boyutu"" alanı doldurulmadı.'; es_ES = 'El campo ""Tamaño máximo del archivo"" no está rellenado.'");
		CommonClient.MessageToUser(MessageText, ,"MaxDataAreaFileSize");
		Return;
	EndIf;
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure DataAreaOpenDocumentFilesExtensionsListOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure TextFilesExtensionsListOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Parameters common to all data areas.

&AtClient
Procedure MaxFileSizeOnChange(Item)
	If MaxFileSize = 0 Then
		MessageText = NStr("ru = 'Поле ""Максимальный размер файла"" не заполнено.'; en = 'Please fill the ""File size limit"" field.'; pl = 'Pole ""maksymalny rozmiar pliku"" nie jest wypełnione.';de = 'Das Feld ""Maximale Dateigröße"" ist nicht ausgefüllt.';ro = 'Câmpul ""Dimensiunea maximă a fișierului"" nu este completat.';tr = '""Maksimum dosya boyutu"" alanı doldurulmadı.'; es_ES = 'El campo ""Tamaño máximo del archivo"" no está rellenado.'");
		CommonClient.MessageToUser(MessageText, ,"MaxFileSize");
		Return;
	EndIf;
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure ProhibitedFileExtensionsListOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure OpenDocumentFilesExtensionsListOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure CatalogFilesStorageVolume(Command)
	NameOfFormToOpen = "Catalog.FileStorageVolumes.ListForm";
	OpenForm(NameOfFormToOpen, , ThisObject);
EndProcedure

&AtClient
Procedure FilesSynchronizationSetup(Command)
	NameOfFormToOpen = "InformationRegister.FileSynchronizationSettings.ListForm";
	OpenForm(NameOfFormToOpen, , ThisObject);
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ProhibitFilesImportByExtensionAfterConfirm(Result, AdditionalParameters) Export
	If Result <> Undefined AND Result = "Continue" Then
		Attachable_OnChangeAttribute(AdditionalParameters.Item);
	Else
		DenyUploadFilesByExtension = True;
	EndIf;
EndProcedure

&AtClient
Procedure StoreFilesInVolumesOnHardDiskOnChangeCompletion(Response, Item) Export
	
	If Response <> DialogReturnCode.OK Then
		ConstantsSet.StoreFilesInVolumesOnHardDrive = Not ConstantsSet.StoreFilesInVolumesOnHardDrive;
	Else
		Attachable_OnChangeAttribute(Item);
	EndIf;
	
EndProcedure

&AtServerNoContext
Function PermissionRequestsToUseExternalResourcesOfFilesStorageVolumes(Include)
	
	PermissionRequestsToUse = New Array;
	CatalogName = "FileStorageVolumes";
	
	If Include Then
		Catalogs[CatalogName].AddRequestsToUseExternalResourcesForAllVolumes(
			PermissionRequestsToUse);
	Else
		Catalogs[CatalogName].AddRequestsToStopUsingExternalResourcesForAllVolumes(
			PermissionRequestsToUse);
	EndIf;
	
	Return PermissionRequestsToUse;
	
EndFunction

&AtClient
Procedure Attachable_OnChangeAttribute(Item, UpdateInterface = True)
	
	ConstantName = OnChangeAttributeServer(Item.Name);
	
	RefreshReusableValues();
	
	If UpdateInterface Then
		RefreshInterface = True;
		AttachIdleHandler("UpdateApplicationInterface", 2, True);
	EndIf;
	
	If ConstantName <> "" Then
		Notify("Write_ConstantsSet", New Structure, ConstantName);
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateApplicationInterface()
	
	If RefreshInterface = True Then
		RefreshInterface = False;
		CommonClient.RefreshApplicationInterface();
	EndIf;
	
EndProcedure

&AtServer
Function OnChangeAttributeServer(ItemName)
	
	DataPathAttribute = Items[ItemName].DataPath;
	
	ConstantName = SaveAttributeValue(DataPathAttribute);
	
	SetAvailability(DataPathAttribute);
	
	RefreshReusableValues();
	
	Return ConstantName;
	
EndFunction

&AtServer
Function SaveAttributeValue(DataPathAttribute)
	
	NameParts = StrSplit(DataPathAttribute, ".");
	If NameParts.Count() <> 2 Then
		If DataPathAttribute = "MaxFileSize" Then
			ConstantsSet.MaxFileSize = MaxFileSize * (1024*1024);
			ConstantName = "MaxFileSize";
			
		ElsIf DataPathAttribute = "MaxDataAreaFileSize" Then
			
			If Not Common.DataSeparationEnabled() Then
				ConstantsSet.MaxFileSize = MaxDataAreaFileSize * (1024*1024);
				ConstantName = "MaxFileSize";
			Else
				ConstantsSet.MaxDataAreaFileSize = MaxDataAreaFileSize * (1024*1024);
				ConstantName = "MaxDataAreaFileSize";
			EndIf;
		ElsIf DataPathAttribute = "DenyUploadFilesByExtension" Then
			ConstantsSet.DenyUploadFilesByExtension = DenyUploadFilesByExtension;
			ConstantName = "DenyUploadFilesByExtension";
		EndIf;
	Else	
		ConstantName = NameParts[1];
	EndIf;
	
	If IsBlankString(ConstantName) Then
		Return "";
	EndIf;	
	
	ConstantManager = Constants[ConstantName];
	ConstantValue = ConstantsSet[ConstantName];
	
	If ConstantManager.Get() <> ConstantValue Then
		ConstantManager.Set(ConstantValue);
	EndIf;
	
	Return ConstantName;
	
EndFunction

&AtServer
Procedure SetAvailability(DataPathAttribute = "")
	
	If DataPathAttribute = "ConstantsSet.StoreFilesInVolumesOnHardDrive" OR DataPathAttribute = "" Then
		Items.CatalogFilesStorageVolume.Enabled = ConstantsSet.StoreFilesInVolumesOnHardDrive;
	EndIf;

	If DataPathAttribute = "DenyUploadFilesByExtension" OR DataPathAttribute = "" Then
		Items.DeniedDataAreaExtensionsList.Enabled = DenyUploadFilesByExtension;
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.SynchronizeFiles" OR DataPathAttribute = "" Then
		Items.FileSynchronizationSettings.Enabled = ConstantsSet.SynchronizeFiles;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function HasFilesStorageVolumes()
	
	ModuleFilesOperations = Common.CommonModule("FilesOperations");
	Return ModuleFilesOperations.HasFileStorageVolumes();
	
EndFunction

#EndRegion
