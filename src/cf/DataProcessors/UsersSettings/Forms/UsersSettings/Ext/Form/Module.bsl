///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var NotificationProcessingParameters;

#EndRegion

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	CurrentUserRef = Users.CurrentUser();
	
	If Not Users.IsFullUser() Then
		ConfigureFormForRegularUser();
	EndIf;
	
	If NoViewRight Then
		Items.ReportOrWarning.CurrentPage = Items.InsufficientRights;
		Return;
	EndIf;
	
	CurrentInfobaseUser = DataProcessors.UsersSettings.IBUserName(
		CurrentUserRef);
	
	If Parameters.User <> Undefined Then
		
		IBUserID = Common.ObjectAttributeValue(Parameters.User,
			"IBUserID");
		
		SetPrivilegedMode(True);
		IBUser = InfoBaseUsers.FindByUUID(
			IBUserID);
		SetPrivilegedMode(False);
		
		If IBUser = Undefined Then
			Items.ReportOrWarning.CurrentPage = Items.DisplayWarning;
			Return;
		EndIf;
		
		UserRef = Parameters.User;
		Items.UserRef.Visible = False;
		Title = NStr("ru = 'Настройки пользователя'; en = 'User settings'; pl = 'Ustawienia użytkownika';de = 'Benutzereinstellungen';ro = 'Setările utilizatorului';tr = 'Kullanıcı ayarları'; es_ES = 'Ajustes de usuario'");
	Else
		UserRef = Users.CurrentUser();
	EndIf;
	
	InfoBaseUser = DataProcessors.UsersSettings.IBUserName(UserRef);
	
	UseExternalUsers = GetFunctionalOption("UseExternalUsers");
	
	PersonalSettingsFormName = Common.CommonCoreParameters().PersonalSettingsFormName;
	
	SelectedSettingsPage = Items.SettingsTypes.CurrentPage.Name;
	
EndProcedure

&AtServer
Procedure ConfigureFormForRegularUser()
	
	Items.Copy.Visible = False;
	Items.CopyToOtherUsers.Visible = False;
	Items.CopyFrom.Visible = False;
	Items.ClearSelectedSettings.Visible = False;
	Items.InterfaceContextMenuCopy.Visible = False;
	Items.ReportSettingsTreeContextMenuCopy.Visible = False;
	Items.OtherSettingsContextMenuCopy.Visible = False;
	
	NoViewRight = (CurrentUserRef <> Parameters.User);
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	SearchChoiceList = Settings.Get("SearchChoiceList");
	If TypeOf(SearchChoiceList) = Type("Array") Then
		Items.Search.ChoiceList.LoadValues(SearchChoiceList);
	EndIf;
	Search = "";
	
EndProcedure

&AtServer
Procedure OnSaveDataInSettingsAtServer(Settings)
	
	Settings.Insert("SearchChoiceList", Items.Search.ChoiceList.UnloadValues());
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	NotificationProcessingParameters = New Structure("EventName, Parameter", EventName, Parameter);
	AttachIdleHandler("Attachable_ProcessNotification", 0.1, True);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If NoViewRight Then
		Return;
	EndIf;
	
	AttachIdleHandler("UpdateSettingsList", 0.1, True);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OnChangePage(Item, CurrentPage)
	
	SelectedSettingsPage = CurrentPage.Name;
	
EndProcedure

&AtClient
Procedure SearchOnChange(Item)
	
	If ValueIsFilled(Search) Then
		ChoiceList = Items.Search.ChoiceList;
		ListItem = ChoiceList.FindByValue(Search);
		If ListItem = Undefined Then
			ChoiceList.Insert(0, Search);
			If ChoiceList.Count() > 10 Then
				ChoiceList.Delete(10);
			EndIf;
		Else
			Index = ChoiceList.IndexOf(ListItem);
			If Index <> 0 Then
				ChoiceList.Move(Index, -Index);
			EndIf;
		EndIf;
		CurrentItem = Items.Search;
	EndIf;
	
	UpdateSettingsList();
	
EndProcedure

&AtClient
Procedure UserRefStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	FilterParameters = New Structure("ChoiceMode", True);
	
	If UseExternalUsers Then
		UsersTypeSelection = New ValueList;
		UsersTypeSelection.Add("ExternalUsers", NStr("ru = 'Внешние пользователи'; en = 'External users'; pl = 'Użytkownicy zewnętrzni';de = 'Externe Benutzer';ro = 'Utilizatori externi';tr = 'Harici kullanıcılar'; es_ES = 'Usuarios externos'"));
		UsersTypeSelection.Add("Users",        NStr("ru = 'Пользователи'; en = 'Users'; pl = 'Użytkownicy';de = 'Benutzer';ro = 'Utilizatori';tr = 'Kullanıcılar'; es_ES = 'Usuarios'"));
		
		UsersTypeSelection.ShowChooseItem(New NotifyDescription(
			"UserRefStartChoiceCompletion", ThisObject, FilterParameters));
	Else
		OpenForm("Catalog.Users.Form.ListForm",
			FilterParameters, Items.UserRef);
	EndIf;
	
EndProcedure

&AtClient
Procedure UserRefStartChoiceCompletion(SelectedOption, FilterParameters) Export
	
	If SelectedOption = Undefined Then
		Return;
	EndIf;
	
	If SelectedOption.Value = "Users" Then
		OpenForm("Catalog.Users.Form.ListForm",
			FilterParameters, Items.UserRef);
		
	ElsIf SelectedOption.Value = "ExternalUsers" Then
		OpenForm("Catalog.ExternalUsers.Form.ListForm",
			FilterParameters, Items.UserRef);
	EndIf;
	
EndProcedure

&AtClient
Procedure ReportAndInterfaceSettingsBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
	
	If Not Clone Then
		Cancel = True;
		Return;
	EndIf;
	
	CopySettings();
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure SettingsBeforeDelete(Item, Cancel)
	
	Cancel = True;
	
	QuestionText = NStr("ru = 'Очистить выбранные настройки?'; en = 'Do you want to clear the selected settings?'; pl = 'Czy usunąć wybrane ustawienia?';de = 'Löschen Sie die ausgewählten Einstellungen?';ro = 'Goliți setările selectate?';tr = 'Seçilen ayarları temizle?'; es_ES = '¿Eliminar las configuraciones seleccionadas?'");
	Notification = New NotifyDescription("SettingsBeforeDeleteCompletion", ThisObject, Item);
	
	ShowQueryBox(Notification, QuestionText, QuestionDialogMode.YesNo,, DialogReturnCode.Yes);
	
EndProcedure

&AtClient
Procedure SettingsTreeChoice(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	UsersInternalClient.OpenReportOrForm(CurrentItem,
		InfoBaseUser, CurrentInfobaseUser, PersonalSettingsFormName);
	
EndProcedure

&AtClient
Procedure UserRefOnChange(Item)
	
	Items.CommandBar.Enabled = Not IsBlankString(Item.SelectedText);
	
	If SettingsGettingResult() = "NoIBUser" Then
		UserRef = CurrentUserRef;
		
		ShowMessageBox(, StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'У выбранного пользователя ""%1"" не указан
			           |пользователь информационной базы, просмотреть его настройки невозможно.
			           |Устранить проблему можно в карточке данного пользователя.'; 
			           |en = 'Cannot view the settings of the selected user ""%1""
			           |because it is not mapped to an infobase user.
			           |You can correct this in the user profile.'; 
			           |pl = 'Wybrany użytkownik ""%1"" nie posiada
			           | bazy danych o użytkownikach, niemożliwe jest przejrzenie jej ustawień. 
			           |Możesz rozwiązać problem na karcie użytkownika.';
			           |de = 'Der ausgewählte Benutzer ""%1"" hat nicht den 
			           |Benutzer der Informationsbasis, es ist unmöglich, seine Einstellungen zu sehen.
			           |Das Problem kann im Benutzerprofil behoben werden.';
			           |ro = 'La utilizatorul selectat ""%1"" nu este indicat
			           |utilizatorul bazei de informații, setările lui nu pot fi vizualizate.
			           |Puteți înlătura problema în fișa acestui utilizator.';
			           |tr = 'Seçilen ""%1"" kullanıcısı veritabanı kullanıcısı tarafından listelenmiyor, 
			           |ayarlarını görüntüleyemiyor. 
			           |Sorunu bu kullanıcının kartında çözebilirsiniz.'; 
			           |es_ES = 'Para el usuario seleccionado ""%1"" no está especificado
			           | el usuario de la base de información, es imposible ver sus ajustes.
			           |Se puede resolver este problema en la tarjeta de este usuario.'"),
			UserRef));
		Return;
	EndIf;
	
	UpdateSettingsList();
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Update(Command)
	
	UpdateSettingsList();
	
