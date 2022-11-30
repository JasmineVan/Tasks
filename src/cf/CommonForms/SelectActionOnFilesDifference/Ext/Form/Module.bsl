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
	
	FillPropertyValues(
		ThisObject,
		Parameters,
		"ChangeDateInWorkingDirectory,
		|ChangeDateInFileStorage,
		|FullFileNameInWorkingDirectory,
		|SizeInWorkingDirectory,
		|SizeInFileStorage,
		|Message,
		|Title");
		
	TestNewer = " (" + NStr("ru='новее'; en = 'newer'; pl = 'nowsze';de = 'neuer';ro = 'mai nou';tr = 'daha yeni'; es_ES = 'más nuevo'") + ")";
	If ChangeDateInWorkingDirectory > ChangeDateInFileStorage Then
		ChangeDateInWorkingDirectory = String(ChangeDateInWorkingDirectory) + TestNewer;
	Else
		ChangeDateInFileStorage = String(ChangeDateInFileStorage) + TestNewer;
	EndIf;
	
	Items.Message.Height = StrLineCount(Message) + 2;
	
	If Parameters.FileOperation = "PutInFileStorage" Then
		
		Items.FormOpenExistingFile.Visible = False;
		Items.FormGetFromStorage.Visible    = False;
		Items.FormPut.DefaultButton   = True;
		
	ElsIf Parameters.FileOperation = "OpenInWorkingFolder" Then
		
		Items.FormPut.Visible  = False;
		Items.FormDontPutFile.Visible = False;
		Items.FormOpenExistingFile.DefaultButton = True;
	Else
		Raise NStr("ru = 'Неизвестное действие над файлом'; en = 'Unknown file operation.'; pl = 'Nieznana operacja na pliku';de = 'Unbekannter Vorgang in Datei';ro = 'Operație necunoscută cu fișierul';tr = 'Dosyada bilinmeyen işlem'; es_ES = 'Operación desconocida en el archivo'");
	EndIf;
	
	If Common.IsMobileClient() Then
		CommandBarLocation = FormCommandBarLabelLocation.Auto;
		Items.MessageIcon.Visible = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure OpenExistingFile(Command)
	
	Close("OpenExistingFile");
	
EndProcedure

&AtClient
Procedure Put(Command)
	
	Close("INTO");
	
EndProcedure

&AtClient
Procedure GetFromApplication(Command)
	
	Close("GetFromStorageAndOpen");
	
EndProcedure

&AtClient
Procedure DontPut(Command)
	
	Close("DontPut");
	
EndProcedure

&AtClient
Procedure OpenDirectory(Command)
	
	FilesOperationsInternalClient.OpenExplorerWithFile(FullFileNameInWorkingDirectory);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close("Cancel");
	
EndProcedure

#EndRegion
