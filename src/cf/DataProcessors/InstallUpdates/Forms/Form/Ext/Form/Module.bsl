///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var AdministrationParameters, PatchesFiles;

#EndRegion

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not ConfigurationUpdate.HasRightsToInstallUpdate() Then
		Raise NStr("ru = 'Недостаточно прав для обновления конфигурации. Обратитесь к администратору.'; en = 'Insufficient rights to update the configuration. Please contact the administrator.'; pl = 'Niewystarczające uprawnienia do aktualizacji konfiguracji. Zwróć się do administratora.';de = 'Nicht genügend Rechte, um die Konfiguration zu aktualisieren. Wenden Sie sich an den Administrator.';ro = 'Drepturi insuficiente pentru actualizarea configurației. Adresați-vă administratorului.';tr = 'Yapılandırmayı güncellemek için yeterli hak yok. Lütfen sistem yöneticinize başvurun.'; es_ES = 'Insuficientes derechos para actualizar la configuración. Diríjase al administrador.'");
	ElsIf Users.IsExternalUserSession() Then
		Raise NStr("ru = 'Данная операция не доступна внешнему пользователю системы.'; en = 'This operation is not available to external users.'; pl = 'Ta operacja nie jest dostępna dla zewnętrznego użytkownika systemu.';de = 'Dieser Vorgang ist für externe Systembenutzer nicht verfügbar.';ro = 'Această operație nu este disponibilă pentru utilizatorul de sistem extern.';tr = 'Bu işlem harici sistem kullanıcısı için mevcut değildir.'; es_ES = 'Esta operación no se encuentra disponible para el usuario del sistema externo.'");
	EndIf;
	
	If Not Common.IsWindowsClient() Then
		Return; // Cancel is set in OnOpen().
	EndIf;
	
	StandardSubsystemsServer.SetGroupTitleRepresentation(ThisObject);
	
	IsFileInfobase = Common.FileInfobase();
	IsSubordinateDIBNode = Common.IsSubordinateDIBNode();
	
	// If it is the first start after a configuration update, storing and resetting status.
	Object.UpdateResult = ConfigurationUpdate.ConfigurationUpdateSuccessful(ScriptDirectory);
	If Object.UpdateResult <> Undefined Then
		ConfigurationUpdate.ResetConfigurationUpdateStatus();
	EndIf;
	
	If Not Common.SubsystemExists("StandardSubsystems.EmailOperations") Then
		Items.EmailPanel.Visible = False;
	EndIf;
	
	Items.ErrorInformationPanel.Visible = SystemCheckIssues();
	Items.ExtensionsInformationPanel.Visible = ConfigurationUpdate.WarnAboutExistingExtensions();
	
	// Checking every time the wizard is opened.
	ConfigurationChanged = ConfigurationChanged();
	UpdateFileRequired = ?(ConfigurationChanged, 0, 1);
	
	If Parameters.Exit Then
		Items.UpdateRadioButtonsFile.Visible = False;
		Items.UpdateRadioButtonsServer.Visible = False;
		Items.UpdateDateTimeField.Visible = False;
		Items.ClickNextLabel.Visible = True;
	EndIf;
	
	If Parameters.ConfigurationUpdateReceived Then
		Items.UpdateMethodFilePages.CurrentPage = Items.UpdateReceivedFromApplicationFilePage;
	EndIf;
	
	Items.ConfigurationIsUpdatedDuringDataExchangeWithMainNodeLabel.Title = StringFunctionsClientServer.SubstituteParametersToString(
		Items.ConfigurationIsUpdatedDuringDataExchangeWithMainNodeLabel.Title, ExchangePlans.MasterNode());
	
	SetPrivilegedMode(True);
	
	If IsBlankString(Parameters.SelectedFiles) Then 
		RestoreConfigurationUpdateSettings();
	Else 
		SelectedFiles = Parameters.SelectedFiles;
	EndIf;
	
	If IsFileInfobase AND Object.UpdateMode > 1 Or Parameters.Exit Then
		Object.UpdateMode = 0;
	EndIf;
	
	Items.FindAndInstallUpdates.Visible = Common.SubsystemExists("OnlineUserSupport.GetApplicationUpdates");
	
	IsBaseVersion = StandardSubsystemsServer.IsBaseConfigurationVersion();
	If IsBaseVersion Then
		SelectionOptionTitle = "&" + NStr("ru = 'Укажите файл обновления'; en = 'Specify an update file'; pl = 'Wskaż plik aktualizacji';de = 'Geben Sie die Update-Datei an';ro = 'Indicați fișierul de actualizare';tr = 'Güncelleme dosyasını belirtin'; es_ES = 'Especifique el archivo de actualización'");
		Items.UpdateFileRequiredRadioButtons.ChoiceList[1].Presentation = SelectionOptionTitle;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// Initializing variables.
	PatchesFiles = New Array;
	If Not IsBlankString(PatchesFilesAsString) Then
		PatchesFiles = StrSplit(PatchesFilesAsString, ",");
	EndIf;
	
	Result = ConfigurationUpdateClient.UpdatesInstallationSupported();
	If Not Result.Supported Then
		ShowMessageBox(, Result.ErrorDescription);
		Cancel = True;
		Return;
	EndIf;
	
	If Parameters.RunUpdate Then
		ProceedToUpdateModeSelection();
		Return;
	EndIf;
	
	Pages    = Items.WizardPages.ChildItems;
	PageName = Pages.UpdateFile.Name;
	
	If IsSubordinateDIBNode Then
		If ConfigurationChanged Then
			ProceedToUpdateModeSelection();
			Return;
		Else
			PageName = Pages.NoUpdatesFound.Name;
		EndIf;
	EndIf;
	
	BeforeOpenPage(Pages[PageName]);
	Items.WizardPages.CurrentPage = Pages[PageName];
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectedValue, ChoiceSource)
	
	If Upper(ChoiceSource.FormName) = Upper("DataProcessor.ActiveUsers.Form.ActiveUsers") Then
		UpdateConnectionsInformation();
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "LegitimateSoftware" AND Not Parameter Then
		
		HandleBackButtonClick();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
	ConfigurationUpdateClient.WriteEventsToEventLog();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

