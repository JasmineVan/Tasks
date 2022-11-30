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
	If Not ValueIsFilled(Parameters.Key) Then
		ErrorText = 
			NStr("ru = 'Общая форма ""Предупреждение безопасности"" является вспомогательной и открывается из служебных механизмов программы.'; en = 'The common form ""Security warning"" is auxiliary; it is meant to be opened by the internal application algorithms.'; pl = 'Wspólny formularz ""Ostrzeżenie o bezpieczeństwie"" jest pomocniczy; Ma być otwarty przez wewnętrzne algorytmy aplikacji.';de = 'Die allgemeine Form der ""Sicherheitswarnung"" ist eine Hilfsform, die sich aus den Servicemechanismen des Programms öffnet.';ro = 'Forma generală ""Avertisment de securitate"" este auxiliară și se deschide din mecanismele de serviciu ale programului.';tr = '""Güvenlik Uyarısı"" genel formu yardımcı olup  programın hizmet mekanizmalarından açılır.'; es_ES = 'El formulario común ""Avisos de seguridad"" es adicional y se abre de los mecanismos de servicio del programa.'");
		Raise ErrorText;
	EndIf;
	
	CurrentPage = Items.Find(Parameters.Key);
	For Each Page In Items.Pages.ChildItems Do
		Page.Visible = (Page = CurrentPage);
	EndDo;
	Items.Pages.CurrentPage = CurrentPage;
	
	If CurrentPage = Items.AfterUpdate Then
		Items.DenyOpeningExternalReportsAndDataProcessors.DefaultButton = True;
	ElsIf CurrentPage = Items.AfterObtainRight Then
		Items.IAgree.DefaultButton = True;
	EndIf;
	
	PurposeUseKey = Parameters.Key;
	WindowOptionsKey = Parameters.Key;
	
	If Not IsBlankString(Parameters.FileName) Then
		Items.WarningOnOpenFile.Title =
			StringFunctionsClientServer.SubstituteParametersToString(
				Items.WarningOnOpenFile.Title, Parameters.FileName);
	EndIf;
	
	If Common.DataSeparationEnabled() Then 
		Items.WarningBeforeDeleteExtensionBackup.Visible = False;
	Else 
		If Common.SubsystemExists("StandardSubsystems.IBBackup") Then
			
			ModuleIBBackupServer = Common.CommonModule("IBBackupServer");
			
			Backup = New Array;
			Backup.Add(NStr("ru = 'Перед удалением расширения рекомендуется'; en = 'It is recommended that you create an infobase backup'; pl = 'Przed usunięciem rozszerzenia jest zalecane';de = 'Bevor Sie die Erweiterung löschen, wird empfohlen, dass Sie';ro = 'Înainte de ștergerea extensiei recomandăm';tr = 'Uzantıyı silmeden önce'; es_ES = 'Antes de eliminar la extensión se recomienda'"));
			Backup.Add(Chars.LF);
			Backup.Add(New FormattedString(
				NStr("ru = 'выполнить резервное копирование информационной базы'; en = 'before deleting the extension.'; pl = 'wykonaj kopiowanie zapasowe bazy informacyjnej';de = 'eine Sicherungskopie der Infobase durchführen';ro = 'să executați copierea de rezervă a bazei de informații';tr = 'veritabanın yedeklenmesi önerilir'; es_ES = 'hacer una copia de respaldo de la base de información'"),,,,
				ModuleIBBackupServer.BackupDataProcessorURL()));
			Backup.Add(".");
			
			Items.WarningBeforeDeleteExtensionBackup.Title = 
				New FormattedString(Backup);
			
		EndIf;
	EndIf;
	
	If Parameters.MultipleChoice Then 
		Items.WarningBeforeDeleteExtensionTextDelete.Title = NStr("ru = 'Удалить выделенные расширения?'; en = 'Do you want to delete the selected extensions?'; pl = 'Usunąć zaznaczone rozszerzenia?';de = 'Ausgewählte Erweiterungen löschen?';ro = 'Ștergeți extensiile selectate?';tr = 'Seçilen uzantılar silinsin mi?'; es_ES = '¿Eliminar las extensiones seleccionadas?'");
	Else 
		Items.WarningBeforeDeleteExtensionTextDelete.Title = NStr("ru = 'Удалить расширение?'; en = 'Do you want to delete the extension?'; pl = 'Usunąć rozszerzenie?';de = 'Erweiterung löschen?';ro = 'Ștergeți extensia?';tr = 'Uzantı silinsin mi?'; es_ES = '¿Eliminar la extensión?'");
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure WarningBeforeDeleteBackupProcessURLExtension(Item, 
	FormattedStringURL, StandardProcessing)
	
	Close(DialogReturnCode.Cancel);
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure ContinueCommand(Command)
	SelectedButtonName = Command.Name;
	CloseFormAndReturnResult();