EndProcedure

&AtClient
Procedure CopyToOtherUsers(Command)
	
	CopySettings();
	
EndProcedure

&AtClient
Procedure CopyAllSettings(Command)
	
	SettingsToCopy.Clear();
	
	SettingsToCopy.Add("ReportSettings",      NStr("ru = 'Настройки отчетов'; en = 'Report settings'; pl = 'Ustawienia sprawozdań';de = 'Berichtseinstellungen';ro = 'Setările rapoartelor';tr = 'Rapor ayarları'; es_ES = 'Ajustes de informes'"));
	SettingsToCopy.Add("InterfaceSettings", NStr("ru = 'Настройки внешнего вида'; en = 'Interface settings'; pl = 'Ustawienia wyglądu';de = 'Aussehen Einstellungen';ro = 'Setările aspectului extern';tr = 'Görünüm ayarları'; es_ES = 'Configuraciones del aspecto'"));
	SettingsToCopy.Add("FormData",            NStr("ru = 'Данные форм'; en = 'Form data'; pl = 'Dane formularza';de = 'Formulardaten';ro = 'Date formular';tr = 'Veri oluştur'; es_ES = 'Datos del formulario'"));
	SettingsToCopy.Add("PersonalSettings", NStr("ru = 'Персональные настройки'; en = 'Personal settings'; pl = 'Osobiste ustawienia';de = 'Persönliche Einstellungen';ro = 'Setări personale';tr = 'Kişisel ayarlar'; es_ES = 'Configuraciones personales'"));
	SettingsToCopy.Add("Favorites",             NStr("ru = 'Избранное'; en = 'Favorites'; pl = 'Ulubione';de = 'Favoriten';ro = 'Favorite';tr = 'Sık kullanılanlar'; es_ES = 'Favoritos'"));
	SettingsToCopy.Add("PrintSettings",       NStr("ru = 'Настройки печати'; en = 'Print settings'; pl = 'Ustawienia drukowania';de = 'Druckeinstellungen';ro = 'Setări de imprimare';tr = 'Yazdırma ayarları'; es_ES = 'Imprimir configuraciones'"));
	SettingsToCopy.Add("OtherUserSettings",
		NStr("ru = 'Настройки дополнительных отчетов и обработок'; en = 'Additional report and data processor settings'; pl = 'Ustawienia dodatkowych raportów i przetwarzania';de = 'Einstellungen von zusätzlichen Berichten und Datenprozessoren';ro = 'Setările rapoartelor și procesărilor suplimentare';tr = 'Ek raporlar ve veri işlemcilerin ayarları'; es_ES = 'Configuraciones de informes adicionales y procesadores de datos'"));
	
	FormParameters = New Structure;
	FormParameters.Insert("User", UserRef);
	FormParameters.Insert("ActionType",  "CopyAll");
	
	OpenForm("DataProcessor.UsersSettings.Form.SelectUsers", FormParameters);
	
EndProcedure

&AtClient
Procedure CopyReportSettings(Command)
	
	SettingsToCopy.Clear();
	
	SettingsToCopy.Add("ReportSettings", NStr("ru = 'Настройки отчетов'; en = 'Report settings'; pl = 'Ustawienia sprawozdań';de = 'Berichtseinstellungen';ro = 'Setările rapoartelor';tr = 'Rapor ayarları'; es_ES = 'Ajustes de informes'"));
	
	FormParameters = New Structure;
	FormParameters.Insert("User", UserRef);
	FormParameters.Insert("ActionType",  "CopyAll");
	
	OpenForm("DataProcessor.UsersSettings.Form.SelectUsers", FormParameters);
	
EndProcedure

&AtClient
Procedure CopyInterfaceSettings(Command)
	
	SettingsToCopy.Clear();
	
	SettingsToCopy.Add("InterfaceSettings", NStr("ru = 'Настройки внешнего вида'; en = 'Interface settings'; pl = 'Ustawienia wyglądu';de = 'Aussehen Einstellungen';ro = 'Setările aspectului extern';tr = 'Görünüm ayarları'; es_ES = 'Configuraciones del aspecto'"));
	
	FormParameters = New Structure;
	FormParameters.Insert("User", UserRef);
	FormParameters.Insert("ActionType",  "CopyAll");
	
	OpenForm("DataProcessor.UsersSettings.Form.SelectUsers", FormParameters);
	
EndProcedure

&AtClient
Procedure CopyReportAndInterfaceSettings(Command)
	
	SettingsToCopy.Clear();
	SettingsToCopy.Add("ReportSettings",      NStr("ru = 'Настройки отчетов'; en = 'Report settings'; pl = 'Ustawienia sprawozdań';de = 'Berichtseinstellungen';ro = 'Setările rapoartelor';tr = 'Rapor ayarları'; es_ES = 'Ajustes de informes'"));
	SettingsToCopy.Add("InterfaceSettings", NStr("ru = 'Настройки внешнего вида'; en = 'Interface settings'; pl = 'Ustawienia wyglądu';de = 'Aussehen Einstellungen';ro = 'Setările aspectului extern';tr = 'Görünüm ayarları'; es_ES = 'Configuraciones del aspecto'"));
	
	FormParameters = New Structure;
	FormParameters.Insert("User", UserRef);
	FormParameters.Insert("ActionType",  "CopyAll");
	
	OpenForm("DataProcessor.UsersSettings.Form.SelectUsers", FormParameters);
	
EndProcedure

&AtClient
Procedure Clear(Command)
	
	SettingsTree = SelectedSettingsPageFormTable();
	
	If SettingsTree.SelectedRows.Count() = 0 Then
		
		ShowMessageBox(,NStr("ru = 'Необходимо выбрать настройки, которые требуется удалить.'; en = 'Please select the settings that you want to clear.'; pl = 'Wybierz ustawienia do usunięcia.';de = 'Wählen Sie die zu löschenden Einstellungen.';ro = 'Selectați setările pentru ștergere.';tr = 'Silmek için ayarları seçin.'; es_ES = 'Seleccionar las configuraciones para borrar.'"));
		Return;
		
	EndIf;
	
	Notification = New NotifyDescription("ClearCompletion", ThisObject, SettingsTree);
	QuestionText = NStr("ru = 'Очистить выделенные настройки?'; en = 'Do you want to clear the selected settings?'; pl = 'Czy usunąć wybrane ustawienia?';de = 'Löschen Sie die ausgewählten Einstellungen?';ro = 'Ștergeți setările selectate?';tr = 'Seçilen ayarları temizle?'; es_ES = '¿Eliminar las configuraciones seleccionadas?'");
	
	ShowQueryBox(Notification, QuestionText, QuestionDialogMode.YesNo,, DialogReturnCode.Yes);
	
EndProcedure

