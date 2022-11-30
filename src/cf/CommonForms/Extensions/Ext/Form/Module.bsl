///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var CurrentContext;

#EndRegion

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	URL = "e1cib/app/CommonForm.Extensions";
	
	If Not Users.IsFullUser() Then
		Raise NStr("ru = 'Недостаточно прав доступа. Обратитесь к администратору.'; en = 'Insufficient access rights. Contact the administrator.'; pl = 'Niewystarczające prawa dostępu. Skontaktuj się z administratorem.';de = 'Nicht genügend Zugriffsrechte. Wenden Sie sich an den Administrator.';ro = 'Drepturi de acces insuficiente. Adresați-vă administratorului.';tr = 'Erişim hakları yetersizdir. Yöneticinize başvurun.'; es_ES = 'Insuficientes derechos de acceso. Diríjase al administrador.'");
	EndIf;
	
	If Not AccessRight("Administration", Metadata) Then
		Items.ExtensionsListSafeModeFlag.ReadOnly = True;
	EndIf;
	
	If StandardSubsystemsServer.IsBaseConfigurationVersion() Then
		Raise NStr("ru = 'Расширения недоступны в базовой версии программы.'; en = 'Extensions are unavailable in the base version of the application.'; pl = 'Rozszerzenia nie są dostępne w podstawowej wersji programu.';de = 'Erweiterungen sind in der Basisversion des Programms nicht verfügbar.';ro = 'Extensiile nu sunt disponibile în versiunea de bază a programului.';tr = 'Uygulamanın temel sürümünde uzantılar mevcut değil.'; es_ES = 'Extensiones no disponibles en la versión básica del programa.'");
	EndIf;
	
	If Not AccessRight("ConfigurationExtensionsAdministration", Metadata) Then
		Items.ExtensionsListUpdate.OnlyInAllActions = False;
		Items.ExtensionsList.ReadOnly = True;
		Items.ExtensionsListAdd.Visible = False;
		Items.ExtensionsListDelete.Visible = False;
		Items.ExtensionsListUpdateFromFile.Visible = False;
		Items.ExtensionsListSaveAs.Visible = False;
		Items.ExtensionsListContextMenuAdd.Visible = False;
		Items.ExtensionsListContextMenuDelete.Visible = False;
		Items.ExtensionsListContextMenuUpdateFromFile.Visible = False;
		Items.ExtensionsListContextMenuSaveAs.Visible = False;
	EndIf;
	
	Items.ExtensionsListShared.Visible = Common.DataSeparationEnabled();
	Items.ExtensionsListReceivedFromMasterNode.Visible = Common.IsSubordinateDIBNode();
	Items.ExtensionsListReplicateToSubordinateNodes.Visible = StandardSubsystemsCached.DIBUsed();
	
	Items.FormInstalledPatches.Visible = 
		Common.SubsystemExists("StandardSubsystems.ConfigurationUpdate");
	
	UpdateList();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SetCommandBarButtonAvailability()
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "LoggedOffFromDataArea" 
		Or EventName = "LoggedOnToDataArea" Then
		
		AttachIdleHandler("UpdateListIdleHandler", 0.1, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure WarningURLProcessingDetails(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	Exit(False, True);
EndProcedure

#EndRegion

#Region ExtensionListFormTableItemsEventHandlers

&AtClient
Procedure ExtensionListOnActivateRow(Item)
	
	SetCommandBarButtonAvailability();
	
EndProcedure

&AtClient
Procedure ExtensionListBeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)
	
	Cancel = True;
	LoadExtension(Undefined, True);
	
EndProcedure

&AtClient
Procedure ExtensionListBeforeDelete(Item, Cancel)
	
	Cancel = True;
	DeleteExtensions(Item.SelectedRows);
	
EndProcedure

&AtClient
Procedure ExtensionListSafeModeFlagOnChange(Item)
	
	CurrentExtension = Items.ExtensionsList.CurrentData;
	If CurrentExtension = Undefined Then
		Return;
	EndIf;
	
	ExtensionListSafeModeFlagOnChangeAtServer(CurrentExtension.GetID());
	
EndProcedure

&AtClient
Procedure ExtensionListAttachOnChange(Item)
	
	CurrentExtension = Items.ExtensionsList.CurrentData;
	If CurrentExtension = Undefined Then
		Return;
	EndIf;
	
	RowID = CurrentExtension.GetID();
	
	If Not CurrentExtension.Attach Then 
		
		Context = New Structure;
		Context.Insert("RowID", RowID);
		
		Notification = New NotifyDescription("DetachExtensionAfterConfirmation", ThisObject, Context);
		
		FormParameters = New Structure;
		FormParameters.Insert("Key", "BeforeDetachExtension");
		
		OpenForm("CommonForm.SecurityWarning", FormParameters,,,,, Notification)
		
	Else 
		
		ExtensionsListAttachOnChangeAtServer(RowID);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExtensionsListSendToSubordinateDIBNodesOnChange(Item)
	
	CurrentExtension = Items.ExtensionsList.CurrentData;
	If CurrentExtension = Undefined Then
		Return;
	EndIf;
	
	ExtensionsListSendToSubordinateDIBNodesOnChangeAtServer(CurrentExtension.GetID());
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Update(Command)
	
	UpdateList();
	
EndProcedure

&AtClient
Procedure SaveAs(Command)
	
	CurrentExtension = Items.ExtensionsList.CurrentData;
	
	If CurrentExtension = Undefined Then
		Return;
	EndIf;
	
	Address = SaveAtServer(CurrentExtension.ExtensionID);
	
	If Address = Undefined Then
		Return;
	EndIf;
	
	SavingParameters = FileSystemClient.FileSavingParameters();
	SavingParameters.Dialog.Title = NStr("ru = 'Выберите файл для сохранения расширения конфигурации'; en = 'Select file to save configuration extension.'; pl = 'Wybierz plik do zapisu rozszerzenia konfiguracji';de = 'Wählen Sie die Datei aus, in der die Konfigurationserweiterung gespeichert werden soll';ro = 'Selectați fișierul pentru salvarea extensiei configurației';tr = 'Yapılandırmanın kaydedileceği dosyayı seçin'; es_ES = 'Seleccione un archivo para guardar la extensión de la configuración'");
	SavingParameters.Dialog.Filter    = NStr("ru = 'Файлы расширений конфигурации (*.cfe)|*.cfe|Все файлы (*.*)|*.*'; en = 'Configuration extension files (*.cfe)|*.cfe|All files (*.*)|*.*'; pl = 'Pliki rozszerzeń konfiguracji (*.cfe)|*.cfe|Wszystkie pliki (*.*)|*.*';de = 'Konfigurationserweiterungsdateien (*.cfe)|*.cfe|Alle Dateien (*.*)|*.*';ro = 'Fișierele extensiilor configurațiilor (*.cfe)|*.cfe|Toate fișierele (*.*)|*.*';tr = 'Yapılandırma uzantı dosyaları (*.cfe)|*.cfe|Tüm dosyalar (*.*)|*.*'; es_ES = 'Archivos de extensiones de la configuración (*.cfe)|*.cfe|Todos los archivos (*.*)|*.*'");
	
	FileSystemClient.SaveFile(Undefined, Address,
		CurrentExtension.Name + "_" + CurrentExtension.Version + ".cfe", SavingParameters);
	
EndProcedure

&AtClient
Procedure UpdateFromFileOnHardDrive(Command)
	
	CurrentExtension = Items.ExtensionsList.CurrentData;
	
	If CurrentExtension = Undefined Then
		Return;
	EndIf;
	
	LoadExtension(CurrentExtension.ExtensionID);
	
EndProcedure

&AtClient
Procedure UpdateExtensionCaches(Command)
	
	UpdateExtensionCachesAtServer();
	
	ShowMessageBox(,
		NStr("ru = 'Выполнено обновление версии параметров работы расширений,
		           |подключенных в этом сеансе.'; 
		           |en = 'The version of parameters of extensions
		           |attached in this session was updated.'; 
		           |pl = 'Wykonano aktualizację wersji parametrów działania rozszerzeń,
		           |podłączonych w tej sesji.';
		           |de = 'Eine Aktualisierung der Betriebsparameter
		           |der in dieser Sitzung verbundenen Erweiterungen wurde abgeschlossen.';
		           |ro = 'Este executată actualizarea versiunii parametrilor de lucru ai extensiilor
		           |conectate în această sesiune.';
		           |tr = 'Bu oturumda bağlı uzantı ayarları 
		           |sürümünü güncelleştirin.'; 
		           |es_ES = 'Se ha actualizado la versión de los parámetros del uso de extensiones
		           |conectadas en esta sesión.'"));
	
EndProcedure

&AtClient
Procedure DeleteObsoleteExtensionCaches(Command)
	
	DeleteObsoleteExtensionsCachesAtServer();
	ShowMessageBox(, NStr("ru = 'Выполнено удаление устаревших версий параметров работы расширений.'; en = 'Obsolete versions of extension parameters are deleted.'; pl = 'Usunięto przestarzałe wersje parametrów działania rozszerzeń.';de = 'Die veralteten Versionen der Erweiterungen wurden gelöscht.';ro = 'Este executată ștergerea versiunilor învechite ale parametrilor de lucru ai extensiilor.';tr = 'Uzantı ayarları eski sürümleri kaldırıldı.'; es_ES = 'Se han eliminado las versiones antiguas de los parámetros del uso de extensiones.'"));
	
EndProcedure

&AtClient
Procedure InstalledPatches(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.ConfigurationUpdate") Then
		ModuleSoftwareUpdateClient = CommonClient.CommonModule("ConfigurationUpdateClient");
		ModuleSoftwareUpdateClient.ShowInstalledPatches();
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure UpdateListIdleHandler()
	
	UpdateList();
	
EndProcedure

&AtServer
Procedure UpdateList(AfterAdd = False)
	
	If AfterAdd Then
		CurrentRowIndex = ExtensionsList.Count();
	Else
		CurrentRowIndex = 0;
		CurrentRowID = Items.ExtensionsList.CurrentRow;
		If CurrentRowID <> Undefined Then
			Row = ExtensionsList.FindByID(CurrentRowID);
			If Row <> Undefined Then
				CurrentRowIndex = ExtensionsList.IndexOf(Row);
			EndIf;
		EndIf;
	EndIf;
	
	ExtensionsList.Clear();
	
	SetPrivilegedMode(True);
	Extensions = ConfigurationExtensions.Get();
	AttachedExtensions = ExtensionsIDs(ConfigurationExtensionsSource.SessionApplied);
	DetachedExtensions  = ExtensionsIDs(ConfigurationExtensionsSource.SessionDisabled);
	SetPrivilegedMode(False);
	
	If Common.SubsystemExists("StandardSubsystems.ConfigurationUpdate") Then 
		
		ModuleSoftwareUpdate = Common.CommonModule("ConfigurationUpdate");
		
		ExtensionsToExclude = New Array;
		
		For Each Extension In Extensions Do
			If ModuleSoftwareUpdate.IsPatch(Extension) Then 
				ExtensionsToExclude.Add(Extension);
			EndIf;
		EndDo;
		
		For Each ExtensionToExclude In ExtensionsToExclude Do
			Index = Extensions.Find(ExtensionToExclude);
			If Index <> Undefined Then
				Extensions.Delete(Index);
			EndIf;
		EndDo;
		
	EndIf;
	
	For Each Extension In Extensions Do
		ExtensionItem = ExtensionsList.Add();
		ExtensionItem.ExtensionID = Extension.UUID;
		ExtensionItem.Name = Extension.Name;
		ExtensionItem.Version = Extension.Version;
		ExtensionItem.Checksum = Base64String(Extension.HashSum);
		ExtensionItem.Synonym = Extension.Synonym;
		ExtensionItem.Purpose = Extension.Purpose;
		ExtensionItem.SafeMode = Extension.SafeMode;
		ExtensionItem.Attach = Extension.Active;
		ExtensionItem.ReceivedFromMasterDIBNode = Extension.MasterNode <> Undefined;
		ExtensionItem.PassToSubordinateDIBNodes = Extension.UsedInDistributedInfoBase;
		ExtensionItem.SerialNumber = Extensions.Find(Extension) + 1;
		
		ExtensionItem.Common = (Extension.Scope = ConfigurationExtensionScope.InfoBase);
		
		ExtensionItem.AssignmentPriority =
			?(Extension.Purpose = Metadata.ObjectProperties.ConfigurationExtensionPurpose.Patch, 1,
			?(Extension.Purpose = Metadata.ObjectProperties.ConfigurationExtensionPurpose.Customization, 2, 3));
		
		ExtensionKey = Extension.Name + Extension.HashSum + Extension.Scope;	
		If AttachedExtensions[ExtensionKey] <> Undefined Then
			ExtensionItem.Attached = 0;
			ExtensionItem.ConnectionState = NStr("ru = 'Подключено'; en = 'Attached'; pl = 'Podłączono';de = 'Verbunden';ro = 'Conectat';tr = 'Bağlandı'; es_ES = 'Conectado'");
		ElsIf DetachedExtensions[ExtensionKey] <> Undefined Then
			ExtensionItem.Attached = 2;
			ExtensionItem.ConnectionState = NStr("ru = 'Отключено'; en = 'Detached'; pl = 'Wyłączono';de = 'Deaktiviert';ro = 'Dezactivat';tr = 'Devre dışı'; es_ES = 'Desconectado'");
		Else
			ExtensionItem.Attached = 1;
			ExtensionItem.ConnectionState = NStr("ru = 'Требуется перезапуск'; en = 'Restart required'; pl = 'Wymagane ponowne uruchomienie';de = 'Neustart erforderlich';ro = 'Este necesară relansarea';tr = 'Yeniden başlatılmalı'; es_ES = 'Se requiere reiniciar'");
		EndIf;	
			
		If IsBlankString(ExtensionItem.Synonym) Then
			ExtensionItem.Synonym = ExtensionItem.Name;
		EndIf;
		
		If TypeOf(Extension.SafeMode) = Type("Boolean") Then
			ExtensionItem.SafeModeFlag = Extension.SafeMode;
		Else
			ExtensionItem.SafeModeFlag = True;
		EndIf;
	EndDo;
	ExtensionsList.Sort("ReceivedFromMasterDIBNode DESC, AssignmentPriority, Common DESC, SerialNumber");
	
	If CurrentRowIndex >= ExtensionsList.Count() Then
		CurrentRowIndex = ExtensionsList.Count() - 1;
	EndIf;
	If CurrentRowIndex >= 0 Then
		Items.ExtensionsList.CurrentRow = ExtensionsList.Get(
			CurrentRowIndex).GetID();
	EndIf;
	
	SetPrivilegedMode(True);
	InstalledExtensions = Catalogs.ExtensionsVersions.InstalledExtensions();
	ExtensionsStateChanged = 
		(SessionParameters.InstalledExtensions.MainState <> InstalledExtensions.MainState);
	Items.WarningGroup.Visible = ExtensionsStateChanged;
	SetPrivilegedMode(False);
	
	// Updating the form attribute for conditional formatting.
	IsSharedUserInArea = IsSharedUserInArea();
	
	Items.InformationGroup.Visible = IsSharedUserInArea;
	
EndProcedure

&AtServer
Function ExtensionsIDs(ExtensionSource)
	
	Extensions = ConfigurationExtensions.Get(, ExtensionSource);
	IDs = New Map;
	
	For Each Extension In Extensions Do
		IDs.Insert(Extension.Name + Extension.HashSum + Extension.Scope, True);
	EndDo;
	
	Return IDs;
	
EndFunction

&AtServer
Function SaveAtServer(ExtensionID)
	
	Extension = FindExtension(ExtensionID);
	
	If Extension <> Undefined Then
		Return PutToTempStorage(Extension.GetData(), ThisObject.UUID);
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtServer
Function FindExtension(ExtensionID)
	
	Filter = New Structure;
	Filter.Insert("UUID", New UUID(ExtensionID));
	Extensions = ConfigurationExtensions.Get(Filter);
	
	Extension = Undefined;
	
	If Extensions.Count() = 1 Then
		Extension = Extensions[0];
	EndIf;
	
	Return Extension;
	
EndFunction

&AtServer
Procedure UpdateExtensionCachesAtServer()
	
	SetPrivilegedMode(True);
	
	InformationRegisters.ExtensionVersionParameters.ClearAllExtensionParameters();
	InformationRegisters.ExtensionVersionParameters.FillAllExtensionParameters();
	
EndProcedure

&AtServer
Procedure DeleteObsoleteExtensionsCachesAtServer()
	
	SetPrivilegedMode(True);
	Catalogs.ExtensionsVersions.DeleteObsoleteParametersVersions();
	
EndProcedure

&AtClient
Procedure DeleteExtensions(SelectedRows)
	
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	If SelectedRows.Count() = 1 Then
		CurrentExtension = Items.ExtensionsList.CurrentData;
		
		If CurrentExtension.Common 
				AND IsSharedUserInArea
				Or CurrentExtension.ReceivedFromMasterDIBNode Then 
			
			// If a user selected a row and pressed Del, and there is a common extension in a session with 
			// separators or in a subordinate DIB node received from the master node, the keystroke is ignored.
			// 
			// 
			Return;
		EndIf;
	EndIf;
	
	Context = New Structure;
	Context.Insert("SelectedRows", SelectedRows);
	
	Notification = New NotifyDescription("DeleteExtensionAfterConfirmation", ThisObject, Context);
	
	FormParameters = New Structure;
	FormParameters.Insert("Key", "BeforeDeleteExtension");
	FormParameters.Insert("MultipleChoice", SelectedRows.Count() > 1);
	
	OpenForm("CommonForm.SecurityWarning", FormParameters,,,,, Notification)
	
EndProcedure

&AtClient
Procedure DeleteExtensionAfterConfirmation(Result, Context) Export
	
	If Result <> "Continue" Then
		Return;
	EndIf;
	
	Notification = New NotifyDescription("DeleteExtensionFollowUp", ThisObject, Context);
	
	If CommonClient.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		Queries = RequestsToCancelExternalModuleUsagePermissions(Context.SelectedRows);
		ModuleSafeModeManagerClient = CommonClient.CommonModule("SafeModeManagerClient");
		ModuleSafeModeManagerClient.ApplyExternalResourceRequests(Queries, ThisObject, Notification);
	Else
		ExecuteNotifyProcessing(Notification, DialogReturnCode.OK);
	EndIf;
	
EndProcedure

&AtClient
Procedure DeleteExtensionFollowUp(Result, Context) Export
	
	If Result = DialogReturnCode.OK Then
		ShowTimeConsumingOperation();
		CurrentContext = Context;
		AttachIdleHandler("DeleteExtensionCompletion", 0.1, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure DeleteExtensionCompletion()
	
	Context = CurrentContext;
	
	Try
		DeleteExtensionsAtServer(Context.SelectedRows);
	Except
		ErrorInformation = ErrorInfo();
		AttachIdleHandler("HideTimeConsumingOperation", 0.1, True);
		ShowMessageBox(, BriefErrorDescription(ErrorInformation));
		Return;
	EndTry;
	AttachIdleHandler("HideTimeConsumingOperation", 0.1, True);
	
EndProcedure

&AtServer
Procedure DeleteExtensionsAtServer(SelectedRows)
	
	ExtensionsToDelete = New Array;
	
	ErrorText = "";
	Try
		ExtensionToDelete = "";
		For Each ListItem In ExtensionsList Do
			If SelectedRows.Find(ListItem.GetID()) = Undefined Then
				Continue;
			EndIf;
			Extension = FindExtension(ListItem.ExtensionID);
			If Extension <> Undefined Then
				ExtensionDetails = New Structure;
				ExtensionDetails.Insert("Deleted", False);
				ExtensionDetails.Insert("Extension", Extension);
				ExtensionDetails.Insert("ExtensionData", Extension.GetData());
				ExtensionsToDelete.Add(ExtensionDetails);
			EndIf;
		EndDo;
		Index = ExtensionsToDelete.Count() - 1;
		While Index >= 0 Do
			ExtensionDetails = ExtensionsToDelete[Index];
			DisableSecurityWarnings(ExtensionDetails.Extension);
			ExtensionToDelete = ExtensionDetails.Extension.Synonym;
			ExtensionDetails.Extension.Delete();
			ExtensionToDelete = "";
			ExtensionDetails.Deleted = True;
			Index = Index - 1;
		EndDo;
		
		If Common.SeparatedDataUsageAvailable()
		   AND ConfigurationExtensions.Get().Count() = 0 Then
			
			Catalogs.ExtensionsVersions.OnRemoveAllExtensions();
		EndIf;
	Except
		ErrorInformation = ErrorInfo();
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось удалить расширение ""%1"" по причине:
			           |
			           |%2'; 
			           |en = 'Cannot delete extension ""%1"" due to:
			           |
			           |%2'; 
			           |pl = 'Nie udało się usunąć rozszerzenie ""%1"" z powodu:
			           |
			           |%2';
			           |de = 'Die Erweiterung ""%1"" konnte aus diesem Grund nicht gelöscht werden:
			           |
			           |%2';
			           |ro = 'Eșec la ștergerea extensiei ""%1"" din motivul:
			           |
			           |%2';
			           |tr = '""%1"" uzantısı 
			           |
			           |%2 nedeniyle silinemedi'; 
			           |es_ES = 'No se ha podido eliminar la extensión ""%1"" a causa de: 
			           |
			           |%2'"),
			ExtensionToDelete,
			BriefErrorDescription(ErrorInformation));
	EndTry;
	
	If Not ValueIsFilled(ErrorText) Then
		Try
			InformationRegisters.ExtensionVersionParameters.UpdateExtensionParameters();
		Except
			ErrorInformation = ErrorInfo();
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'После удаления, при подготовке оставшихся расширений к работе, произошла ошибка:
				           |
				           |%1'; 
				           |en = 'After extension deleting, an error occurred while provisioning the remaining extensions:
				           |
				           |%1'; 
				           |pl = 'Po usunięciu, podczas przygotowania pozostałych rozszerzeń do pracy, zaistniał błąd:
				           |
				           |%1';
				           |de = 'Nach dem Löschen, während die verbleibenden Erweiterungen für die Arbeit vorbereitet wurden, ist ein Fehler aufgetreten:
				           |
				           |%1';
				           |ro = 'După ștergere, la pregătirea extensiilor rămase pentru lucru, s-a produs eroarea:
				           |
				           |%1';
				           |tr = 'Silindikten sonra, kalan uzantıları çalışma için hazırlarken bir hata oluştu:
				           |
				           |%1'; 
				           |es_ES = 'Después de eliminar, al preparar las extensiones restantes para usar se ha producido un error:
				           |
				           |%1'"), BriefErrorDescription(ErrorInformation));
		EndTry;
	EndIf;
	
	If ValueIsFilled(ErrorText) Then
		RecoveryErrorInformation = Undefined;
		RecoveryPerformed = False;
		Try
			For Each ExtensionDetails In ExtensionsToDelete Do
				If Not ExtensionDetails.Deleted Then
					Continue;
				EndIf;
				ExtensionDetails.Extension.Write(ExtensionDetails.ExtensionData);
				RecoveryPerformed = True;
			EndDo;
		Except
			RecoveryErrorInformation = ErrorInfo();
			ErrorText = ErrorText + Chars.LF + Chars.LF
				+ StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'При попытке восстановить удаленные расширения произошла еще одна ошибка:
					           |%1'; 
					           |en = 'An error occurred while attempting to restore deleted extensions:
					           |%1'; 
					           |pl = 'Podczas próby odzyskania usuniętych rozszerzeń zaistniał jeszcze jeden błąd:
					           |%1';
					           |de = 'Beim Versuch, gelöschte Erweiterungen wiederherzustellen, ist noch ein Fehler aufgetreten:
					           |%1';
					           |ro = 'La tentativa de restabilire a extensiilor șterse s-a produs încă o eroare:
					           |%1';
					           |tr = 'Silinmiş uzantıları geri yüklemeye çalışırken bir hata daha oluştu: 
					           |%1'; 
					           |es_ES = 'Al intentar restablecer las extensiones eliminadas se ha producido un error más:
					           |%1'"), BriefErrorDescription(RecoveryErrorInformation));
		EndTry;
		If RecoveryPerformed
		   AND RecoveryErrorInformation = Undefined Then
			
			ErrorText = ErrorText + Chars.LF + Chars.LF
				+ NStr("ru = 'Удаленные расширения были восстановлены.'; en = 'The deleted extensions are restored.'; pl = 'Usunięte rozszerzenia zostały odzyskane.';de = 'Entfernte Erweiterungen wurden wiederhergestellt.';ro = 'Extensiile șterse au fost restabilite.';tr = 'Silinmiş uzantılar geri yüklendi.'; es_ES = 'Las extensiones eliminadas han sido restablecidas.'");
		EndIf;
	EndIf;
	
	If ValueIsFilled(ErrorText) Then
		Raise ErrorText;
	EndIf;
	
	UpdateList();
	
EndProcedure

&AtClient
Procedure DetachExtensionAfterConfirmation(Result, Context) Export
	
	If Result <> "Continue" Then
		
		ListLine = ExtensionsList.FindByID(Context.RowID);
		
		If ListLine = Undefined Then
			Return;
		EndIf;
		
		ListLine.Attach = Not ListLine.Attach;
		
		Return;
	EndIf;
	
	ExtensionsListAttachOnChangeAtServer(Context.RowID);
	
EndProcedure

&AtServer
Function RequestsToCancelExternalModuleUsagePermissions(SelectedRows)
	
	Queries = New Array;
	
	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	If Not ModuleSafeModeManager.UseSecurityProfiles() Then
		Return Queries;
	EndIf;
	
	Permissions = New Array;
	
	For Each RowID In SelectedRows Do
		CurrentExtension = ExtensionsList.FindByID(RowID);
		Permissions.Add(ModuleSafeModeManager.PermissionToUseExternalModule(
			CurrentExtension.Name, CurrentExtension.Checksum));
	EndDo;
	
	Queries.Add(ModuleSafeModeManager.RequestToCancelPermissionsToUseExternalResources(
		Common.MetadataObjectID("InformationRegister.ExtensionVersionParameters"),
		Permissions));
		
	Return Queries;
	
EndFunction

&AtClient
Procedure ShowTimeConsumingOperation()
	
	Items.RefreshPages.CurrentPage = Items.TimeConsumingOperationPage;
	SetCommandBarButtonAvailability();
	
EndProcedure

&AtClient
Procedure HideTimeConsumingOperation()
	
	Items.RefreshPages.CurrentPage = Items.ExtensionsListPage;
	SetCommandBarButtonAvailability();
	
EndProcedure

&AtClient
Procedure LoadExtension(Val ExtensionID, MultipleChoice = False)
	
	Context = New Structure;
	Context.Insert("ExtensionID", ExtensionID);
	Context.Insert("MultipleChoice", MultipleChoice);
	Notification = New NotifyDescription("LoadExtensionAfterConfirmation", ThisObject, Context);
	
	FormParameters = New Structure("Key", "BeforeAddExtensions");
	
	OpenForm("CommonForm.SecurityWarning", FormParameters,,,,, Notification);
	
EndProcedure

&AtClient
Procedure LoadExtensionAfterConfirmation(Response, Context) Export
	If Response <> "Continue" Then
		Return;
	EndIf;
	
	Notification = New NotifyDescription("LoadExtensionAfterPutFiles", ThisObject, Context);
	
	ImportParameters = FileSystemClient.FileImportParameters();
	ImportParameters.Dialog.Filter = NStr("ru = 'Расширение конфигурации'; en = 'Configuration extensions'; pl = 'Rozszerzenie konfiguracji';de = 'Erweiterung der Konfiguration';ro = 'Extensia configurației';tr = 'Yapılandırma uzantısı'; es_ES = 'Extensión de la configuración'", "ru")+ " (*.cfe)|*.cfe";
	ImportParameters.Dialog.Title = NStr("ru = 'Выберите файл расширения конфигурации'; en = 'Select configuration extension file'; pl = 'Wybierz plik rozszerzenia konfiguracji';de = 'Wählen Sie die Konfigurationserweiterungsdatei aus';ro = 'Alegeți fișierul extensiei configurației';tr = 'Yapılandırma uzantı dosyasını seçin'; es_ES = 'Seleccione un archivo de la extensión de la configuración'", "ru");
	ImportParameters.Dialog.CheckFileExist = True;
	
	ImportParameters.FormID = UUID;
	FileSystemClient.ImportFiles(Notification, ImportParameters);
	
EndProcedure

&AtClient
Procedure LoadExtensionAfterPutFiles(FilesThatWerePut, Context) Export
	
	If FilesThatWerePut = Undefined
	 Or FilesThatWerePut.Count() = 0 Then
		
		Return;
	EndIf;
	
	If CommonClient.SubsystemExists("StandardSubsystems.ConfigurationUpdate") Then
		ModuleSoftwareUpdateClient = CommonClient.CommonModule("ConfigurationUpdateClient");
		
		If SelectedFilesContainOnlyPatches(FilesThatWerePut, ModuleSoftwareUpdateClient) Then 
			
			BackupParameters = New Structure;
			BackupParameters.Insert("SelectedFiles", SelectedFilesByDetails(FilesThatWerePut));
			ModuleSoftwareUpdateClient.ShowUpdateSearchAndInstallation(BackupParameters);
			Return;
			
		ElsIf SelectedFilesContainPatches(FilesThatWerePut, ModuleSoftwareUpdateClient) Then 
			ShowMessageBox(,
				NStr("ru = 'Выбранные файлы не должны одновременно содержать исправления (патчи) и другие виды расширений.'; en = 'The selected files cannot contain both patches and extensions of other types.'; pl = 'Wybrane pliki nie powinny jednocześnie zawierać korekt (łat) i innych rodzajów rozszerzeń.';de = 'Die ausgewählten Dateien sollten nicht gleichzeitig Patches und andere Arten von Erweiterungen enthalten.';ro = 'Fișierele selectate nu trebuie să conțină concomitent corectări (patch-uri) și alte tipuri de extensii.';tr = 'Seçilen dosyalar aynı anda düzeltmeler (yamalar) ve diğer uzantı türlerini içermemelidir.'; es_ES = 'Los archivos seleccionados no deben contener simultáneamente las correcciones (parches) y otros tipos de extensiones.'"));
			Return;
		EndIf;
	EndIf;
	
	Context.Insert("FilesThatWerePut", FilesThatWerePut);
	
	ClosingNotification = New NotifyDescription(
		"LoadExtensionContinuation", ThisObject, Context);
	
	If CommonClient.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		
		PermissionRequests = New Array;
		Try
			AddPermissionRequest(PermissionRequests, FilesThatWerePut, Context.ExtensionID);
		Except
			ErrorInformation = ErrorInfo();
			ShowMessageBox(, BriefErrorDescription(ErrorInformation));
			Return;
		EndTry;
		
		ModuleSafeModeManagerClient = CommonClient.CommonModule("SafeModeManagerClient");
		ModuleSafeModeManagerClient.ApplyExternalResourceRequests(
			PermissionRequests, ThisObject, ClosingNotification);
	Else
		ExecuteNotifyProcessing(ClosingNotification, DialogReturnCode.OK);
	EndIf;
	
EndProcedure

&AtClient
Function SelectedFilesContainPatches(FilesThatWerePut, ModuleSoftwareUpdateClient)
	
	For Each FileThatWasPut In FilesThatWerePut Do 
		File = New File(FileThatWasPut.Name);
		If ModuleSoftwareUpdateClient.IsPatch(File.Name) Then 
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

&AtClient
Function SelectedFilesContainOnlyPatches(FilesThatWerePut, ModuleSoftwareUpdateClient)
	
	For Each FileThatWasPut In FilesThatWerePut Do 
		File = New File(FileThatWasPut.Name);
		If Not ModuleSoftwareUpdateClient.IsPatch(File.Name) Then 
			Return False;
		EndIf;
	EndDo;
	
	Return True;
	
EndFunction

&AtClient
Function SelectedFilesByDetails(FilesThatWerePut)
	
	FileList = New Array;
	
	For Each FileThatWasPut In FilesThatWerePut Do 
		File = New File(FileThatWasPut.Name);
		FileList.Add(File.FullName);
	EndDo;
	
	Return StrConcat(FileList, ", ");
	
EndFunction

&AtClient
Procedure LoadExtensionContinuation(Result, Context) Export
	
	If Result <> DialogReturnCode.OK Then
		Return;
	EndIf;
	
	ShowTimeConsumingOperation();
	CurrentContext = Context;
	AttachIdleHandler("LoadExtensionCompletion", 0.1, True);
	
EndProcedure

&AtClient
Procedure LoadExtensionCompletion()
	
	Context = CurrentContext;
	
	UnattachedExtensions = "";
	ExtensionsChanged = False;
	Try
		ChangeExtensionsAtServer(Context.FilesThatWerePut,
			Context.ExtensionID, UnattachedExtensions, ExtensionsChanged);
	Except
		ErrorInformation = ErrorInfo();
		AttachIdleHandler("HideTimeConsumingOperation", 0.1, True);
		ShowMessageBox(, BriefErrorDescription(ErrorInformation));
		Return;
	EndTry;
	AttachIdleHandler("HideTimeConsumingOperation", 0.1, True);
	
	If Not ExtensionsChanged Then
		Return;
	EndIf;
	
	If Context.ExtensionID = Undefined Then
		If Context.FilesThatWerePut.Count() > 1 Then
			NotificationText = NStr("ru = 'Расширения конфигурации добавлены'; en = 'Configuration extensions added'; pl = 'Rozszerzenia konfiguracji zostały dodane';de = 'Konfigurationserweiterungen hinzugefügt';ro = 'Extensiile configurației sunt adăugate';tr = 'Yapılandırma uzantıları eklendi'; es_ES = 'Extensiones de configuración añadida'", "ru");
		Else
			NotificationText = NStr("ru = 'Расширение конфигурации добавлено'; en = 'Configuration extension added'; pl = 'Rozszerzenie konfiguracji zostało dodane';de = 'Konfigurationserweiterung hinzugefügt';ro = 'Extensia configurației este adăugată';tr = 'Yapılandırma uzantısı eklendi'; es_ES = 'Extensión de configuración añadida'", "ru");
		EndIf;
	Else
		NotificationText = NStr("ru = 'Расширение конфигурации обновлено'; en = 'Configuration extension updated'; pl = 'Rozszerzenie konfiguracji zostało zaktualizowane';de = 'Konfigurationserweiterung aktualisiert';ro = 'Extensia configurației este actualizată';tr = 'Yapılandırma uzantısı güncellendi'; es_ES = 'Extensión de configuración actualizada'", "ru");
	EndIf;
	
	If ValueIsFilled(UnattachedExtensions) Then
		If Context.FilesThatWerePut.Count() > 1 Then
			If StrFind(UnattachedExtensions, ",") > 0 Then
				Note = NStr("ru = 'Некоторые расширения не подключаются:'; en = 'Cannot attach the following extensions:'; pl = 'Niektóre rozszerzenia nie podłączają się:';de = 'Einige Erweiterungen stellen keine Verbindung her:';ro = 'Unele extensii nu se conectează:';tr = 'Bazı uzantılar bağlanamadı:'; es_ES = 'Algunas extensiones de se conectan:'");
			Else
				Note = NStr("ru = 'Одно расширение не подключается:'; en = 'Cannot attach the extension:'; pl = 'Jedno rozszerzenie nie podłącza się:';de = 'Eine Erweiterung verbindet sich nicht:';ro = 'O extensie nu se conectează:';tr = 'Bir uzantı bağlanamadı:'; es_ES = 'Una extensión no se conecta:'");
			EndIf;
			Note = Note + " " + UnattachedExtensions;
		Else
			Note = NStr("ru = 'Расширение не подключается.'; en = 'Cannot attach an extension.'; pl = 'Rozszerzenie nie podłącza się.';de = 'Die Erweiterung wird nicht verbunden.';ro = 'Extensia nu se conectează.';tr = 'Uzantı bağlanamadı:'; es_ES = 'Extensión no se conecta.'");
		EndIf;
	Else
		Note = "";
	EndIf;
	
	ShowUserNotification(NotificationText, , Note);
	
EndProcedure

&AtServer
Procedure ChangeExtensionsAtServer(FilesThatWerePut, ExtensionID, UnattachedExtensions, ExtensionsChanged)
	
	Extension = Undefined;
	
	If ExtensionID <> Undefined Then
		Extension = FindExtension(ExtensionID);
		If Extension = Undefined Then
			Return;
		EndIf;
		PreviousExtensionName = Extension.Name;
		ExtensionData = Extension.GetData();
	EndIf;
	
	ExtensionsToCheck = New Map;
	AddedExtensions = New Array;
	
	ErrorText = "";
	NewBinaryDataSaved = False;
	AddedExtensionFileName = Undefined;
	Try
		If ExtensionID <> Undefined Then
			DisableSecurityWarnings(Extension);
			NewBinaryData = GetFromTempStorage(FilesThatWerePut[0].Location);
			Errors = Extension.CheckCanApply(NewBinaryData, False);
			For Each Error In Errors Do
				If Error.Importance <> ConfigurationExtensionApplicationIssueSeverity.Critical Then
					Continue;
				EndIf;
				ErrorText = ErrorText + Chars.LF + Error.Details;
			EndDo;
			If ValueIsFilled(ErrorText) Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Новое расширение не может быть применено по причине:
					           |%1'; 
					           |en = 'Cannot apply the extension. Reason:
					           |%1'; 
					           |pl = 'Nowe rozszerzenie nie może być zastosowane z powodu:
					           |%1';
					           |de = 'Eine neue Erweiterung kann aus folgendem Grund nicht beantragt werden:
					           |%1';
					           |ro = 'Extensia nouă nu poate fi aplicată din motivul:
					           |%1';
					           |tr = 'Yeni uzantı 
					           |%1 nedeniyle uygulanamaz'; 
					           |es_ES = 'La extensión nueva no puede ser aplicada a causa de:
					           |%1'"),
					ErrorText);
			Else
				Extension.Write(NewBinaryData);
				NewBinaryDataSaved = True;
				Extension = FindExtension(ExtensionID);
				If PreviousExtensionName = Extension.Name Then
					ExtensionsToCheck.Insert(Extension.Name, Extension.Synonym);
				Else
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Нельзя заменить расширение ""%1"" на ""%2"".'; en = 'Cannot replace extension ""%1"" with ""%2"".'; pl = 'Nie można zamienić rozszerzenie ""%1"" na ""%2"".';de = 'Sie können die Erweiterung ""%1"" durch ""%2"" nicht ersetzen.';ro = 'Nu puteți înlocui extensia ""%1"" cu ""%2"".';tr = '""%1"" uzantı ""%2"" uzantı ile değiştirilemez.'; es_ES = 'No se puede reemplazar la extensión ""%1"" por ""%2"".'"),
						PreviousExtensionName,
						Extension.Name);
				EndIf;
			EndIf;
		Else
			For Each FileThatWasPut In FilesThatWerePut Do
				Extension = ConfigurationExtensions.Create();
				DisableSecurityWarnings(Extension);
				AddedExtensionFileName = FileThatWasPut.Name;
				Extension.Write(GetFromTempStorage(FileThatWasPut.Location));
				AddedExtensionFileName = Undefined;
				Extension = FindExtension(String(Extension.UUID));
				AddedExtensions.Insert(0, Extension);
				ExtensionsToCheck.Insert(Extension.Name, Extension.Synonym);
			EndDo;
		EndIf;
	Except
		ErrorInformation = ErrorInfo();
		If ExtensionID <> Undefined Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось обновить расширение по причине:
				           |
				           |%1'; 
				           |en = 'Cannot update the extension. Reason:
				           |
				           |%1'; 
				           |pl = 'Nie można zaktualizować rozszerzenia. Powód:
				           |
				           |%1';
				           |de = 'Aus diesem Grund war es nicht möglich, die Erweiterung zu aktualisieren:
				           |
				           |%1';
				           |ro = 'Eșec la actualizarea extensiei din motivul:
				           |
				           |%1';
				           |tr = 'Uzantı 
				           |
				           |%1 nedeniyle güncellenemedi'; 
				           |es_ES = 'No se ha podido actualizar la extensión a causa de:
				           |
				           |%1'"), BriefErrorDescription(ErrorInformation));
			
		ElsIf ValueIsFilled(AddedExtensionFileName) Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось добавить расширение из файла
				           |""%1""
				           |по причине:
				           |
				           |%2'; 
				           |en = 'Cannot add an extension from file
				           |""%1.""
				           |Reason:
				           |
				           |%2'; 
				           |pl = 'Nie udało się dodać rozszerzenie z pliku 
				           |""%1""
				           |z powodu:
				           |
				           |%2';
				           |de = 'Aus diesem Grund konnte keine Erweiterung aus der Datei
				           |""%1""
				           | hinzugefügt werden:
				           |
				           |%2';
				           |ro = 'Eșec la adăugarea extensiei din fișierul
				           |""%1""
				           |din motivul:
				           |
				           |%2';
				           |tr = '
				           |"" dosyasından %1
				           |
				           | nedeniyle uzantı 
				           |%2eklenemedi'; 
				           |es_ES = 'No se ha podido añadir la extensión del archivo
				           |""%1""
				           |a causa de:
				           |
				           |%2'"),
				AddedExtensionFileName,
				BriefErrorDescription(ErrorInformation));
		Else
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось добавить по причине:
				           |
				           |%1'; 
				           |en = 'Cannot add an extension. Reason:
				           |
				           |%1'; 
				           |pl = 'Nie udało się dodać z powodu:
				           |
				           |%1';
				           |de = 'Konnte nicht hinzugefügt werden, aus dem Grund:
				           |
				           |%1';
				           |ro = 'Eșec la adăugare din motivul:
				           |
				           |%1';
				           |tr = ' 
				           |
				           |%1 nedeniyle eklenemedi'; 
				           |es_ES = 'No se ha podido actualizar a causa de:
				           |
				           |%1'"), BriefErrorDescription(ErrorInformation));
		EndIf;
	EndTry;
	
	If Not ValueIsFilled(ErrorText) Then
		Try
			InformationRegisters.ExtensionVersionParameters.UpdateExtensionParameters(ExtensionsToCheck, UnattachedExtensions);
			ExtensionsChanged = True;
		Except
			ErrorInformation = ErrorInfo();
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'После добавления, при подготовке расширений к работе, произошла ошибка:
				           |
				           |%1'; 
				           |en = 'An error occurred while preparing the added extensions for use:
				           |
				           |%1'; 
				           |pl = 'Po dodaniu, podczas przygotowania rozszerzeń do pracy, wystąpił błąd:
				           |
				           |%1';
				           |de = 'Nach dem Hinzufügen ist ein Fehler bei der Vorbereitung der Erweiterungen für den Betrieb aufgetreten:
				           |
				           |%1';
				           |ro = 'După adăugare, la pregătirea extensiilor pentru lucru, s-a produs eroarea:
				           |
				           |%1';
				           |tr = 'Eklendikten sonra, kalan uzantıları çalışma için hazırlarken bir hata oluştu:
				           |
				           |%1'; 
				           |es_ES = 'Después de añadir al preparar las extensiones para el trabajo se ha producido un error:
				           |
				           |%1'"), BriefErrorDescription(ErrorInformation));
		EndTry;
	EndIf;
	
	If ValueIsFilled(ErrorText) Then
		RecoveryErrorInformation = Undefined;
		RecoveryPerformed = False;
		Try
			If ExtensionID <> Undefined Then
				If NewBinaryDataSaved Then
					Extension = FindExtension(ExtensionID);
					If Extension = Undefined Then
						Extension = ConfigurationExtensions.Create();
					EndIf;
					Extension.Write(ExtensionData);
				EndIf;
				RecoveryPerformed = True;
			Else
				For Each AddedExtension In AddedExtensions Do
					Filter = New Structure("Name", AddedExtension.Name);
					Extensions = ConfigurationExtensions.Get(Filter);
					For Each Extension In Extensions Do
						If Extension.HashSum = AddedExtension.HashSum Then
							Extension.Delete();
							RecoveryPerformed = True;
						EndIf;
					EndDo;
				EndDo;
			EndIf;
		Except
			RecoveryErrorInformation = ErrorInfo();
			If ExtensionID <> Undefined Then
				ErrorText = ErrorText + Chars.LF + Chars.LF
					+ StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'При попытке восстановить измененное расширение произошла еще одна ошибка:
						           |%1'; 
						           |en = 'Another error occurred while attempting to restore a modified extension:
						           |%1'; 
						           |pl = 'Podczas próby odzyskania zmienionego rozszerzenia zaistniał jeszcze jeden błąd:
						           |%1';
						           |de = 'Beim Versuch, die geänderte Erweiterung wiederherzustellen, trat ein weiterer Fehler auf:
						           |%1';
						           |ro = 'La tentativa de restabilire a extensiei modificate s-a produs încă o eroare:
						           |%1';
						           |tr = 'Silinmiş uzantıları geri yüklemeye çalışırken bir hata daha oluştu: 
						           |%1'; 
						           |es_ES = 'Al intentar restablecer la extensión cambiada se ha producido un error más:
						           |%1'"), BriefErrorDescription(RecoveryErrorInformation));
			Else
				ErrorText = ErrorText + Chars.LF + Chars.LF
					+ StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'При попытке удалить добавленные расширения произошла еще одна ошибка:
						           |%1'; 
						           |en = 'Another error occurred while attempting to delete added extensions:
						           |%1'; 
						           |pl = 'Podczas próby usunięcia dodanych rozszerzeń zaistniał jeszcze jeden błąd:
						           |%1';
						           |de = 'Beim Versuch, die hinzugefügten Erweiterungen zu entfernen, trat ein weiterer Fehler auf:
						           |%1';
						           |ro = 'La tentativa de ștergere a extensiilor adăugate s-a produs încă o eroare:
						           |%1';
						           |tr = 'Silinmiş uzantıları geri yüklemeye çalışırken bir hata daha oluştu: 
						           |%1'; 
						           |es_ES = 'Al intentar eliminar las extensiones cambiadas se ha producido un error más:
						           |%1'"), BriefErrorDescription(RecoveryErrorInformation));
			EndIf;
		EndTry;
		If RecoveryPerformed
		   AND RecoveryErrorInformation = Undefined Then
			
			If ExtensionID <> Undefined Then
				If NewBinaryDataSaved Then
					ErrorText = ErrorText + Chars.LF + Chars.LF
						+ NStr("ru = 'Измененное расширение было восстановлено.'; en = 'The modified extension is restored.'; pl = 'Zmienione rozszerzenie zowstało odzyskane.';de = 'Die geänderte Erweiterung wurde wiederhergestellt.';ro = 'Extensia modificată a fost restabilită.';tr = 'Değişmiş uzantı geri yüklendi.'; es_ES = 'La extensión cambiada ha sido restablecida.'");
				Else
					ErrorText = ErrorText + Chars.LF + Chars.LF
						+ NStr("ru = 'Расширение не было изменено.'; en = 'The extension is not modified.'; pl = 'Rozszerzenie nie zostało zmienione.';de = 'Die Erweiterung wurde nicht verändert.';ro = 'Extensia nu a fost modificată.';tr = 'Uzantı değiştirilmedi.'; es_ES = 'La extensión no ha sido cambiada.'");
				EndIf;
			Else
				ErrorText = ErrorText + Chars.LF + Chars.LF
					+ NStr("ru = 'Добавленные расширения были удалены.'; en = 'The added extensions are deleted.'; pl = 'Dodane rozszerzenia zostaną usunięte.';de = 'Hinzugefügte Erweiterungen wurden entfernt.';ro = 'Extensiile adăugate au fost șterse.';tr = 'Eklenen uzantılar silindi.'; es_ES = 'Las extensiones añadidas han sido eliminadas.'");
			EndIf;
		EndIf;
	EndIf;
	
	If ValueIsFilled(ErrorText) Then
		Raise ErrorText;
	EndIf;
	
	UpdateList(ExtensionID = Undefined);
	
EndProcedure

&AtServer
Procedure ExtensionListSafeModeFlagOnChangeAtServer(RowID)
	
	ListLine = ExtensionsList.FindByID(RowID);
	
	If ListLine = Undefined Then
		Return;
	EndIf;
	
	Extension = FindExtension(ListLine.ExtensionID);
	
	If Extension <> Undefined Then
		
		If Extension.SafeMode <> ListLine.SafeModeFlag Then
			Extension.SafeMode = ListLine.SafeModeFlag;
			
			DisableSecurityWarnings(Extension);
			Try
				Extension.Write();
			Except
				ListLine.SafeModeFlag = Not ListLine.SafeModeFlag;
				Raise;
			EndTry;
			
			ListLine.SafeMode = ListLine.SafeModeFlag;
		EndIf;
		
	EndIf;
	
	UpdateList();
	
EndProcedure

&AtServer
Procedure ExtensionsListAttachOnChangeAtServer(RowID)
	
	ListLine = ExtensionsList.FindByID(RowID);
	
	If ListLine = Undefined Then
		Return;
	EndIf;
	
	Extension = FindExtension(ListLine.ExtensionID);
	
	If Extension <> Undefined Then
	
		If Extension.Active <> ListLine.Attach Then
			Extension.Active = ListLine.Attach;
			
			DisableSecurityWarnings(Extension);
			Try
				Extension.Write();
			Except
				ListLine.Attach = Not ListLine.Attach;
				Raise;
			EndTry;
		EndIf;
		
	EndIf;
	
	UpdateList();
	
EndProcedure

&AtServer
Procedure ExtensionsListSendToSubordinateDIBNodesOnChangeAtServer(RowID)
	
	ListLine = ExtensionsList.FindByID(RowID);
	
	If ListLine = Undefined Then
		Return;
	EndIf;
	
	Extension = FindExtension(ListLine.ExtensionID);
	
	If Extension <> Undefined Then
	
		If Extension.UsedInDistributedInfoBase <> ListLine.PassToSubordinateDIBNodes Then
			Extension.UsedInDistributedInfoBase = ListLine.PassToSubordinateDIBNodes;
			
			DisableSecurityWarnings(Extension);
			Try
				Extension.Write();
			Except
				ListLine.PassToSubordinateDIBNodes = Not ListLine.PassToSubordinateDIBNodes;
				Raise;
			EndTry;
			
			ListLine.PassToSubordinateDIBNodes = ListLine.PassToSubordinateDIBNodes;
		EndIf;
		
	EndIf;
	
	UpdateList();
	
EndProcedure

&AtServer
Procedure AddPermissionRequest(PermissionRequests, FilesThatWerePut, ExtensionID = Undefined)
	
	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	If Not ModuleSafeModeManager.UseSecurityProfiles() Then
		Return;
	EndIf;
	Permissions = New Array;
	
	For Each FileThatWasPut In FilesThatWerePut Do
		UpdatedExtensionData = Undefined;
		RecoveryRequired = False;
		Try
			If ExtensionID = Undefined Then
				TemporaryExtension = ConfigurationExtensions.Create();
			Else
				TemporaryExtension = FindExtension(ExtensionID);
				If TemporaryExtension = Undefined Then
					Raise
						NStr("ru = 'Текущее расширение не найдено в базе данных,
						           |возможно оно было удалено в другом сеансе.'; 
						           |en = 'The current extension is not found in the database.
						           |It might be deleted in another session.'; 
						           |pl = 'Bieżące rozszerzenie nie zostało znalezione w bazie danych,
						           |być może zostało ono usunięte w innej sesji.';
						           |de = 'Die aktuelle Erweiterung wurde nicht in der Datenbank gefunden,
						           |sie wurde möglicherweise in einer anderen Sitzung gelöscht.';
						           |ro = 'Extensia curentă nu a fost găsită în baza de date,
						           |posibil, ea a fost ștearsă în altă sesiune.';
						           |tr = 'Geçerli uzantı veritabanında bulunamadı, 
						           |başka bir oturumda silinmiş olabilir.'; 
						           |es_ES = 'La extensión actual no se ha encontrado en la base de datos,
						           |es posible que haya sido eliminada en otra sesión.'");
				EndIf;
				UpdatedExtensionData = TemporaryExtension.GetData();
			EndIf;
			DisableSecurityWarnings(TemporaryExtension);
			ExtensionData = GetFromTempStorage(FileThatWasPut.Location);
			TemporaryExtension.Write(ExtensionData);
			RecoveryRequired = True;
			TemporaryExtension = FindExtension(String(TemporaryExtension.UUID));
			TemporaryExtensionProperties = New Structure;
			TemporaryExtensionProperties.Insert("Name",      TemporaryExtension.Name);
			TemporaryExtensionProperties.Insert("HashSum", TemporaryExtension.HashSum);
			If ExtensionID = Undefined Then
				TemporaryExtension.Delete();
			Else
				TemporaryExtension = FindExtension(ExtensionID);
				If TemporaryExtension = Undefined Then
					TemporaryExtension = ConfigurationExtensions.Create();
				EndIf;
				TemporaryExtension.Write(UpdatedExtensionData);
			EndIf;
			RecoveryRequired = False;
			Permissions.Add(ModuleSafeModeManager.PermissionToUseExternalModule(
				TemporaryExtensionProperties.Name, Base64String(TemporaryExtensionProperties.HashSum)));
		Except
			ErrorInformation = ErrorInfo();
			If ExtensionID = Undefined Then
				If FilesThatWerePut.Count() > 1 Then
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
							NStr("ru = 'При попытке временно добавить расширение из файла
							           |""%1""
							           |возникла ошибка:
							           |%2'; 
							           |en = 'An error occurred while attempting to temporarily add an extension from file
							           |""%1""
							           |:
							           |%2'; 
							           |pl = 'Podczas próby czasowo dodać rozszerzenie z pliku 
							           | ""%1""
							           |wystąpił błąd: 
							           |%2';
							           |de = 'Beim Versuch, vorübergehend eine Erweiterung aus der Datei
							           |""%1""
							           | hinzuzufügen, ist ein Fehler aufgetreten:
							           |%2';
							           |ro = 'La tentativa de adăugare temporară a extensiei din fișierul
							           |""%1""
							           |s-a produs eroarea:
							           |%2';
							           |tr = '
							           |""%1""
							           |Dosyasından geçici olarak bir uzantı eklemeye çalışırken bir hata oluştu:
							           |%2'; 
							           |es_ES = 'Al intentar añadir temporalmente la extensión del archivo
							           |""%1""
							           |se ha producido un error:
							           |%2'"),
							FileThatWasPut.Name,
							BriefErrorDescription(ErrorInformation));
				Else
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
							NStr("ru = 'При попытке временно добавить расширение возникла ошибка:
							           |%1'; 
							           |en = 'An error occurred while attempting to temporarily add an extension:
							           |%1'; 
							           |pl = 'Podczas próby czasowo dodać rozszerzenie wystąpił błąd: 
							           |%1';
							           |de = 'Beim Versuch, eine Erweiterung vorübergehend hinzuzufügen, ist ein Fehler aufgetreten:
							           |%1';
							           |ro = 'La tentativa de adăugare temporară a extensiei s-a produs eroarea:
							           |%1';
							           |tr = 'Geçici olarak bir uzantı eklenmeye çalışırken bir hata oluştu: 
							           |%1'; 
							           |es_ES = 'Al intentar añadir temporalmente la extensión se ha producido un error:
							           |%1'"), BriefErrorDescription(ErrorInformation));
				EndIf;
			Else
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'При попытке временно обновить расширение возникла ошибка:
						           |%1'; 
						           |en = 'An error occurred while attempting to temporarily update an extension:
						           |%1'; 
						           |pl = 'Podczas próby czasowo aktualizować rozszerzenie błąd: 
						           |%1';
						           |de = 'Beim Versuch, die Erweiterung vorübergehend zu aktualisieren, ist ein Fehler aufgetreten:
						           |%1';
						           |ro = 'La tentativa de actualizare temporară a extensiei s-a produs eroarea:
						           |%1';
						           |tr = 'Geçici olarak bir uzantı güncellenmeye çalışırken bir hata oluştu: 
						           |%1'; 
						           |es_ES = 'Al intentar actualizar temporalmente la extensión se ha producido un error:
						           |%1'"), BriefErrorDescription(ErrorInformation));
			EndIf;
			If RecoveryRequired Then
				Try
					If ExtensionID = Undefined Then
						TemporaryExtension.Delete();
					Else
						TemporaryExtension = FindExtension(ExtensionID);
						If TemporaryExtension = Undefined Then
							TemporaryExtension = ConfigurationExtensions.Create();
						EndIf;
						TemporaryExtension.Write(UpdatedExtensionData);
					EndIf;
				Except
					ErrorInformation = ErrorInfo();
					If ExtensionID = Undefined Then 
						If FilesThatWerePut.Count() > 1 Then
							ErrorText = ErrorText + Chars.LF + Chars.LF
								+ StringFunctionsClientServer.SubstituteParametersToString(
									NStr("ru = 'При попытке удалить временно добавленное расширение из файла
									           |%1
									           |возникла еще одна ошибка:
									           |%2'; 
									           |en = 'Another error occurred while attempting to delete an extension temporarily added from file
									           |%1
									           |:
									           |%2'; 
									           |pl = 'Podczas próby usunąć czasowo dodane rozszerzenie z pliku
									           |%1
									           |wystąpił jeszcze jeden błąd: 
									           |%2';
									           |de = 'Beim Versuch, eine temporär hinzugefügte Erweiterung aus der Datei
									           |%1
									           |zu entfernen, trat ein weiterer Fehler auf:
									           |%2';
									           |ro = 'La tentativa de ștergere a extensiei adăugate temporar din fișierul
									           |%1
									           |s-a produs eroarea:
									           |%2';
									           |tr = '
									           |""%1""
									           |Dosyasından geçici olarak bir uzantı eklemeye çalışırken bir hata oluştu:
									           |%2'; 
									           |es_ES = 'Al intentar eliminar la extensión temporalmente añadida del archivo
									           |""%1""
									           |se ha producido un error más:
									           |%2'"),
									FileThatWasPut.Name,
									BriefErrorDescription(ErrorInformation));
						Else
							ErrorText = ErrorText + Chars.LF + Chars.LF
								+ StringFunctionsClientServer.SubstituteParametersToString(
									NStr("ru = 'При попытке удалить временно добавленное расширение возникла еще одна ошибка:
									           |%1'; 
									           |en = 'Another error occurred while attempting to delete a temporarily added extension:
									           |%1'; 
									           |pl = 'Podczas próby usunąć czasowo dodane rozszerzenie wystąpił jeszcze jeden błąd: 
									           |%1';
									           |de = 'Beim Versuch, eine temporär hinzugefügte Erweiterung zu entfernen, trat ein weiterer Fehler auf:
									           |%1';
									           |ro = 'La tentativa de ștergere a extensiei adăugate temporar s-a produs încă o eroare:
									           |%1';
									           |tr = 'Geçici olarak eklenmiş uzantıyı geri yüklemeye çalışırken bir hata daha oluştu: 
									           |%1'; 
									           |es_ES = 'Al intentar eliminar la extensión temporalmente añadida se ha producido un error más:
									           |%1'"), BriefErrorDescription(ErrorInformation));
						EndIf;
					Else
						ErrorText = ErrorText + Chars.LF + Chars.LF
							+ StringFunctionsClientServer.SubstituteParametersToString(
								NStr("ru = 'При попытке восстановить временно измененное расширение возникла еще одна ошибка:
								           |%1'; 
								           |en = 'Another error occurred while attempting to restore a temporarily changed extension:
								           |%1'; 
								           |pl = 'Podczas próby odzyskania czasowo zmienionego rozszerzenia wystąpił jeszcze jeden błąd: 
								           |%1';
								           |de = 'Beim Versuch, eine temporär geänderte Erweiterung wiederherzustellen, trat ein weiterer Fehler auf:
								           |%1';
								           |ro = 'La tentativa de restabilire a extensiei modificate temporar s-a produs încă o eroare:
								           |%1';
								           |tr = 'Geçici olarak değiştirilmiş uzantıyı geri yüklemeye çalışırken bir hata daha oluştu: 
								           |%1'; 
								           |es_ES = 'Al intentar restablecer la extensión temporalmente cambiada se ha producido un error más:
								           |%1'"), BriefErrorDescription(ErrorInformation));
					EndIf;
				EndTry;
			EndIf;
			Raise ErrorText;
		EndTry;
	EndDo;
	
	InstalledExtensions = ConfigurationExtensions.Get();
	For Each Extension In InstalledExtensions Do
		Permissions.Add(ModuleSafeModeManager.PermissionToUseExternalModule(
			Extension.Name, Base64String(Extension.HashSum)));
	EndDo;
	
	PermissionRequests.Add(ModuleSafeModeManager.RequestToUseExternalResources(Permissions,
		Common.MetadataObjectID("InformationRegister.ExtensionVersionParameters")));
	
EndProcedure

&AtServer
Procedure DisableSecurityWarnings(Extension)
	
	Extension.UnsafeActionProtection = Common.ProtectionWithoutWarningsDetails();
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Setting ViewOnly appearance parameter for common extensions and extensions passed from the master node to the subordinate DIB node.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ExtensionsListAttach.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ExtensionsListSafeModeFlag.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ExtensionsListReplicateToSubordinateNodes.Name);
	
	FilterItemsGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterItemsGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	FilterItemGroupCommon = FilterItemsGroup.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterItemGroupCommon.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterItemGroupCommon.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ExtensionsList.Common");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = FilterItemGroupCommon.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("IsSharedUserInArea");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = FilterItemsGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ExtensionsList.ReceivedFromMasterDIBNode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure

&AtClient
Procedure SetCommandBarButtonAvailability()
	
	If Items.RefreshPages.CurrentPage = Items.TimeConsumingOperationPage Then 
		
		Items.ExtensionsListAdd.Enabled = False;
		Items.ExtensionsListDelete.Enabled = False;
		Items.ExtensionsListUpdateFromFile.Enabled = False;
		
		Items.ExtensionsListContextMenuAdd.Enabled = False;
		Items.ExtensionsListContextMenuDelete.Enabled = False;
		Items.ExtensionsListContextMenuUpdateFromFile.Enabled = False;
		
	ElsIf Items.RefreshPages.CurrentPage = Items.ExtensionsListPage Then 
		
		OneRowSelected = Items.ExtensionsList.SelectedRows.Count() = 1;
		
		CanEdit = True;
		If OneRowSelected Then 
			CurrentExtension = Items.ExtensionsList.CurrentData;
			
			CanEdit = (Not CurrentExtension.Common 
				Or Not IsSharedUserInArea())
				AND Not CurrentExtension.ReceivedFromMasterDIBNode;
		EndIf;
		
		Items.ExtensionsListAdd.Enabled = True;
		Items.ExtensionsListDelete.Enabled = CanEdit;
		Items.ExtensionsListUpdateFromFile.Enabled = OneRowSelected AND CanEdit;
		Items.ExtensionsListSaveAs.Enabled = OneRowSelected;
		
		Items.ExtensionsListContextMenuAdd.Enabled = True;
		Items.ExtensionsListContextMenuDelete.Enabled = CanEdit;
		Items.ExtensionsListContextMenuUpdateFromFile.Enabled = OneRowSelected AND CanEdit;
		Items.ExtensionsListContextMenuSaveAs.Enabled = OneRowSelected;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function IsSharedUserInArea()
	
	SessionWithoutSeparators = True;
	
	If Common.DataSeparationEnabled()
	   AND Common.SubsystemExists("StandardSubsystems.SaaS") Then
		
		ModuleSaaS = Common.CommonModule("SaaS");
		SessionWithoutSeparators = ModuleSaaS.SessionWithoutSeparators();
		
	EndIf;
	
	Return SessionWithoutSeparators
		AND Common.DataSeparationEnabled()
		AND Common.SeparatedDataUsageAvailable();
		
EndFunction

#EndRegion
