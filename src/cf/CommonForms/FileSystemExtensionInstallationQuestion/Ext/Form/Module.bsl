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
	
	If Not IsBlankString(Parameters.SuggestionText) Then
		Items.NoteDecoration.Title = Parameters.SuggestionText
			+ Chars.LF
			+ NStr("ru = 'Установить?'; en = 'Do you want to install the extension?'; pl = 'Zainstalować?';de = 'Installieren?';ro = 'Instalați?';tr = 'Ayarla?'; es_ES = '¿Instalar?'");
		
	ElsIf Not Parameters.CanContinueWithoutInstalling Then
		Items.NoteDecoration.Title =
			NStr("ru = 'Для выполнения действия требуется установить расширение для веб-клиента 1С:Предприятие.
			           |Установить?'; 
			           |en = 'To perform this operation, you need to install 1C:Enterprise web client extension.
			           |Do you want to install it?'; 
			           |pl = 'Do wykonania czynności wymagane jest zainstalowanie rozszerzenia dla klienta sieci Web 1C:Enterprise.
			           |Zainstalować?';
			           |de = 'Für die Ausführung der Aktion muss eine Erweiterung für den 1C: Enterprise Webclient installiert werden. 
			           |Installieren?';
			           |ro = 'Pentru executarea acțiunii este necesară instalarea extensiei pentru clientul web 1C:Enterprise.
			           |Instalați?';
			           |tr = 'İşlemin yürütülmesi için 1C:Enterprise web istemcisi için uzantı yüklemesi gerekir. 
			           |Yüklensin mi?'; 
			           |es_ES = 'Para la ejecución de la acción, se requiere instalar la extensión para el cliente web de la 1C:Empresa.
			           |¿Instalar?'");
	EndIf;
	
	If Not Parameters.CanContinueWithoutInstalling Then
		Items.ContinueWithoutInstalling.Title = NStr("ru = 'Отмена'; en = 'Cancel'; pl = 'Anuluj';de = 'Abbrechen';ro = 'Revocare';tr = 'İptal'; es_ES = 'Cancelar'");
		Items.DontRemindAgain.Visible = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure InstallAndContinue(Command)
	
	Notification = New NotifyDescription("InstallAndContinueCompletion", ThisObject);
	BeginInstallFileSystemExtension(Notification);
	
EndProcedure

&AtClient
Procedure ContinueWithoutInstalling(Command)
	
	Close("ContinueWithoutInstalling");
	
EndProcedure

&AtClient
Procedure DontRemindAgain(Command)
	
	Close("DoNotPrompt");
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure InstallAndContinueCompletion(Context) Export
	
	Notification = New NotifyDescription("InstallAndContinueAfterAttachExtension", ThisObject);
	BeginAttachingFileSystemExtension(Notification);
	
EndProcedure

&AtClient
Procedure InstallAndContinueAfterAttachExtension(Attached, Context) Export
	
	If Attached Then
		Close("ExtensionAttached");
	Else
		Notification = New NotifyDescription("InstallAndContinueAfterErrorWarning", ThisObject);
		ShowMessageBox(Notification, 
			NStr("ru = 'Не удалось установить расширение для работы с файлами.
			           |по причине:
			           |Метод НачатьПодключениеРасширенияРаботыСФайлами вернул Ложь
			           |
			           |Обратитесь к администратору.'; 
			           |en = 'Could not install the file system extension due to:
			           | StartAttachFileSystemExtension method returned False.
			           |
			           | Contact the administrator.
			           |'; 
			           |pl = 'Nie można zainstalować rozszerzenia do pracy z plikami.
			           |Z powodu:
			           |Metoda StartAttachFileSystemExtension zwrócono Fałsz
			           |
			           |Skontaktuj się z administratorem.';
			           |de = 'Erweiterung für die Arbeit mit Dateien konnte nicht installiert werden.
			           |Aus folgendem Grund:
			           |Die Methode StartAttachFileSystemExtension hat Falsch
			           |
			           |zurückgegeben. Wenden Sie sich an Ihren Administrator.';
			           |ro = 'Eșec la instalarea extensiei pentru lucrul cu fișierele.
			           |din motivul:
			           |Metoda StartAttachFileSystemExtension a returnat Ложь
			           |
			           |Adresați-vă administratorului.';
			           |tr = 'Dosyalarla çalışmak için uzantı 
			           | nedeniyle 
			           |yüklenemedi.  StartAttachFileSystemExtension yöntemi Yanlış olarak cevap verdi.
			           |
			           | Admine başvurun.'; 
			           |es_ES = 'No se ha podido instalar la extensión para usar los archivos.
			           |a causa de:
			           |El método StartAttachFileSystemExtension ha devuelto Falso
			           |
			           |Diríjase al administrador.'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure InstallAndContinueAfterErrorWarning(Context) Export
	
	Close("ContinueWithoutInstalling");
	
EndProcedure

#EndRegion