&AtClient
Procedure ClearSettingsForSelectedUsers(Command)
	
	SettingsTree = SelectedSettingsPageFormTable();
	SelectedRows = SettingsTree.SelectedRows;
	If SelectedRows.Count() = 0 Then
		
		ShowMessageBox(, NStr("ru = 'Необходимо выбрать настройки, которые требуется удалить.'; en = 'Please select the settings that you want to clear.'; pl = 'Wybierz ustawienia do usunięcia.';de = 'Wählen Sie die zu löschenden Einstellungen.';ro = 'Selectați setările pentru ștergere.';tr = 'Silmek için ayarları seçin.'; es_ES = 'Seleccionar las configuraciones para borrar.'"));
		Return;
		
	EndIf;
	
	QuestionText =
		NStr("ru = 'Очистить выделенные настройки?
		           |Откроется окно выбора пользователей, которым необходимо очистить настройки.'; 
		           |en = 'Do you want to clear the selected settings?
		           |This will open the list where you can select the users whose settings will be cleared.'; 
		           |pl = 'Wyczyść wybrane ustawienia?
		           |Otworzy się okno wyboru użytkowników, ustawienia których należy usunąć.';
		           |de = 'Die markierten Einstellungen löschen?
		           |Es erscheint das Fenster zur Auswahl der Benutzer, die die Einstellungen löschen müssen.';
		           |ro = 'Ștergeți setările selectate?
		           |Se va deschide fereastra de selectare a utilizatorilor, setările cărora trebuie șterse.';
		           |tr = 'Seçilen ayarları temizle? 
		           |Ayarları temizlenecek olan kullanıcı seçim penceresi açılacaktır.'; 
		           |es_ES = '¿Eliminar los ajustes seleccionados?
		           |Eso abrirá la pantalla de selección cuyos ajustes tienen que eliminarse.'");
	
	Notification = New NotifyDescription("ClearSettingsForSelectedUsersCompletion", ThisObject);
	
	ShowQueryBox(Notification, QuestionText, QuestionDialogMode.YesNo,, DialogReturnCode.Yes);
	
EndProcedure

&AtClient
Procedure ClearAllSettings(Command)
	
	QuestionText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Очистить все настройки у пользователя ""%1""?'; en = 'Do you want to clear all settings for user ""%1""?'; pl = 'Oczyść wszystkie ustawienia użytkownika ""%1""?';de = 'Löschen Sie alle Einstellungen des Benutzers ""%1""?';ro = 'Ștergeți toate setările utilizatorului ""%1""?';tr = 'Tüm ""%1"" kullanıcı ayarlarını temizle?'; es_ES = '¿Eliminar todas las configuraciones del usuario ""%1""?'"), String(UserRef));
	
	QuestionButtons = New ValueList;
	QuestionButtons.Add("Clear", NStr("ru = 'Очистить'; en = 'Clear'; pl = 'Wyczyść';de = 'Löschen';ro = 'Golire';tr = 'Temizle'; es_ES = 'Eliminar'"));
	QuestionButtons.Add("Cancel",   NStr("ru = 'Отмена'; en = 'Cancel'; pl = 'Anuluj';de = 'Abbrechen';ro = 'Revocare';tr = 'İptal'; es_ES = 'Cancelar'"));
	
	Notification = New NotifyDescription("ClearAllSettingsCompletion", ThisObject);
	
	ShowQueryBox(Notification, QuestionText, QuestionButtons,, QuestionButtons[1].Value);
	
EndProcedure

&AtClient
Procedure ClearReportAndInterfaceSettings(Command)
	
	QuestionText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Очистить все настройки отчетов и внешнего вида у пользователя ""%1""?'; en = 'Do you want to clear all interface and report settings for user ""%1""?'; pl = 'Oczyść wszystkie ustawienia sprawozdań i wyglądu użytkownika ""%1""?';de = 'Löschen Sie alle Einstellungen von Berichten und Aussehen von Benutzer ""%1""?';ro = 'Goliți toate setările rapoartelor și aspectului utilizatorului ""%1""?';tr = 'Tüm rapor ayarlarını ve ""%1"" kullanıcı görünümünü temizle?'; es_ES = '¿Eliminar todas las configuraciones de informes y el aspecto del usuario ""%1""?'"),
		String(UserRef));
	
	QuestionButtons = New ValueList;
	QuestionButtons.Add("Clear", NStr("ru = 'Очистить'; en = 'Clear'; pl = 'Wyczyść';de = 'Löschen';ro = 'Golire';tr = 'Temizle'; es_ES = 'Eliminar'"));
	QuestionButtons.Add("Cancel",   NStr("ru = 'Отмена'; en = 'Cancel'; pl = 'Anuluj';de = 'Abbrechen';ro = 'Revocare';tr = 'İptal'; es_ES = 'Cancelar'"));
	
	Notification = New NotifyDescription("ClearReportAndInterfaceSettingsCompletion", ThisObject);
	
	ShowQueryBox(Notification, QuestionText, QuestionButtons,, QuestionButtons[1].Value);
	
EndProcedure

&AtClient
Procedure OpenSettingsItem(Command)
	
	UsersInternalClient.OpenReportOrForm(CurrentItem,
		InfoBaseUser, CurrentInfobaseUser, PersonalSettingsFormName);
	
EndProcedure