////////////////////////////////////////////////////////////////////////////////
// UpdateFile page

&AtClient
Procedure UpdateFileRequiredRadioButtonsOnChange(Item)
	BeforeOpenPage();
EndProcedure

&AtClient
Procedure UpdateFileFieldStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	Dialog = New FileDialog(FileDialogMode.Open);
	Dialog.Directory = GetFileDirectory(Items.UpdateFileField.EditText);
	Dialog.CheckFileExist = True;
	If IsBaseVersion Then
		Dialog.Filter = NStr("ru = 'Все файлы поставки (*.cf*;*.cfu)|*.cf*;*.cfu|Файлы поставки конфигурации (*.cf)|*.cf|Файлы поставки обновления конфигурации(*.cfu)|*.cfu'; en = 'All delivery files (*.cf*;*.cfu)|*.cf*;*.cfu|Configuration delivery files (*.cf)|*.cf|Configuration update delivery files(*.cfu)|*.cfu'; pl = 'Wszystkie pliki dostawy (*.cf*;*.cfu)|*.cf*;*.cfu|Pliki dostawy konfiguracji (*.cf)|*.cf|Pliki dostawy aktualizacji konfiguracji(*.cfu)|*.cfu';de = 'Alle Lieferdateien(*.cf*;*.cfu)|*.cf*;*.cfu|Konfiguration Lieferdateien(*.cf)|*.cf| Konfiguration Update Lieferdateien(*.cfu)|*.cfu';ro = 'Toate fișierele de livrare (*.cf*;*.cfu)|*.cf*;*.cfu|Configurarea fișierelor de livrare (*.cf)|*.cf|Configurarea fișierelor de livrare de actualizare(*.cfu)|*.cfu';tr = 'Tüm  teslim dosyaları (* .cf *; *. Cfu) | * .cf *; *. cfu | Yapılandırma  teslim dosyaları (*.cf) | * .cf | Yapılandırma güncelleme teslim  dosyaları (*. cfu) | * .cfu'; es_ES = 'Todos archivos de envío (*.cf*;*.cfu)|*.cf*;*.cfu|Archivos de envío de configuraciones(*.cf)|*.cf|Archivos de envío de la actualización de configuraciones(*.cfu)|*.cfu'");
	Else
		Dialog.Multiselect = True;
		Dialog.Filter = NStr("ru = 'Все файлы (*.cf*;*.cfu;*.cfe;*.zip)|*.cf*;*.cfu;*.cfe;*.zip|Файлы поставки конфигурации (*.cf)|*.cf|Файлы поставки обновления конфигурации (*.cfu)|*.cfu|Файлы исправлений (*.cfe*;*.zip)|*.cfe*;*.zip'; en = 'All files (*.cf*;*.cfu;*.cfe;*.zip)|*.cf*;*.cfu;*.cfe;*.zip|Configuration delivery files (*.cf)|*.cf|Configuration update delivery files (*.cfu)|*.cfu|Patch files (*.cfe*;*.zip)|*.cfe*;*.zip'; pl = 'Wszystkie pliki (*.cf*;*.cfu;*.cfe;*.zip)|*.cf*;*.cfu;*.cfe;*.zip|Pliki dostawy konfiguracji (*.cf)|*.cf|Pliki dostawy aktualizacji konfiguracji (*.cfu)|*.cfu|Pliki korekt (*.cfe*;*.zip)|*.cfe*;*.zip';de = 'Alle Dateien (*.cf*;*.cfu;*.cfe;*.zip)|*.cf*;*.cfu;*.cfe;*.zip|.zip|Konfigurations-Lieferdateien (*.cf)|*.cf|Konfigurations-Update Lieferdateien (*.cfu)|*.cfu|Korrekturdateien (*.cfe*;*.zip)|*.cfe*;*.zip';ro = 'Toate fișierele (*.cf*;*.cfu;*.cfe;*.zip)|*.cf*;*.cfu;*.cfe;*.zip| Fișierele de livrare configurației (*.cf)|*.cf|Fișierele de livrare a actualizării configurației (*.cfu)|*.cfu|Fișierele corectărilor (*.cfe*;*.zip)|*.cfe*;*.zip';tr = 'Tüm dosyalar (*.cf*;*.cfu;*.cfe;*.zip)|*.cf*;*.cfu;*.cfe;*.zip|Yapılandırma dosyaları (*.cf)|*.cf|Yapılandırma güncelleme dosyaları (*.cfu)|*.cfu|Düzeltme dosyaları (*.cfe*;*.zip)|*.cfe*;*.zip'; es_ES = 'Todos los archivos (*.cf*;*.cfu;*.cfe;*.zip)|*.cf*;*.cfu;*.cfe;*.zip|Archivos  de suministro de configuración (*.cf)|*.cf|Archivos de  suministro de actualización de configuración (*.cfu)|*.cfu|Archivos de correcciones (*.cfe*;*.zip)|*.cfe*;*.zip'");
	EndIf;
	Dialog.Title = NStr("ru = 'Выбор поставки обновления конфигурации'; en = 'Select configuration update delivery'; pl = 'Wybierz dostarczanie aktualizacji konfiguracji';de = 'Wählen Sie eine Konfigurations-Update Lieferung';ro = 'Selectați o livrare de actualizare a configurației';tr = 'Bir yapılandırma güncellemesi teslimatı seçin'; es_ES = 'Seleccionar un envío de la actualización de configuraciones'");
	
	If Dialog.Choose() Then
		SelectedFiles = StrConcat(Dialog.SelectedFiles, ",");
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// AfterInstallPatches page

