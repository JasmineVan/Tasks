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
	
	FillPropertyValues(Object, Parameters);
	UpdateControlsStates(ThisObject);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure BackupDirectoryFieldStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	Dialog = New FileDialog(FileDialogMode.ChooseDirectory);
	Dialog.Directory = Object.IBBackupDirectoryName;
	Dialog.CheckFileExist = True;
	Dialog.Title = NStr("ru = 'Выбор каталога резервной копии ИБ'; en = 'Select infobase backup directory'; pl = 'Wybór katalogu kopii zapasowych bazy informacyjnej';de = 'Wählen Sie ein Infobasensicherungsverzeichnis';ro = 'Selectarea directorului copiei de rezervă a BI';tr = 'Bir veritabanı yedekleme dizini seçin'; es_ES = 'Seleccionar un directorio de la creación de la copia de respaldo de la infobase'");
	If Dialog.Choose() Then
		Object.IBBackupDirectoryName = Dialog.Directory;
	EndIf;
	
EndProcedure

&AtClient
Procedure CreateBackupOnChange(Item)
	UpdateControlsStates(ThisObject);
EndProcedure

&AtClient
Procedure RestoreInfobaseOnChange(Item)
	UpdateManualRollbackLabel(ThisObject);
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure OkCommand(Command)
	Cancel = False;
	If Object.CreateDataBackup = 2 Then
		File = New File(Object.IBBackupDirectoryName);
		Cancel = Not File.Exist() Or Not File.IsDirectory();
		If Cancel Then
			ShowMessageBox(, NStr("ru = 'Укажите существующий каталог для сохранения резервной копии ИБ.'; en = 'Please specify an existing directory for storing the infobase backup.'; pl = 'Wskaż istniejący katalog dla zachowania kopii zapasowej BI.';de = 'Geben Sie ein vorhandenes Verzeichnis an, um die IB-Sicherung zu speichern.';ro = 'Indicați catalogul existent pentru salvarea copiei de rezervă a BI.';tr = 'IB yedeğini kaydetmek için varolan bir dizini belirtin.'; es_ES = 'Especificar un directorio existente para guardar la copia de respaldo de la infobase.'"));
			CurrentItem = Items.BackupDirectoryField;
		EndIf;
	EndIf;
	If Not Cancel Then
		SelectionResult = New Structure;
		SelectionResult.Insert("CreateDataBackup",           Object.CreateDataBackup);
		SelectionResult.Insert("IBBackupDirectoryName",       Object.IBBackupDirectoryName);
		SelectionResult.Insert("RestoreInfobase", Object.RestoreInfobase);
		Close(SelectionResult);
	EndIf;
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure UpdateControlsStates(Form)
	
	Form.Items.BackupDirectoryField.AutoMarkIncomplete = (Form.Object.CreateDataBackup = 2);
	Form.Items.BackupDirectoryField.Enabled = (Form.Object.CreateDataBackup = 2);
	InfoPages = Form.Items.InformationPanel.ChildItems;
	CreateDataBackup = Form.Object.CreateDataBackup;
	InformationPanel = Form.Items.InformationPanel;
	If CreateDataBackup = 0 Then // Do not create a backup.
		Form.Object.RestoreInfobase = False;
		InformationPanel.CurrentPage = InfoPages.NoRollback;
	ElsIf CreateDataBackup = 1 Then // Create a temporary backup.
		InformationPanel.CurrentPage = InfoPages.ManualRollback;
		UpdateManualRollbackLabel(Form);
	ElsIf CreateDataBackup = 2 Then // Create a backup in the specified directory.
		Form.Object.RestoreInfobase = True;
		InformationPanel.CurrentPage = InfoPages.AutomaticRollback;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateManualRollbackLabel(Form)
	LabelPages = Form.Items.ManualRollbackLabelsPages.ChildItems;
	Form.Items.ManualRollbackLabelsPages.CurrentPage = ?(Form.Object.RestoreInfobase,
		LabelPages.Restore, LabelPages.DontRestore);
EndProcedure

#EndRegion