&AtClient
Procedure ClearSettingsForAllUsers(Command)
	
	QuestionText =
		NStr("ru = 'Сейчас будут очищены все настройки всех пользователей.
		           |Продолжить?'; 
		           |en = 'All settings of all users will be cleared.
		           |Do you want to continue?'; 
		           |pl = 'Wszystkie ustawienia użytkownika zostaną oczyszczone.
		           |Kontynuować?';
		           |de = 'Alle Benutzereinstellungen werden gelöscht.
		           |Fortsetzen?';
		           |ro = 'Acum vor fi golite toate setările ale tuturor utilizatorilor.
		           |Continuați?';
		           |tr = 'Tüm kullanıcı ayarları temizlenecek. 
		           |Devam et?'; 
		           |es_ES = 'Todas las configuraciones del usuario se eliminarán.
		           |¿Continuar?'");
	
	QuestionButtons = New ValueList;
	QuestionButtons.Add("ClearAll", NStr("ru = 'Очистить все'; en = 'Clear all'; pl = 'Odznacz wszystko';de = 'Alles löschen';ro = 'Golire toate';tr = 'Tümünü temizle'; es_ES = 'Eliminar todo'"));
	QuestionButtons.Add("Cancel",      NStr("ru = 'Отмена'; en = 'Cancel'; pl = 'Anuluj';de = 'Abbrechen';ro = 'Revocare';tr = 'İptal'; es_ES = 'Cancelar'"));
	
	Notification = New NotifyDescription("ClearSettingsForAllUsersCompletion", ThisObject);
	ShowQueryBox(Notification, QuestionText, QuestionButtons,, QuestionButtons[1].Value);
	
EndProcedure

&AtClient
Procedure CopyFrom(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("User",       UserRef);
	FormParameters.Insert("FormOpeningMode", "CopyFrom");
	
	OpenForm("DataProcessor.UsersSettings.Form.CopyUsersSettings", FormParameters);
	
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions for displaying lists of settings.

&AtClient
Procedure UpdateSettingsList()
	
	Items.QuickSearch.Enabled = False;
	Items.CommandBar.Enabled = False;
	Items.TimeConsumingOperationPages.CurrentPage = Items.TimeConsumingOperationPage;
	
	Result = UpdatingSettingsList();
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow = False;
	
	CompletionNotification = New NotifyDescription("UpdateSettingsListCompletion", ThisObject);
	
	TimeConsumingOperationsClient.WaitForCompletion(Result, CompletionNotification, IdleParameters);
	
EndProcedure

&AtServer
Function UpdatingSettingsList()
	
	If ExecutionResult <> Undefined
	   AND ValueIsFilled(ExecutionResult.JobID) Then
		TimeConsumingOperations.CancelJobExecution(ExecutionResult.JobID);
	EndIf;
	
	TimeConsumingOperationParameters = TimeConsumingOperationParameters();
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.WaitForCompletion = 0; // Run immediately.
	ExecutionParameters.BackgroundJobDescription = NStr("ru = 'Обновление настроек пользователей'; en = 'Update user settings'; pl = 'Aktualizacja ustawień użytkowników';de = 'Aktualisieren der Benutzereinstellungen';ro = 'Actualizarea setărilor utilizatorilor';tr = 'Kullanıcı ayarlarının güncellenmesi'; es_ES = 'Actualización de los ajustes de usuarios'");
	
	ExecutionResult = TimeConsumingOperations.ExecuteInBackground("UsersInternal.FillSettingsLists",
		TimeConsumingOperationParameters, ExecutionParameters);
	
	Return ExecutionResult;
	
EndFunction

&AtClient
Procedure UpdateSettingsListCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Completed" Then
		FillSettings();
		ExpandValueTree();
		
		Items.TimeConsumingOperationPages.CurrentPage = Items.SettingsPage;
		Items.QuickSearch.Enabled = True;
		Items.CommandBar.Enabled = True;
		
	ElsIf Result.Status = "Error" Then
		Items.TimeConsumingOperationPages.CurrentPage = Items.SettingsPage;
		Raise Result.BriefErrorPresentation;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillSettings()
	
	Result = GetFromTempStorage(ExecutionResult.ResultAddress);
	
	ValueToFormAttribute(Result.ReportSettingsTree, "ReportSettings");
	ValueToFormAttribute(Result.UserReportOptions, "UserReportOptionTable");
	ValueToFormAttribute(Result.InterfaceSettings, "Interface");
	ValueToFormAttribute(Result.OtherSettingsTree, "OtherSettings");
	
	CalculateSettingsCount();
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions for calculating the number of settings items.

&AtServer
Procedure CalculateSettingsCount()
	
	SettingsList = ReportSettings.GetItems();
	SettingsCount = SettingsInTreeCount(SettingsList);
	
	If SettingsCount <> 0 Then
		Items.ReportSettingsPage.Title =
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru='Настройки отчетов (%1)'; en = 'Report settings (%1)'; pl = 'Ustawienia sprawozdania (%1)';de = 'Berichteinstellungen (%1)';ro = 'Setările raportului (%1)';tr = 'Rapor ayarları (%1)'; es_ES = 'Configuraciones del informe (%1)'"), SettingsCount);
	Else
		Items.ReportSettingsPage.Title = NStr("ru = 'Настройки отчетов'; en = 'Report settings'; pl = 'Ustawienia sprawozdań';de = 'Berichtseinstellungen';ro = 'Setările rapoartelor';tr = 'Rapor ayarları'; es_ES = 'Ajustes de informes'");
	EndIf;
	
	SettingsList = Interface.GetItems();
	SettingsCount = SettingsInTreeCount(SettingsList);
	
	If SettingsCount <> 0 Then
		Items.InterfacePage.Title =
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Внешний вид (%1)'; en = 'Interface settings (%1)'; pl = 'Formatowanie (%1)';de = 'Erscheinen (%1)';ro = 'Aspectul (%1)';tr = 'Düzenleme (%1)'; es_ES = 'Aspecto (%1)'"), SettingsCount);
	Else
		Items.InterfacePage.Title = NStr("ru = 'Внешний вид'; en = 'Interface'; pl = 'Wygląd';de = 'Aussehen';ro = 'Aspectul';tr = 'Dış görüntü'; es_ES = 'Aspecto'");
	EndIf;
	
	SettingsList = OtherSettings.GetItems();
	SettingsCount = SettingsInTreeCount(SettingsList);
	
	If SettingsCount <> 0 Then
		Items.OtherSettingsPage.Title =
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Прочие настройки (%1)'; en = 'Other settings (%1)'; pl = 'Inne ustawienia (%1)';de = 'Andere Einstellungen (%1)';ro = 'Alte setări (%1)';tr = 'Diğer ayarlar (%1)'; es_ES = 'Otras configuraciones (%1)'"), SettingsCount);
	Else
		Items.OtherSettingsPage.Title = NStr("ru = 'Прочие настройки'; en = 'Other settings'; pl = 'Inne ustawienia';de = 'Andere Einstellungen';ro = 'Alte setări';tr = 'Diğer ayarlar'; es_ES = 'Otras configuraciones'");
	EndIf;
	
EndProcedure

&AtServer
Function SettingsInTreeCount(SettingsList)
	
	SettingsCount = 0;
	For Each Setting In SettingsList Do
		
		SubordinateSettingsCount = Setting.GetItems().Count();
		If SubordinateSettingsCount = 0 Then
			SettingsCount = SettingsCount + 1;
		Else
			SettingsCount = SettingsCount + SubordinateSettingsCount;
		EndIf;
		
	EndDo;
	
	Return SettingsCount;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions for copying, deleting, and clearing settings.

&AtServer
Procedure CopyAtServer(UsersDestination, ReportPersonalizationCount, Report)
	
	Result = SelectedSettings();
	SelectedReportOptionsTable = New ValueTable;
	SelectedReportOptionsTable.Columns.Add("Presentation");
	SelectedReportOptionsTable.Columns.Add("StandardProcessing");
	
	If SelectedSettingsPage = "ReportSettingsPage" Then
		
		For Each Setting In Result.SettingsArray Do
			
			For Each Item In Setting Do
				
				If Item.Check Then
					ReportPersonalizationCount = ReportPersonalizationCount + 1;
					ReportKey = StringFunctionsClientServer.SubstituteParametersToString(Item.Value, "/");
					
					FilterParameter = New Structure("ObjectKey", ReportKey[0]);
					RowsArray = UserReportOptionTable.FindRows(FilterParameter);
					
					If RowsArray.Count() <> 0 Then
						TableRow = SelectedReportOptionsTable.Add();
						TableRow.Presentation = RowsArray[0].Presentation;
						TableRow.StandardProcessing = True;
					EndIf;
					
				EndIf;
				
			EndDo;
			
		EndDo;
		
		NotCopiedReportSettings = New ValueTable;
		NotCopiedReportSettings.Columns.Add("User");
		NotCopiedReportSettings.Columns.Add("ReportsList", New TypeDescription("ValueList"));
		
		DataProcessors.UsersSettings.CopyReportAndPersonalSettings(
			ReportsUserSettingsStorage,
			InfoBaseUser,
			UsersDestination,
			Result.SettingsArray,
			NotCopiedReportSettings);
		
		// Copying report options.
		DataProcessors.UsersSettings.CopyReportOptions(Result.ReportOptionArray,
			UserReportOptionTable, InfoBaseUser, UsersDestination);
			
		If NotCopiedReportSettings.Count() <> 0
		 Or UserReportOptionTable.Count() <> 0 Then
			
			Report = DataProcessors.UsersSettings.CreateReportOnCopyingSettings(
				NotCopiedReportSettings, SelectedReportOptionsTable);
		EndIf;
		
	ElsIf SelectedSettingsPage = "InterfacePage" Then
		DataProcessors.UsersSettings.CopyInterfaceSettings(InfoBaseUser,
			UsersDestination, Result.SettingsArray);
	Else
		
		If Result.PersonalSettingsArray.Count() <> 0 Then
			DataProcessors.UsersSettings.CopyReportAndPersonalSettings(
				CommonSettingsStorage,
				InfoBaseUser,
				UsersDestination,
				Result.PersonalSettingsArray);
		EndIf;
			
		If Result.UserSettingsArray.Count() <> 0 Then
			
			For Each OtherUserSettings In Result.UserSettingsArray Do
				For Each DestinationUser In UsersDestination Do
					
					UserInfo = New Structure;
					UserInfo.Insert("UserRef", DestinationUser);
					UserInfo.Insert("InfobaseUserName",
						DataProcessors.UsersSettings.IBUserName(DestinationUser));
					
					UsersInternal.OnSaveOtherUserSettings(
						UserInfo, OtherUserSettings);
				EndDo;
			EndDo;
		EndIf;
		
		DataProcessors.UsersSettings.CopyInterfaceSettings(
			InfoBaseUser, UsersDestination, Result.SettingsArray);
	EndIf;
	
EndProcedure

&AtServer
Procedure CopyAllSettingsAtServer(User, UsersDestination, SettingsArray, Report)
	
	NotCopiedReportSettings = New ValueTable;
	NotCopiedReportSettings.Columns.Add("User");
	NotCopiedReportSettings.Columns.Add("ReportsList", New TypeDescription("ValueList"));
	
	DataProcessors.UsersSettings.CopyUsersSettings(
		UserRef, UsersDestination, SettingsArray, NotCopiedReportSettings);
		
	If NotCopiedReportSettings.Count() <> 0
	 Or UserReportOptionTable.Count() <> 0 Then
		
		Report = DataProcessors.UsersSettings.CreateReportOnCopyingSettings(
			NotCopiedReportSettings, UserReportOptionTable);
	EndIf;
	
EndProcedure

&AtServer
Procedure ClearAtServer(Users = Undefined, SelectedUsers = False)
	
	Result = SelectedSettings();
	StorageDescription = SettingsStorageForSelectedPage();
	
	If SelectedUsers Then
		
		DataProcessors.UsersSettings.DeleteSettingsForSelectedUsers(Users,
			Result.SettingsArray, StorageDescription);
		
		If Result.PersonalSettingsArray.Count() <> 0 Then
			DataProcessors.UsersSettings.DeleteSettingsForSelectedUsers(Users,
				Result.PersonalSettingsArray, "CommonSettingsStorage");
		EndIf;
		
		Return;
	EndIf;
	
	// Clear settings
	UserInfo = New Structure;
	UserInfo.Insert("InfobaseUserName", InfoBaseUser);
	UserInfo.Insert("UserRef", UserRef);
	
	DataProcessors.UsersSettings.DeleteSelectedSettings(UserInfo,
		Result.SettingsArray, StorageDescription);
	
	If Result.PersonalSettingsArray.Count() <> 0 Then
		DataProcessors.UsersSettings.DeleteSelectedSettings(UserInfo,
			Result.PersonalSettingsArray, "CommonSettingsStorage");
	EndIf;
	
	If Result.UserSettingsArray.Count() <> 0 Then
		
		For Each OtherUserSettings In Result.UserSettingsArray Do
			UsersInternal.OnDeleteOtherUserSettings(
				UserInfo, OtherUserSettings);
		EndDo;
	EndIf;
	
	// Clearing report options
	If SelectedSettingsPage = "ReportSettingsPage" Then
		
		DataProcessors.UsersSettings.DeleteReportOptions(Result.ReportOptionArray,
			UserReportOptionTable, InfoBaseUser);
	EndIf;
	
EndProcedure

&AtServer
Procedure ClearAllSettingsAtServer(SettingsToClear)
	
	UsersArray = New Array;
	UsersArray.Add(UserRef);
	
	DataProcessors.UsersSettings.DeleteUserSettings(SettingsToClear,
		UsersArray, UserReportOptionTable);
	
EndProcedure

&AtServer
Procedure ClearAllUserSettingsAtServer()
	
	SettingsToClear = New Array;
	SettingsToClear.Add("ReportSettings");
	SettingsToClear.Add("InterfaceSettings");
	SettingsToClear.Add("PersonalSettings");
	SettingsToClear.Add("FormData");
	SettingsToClear.Add("Favorites");
	SettingsToClear.Add("PrintSettings");
	
	UsersArray = New Array;
	UsersTable = New ValueTable;
	UsersTable.Columns.Add("User");
	
	UsersTable = DataProcessors.UsersSettings.UsersToCopy("",
		UsersTable, False, True);
	
	For Each TableRow In UsersTable Do
		UsersArray.Add(TableRow.User);
	EndDo;
	
	DataProcessors.UsersSettings.DeleteUserSettings(SettingsToClear, UsersArray);
	
EndProcedure

&AtClient
Procedure DeleteSettingsFromValueTree(SelectedRows)
	
	For Each SelectedRow In SelectedRows Do
		
		If SelectedSettingsPage = "ReportSettingsPage" Then
			DeleteSettingsRow(ReportSettings, SelectedRow);
			
		ElsIf SelectedSettingsPage = "InterfacePage" Then
			DeleteSettingsRow(Interface, SelectedRow);
		Else
			DeleteSettingsRow(OtherSettings, SelectedRow);
		EndIf;
		
	EndDo;
	
	CalculateSettingsCount();
EndProcedure

&AtClient
Procedure ClearCompletion(Response, SettingsTree) Export
	
	If Response = DialogReturnCode.No Then
		Return;
	EndIf;
	
	SelectedRows = SettingsTree.SelectedRows;
	SettingsCount = CopiedOrDeletedSettingsCount(SettingsTree);
	
	ClearAtServer();
	CommonClient.RefreshApplicationInterface();
	
	If SettingsCount = 1 Then
		
		SettingName = SettingsTree.CurrentData.Settings;
		If StrLen(SettingName) > 24 Then
			SettingName = Left(SettingName, 24) + "...";
		EndIf;
		
	EndIf;
	
	DeleteSettingsFromValueTree(SelectedRows);
	
	NotifyDeletion(SettingsCount, SettingName);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Auxiliary procedures and functions.

&AtClient
Procedure Attachable_ProcessNotification()
	
	EventName = NotificationProcessingParameters.EventName;
	Parameter   = NotificationProcessingParameters.Parameter;
	
	If Upper(EventName) = Upper("SettingsCopied") Then
		UpdateSettingsList();
		CommonClient.RefreshApplicationInterface();
		Return;
	EndIf;
	
	If Upper(EventName) <> Upper("UserSelection") Then
		Return;
	EndIf;
	
	UsersDestination = Parameter.UsersDestination;
	UsersCount = UsersDestination.Count();
	
	SettingsCopiedToNote = UsersInternalClient.UsersNote(
		UsersCount, UsersDestination[0]);
	
	NotificationText     = NStr("ru = 'Копирование настроек'; en = 'Copy settings'; pl = 'Skopiuj ustawienia';de = 'Einstellungen kopieren';ro = 'Copiați setările';tr = 'Ayarları kopyala'; es_ES = 'Copiar configuraciones'");
	NotificationPicture  = PictureLib.Information32;
	
	If Parameter.CopyAll Then
		
		SettingsArray = New Array;
		SettingsNames = "";
		For Each Setting In SettingsToCopy Do 
			
			SettingsNames = SettingsNames + Lower(Setting.Presentation) + ", ";
			SettingsArray.Add(Setting.Value);
			
		EndDo;
		
		SettingsNames = Left(SettingsNames, StrLen(SettingsNames)-2);
		
		If SettingsArray.Count() = 7 Then
			NotificationComment = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Скопированы все настройки %1'; en = 'All settings are copied to %1.'; pl = 'Wszystkie ustawienia zostały skopiowane %1';de = 'Alle Einstellungen wurden kopiert %1';ro = 'Toate setările au fost copiate %1';tr = 'Tüm ayarlar kopyalandı %1'; es_ES = 'Todas las configuraciones copiadas %1'"), SettingsCopiedToNote);
		Else
			NotificationComment = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = '%1 скопированы %2'; en = '%1 copied to %2'; pl = '%1 skopiowano %2';de = '%1 werden kopiert %2';ro = '%1 sunt copiate %2';tr = '%1 kopyalandı %2'; es_ES = '%1 están copiadas %2'"), SettingsNames, SettingsCopiedToNote);
		EndIf;
		
		Report = Undefined;
		CopyAllSettingsAtServer(InfoBaseUser,
			UsersDestination, SettingsArray, Report);
		
		If Report <> Undefined Then
			QuestionText = NStr("ru = 'Не все варианты отчетов и настройки были скопированы.'; en = 'Some report options and settings are not copied.'; pl = 'Nie wszystkie opcje i ustawienia raportu zostały skopiowane.';de = 'Nicht alle Berichtsoptionen und -einstellungen wurden kopiert.';ro = 'Nu toate variantele rapoartelor și setările au fost copiate.';tr = 'Tüm rapor seçenekleri ve ayarları kopyalanmadı.'; es_ES = 'No todas las opciones del informe y las configuraciones se han copiado.'");
			
			QuestionButtons = New ValueList;
			QuestionButtons.Add("Ok", NStr("ru = 'ОК'; en = 'OK'; pl = 'OK';de = 'OK';ro = 'OK';tr = 'OK'; es_ES = 'OK'"));
			QuestionButtons.Add("ShowReport", NStr("ru = 'Показать отчет'; en = 'View report'; pl = 'Pokaż sprawozdanie';de = 'Bericht zeigen';ro = 'Afișare raportul';tr = 'Raporu göster'; es_ES = 'Mostrar el informe'"));
			
			Notification = New NotifyDescription("NotificationProcessingShowQueryBox", ThisObject, Report);
			ShowQueryBox(Notification, QuestionText, QuestionButtons,, QuestionButtons[0].Value);
			
			Return;
		EndIf;
		
		ShowUserNotification(NotificationText, , NotificationComment, NotificationPicture);
		Return;
	EndIf;
	
	If Parameter.SettingsClearing Then
		
		SettingsTree = SelectedSettingsPageFormTable();
		SettingsCount = CopiedOrDeletedSettingsCount(SettingsTree);
		
		ClearAtServer(UsersDestination, True);
		
		If SettingsCount = 1 Then
			
			SettingName = SettingsTree.CurrentData.Settings;
			If StrLen(SettingName) > 24 Then
				SettingName = Left(SettingName, 24) + "...";
			EndIf;
			
		EndIf;
		
		UsersCount = Parameter.UsersDestination.Count();
		NotifyDeletion(SettingsCount, SettingName, UsersCount);
		Return;
	EndIf;
	
	SettingsTree = SelectedSettingsPageFormTable();
	SettingsCount = CopiedOrDeletedSettingsCount(SettingsTree);
	
	ReportPersonalizationCount = 0;
	Report = Undefined;
	CopyAtServer(UsersDestination, ReportPersonalizationCount, Report);
	
	If Report <> Undefined Then
		QuestionText = NStr("ru = 'Не все варианты отчетов и настройки были скопированы.'; en = 'Some report options and settings are not copied.'; pl = 'Nie wszystkie opcje i ustawienia raportu zostały skopiowane.';de = 'Nicht alle Berichtsoptionen und -einstellungen wurden kopiert.';ro = 'Nu toate variantele rapoartelor și setările au fost copiate.';tr = 'Tüm rapor seçenekleri ve ayarları kopyalanmadı.'; es_ES = 'No todas las opciones del informe y las configuraciones se han copiado.'");
		QuestionButtons = New ValueList;
		QuestionButtons.Add("Ok", NStr("ru = 'ОК'; en = 'OK'; pl = 'OK';de = 'OK';ro = 'OK';tr = 'OK'; es_ES = 'OK'"));
		QuestionButtons.Add("ShowReport", NStr("ru = 'Показать отчет'; en = 'View report'; pl = 'Pokaż sprawozdanie';de = 'Bericht zeigen';ro = 'Afișare raportul';tr = 'Raporu göster'; es_ES = 'Mostrar el informe'"));
		
		Notification = New NotifyDescription("NotificationProcessingShowQueryBox", ThisObject, Report);
		ShowQueryBox(Notification, QuestionText, QuestionButtons,, QuestionButtons[0].Value);
		Return;
	Else
		
		If SettingsCount = 1 Then
			SettingPresentation = SettingsTree.CurrentData.Settings;
		EndIf;
		
		NotificationComment = UsersInternalClient.GenerateNoteOnCopy(
			SettingPresentation, SettingsCount, SettingsCopiedToNote);
		
		ShowUserNotification(NotificationText, , NotificationComment, NotificationPicture);
	EndIf;
	
EndProcedure

&AtClient
Procedure ClearSettingsForSelectedUsersCompletion(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.No Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("User", UserRef);
	FormParameters.Insert("ActionType",  "Clearing");
	
	OpenForm("DataProcessor.UsersSettings.Form.SelectUsers", FormParameters);
	
EndProcedure

&AtClient
Procedure ClearSettingsForAllUsersCompletion(Response, AdditionalParameters) Export
	
	If Response = "Cancel" Then
		Return;
	EndIf;
	
	ClearAllUserSettingsAtServer();
	CommonClient.RefreshApplicationInterface();
	
	ShowUserNotification(NStr("ru = 'Очистка настроек'; en = 'Clear settings'; pl = 'Oczyść ustawienia';de = 'Einstellungen löschen';ro = 'Ștergeți setările ';tr = 'Temizleme ayarları'; es_ES = 'Eliminar configuraciones'"), ,
		NStr("ru = 'Очищены все настройки всех пользователя'; en = 'All settings of all users are cleared.'; pl = 'Wszystkie ustawienia wszystkich użytkowników zostały oczyszczone';de = 'Alle Einstellungen aller Benutzer sind bereinigt';ro = 'Toate setările tuturor utilizatorilor sunt șterse';tr = 'Tüm kullanıcıların tüm ayarları temizlendi'; es_ES = 'Todas las configuraciones de todos los usuarios se han eliminado'"), PictureLib.Information32);
	
EndProcedure

&AtClient
Procedure ClearAllSettingsCompletion(Response, AdditionalParameters) Export
	
	If Response = "Cancel" Then
		Return;
	EndIf;
	
	SettingsToClear = New Array;
	SettingsToClear.Add("ReportSettings");
	SettingsToClear.Add("InterfaceSettings");
	SettingsToClear.Add("FormData");
	SettingsToClear.Add("PersonalSettings");
	SettingsToClear.Add("Favorites");
	SettingsToClear.Add("PrintSettings");
	SettingsToClear.Add("OtherUserSettings");
	
	ClearAllSettingsAtServer(SettingsToClear);
	CommonClient.RefreshApplicationInterface();
	UpdateSettingsList();
	
	NoteText = NStr("ru = 'Очищены все настройки пользователя ""%1""'; en = 'All settings of user ""%1"" are cleared.'; pl = 'Wszystkie ustawienia użytkownika ""%1"" zostały oczyszczone';de = 'Alle Einstellungen des Benutzers ""%1"" sind bereinigt';ro = 'Toate setările utilizatorului ""%1"" sunt șterse';tr = '""%1"" kullanıcıya ait tüm ayarlar temizlendi'; es_ES = 'Todas las configuraciones del usuario ""%1"" se han eliminado'");
	NoteText = StringFunctionsClientServer.SubstituteParametersToString(NoteText, UserRef);
	ShowUserNotification(NStr("ru = 'Очистка настроек'; en = 'Clear settings'; pl = 'Oczyść ustawienia';de = 'Einstellungen löschen';ro = 'Ștergeți setările ';tr = 'Temizleme ayarları'; es_ES = 'Eliminar configuraciones'"), , NoteText, PictureLib.Information32);
	
EndProcedure

&AtClient
Procedure ClearReportAndInterfaceSettingsCompletion(Response, AdditionalParameters) Export
	
	If Response = "Cancel" Then
		Return;
	EndIf;
	
	SettingsToClear = New Array;
	SettingsToClear.Add("ReportSettings");
	SettingsToClear.Add("InterfaceSettings");
	SettingsToClear.Add("FormData");
	
	ClearAllSettingsAtServer(SettingsToClear);
	CommonClient.RefreshApplicationInterface();
	
	NoteText = NStr("ru = 'Очищены все настройки отчетов и внешнего вида у пользователя ""%1""'; en = 'All interface and report settings of user ""%1"" are cleared.'; pl = 'Wszystkie ustawienia raportów i wyglądu użytkownika ""%1"" zostały oczyszczone';de = 'Alle Einstellungen von Berichten und Aussehen des Benutzers ""%1"" sind bereinigt';ro = 'Toate setările rapoartelor și aspectul utilizatorului ""%1"" sunt golite';tr = 'Tüm rapor ayarları ve kullanıcı ""%1"" görünümleri temizlendi'; es_ES = 'Todas las configuraciones de informes y el aspecto del usuario ""%1"" se han eliminado'");
	NoteText = StringFunctionsClientServer.SubstituteParametersToString(NoteText, String(UserRef));
	ShowUserNotification(NStr("ru = 'Очистка настроек'; en = 'Clear settings'; pl = 'Oczyść ustawienia';de = 'Einstellungen löschen';ro = 'Ștergeți setările ';tr = 'Temizleme ayarları'; es_ES = 'Eliminar configuraciones'"), , NoteText, PictureLib.Information32);
	
EndProcedure

&AtClient
Procedure SettingsBeforeDeleteCompletion(Response, Item) Export
	
	If Response = DialogReturnCode.No Then
		Return;
	EndIf;
	
	ClearAtServer();
	CommonClient.RefreshApplicationInterface();
	
	SelectedRows = Item.SelectedRows;
	SettingsCount = CopiedOrDeletedSettingsCount(Item);
	
	If SettingsCount = 1 Then
		
		SettingsTree = SelectedSettingsPageFormTable();
		SettingName = SettingsTree.CurrentData.Settings;
		
		If StrLen(SettingName) > 24 Then
			SettingName = Left(SettingName, 24) + "...";
		EndIf;
		
	EndIf;
	
	DeleteSettingsFromValueTree(SelectedRows);
	
	NotifyDeletion(SettingsCount, SettingName);
	
EndProcedure

&AtClient
Procedure NotificationProcessingShowQueryBox(Response, Report) Export
	
	If Response = "Ok" Then
		Return;
	Else
		Report.ShowGroups = True;
		Report.ShowGrid = False;
		Report.ShowHeaders = False;
		Report.Show();
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure ExpandValueTree()
	
	Rows = ReportSettings.GetItems();
	For Each Row In Rows Do
		Items.ReportSettingsTree.Expand(Row.GetID(), True);
	EndDo;
	
	Rows = Interface.GetItems();
	For Each Row In Rows Do
		Items.Interface.Expand(Row.GetID(), True);
	EndDo;
	
EndProcedure

&AtClient
Function SelectedSettingsPageFormTable()
	
	If SelectedSettingsPage = "ReportSettingsPage" Then
		Return Items.ReportSettingsTree;
	ElsIf SelectedSettingsPage = "InterfacePage" Then
		Return Items.Interface;
	Else
		Return Items.OtherSettings;
	EndIf;
	
EndFunction

&AtClient
Function CopiedOrDeletedSettingsCount(SettingsTree)
	
	SelectedRows = SettingsTree.SelectedRows;
	// Moving the array of selected rows to a value list in order to sort the selected rows.
	SelectedRowsList = New ValueList;
	For Each Item In SelectedRows Do
		SelectedRowsList.Add(Item);
	EndDo;
	
	SelectedRowsList.SortByValue();
	If SelectedSettingsPage = "ReportSettingsPage" Then
		CurrentValueTree = ReportSettings;
	ElsIf SelectedSettingsPage = "InterfacePage" Then
		CurrentValueTree = Interface;
	Else
		CurrentValueTree = OtherSettings;
	EndIf;
	
	SettingsCount = 0;
	For Each SelectedRow In SelectedRowsList Do
		TreeItem = CurrentValueTree.FindByID(SelectedRow.Value);
		SubordinateItemsCount = TreeItem.GetItems().Count();
		ItemParent = TreeItem.GetParent();
		
		If SubordinateItemsCount <> 0 Then
			SettingsCount = SettingsCount + SubordinateItemsCount;
			TopLevelItem = TreeItem;
		ElsIf SubordinateItemsCount = 0
			AND ItemParent = Undefined Then
			SettingsCount = SettingsCount + 1;
		Else
			
			If ItemParent <> TopLevelItem Then
				SettingsCount = SettingsCount + 1;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Return SettingsCount;
EndFunction

&AtClient
Procedure DeleteSettingsRow(SettingsTree, SelectedRow)
	
	SettingsItem = SettingsTree.FindByID(SelectedRow);
	If SettingsItem = Undefined Then
		Return;
	EndIf;
	
	SettingsItemParent = SettingsItem.GetParent();
	If SettingsItemParent <> Undefined Then
		
		SubordinateRowsCount = SettingsItemParent.GetItems().Count();
		If SubordinateRowsCount = 1 Then
			
			If SettingsItemParent.Type <> "PersonalOption" Then
				SettingsTree.GetItems().Delete(SettingsItemParent);
			EndIf;
			
		Else
			SettingsItemParent.GetItems().Delete(SettingsItem);
		EndIf;
		
	Else
		SettingsTree.GetItems().Delete(SettingsItem);
	EndIf;
	
EndProcedure

&AtClient
Procedure NotifyDeletion(SettingsCount, SettingName = Undefined, UsersCount = Undefined)
	
	SubjectInWords = Format(SettingsCount, "NFD=0") + " "
		+ UsersInternalClientServer.IntegerSubject(SettingsCount,
			"", NStr("ru = 'настройка,настройки,настроек,,,,,,0'; en = 'setting,settings,,,0'; pl = 'ustawienia,ustawienia,,,0';de = 'Einstellung, Einstellungen, Einstellungen,,,,,,0';ro = 'setare,setări,setări,,,,,,0';tr = 'ayar, ayarlar, ayarlar,,,,,,0'; es_ES = 'ajuste,ajustes,,,0'"));
	
	If SettingsCount = 1
	   AND UsersCount = Undefined Then
		
		NoteText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = '""%1"" очищена пользователю ""%2""'; en = '""%1"" cleared for user ""%2.""'; pl = '""%1"" została oczyszczona dla użytkownika ""%2""';de = '""%1"" wird für Benutzer gelöscht ""%2""';ro = '""%1"" este golită la utilizatorul ""%2""';tr = '""%1"" %2 için temizlendi'; es_ES = '""%1"" se ha eliminado para el usuario ""%2""'"), SettingName, String(UserRef));
		
	ElsIf UsersCount = Undefined Then
		NoteText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Очищено %1 пользователю ""%2""'; en = '%1 cleared for user ""%2.""'; pl = 'Oczyszczone %1 użytkownikowi ""%2""';de = '%1 für Benutzer ""%2"" gelöscht';ro = '%1 este golită pentru utilizatorul ""%2""';tr = '""%1"" kullanıcı için silindi %2'; es_ES = 'Está eliminado %1 al usuario ""%2""'"), SubjectInWords, String(UserRef));
	EndIf;
	
	ClearSettingsForNote = UsersInternalClient.UsersNote(
		UsersCount, String(UserRef));
	
	If UsersCount <> Undefined Then
		
		If SettingsCount = 1 Then
			NoteText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = '""%1"" очищена %2'; en = '""%1"" cleared for %2'; pl = '""%1"" wyczyszczono %2';de = '""%1"" gelöscht %2';ro = '""%1"" golită %2';tr = '""%1"" temizlendi %2'; es_ES = '""%1"" eliminado %2'"), SettingName, ClearSettingsForNote);
		Else
			NoteText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Очищено %1 %2'; en = '%1 cleared for %2'; pl = 'Wyczyszczono %1 %2';de = 'Gelöscht %1 %2';ro = 'Golite %1 %2';tr = 'Temizlendi %1 %2'; es_ES = 'Eliminado %1 %2'"), SubjectInWords, ClearSettingsForNote);
		EndIf;
		
	EndIf;
	
	ShowUserNotification(NStr("ru = 'Очистка настроек'; en = 'Clear settings'; pl = 'Oczyść ustawienia';de = 'Einstellungen löschen';ro = 'Ștergeți setările ';tr = 'Temizleme ayarları'; es_ES = 'Eliminar configuraciones'"),
		, NoteText, PictureLib.Information32);
	
EndProcedure

&AtClient
Procedure CopySettings()
	
	SettingsTree = SelectedSettingsPageFormTable();
	If SettingsTree.SelectedRows.Count() = 0 Then
		ShowMessageBox(,
			NStr("ru = 'Необходимо выбрать настройки, которые требуется скопировать.'; en = 'Select the settings that you want to copy.'; pl = 'Wybierz ustawienia do skopiowania.';de = 'Wählen Sie die zu kopierenden Einstellungen.';ro = 'Selectați setările pentru copiere.';tr = 'Silmek için ayarları seçin.'; es_ES = 'Seleccionar las configuraciones para copiar.'"));
		Return;
	ElsIf SettingsTree.SelectedRows.Count() = 1 Then
		
		If SettingsTree.CurrentData.Type = "PersonalOption" Then
			ShowMessageBox(,
				NStr("ru = 'Невозможно скопировать личный вариант отчета.
			               |Для того чтобы личный вариант отчета стал доступен другим пользователям, необходимо
			               |его пересохранить со снятой пометкой ""Только для автора"".'; 
			               |en = 'Cannot copy a personal report option.
			               |To make the personal report option available to other users,
			               |save it with ""Available to author only"" check box cleared.'; 
			               |pl = 'Kopiowanie wersji osobistej raportu jest niemożliwe.
			               |Aby udostępnić osobistą wersję raportu innym użytkownikom, należy
			               |zapisać ją z usuniętym znakiem ""Tylko dla autora"".';
			               |de = 'Es ist nicht möglich, eine persönliche Version des Berichts zu kopieren.
			               |Um die persönliche Variante des Berichts anderen Benutzern zur Verfügung zu stellen, sollten Sie 
			               |ihn mit dem Kennzeichen ""Nur Autor"" neu speichern.';
			               |ro = 'Nu puteți copia varianta personală a raportului.
			               |Pentru ca varianta personală a raportului să devină accesibilă pentru alți utilizatori trebuie s-o 
			               |salvați din nou cu marcajul scos ""Numai pentru autor"".';
			               |tr = '
			               |Kişisel rapor seçeneklerinin kopyalanması mümkün değildir. 
			               |Kişisel rapor seçeneğini diğer kullanıcılara sunmak istiyorsanız, ""Yalnızca sahibi için"" işaretini kaldırmanız gerekir.'; 
			               |es_ES = 'Imposible copiar la opción de informe personal.
			               |Si quiere que la opción de informe personal esté disponible a otros usuarios, entonces usted necesita
			               | volver a guardarla con la marca ""Solo para el autor"" eliminada.'"));
			Return;
		ElsIf SettingsTree.CurrentData.Type = "SettingsItemPersonal" Then
			ShowMessageBox(,
				NStr("ru = 'Невозможно скопировать настройку личного варианта отчета.
			               |Копирование настроек личных вариантов отчетов не предусмотрено.'; 
			               |en = 'Cannot copy the setting of a personal report option.
			               |Copying settings of personal report options is not supported.'; 
			               |pl = 'Nie można skopiować ustawienia opcji osobistego raportu.
			               |Kopiowanie poszczególnych ustawień indywidualnych opcji raportu/sprawozdania, nie jest dostępne.';
			               |de = 'Die Einstellung der persönlichen Berichtsoption kann nicht kopiert werden. 
			               |Das Kopieren der einzelnen Einstellungen der Berichtsoption ist nicht vorgesehen.';
			               |ro = 'Nu puteți copia setarea variantei personale a raportului.
			               |Copierea setărilor variantelor personale ale rapoartelor nu este prevăzută.';
			               |tr = 'Kişisel rapor seçeneğinin ayarını kopyalamak imkansız. 
			               |Tek tek rapor seçenek ayarlarının kopyalanması sağlanmamıştır.'; 
			               |es_ES = 'Imposible copiar la configuración de la opción de informe personal.
			               |No se proporciona el copiar de las configuraciones de la opción de informe individual.'"));
			Return;
		EndIf;
		
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("User", UserRef);
	FormParameters.Insert("ActionType",  "");
	
	OpenForm("DataProcessor.UsersSettings.Form.SelectUsers", FormParameters);
	
EndProcedure

&AtServer
Function SettingsGettingResult()
	
	If Not ValueIsFilled(UserRef) Then
		UserRef = Catalogs.Users.EmptyRef();
		InfoBaseUser = Undefined;
	Else
		InfoBaseUser = DataProcessors.UsersSettings.IBUserName(
			UserRef);
	EndIf;
	
	If InfoBaseUser = Undefined Then
		Return "NoIBUser";
	EndIf;
	
	Return "Success";
	
EndFunction

&AtServer
Function SettingsTreeForSelectedPage()
	
	If SelectedSettingsPage = "ReportSettingsPage" Then
		Return ReportSettings;
	ElsIf SelectedSettingsPage = "InterfacePage" Then
		Return Interface;
	Else
		Return OtherSettings;
	EndIf;
	
EndFunction

&AtServer
Function SettingsStorageForSelectedPage()
	
	If SelectedSettingsPage = "ReportSettingsPage" Then
		Return "ReportsUserSettingsStorage";
	ElsIf SelectedSettingsPage = "InterfacePage"
		Or SelectedSettingsPage = "OtherSettingsPage" Then
		Return "SystemSettingsStorage";
	EndIf;
	
EndFunction

&AtServer
Function SelectedSettingsItems()
	
	If SelectedSettingsPage = "ReportSettingsPage" Then
		Return Items.ReportSettingsTree.SelectedRows;
	ElsIf SelectedSettingsPage = "InterfacePage" Then
		Return Items.Interface.SelectedRows;
	Else
		Return Items.OtherSettings.SelectedRows;
	EndIf;
	
EndFunction

&AtServer
Function SelectedSettings()
	
	SettingsTree = SettingsTreeForSelectedPage();
	SettingsArray = New Array;
	PersonalSettingsArray = New Array;
	ReportOptionArray = New Array;
	UserSettingsArray = New Array;
	CurrentReportOption = Undefined;
	
	SelectedItems = SelectedSettingsItems();
	
	For Each SelectedItem In SelectedItems Do
		SelectedSetting = SettingsTree.FindByID(SelectedItem);
		
		// Filling the array of personal settings.
		If SelectedSetting.Type = "PersonalSettings" Then
			PersonalSettingsArray.Add(SelectedSetting.Keys);
			Continue;
		EndIf;
		
		// Filling the array of other user settings.
		If SelectedSetting.Type = "OtherUserSettingsItem" Then
			OtherUserSettings = New Structure;
			OtherUserSettings.Insert("SettingID", SelectedSetting.RowType);
			OtherUserSettings.Insert("SettingValue",      SelectedSetting.Keys);
			UserSettingsArray.Add(OtherUserSettings);
			Continue;
		EndIf;
		
		// Marking personal settings in the list of keys.
		If SelectedSetting.Type = "PersonalOption" Then
			
			For Each Item In SelectedSetting.Keys Do
				Item.Check = True;
			EndDo;
			CurrentReportOption = SelectedSetting.Keys.Copy();
			// Filling the array of user-defined report options.
			ReportOptionArray.Add(SelectedSetting.Keys);
			
		ElsIf SelectedSetting.Type = "StandardOptionPersonal" Then
			ReportOptionArray.Add(SelectedSetting.Keys);
		EndIf;
		
		If SelectedSetting.Type = "SettingsItemPersonal" Then
			
			If CurrentReportOption <> Undefined
			   AND CurrentReportOption.FindByValue(SelectedSetting.Keys[0].Value) <> Undefined Then
				
				Continue;
			Else
				SelectedSetting.Keys[0].Check = True;
				SettingsArray.Add(SelectedSetting.Keys);
				Continue;
			EndIf;
			
		EndIf;
		
		SettingsArray.Add(SelectedSetting.Keys);
		
	EndDo;
	
	Result = New Structure;
	Result.Insert("SettingsArray", SettingsArray);
	Result.Insert("PersonalSettingsArray", PersonalSettingsArray);
	Result.Insert("ReportOptionArray", ReportOptionArray);
	Result.Insert("UserSettingsArray", UserSettingsArray);
	
	Return Result;
EndFunction

&AtServer
Function TimeConsumingOperationParameters()
	
	TimeConsumingOperationParameters = New Structure;
	TimeConsumingOperationParameters.Insert("FormName");
	TimeConsumingOperationParameters.Insert("Search");
	TimeConsumingOperationParameters.Insert("SettingsOperation");
	TimeConsumingOperationParameters.Insert("InfoBaseUser");
	TimeConsumingOperationParameters.Insert("UserRef");
	
	FillPropertyValues(TimeConsumingOperationParameters, ThisObject);
	
	TimeConsumingOperationParameters.Insert("ReportSettingsTree",
		FormAttributeToValue("ReportSettings"));
	
	TimeConsumingOperationParameters.Insert("InterfaceSettings",
		FormAttributeToValue("Interface"));
	
	TimeConsumingOperationParameters.Insert("OtherSettingsTree",
		FormAttributeToValue("OtherSettings"));
	
	TimeConsumingOperationParameters.Insert("UserReportOptions",
		FormAttributeToValue("UserReportOptionTable"));
	
	Return TimeConsumingOperationParameters;
	
EndFunction

#EndRegion