EndProcedure

&AtClient
Procedure DenyOpeningExternalReportsAndDataProcessors(Command)
	AllowInteractiveOpening = False;
	ManageRoleAtClient(Command);
EndProcedure

&AtClient
Procedure AllowOpeningExternalReportsAndDataProcessors(Command)
	AllowInteractiveOpening = True;
	ManageRoleAtClient(Command);
EndProcedure

&AtClient
Procedure IAgree(Command)
	SelectedButtonName = Command.Name;
	IAgreeAtServer();
	CloseFormAndReturnResult();
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ManageRoleAtClient(Command)
	SelectedButtonName = Command.Name;
	ManageRoleAtServer();
	RefreshReusableValues();
	ProposeRestart();
EndProcedure

&AtServer
Procedure ManageRoleAtServer()
	If Not AccessRight("Administration", Metadata) Then
		Return;
	EndIf;
	OpeningRole = Metadata.Roles.InteractiveOpenExtReportsAndDataProcessors;
	AdministratorRole = Metadata.Roles.SystemAdministrator;
	
	AdministrationParameters = StandardSubsystemsServer.AdministrationParameters();
	AdministrationParameters.Insert("OpenExternalReportsAndDataProcessorsDecisionMade", True);
	StandardSubsystemsServer.SetAdministrationParameters(AdministrationParameters);
	
	RefreshReusableValues();
	
	IBUsers = InfoBaseUsers.GetUsers();
	For Each InfobaseUser In IBUsers Do
		If AllowInteractiveOpening Then
			If InfobaseUser.Roles.Contains(AdministratorRole)
				AND Not InfobaseUser.Roles.Contains(OpeningRole) Then
				InfobaseUser.Roles.Add(OpeningRole);
				InfobaseUser.Write();
			EndIf;
		Else
			If InfobaseUser.Roles.Contains(OpeningRole) Then
				InfobaseUser.Roles.Delete(OpeningRole);
				InfobaseUser.Write();
			EndIf;
		EndIf;
	EndDo;
	
	If AllowInteractiveOpening Then
		RestartRequired = Not AccessRight("InteractiveOpenExtDataProcessors", Metadata);
	Else
		RestartRequired = AccessRight("InteractiveOpenExtDataProcessors", Metadata);
	EndIf;
	
	IAgreeAtServer();
	
	// In the SaaS mode, data area users do not have the right to open external reports and data 
	// processors.
	If Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagementInternal = Common.CommonModule("AccessManagementInternal");
		ModuleAccessManagementInternal.SetExternalReportsAndDataProcessorsOpenRight(AllowInteractiveOpening);
	EndIf;
	
EndProcedure

&AtServer
Procedure IAgreeAtServer()
	Common.CommonSettingsStorageSave("SecurityWarning", "UserAccepts", True);
EndProcedure

&AtClient
Procedure CloseFormAndReturnResult()
	If IsOpen() Then
		NotifyChoice(SelectedButtonName);
	EndIf;
EndProcedure

&AtClient
Procedure ProposeRestart()
	If Not RestartRequired Then
		CloseFormAndReturnResult();
		Return;
	EndIf;
	
	Handler = New NotifyDescription("RestartApplication", ThisObject);
	Buttons = New ValueList;
	Buttons.Add("Restart", NStr("ru = 'Перезапустить'; en = 'Restart'; pl = 'Uruchom ponownie';de = 'Neustart';ro = 'Repornire';tr = 'Yeniden başlat'; es_ES = 'Reiniciar'"));
	Buttons.Add("DoNotRestart", NStr("ru = 'Не перезапускать'; en = 'Do not restart'; pl = 'Nie uruchamiaj ponownie';de = 'Nicht neu starten';ro = 'Nu relansa';tr = 'Yeniden başlatma'; es_ES = 'No reiniciar'"));
	QuestionText = NStr("ru = 'Для применения изменений требуется перезапустить программу.'; en = 'To apply the changes, restart the application.'; pl = 'Aby zastosować zmiany, należy zrestartować program.';de = 'Um die Änderungen zu übernehmen, muss das Programm neu gestartet werden.';ro = 'Pentru aplicarea modificărilor trebuie să relansați programul.';tr = 'Değişiklikleri uygulamak için program yeniden başlatılmalıdır.'; es_ES = 'Para aplicar los cambios se requiere reiniciar el programa.'");
	ShowQueryBox(Handler, QuestionText, Buttons);
EndProcedure

&AtClient
Procedure RestartApplication(Response, ExecutionParameters) Export
	CloseFormAndReturnResult();
	If Response = "Restart" Then
		Exit(False, True);
	EndIf;
EndProcedure

#EndRegion