&AtClient
Procedure ActiveUsersDecorationURLProcessing(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	ShowActiveUsers();
EndProcedure

&AtClient
Procedure PatchInstallationErrorLabelURLProcessing(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	LogFilter = New Structure;
	LogFilter.Insert("EventLogEvent", NStr("ru = 'Исправления.Установка'; en = 'Patch.Install'; pl = 'Patch.Install';de = 'Patch.Install';ro = 'Patch.Install';tr = 'Patch.Install'; es_ES = 'Patch.Install'"));
	EventLogClient.OpenEventLog(LogFilter);
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// SelectUpdateModeFile page

&AtClient
Procedure ActionsListLabelClick(Item)
	ShowActiveUsers();
EndProcedure

&AtClient
Procedure ActionsListLabel1Click(Item)
	ShowActiveUsers();
EndProcedure

&AtClient
Procedure ActionsListLabel3Click(Item)
	ShowActiveUsers();
EndProcedure

&AtClient
Procedure BackupLabelClick(Item)
	
	BackupParameters = New Structure;
	BackupParameters.Insert("CreateDataBackup",           Object.CreateDataBackup);
	BackupParameters.Insert("IBBackupDirectoryName",       Object.IBBackupDirectoryName);
	BackupParameters.Insert("RestoreInfobase", Object.RestoreInfobase);
	
	NotifyDescription = New NotifyDescription("AfterCloseBackupForm", ThisObject);
	ConfigurationUpdateClient.ShowBackup(BackupParameters, NotifyDescription);
	
EndProcedure

&AtClient
Procedure AfterCloseBackupForm(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		FillPropertyValues(Object, Result);
		Items.BackupFileLabel.Title = ConfigurationUpdateClient.BackupCreationTitle(Result);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// SelectUpdateModeServer page

&AtClient
Procedure UpdateRadioButtonsOnChange(Item)
	BeforeOpenPage();
EndProcedure

&AtClient
Procedure EmailReportOnChange(Item)
	BeforeOpenPage();
EndProcedure

&AtClient
Procedure DeferredHandlersLabelURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	InfobaseUpdateClient.ShowDeferredHandlers();
	
EndProcedure

&AtClient
Procedure DetectedIssuesLabelURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	If CommonClient.SubsystemExists("StandardSubsystems.AccountingAudit") Then
		ModuleAccountingAuditInternalClient = CommonClient.CommonModule("AccountingAuditInternalClient");
		ModuleAccountingAuditInternalClient.OpenIssuesReportFromUpdateProcessing(ThisObject, StandardProcessing);
	EndIf;
	
EndProcedure

&AtServer
Function SystemCheckIssues()
	
	If Common.SubsystemExists("StandardSubsystems.AccountingAudit") Then
		ModuleAccountingAuditInternal = Common.CommonModule("AccountingAuditInternal");
		Return ModuleAccountingAuditInternal.SystemCheckIssues();
	EndIf;
	Return False;
	
EndFunction

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure BackButtonClick(Command)
	HandleBackButtonClick();
EndProcedure

&AtClient
Procedure NextButtonClick(Command)
	HandleNextButtonClick();
EndProcedure

&AtClient
Procedure FindAndInstallUpdates(Command)
	
	If CommonClient.SubsystemExists("OnlineUserSupport.GetApplicationUpdates") Then
		Close();
		ModuleGetApplicationUpdatesClient = CommonClient.CommonModule("GetApplicationUpdatesClient");
		ModuleGetApplicationUpdatesClient.UpdateApplication();
	EndIf;

EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure BeforeOpenPage(NewCurrentPage = Undefined)
	
	ParameterName = "StandardSubsystems.MessagesForEventLog";
	If ApplicationParameters[ParameterName] = Undefined Then
		ApplicationParameters.Insert(ParameterName, New ValueList);
	EndIf;
	
	Pages = Items.WizardPages.ChildItems;
	If NewCurrentPage = Undefined Then
		NewCurrentPage = Items.WizardPages.CurrentPage;
	EndIf;
	
	BackButtonAvailable = True;
	NextButtonAvailable = True;
	CloseButtonAvailable = True;
	NextButtonFunction = True; // True = "Next"; False = "Finish."
	CloseButtonFunction = True; // True = "Cancel"; False = "Close."
	
	Items.NextButton.Representation = ButtonRepresentation.Text;
	
	If NewCurrentPage = Pages.NoUpdatesFound Then
		
		NextButtonFunction = False;
		CloseButtonFunction = False;
		NextButtonAvailable = False;
		Items.CurrentConfigurationDetailsLabel.Title = StandardSubsystemsClient.ClientRunParameters().ConfigurationSynonym;
		Items.CurrentConfigurationVersionLabel.Title = StandardSubsystemsClient.ClientRunParameters().ConfigurationVersion;
		
		If Not StandardSubsystemsClient.ClientRunParameters().IsMasterNode Then
			BackButtonAvailable = False;
		EndIf;
		
	ElsIf NewCurrentPage = Pages.SelectUpdateModeFile Then
		
		NextButtonFunction = (Object.UpdateMode = 0);// If not updating now, "Finish."
		
		UpdateConnectionsInformation(Pages.SelectUpdateModeFile);
		
		If Object.CreateDataBackup = 2 Then
			Object.RestoreInfobase = True;
		ElsIf Object.CreateDataBackup = 0 Then
			Object.RestoreInfobase = False;
		EndIf;
		
		Items.BackupFileLabel.Title = ConfigurationUpdateClient.BackupCreationTitle(Object);
		
		If Not StandardSubsystemsClient.ClientRunParameters().IsMasterNode Then
			BackButtonAvailable = False;
		EndIf;
	ElsIf NewCurrentPage = Pages.UpdateModeSelectionServer Then
		
		NextButtonFunction = (Object.UpdateMode = 0);// If not updating now, "Finish."
		Object.RestoreInfobase = False;
		
		RestartInformationPanelPages = Items.RestartInformationPages.ChildItems;
		Items.RestartInformationPages.CurrentPage = ?(Object.UpdateMode = 0,
			RestartInformationPanelPages.RestartNowPage,
			RestartInformationPanelPages.ScheduledRestartPage);
		
		UpdateConnectionsInformation(Pages.UpdateModeSelectionServer);
		
		Items.UpdateDateTimeField.Enabled = (Object.UpdateMode = 2);
		Items.EmailAddress.Enabled   = Object.EmailReport;
		
		If Not StandardSubsystemsClient.ClientRunParameters().IsMasterNode Then
			BackButtonAvailable = False;
		EndIf;
		
		If Object.UpdateMode = 2 Then 
			Items.NextButton.Representation = ButtonRepresentation.PictureAndText;
		EndIf;
		
	ElsIf NewCurrentPage = Pages.UpdateFile Then
		
		BackButtonAvailable = False;
		
		If UpdateFileRequired = 0 Then
			If ConfigurationChanged Then
				Items.ModifiedConfigurationLabelsPages.CurrentPage = Items.ModifiedConfigurationLabelsPages.ChildItems.HasChanges;
			Else
				Items.ModifiedConfigurationLabelsPages.CurrentPage = Items.ModifiedConfigurationLabelsPages.ChildItems.NoChanges;
				NextButtonAvailable = False;
			EndIf;
		EndIf;
		Items.UpdateFromMainConfigurationPanel.Visible = UpdateFileRequired = 0;
		Items.UpdateFileField.Enabled                   = UpdateFileRequired = 1;
		Items.UpdateFileField.AutoMarkIncomplete     = UpdateFileRequired = 1;
		
	EndIf;
	
	ConfigurationUpdateClient.WriteEventsToEventLog();
	
	NextButton = Items.NextButton;
	CloseButton = Items.CloseButton;
	Items.BackButton.Enabled = BackButtonAvailable;
	NextButton.Enabled   = NextButtonAvailable;
	CloseButton.Enabled = CloseButtonAvailable;
	If NextButtonAvailable Then
		If Not NextButton.DefaultButton Then
			NextButton.DefaultButton = True;
		EndIf;
	ElsIf CloseButtonAvailable Then
		If Not CloseButton.DefaultButton Then
			CloseButton.DefaultButton = True;
		EndIf;
	EndIf;
	
	NextButton.Title = ?(NextButtonFunction, NStr("ru = 'Далее >'; en = 'Next >'; pl = 'Dalej >';de = 'Weiter >';ro = 'Următorul >';tr = 'Sonraki >'; es_ES = 'Siguiente >'"), NStr("ru = 'Готово'; en = 'Finish'; pl = 'Koniec';de = 'Abschluss';ro = 'Sfârșit';tr = 'Bitiş'; es_ES = 'Finalizar'"));
	CloseButton.Title = ?(CloseButtonFunction, NStr("ru = 'Отмена'; en = 'Cancel'; pl = 'Anuluj';de = 'Abbrechen';ro = 'Revocare';tr = 'İptal'; es_ES = 'Cancelar'"), NStr("ru = 'Закрыть'; en = 'Close'; pl = 'Zamknij';de = 'Schließen';ro = 'Închideți';tr = 'Kapat'; es_ES = 'Cerrar'"));
	
EndProcedure

&AtClient
Procedure UpdateConnectionsInformation(CurrentPage = Undefined)
	
	If CurrentPage = Undefined Then
		CurrentPage = Items.WizardPages.CurrentPage;
	EndIf;
	
	ParameterName = "StandardSubsystems.MessagesForEventLog";
	If CurrentPage = Items.SelectUpdateModeFile Then
		
		ConnectionsInfo = IBConnectionsServerCall.ConnectionsInformation(False, ApplicationParameters[ParameterName]);
		Items.ConnectionsGroup.Visible = ConnectionsInfo.HasActiveConnections;
		
		If ConnectionsInfo.HasActiveConnections Then
			AllPages = Items.ActiveUsersPanel.ChildItems;
			If ConnectionsInfo.HasCOMConnections Then
				Items.ActiveUsersPanel.CurrentPage = AllPages.ActiveConnections;
			ElsIf ConnectionsInfo.HasDesignerConnection Then
				Items.ActiveUsersPanel.CurrentPage = AllPages.DesignerConnection;
			Else
				Items.ActiveUsersPanel.CurrentPage = AllPages.ActiveUsers;
			EndIf;
		EndIf;
		
	ElsIf CurrentPage = Items.UpdateModeSelectionServer Then
		
		PageParameters = SelectUpdateModePageParametersServer(ApplicationParameters[ParameterName]);
		Items.DeferredHandlersLabel.Visible = PageParameters.DeferredHandlersPresent;
		
		ConnectionsInfo = PageParameters.ConnectionsInformation;
		ConnectionsPresent = ConnectionsInfo.HasActiveConnections AND Object.UpdateMode = 0;
		Items.ConnectionsGroup1.Visible = ConnectionsPresent;
		If ConnectionsPresent Then
			AllPages = Items.ActiveUsersPanel1.ChildItems;
			Items.ActiveUsersPanel1.CurrentPage = ? (ConnectionsInfo.HasCOMConnections, 
				AllPages.ActiveConnections1, AllPages.ActiveUsers1);
		EndIf;
		
	ElsIf CurrentPage = Items.AfterInstallUpdates Then
		
		ConnectionsInfo = IBConnectionsServerCall.ConnectionsInformation(False, ApplicationParameters[ParameterName]);
		Items.ActiveUsersDecoration.Visible = ConnectionsInfo.HasActiveConnections;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure InstallUpdate()
	
	UpdateParameters = New Structure;
	UpdateParameters.Insert("UpdateMode");
	UpdateParameters.Insert("UpdateDateTime");
	UpdateParameters.Insert("EmailReport");
	UpdateParameters.Insert("EmailAddress");
	UpdateParameters.Insert("SchedulerTaskCode");
	UpdateParameters.Insert("CreateDataBackup");
	UpdateParameters.Insert("IBBackupDirectoryName");
	UpdateParameters.Insert("RestoreInfobase");
	UpdateParameters.Insert("NameOfUpdateFile");
	
	FillPropertyValues(UpdateParameters, Object);
	UpdateParameters.Insert("Exit", Parameters.Exit);
	UpdateParameters.Insert("UpdateFileRequired", Boolean(UpdateFileRequired));
	UpdateParameters.Insert("PatchesFiles", PatchesFiles);
	
	ConfigurationUpdateClient.InstallUpdate(ThisObject, UpdateParameters, AdministrationParameters);
	
EndProcedure

&AtClient
Procedure HandleNextButtonClick()
	
	ClearMessages();
	CurrentPage = Items.WizardPages.CurrentPage;
	Pages = Items.WizardPages.ChildItems;
	
	If CurrentPage = Pages.UpdateFile Then
		NavigateFromUpdateFilePage();
	ElsIf CurrentPage = Pages.SelectUpdateModeFile
		Or CurrentPage = Pages.UpdateModeSelectionServer Then
		InstallUpdate();
	ElsIf CurrentPage = Pages.AfterInstallUpdates AND RestartApplication Then
		Exit(True, True);
	Else
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure HandleBackButtonClick()
	
	Pages = Items.WizardPages.ChildItems;
	CurrentPage = Items.WizardPages.CurrentPage;
	NewCurrentPage = CurrentPage;
	
	If CurrentPage = Pages.SelectUpdateModeFile
		Or CurrentPage = Pages.UpdateModeSelectionServer Then
		NewCurrentPage = Pages.UpdateFile;
	EndIf;
	
	BeforeOpenPage(NewCurrentPage);
	Items.WizardPages.CurrentPage = NewCurrentPage;
	
EndProcedure

&AtClient
Procedure NavigateFromUpdateFilePage()
	
	Handler = New NotifyDescription("AfterConfirmSecurity", ThisObject);
	FormParameters = New Structure("Key", "BeforeSelectUpdateFile");
	OpenForm("CommonForm.SecurityWarning", FormParameters, , , , , Handler);
	
EndProcedure

&AtClient
Procedure ProceedToPatchesInstallation()
	
	FilesToPut = New Array;
	For Each PatchFile In PatchesFiles Do
		FilesToPut.Add(New TransferableFileDescription(PatchFile));
	EndDo;
	
	NotifyDescription = New NotifyDescription("ContinueInstallUpdates", ThisObject);
	BeginPuttingFiles(NotifyDescription, FilesToPut,, False, UUID);
	
EndProcedure

&AtClient
Procedure ContinueInstallUpdates(FilesThatWerePut, AdditionalParameters) Export
	
	InstallPatchesAtServer(FilesThatWerePut);
	
	Items.WizardPages.CurrentPage = Items.AfterInstallUpdates;
	Items.NextButton.Title = NStr("ru = 'Готово'; en = 'Finish'; pl = 'Gotowe';de = 'Abschluss';ro = 'Sfârșit';tr = 'Son'; es_ES = 'Finalizar'");
	
EndProcedure

&AtServer
Procedure InstallPatchesAtServer(FilesThatWerePut)
	
	ConnectionsInfo = IBConnectionsServerCall.ConnectionsInformation(False);
	Items.ActiveUsersDecoration.Visible = ConnectionsInfo.HasActiveConnections;
	
	HasErrors = False;
	PatchesInstalled = 0;
	For Each FileThatWasPut In FilesThatWerePut Do
		
		Try
			If StrEndsWith(FileThatWasPut.Name, ".zip") Then
				ArchiveName = GetTempFileName("zip");
				BinaryData = GetFromTempStorage(FileThatWasPut.Location);
				BinaryData.Write(ArchiveName);
				
				PatchFound = False;
				ZIPReader = New ZipFileReader(ArchiveName);
				For Each ArchiveItem In ZIPReader.Items Do
					If ArchiveItem.Extension = "cfe" Then
						PatchFound = True;
						Break;
					EndIf;
				EndDo;
				
				If PatchFound Then
					TempDirectory = FileSystem.CreateTemporaryDirectory("Patches");
					ZIPReader.Extract(ArchiveItem, TempDirectory);
					PatchFullName = TempDirectory + ArchiveItem.Name;
					Data = New BinaryData(PatchFullName);
					DeleteFiles(PatchFullName);
				Else
					Raise NStr("ru = 'Файл не является исправлением.'; en = 'The file is not a patch.'; pl = 'Plik nie jest korektą.';de = 'Die Datei ist kein Fix.';ro = 'Fișierul nu este o corectare.';tr = 'Dosya bir düzeltme değil.'; es_ES = 'El archivo no es corrección.'");
				EndIf;
				ZIPReader.Close();
				DeleteFiles(ArchiveName);
			Else
				Data = GetFromTempStorage(FileThatWasPut.Location);
			EndIf;
			
			Extension = ConfigurationExtensions.Create();
			Extension.SafeMode = False;
			Extension.UsedInDistributedInfoBase = True;
			Extension.UnsafeActionProtection = Common.ProtectionWithoutWarningsDetails();
			Extension.Write(Data);
			
			InstalledExtension = ConfigurationUpdate.ExtensionByID(Extension.UUID);
			If Not ConfigurationUpdate.IsPatch(InstalledExtension) Then
				Extension.Delete();
				Raise NStr("ru = 'Расширение не является патчем.'; en = 'The extension is not a patch.'; pl = 'Rozszerzenie nie jest łatą.';de = 'Die Erweiterung ist kein Patch.';ro = 'Extensia nu este patch.';tr = 'Uzantı yama değildir.'; es_ES = 'La extensión no es parche.'");
			EndIf;
			PatchesInstalled = PatchesInstalled + 1;
		Except
			ErrorInformation = ErrorInfo();
			HasErrors = True;
			PatchFileName = FileNameByPath(FileThatWasPut.Name);
			
			ErrorText = NStr("ru = 'При установке исправления %1 возникла ошибка:
				|%2'; 
				|en = 'An error occurred while installing patch %1:
				|%2'; 
				|pl = 'Podczas instalacji korekty %1 wystąpił błąd:
				|%2';
				|de = 'Bei der Installation der Korrektur %1 ist ein Fehler aufgetreten:
				|%2';
				|ro = 'La instalarea corectării %1 s-a produs eroarea: 
				|%2';
				|tr = '"
" düzeltme kurulduğunda hata oluştu: %1%2'; 
				|es_ES = 'Al instalar la corrección %1 se ha producido un error:
				|%2'");
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText,
				PatchFileName,
				DetailErrorDescription(ErrorInformation));
			WriteLogEvent(NStr("ru = 'Исправления.Установка'; en = 'Patch.Install'; pl = 'Patch.Install';de = 'Patch.Install';ro = 'Patch.Install';tr = 'Patch.Install'; es_ES = 'Patch.Install'", Common.DefaultLanguageCode()),
				EventLogLevel.Error,,, ErrorText);
		EndTry;
	EndDo;
	
	If HasErrors Then
		Items.PatchInstallationError.Visible = True;
		If PatchesInstalled > 0 Then
			LabelText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Установлено исправлений: %1 из %2, изменения вступят в силу после перезапуска программы'; en = 'Patches installed: %1 out of %2. The changes will be applied after you restart the application.'; pl = 'Zainstalowano korekt: %1 z %2, zmiany wejdą w życie po ponownym uruchomieniu programu';de = 'Installierte Fixes: %1 von %2, Änderungen werden nach Neustart des Programms wirksam.';ro = 'Au fost instalate corectările: %1 din %2, modificările vor intra în vigoare după relansarea programului';tr = 'Yapılan düzeltmeler: %1 ''dan %2, değişiklikler program yeniden başladığında geçerli olacaklar'; es_ES = 'Se ha instalado correcciones: %1 de %2, los cambios entrarán en vigor al reiniciar el programa'"),
				PatchesInstalled,
				FilesThatWerePut.Count());
			Items.PatchesInstalledDecoration.Title = LabelText;
			Items.PatchesAreInstalledDecoration.Visible = False;
		Else
			Items.PatchesAreInstalled.Visible = False;
			Items.PatchesInstalledDecoration.Visible = False;
			Return;
		EndIf;
	Else
		Items.PatchInstallationError.Visible = False;
	EndIf;
	
	InformationRegisters.ExtensionVersionParameters.UpdateExtensionParameters();
	
EndProcedure

&AtClient
Procedure ProceedToUpdateModeSelection(IsMoveNext = False)
	
	If AdministrationParameters = Undefined Then
		
		NotifyDescription = New NotifyDescription("AfterGetAdministrationParameters", ThisObject, IsMoveNext);
		FormTitle = NStr("ru = 'Установка обновления'; en = 'Install update'; pl = 'Zainstaluj aktualizację';de = 'Installiere Update';ro = 'Instalarea actualizării';tr = 'Güncellemeyi yükle'; es_ES = 'Instalar la actualización'");
		If IsFileInfobase Then
			NoteLabel = NStr("ru = 'Для установки обновления необходимо ввести
				|параметры администрирования информационной базы'; 
				|en = 'To install the update, enter
				|the infobase administration parameters'; 
				|pl = 'W celu instalacji aktualizacji należy wprowadzić 
				|parametry administrowania bazy informacyjnej';
				|de = 'Um das Update zu installieren, ist es notwendig, die
				|Parameter der Verwaltung der Informationsdatenbank einzugeben.';
				|ro = 'Pentru instalarea actualizării trebuie să introduceți
				|parametrii de administrare a bazei de informații';
				|tr = 'Güncellemeyi ayarlamak için veritabanı
				| yönetim parametrelerini girmek gereklidir'; 
				|es_ES = 'Para establecer la actualización es necesario introducir
				| los parámetros de administración de la infobase'");
			PromptForClusterAdministrationParameters = False;
		Else
			NoteLabel = NStr("ru = 'Для установки обновления необходимо ввести параметры
				|администрирования кластера серверов и информационной базы'; 
				|en = 'To install the update, enter
				|the server cluster and infobase administration parameters'; 
				|pl = 'W celu instalacji aktualizacji należy wprowadzić parametry 
				|administrowania klastera serwerów i bazy informacyjnej';
				|de = 'Um das Update zu installieren, müssen Sie die
				|Administrationsparameter des Server-Clusters und der Informationsbasis eingeben.';
				|ro = 'Pentru instalarea actualizării trebuie să introduceți parametrii
				|de administrare a clusterului serverelor și a bazei de informații';
				|tr = 'Güncelleştirmeyi yüklemek için sunucu ve veritabanı kümesi için 
				|yönetim parametrelerini girmek gerekir'; 
				|es_ES = 'Para instalar la actualización, es necesario introducir los parámetros
				|de administración del clúster de servidores y de la infobase'");
			PromptForClusterAdministrationParameters = True;
		EndIf;
		
		IBConnectionsClient.ShowAdministrationParameters(NotifyDescription, True, PromptForClusterAdministrationParameters,
			AdministrationParameters, FormTitle, NoteLabel);
		
	Else
		
		AfterGetAdministrationParameters(AdministrationParameters, IsMoveNext);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnUpdateLegalityCheck()
	
	If CommonClient.SubsystemExists("StandardSubsystems.SoftwareLicenseCheck") Then
		Notification = New NotifyDescription("OnCheckUpdateLegalityCompletion", ThisObject);
		ModuleSoftwareLicenseCheckClient = CommonClient.CommonModule("SoftwareLicenseCheckClient");
		ModuleSoftwareLicenseCheckClient.ShowLegitimateSoftwareCheck(Notification);
	Else
		OnCheckUpdateLegalityCompletion(True, Undefined);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnCheckUpdateLegalityCompletion(UpdateAcquiredLegally, AdditionalParameters) Export
	
	If UpdateAcquiredLegally = True Then
		ProceedToUpdateModeSelection(True);
	Else
		HandleBackButtonClick();
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterGetAdministrationParameters(Result, IsMoveNext) Export
	
	If IsMoveNext Then
		Items.WizardPages.CurrentPage.Enabled = True;
	EndIf;
	
	If Result <> Undefined Then
		
		AdministrationParameters = Result;
		Pages = Items.WizardPages.ChildItems;
		NewCurrentPage = ?(IsFileInfobase, Pages.SelectUpdateModeFile, Pages.UpdateModeSelectionServer);
		SetAdministratorPassword(AdministrationParameters);
		
		BeforeOpenPage(NewCurrentPage);
		Items.WizardPages.CurrentPage = NewCurrentPage;
		
	Else
		
		WarningText = NStr("ru = 'Для установки обновления необходимо ввести параметры администрирования.'; en = 'To install the update, enter the administration parameters.'; pl = 'Aby zainstalować aktualizację, wprowadź parametry administracyjne.';de = 'Um das Update zu installieren, geben Sie die Administrationsparameter ein.';ro = 'Pentru a instala actualizarea, introduceți parametrii de administrare.';tr = 'Güncellemeyi yüklemek için yönetim parametrelerini girin.'; es_ES = 'Para instalar la actualización, introducir los parámetros de administración.'");
		ShowMessageBox(, WarningText);
		
		MessageText = NStr("ru = 'Не удалось установить обновление программы, т.к. не были введены
			|корректные параметры администрирования информационной базы.'; 
			|en = 'Cannot install the application update as the specified
			|infobase administration parameters are invalid.'; 
			|pl = 'Nie udało się zainstalować aktualizacji aplikacji, ponieważ poprawne parametry
			|administrowania bazy informacyjnej nie zostały wprowadzone.';
			|de = 'Fehler beim Installieren der Anwendungsaktualisierung, d.H., die korrekten
			|Infobase Verwaltungsparameter wurden nicht eingegeben.';
			|ro = 'Imposibil de instalat actualizarea aplicației, adică nu au fost introduși corect
			|parametrii de administrare a bazei de date.';
			|tr = 'Uygulama güncellemesi yüklenemedi, yani, doğru veritabanı yönetim parametreleri 
			|girilmedi.'; 
			|es_ES = 'Fallado a instalar la actualización de la aplicación, por ejemplo, parámetros de administración de la infobase
			|correctos no se han introducido.'");
		EventLogClient.AddMessageForEventLog(ConfigurationUpdateClient.EventLogEvent(), "Error", MessageText);
		
	EndIf;
	
	ConfigurationUpdateClient.WriteEventsToEventLog();
	
EndProcedure

&AtClient
Procedure ShowActiveUsers()
	
	FormParameters = New Structure;
	FormParameters.Insert("NotifyOnClose", True);
	StandardSubsystemsClient.OpenActiveUserList(FormParameters, ThisObject);
	
EndProcedure

&AtServer
Function SelectUpdateModePageParametersServer(MessagesForEventLog)
	
	PageParameters = New Structure;
	PageParameters.Insert("DeferredHandlersPresent", (InfobaseUpdateInternal.UncompletedHandlersStatus() = "UncompletedStatus"));
	PageParameters.Insert("ConnectionsInformation", IBConnections.ConnectionsInformation(False, MessagesForEventLog));
	Return PageParameters;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Scheduling updates.

&AtClient
// Returns a file directory (a partial path without a file name).
//
// Parameters:
//  PathToFile  - String - a path to a file.
//
// Returns:
//   String   - a file directory
Function GetFileDirectory(Val PathToFile)
	
	CharPosition = StrFind(PathToFile, "\", SearchDirection.FromEnd);
	If CharPosition > 1 Then
		Return Mid(PathToFile, 1, CharPosition - 1); 
	Else
		Return "";
	EndIf;
	
EndFunction

&AtServer
Function FileNameByPath(Val PathToFile)
	CharPosition = StrFind(PathToFile, "\", SearchDirection.FromEnd);
	If CharPosition > 1 Then
		Return Mid(PathToFile, CharPosition + 1);
	Else
		Return "";
	EndIf;
EndFunction

&AtServer
Procedure RestoreConfigurationUpdateSettings()
	
	Settings = ConfigurationUpdate.ConfigurationUpdateSettings();
	FillPropertyValues(Object, Settings);
	PatchesFilesAsString = StrConcat(Settings.PatchesFiles, ",");
	If ValueIsFilled(PatchesFilesAsString) Then
		SelectedFiles = Settings.NameOfUpdateFile + "," + PatchesFilesAsString;
	Else
		SelectedFiles = Settings.NameOfUpdateFile;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetAdministratorPassword(AdministrationParameters)
	
	IBAdministrator = InfoBaseUsers.FindByName(AdministrationParameters.InfobaseAdministratorName);
	
	If Not IBAdministrator.StandardAuthentication Then
		
		IBAdministrator.StandardAuthentication = True;
		IBAdministrator.Password = AdministrationParameters.InfobaseAdministratorPassword;
		IBAdministrator.Write();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterConfirmSecurity(Result, AdditionalParameters) Export
	
	If Result = "Continue" Then
		PatchesFiles = New Array;
		
		UpdateFileIsSpecified = False;
		SelectedFileNames = StrSplit(SelectedFiles, ",");
		For Each FileName In SelectedFileNames Do
			If StrEndsWith(FileName, ".cfe")
				Or StrEndsWith(FileName, ".zip") Then
				PatchesFiles.Add(FileName);
			Else // This is an update file.
				If Not UpdateFileIsSpecified Then
					Object.NameOfUpdateFile = FileName;
					UpdateFileIsSpecified = True;
				Else
					Raise NStr("ru = 'Допустимо выбирать только один файл обновления.'; en = 'Only one update file can be selected.'; pl = 'Dostępne jest wybieranie tylko jednego pliku aktualizacji.';de = 'Es kann nur eine Aktualisierungsdatei ausgewählt werden.';ro = 'Se permite alegerea numai unui fișier de actualizare.';tr = 'Sadece bir güncelleme dosyası seçilebilir.'; es_ES = 'Se admite seleccionar solo un archivo de la actualización.'");
				EndIf;
			EndIf;
		EndDo;
		
		If UpdateFileRequired = 1 Then
			If Not ValueIsFilled(SelectedFiles) Then
				CommonClient.MessageToUser(NStr("ru = 'Укажите файл поставки обновления конфигурации.'; en = 'Please select a configuration update delivery file.'; pl = 'Określ dostarczony plik aktualizacji konfiguracji.';de = 'Geben Sie eine Konfigurationsaktualisierungsdatei an.';ro = 'Specificați un fișier de livrare de actualizare a configurației.';tr = 'Bir yapılandırma güncelleme teslim dosyası belirtin.'; es_ES = 'Especificar un archivo de envío de la actualización de configuraciones.'"),,"Object.NameOfUpdateFile");
				CurrentItem = Items.UpdateFileField;
				Return;
			EndIf;
			If Not IsBlankString(Object.NameOfUpdateFile) Then
				File = New File(Object.NameOfUpdateFile);
				If Not File.Exist() Or Not File.IsFile() Then
					CommonClient.MessageToUser(NStr("ru = 'Файл поставки обновления конфигурации не найден.'; en = 'The configuration update delivery file is not found.'; pl = 'Dostarczany plik aktualizacji konfiguracji nie został znaleziony.';de = 'Die Lieferdatei der Konfigurationsaktualisierung wurde nicht gefunden.';ro = 'Fișierul de livrare a actualizării de configurare nu a fost găsit.';tr = 'Yapılandırma güncellemesinin teslim dosyası bulunamadı.'; es_ES = 'Archivo de envío de la actualización de configuraciones no se ha encontrado.'"),,"Object.NameOfUpdateFile");
					CurrentItem = Items.UpdateFileField;
					Return;
				EndIf;
			EndIf;
		EndIf;
		
		If UpdateFileRequired AND Not UpdateFileIsSpecified Then
			ProceedToPatchesInstallation();
		Else
			OnUpdateLegalityCheck();
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion