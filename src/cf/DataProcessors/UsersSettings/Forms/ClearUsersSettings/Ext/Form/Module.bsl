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
	
	UseExternalUsers = GetFunctionalOption("UseExternalUsers");
	UsersToClearSettings = New Structure;
	
	UsersToClearSettingsRadioButtons = "ToSelectedUsers";
	SettingsToClearRadioButton   = "ClearAll";
	ClearSettingsSelectionHistory     = True;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If Upper(EventName) = Upper("UserSelection") Then
		
		If UsersToClearSettings <> Undefined Then
			Items.SelectSettings.Title = NStr("ru='Выбрать'; en = 'Select'; pl = 'Wybór';de = 'Auswählen';ro = 'Selectare';tr = 'Seç'; es_ES = 'Seleccionar'");
			SelectedSettings = Undefined;
			SettingsCount = Undefined;
		EndIf;
			
		UsersToClearSettings = New Structure("UsersArray", Parameter.UsersDestination);
		
		UsersCount = Parameter.UsersDestination.Count();
		If UsersCount = 1 Then
			Items.SelectUsers.Title = String(Parameter.UsersDestination[0]);
			Items.SettingsToClearGroup.Enabled = True;
		ElsIf UsersCount > 1 Then
			NumberAndSubject = Format(UsersCount, "NFD=0") + " "
				+ UsersInternalClientServer.IntegerSubject(UsersCount,
					"", NStr("ru = 'пользователь,пользователя,пользователей,,,,,,0'; en = 'user, users,,,0'; pl = 'użytkownik,użytkownika,użytkowników,,,,,,0';de = 'Benutzer, Benutzer, Benutzer,,,,,,0';ro = 'utilizator,utilizatori,utilizatori,,,,,,0';tr = 'kullanıcı, kullanıcılar, kullanıcılar,,,,,,0'; es_ES = 'usuario,del usuario,de los usuarios,,,,,,0'"));
			Items.SelectUsers.Title = NumberAndSubject;
			SettingsToClearRadioButton = "ClearAll";
		EndIf;
		Items.SelectUsers.ToolTip = "";
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure WhoseSettingsToClearRadioButtonOnChange(Item)
	
	If SettingsToClearRadioButton = "ToSelectedUsers"
		AND UsersCount > 1
		Or UsersToClearSettingsRadioButtons = "AllUsers" Then
		SettingsToClearRadioButton = "ClearAll";
	EndIf;
	
	If UsersToClearSettingsRadioButtons = "ToSelectedUsers"
		AND UsersCount = 1
		Or UsersToClearSettingsRadioButtons = "AllUsers" Then
		Items.SettingsToClearGroup.Enabled = True;
	Else
		Items.SettingsToClearGroup.Enabled = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure SettingsToClearRadioButtonOnChange(Item)
	
	If UsersToClearSettingsRadioButtons = "ToSelectedUsers"
		AND UsersCount > 1 
		Or UsersToClearSettingsRadioButtons = "AllUsers" Then
		SettingsToClearRadioButton = "ClearAll";
		Items.SelectSettings.Enabled = False;
		ShowMessageBox(,NStr("ru = 'Очистка отдельных настроек доступна только при выборе одного пользователя.'; en = 'Clearing individual settings is only available if you select a single user.'; pl = 'Czyszczenie oddzielnych ustawień jest dostępne tylko po wybraniu jednego użytkownika.';de = 'Die Bereinigung separater Einstellungen ist nur verfügbar, wenn ein Benutzer ausgewählt ist.';ro = 'Golirea setărilor separate este disponibilă numai la selectarea unui utilizator.';tr = 'Ayrı ayarların temizlenmesi sadece bir kullanıcı seçildiğinde kullanılabilir.'; es_ES = 'Eliminación de las configuraciones separadas está disponible solo cuando un usuario está seleccionado.'"));
	ElsIf SettingsToClearRadioButton = "ClearAll" Then
		Items.SelectSettings.Enabled = False;
	Else
		Items.SelectSettings.Enabled = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure ChooseUsersClick(Item)
	
	If UseExternalUsers Then
		UsersTypeSelection = New ValueList;
		UsersTypeSelection.Add("ExternalUsers", NStr("ru = 'Внешние пользователи'; en = 'External users'; pl = 'Użytkownicy zewnętrzni';de = 'Externe Benutzer';ro = 'Utilizatori externi';tr = 'Harici kullanıcılar'; es_ES = 'Usuarios externos'"));
		UsersTypeSelection.Add("Users",        NStr("ru = 'Пользователи'; en = 'Users'; pl = 'Użytkownicy';de = 'Benutzer';ro = 'Utilizatori';tr = 'Kullanıcılar'; es_ES = 'Usuarios'"));
		
		Notification = New NotifyDescription("SelectUsersClickSelectItem", ThisObject);
		UsersTypeSelection.ShowChooseItem(Notification);
		Return;
	EndIf;
	
	OpenUserSelectionForm(PredefinedValue("Catalog.Users.EmptyRef"));
	
EndProcedure

&AtClient
Procedure SelectSettings(Item)
	
	If UsersCount = 1 Then
		UserRef = UsersToClearSettings.UsersArray[0];
		FormParameters = New Structure("User, SettingsOperation, ClearSettingsSelectionHistory",
			UserRef, "Clearing", ClearSettingsSelectionHistory);
		OpenForm("DataProcessor.UsersSettings.Form.SettingsChoice", FormParameters, ThisObject,,,,
			New NotifyDescription("SelectSettingsAfterChoice", ThisObject));
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Clear(Command)
	
	ClearMessages();
	SettingsClearing();
	
EndProcedure

&AtClient
Procedure ClearAndClose(Command)
	
	ClearMessages();
	SettingsCleared = SettingsClearing();
	If SettingsCleared Then
		CommonClient.RefreshApplicationInterface();
		Close();
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SelectUsersClickSelectItem(SelectedOption, AdditionalParameters) Export
	
	If SelectedOption = Undefined Then
		Return;
	EndIf;
	
	If SelectedOption.Value = "Users" Then
		User = PredefinedValue("Catalog.Users.EmptyRef");
		
	ElsIf SelectedOption.Value = "ExternalUsers" Then
		User = PredefinedValue("Catalog.ExternalUsers.EmptyRef");
	EndIf;
	
	OpenUserSelectionForm(User);
	
EndProcedure

&AtClient
Procedure OpenUserSelectionForm(User)
	
	SelectedUsers = Undefined;
	UsersToClearSettings.Property("UsersArray", SelectedUsers);
	
	FormParameters = New Structure;
	FormParameters.Insert("User",          User);
	FormParameters.Insert("ActionType",           "Clearing");
	FormParameters.Insert("SelectedUsers", SelectedUsers);
	
	OpenForm("DataProcessor.UsersSettings.Form.SelectUsers", FormParameters);
	
EndProcedure

&AtClient
Procedure SelectSettingsAfterChoice(Parameter, Context) Export
	
	If TypeOf(Parameter) <> Type("Structure") Then
		Return;
	EndIf;
	
	SelectedSettings = New Structure;
	SelectedSettings.Insert("Interface",       Parameter.Interface);
	SelectedSettings.Insert("ReportSettings", Parameter.ReportSettings);
	SelectedSettings.Insert("OtherSettings",  Parameter.OtherSettings);
	
	SelectedSettings.Insert("ReportOptionTable",  Parameter.ReportOptionTable);
	SelectedSettings.Insert("SelectedReportsOptions", Parameter.SelectedReportsOptions);
	
	SelectedSettings.Insert("PersonalSettings",           Parameter.PersonalSettings);
	SelectedSettings.Insert("OtherUserSettings", Parameter.OtherUserSettings);
	
	SettingsCount = Parameter.SettingsCount;
	
	If SettingsCount = 0 Then
		TitleText = NStr("ru='Выбрать'; en = 'Select'; pl = 'Wybierz';de = 'Auswählen';ro = 'Selectare';tr = 'Seç'; es_ES = 'Seleccionar'");
	ElsIf SettingsCount = 1 Then
		SettingPresentation = Parameter.SettingsPresentations[0];
		TitleText = SettingPresentation;
	Else
		TitleText = Format(SettingsCount, "NFD=0") + " "
			+ UsersInternalClientServer.IntegerSubject(SettingsCount,
				"", NStr("ru = 'настройка,настройки,настроек,,,,,,0'; en = 'setting,settings,,,0'; pl = 'ustawienia,ustawienia,,,0';de = 'Einstellung, Einstellungen, Einstellungen,,,,,,0';ro = 'setare,setări,setări,,,,,,0';tr = 'ayar, ayarlar, ayarlar,,,,,,0'; es_ES = 'ajuste,ajustes,,,0'"));
	EndIf;
	
	Items.SelectSettings.Title = TitleText;
	Items.SelectSettings.ToolTip = "";
	
EndProcedure

&AtClient
Function SettingsClearing()
	
	If UsersToClearSettingsRadioButtons = "ToSelectedUsers"
		AND UsersCount = 0 Then
		CommonClient.MessageToUser(
			NStr("ru = 'Выберите пользователя или пользователей,
				|которым необходимо очистить настройки.'; 
				|en = 'Select the user or users
				|whose settings you want to clear.'; 
				|pl = 'Wybierz użytkownika lub użytkowników,
				|ustawienia których należy usunąć.';
				|de = 'Wählen Sie den oder die Benutzer aus,
				|die die Einstellungen löschen möchten.';
				|ro = 'Selectați utilizatorul sau utilizatorii
				|pentru care trebuie golite setările.';
				|tr = 'Ayarları temizlemek için 
				|gerekli olan kullanıcıyı veya kullanıcıları seçin.'; 
				|es_ES = 'Seleccionar el usuario o usuarios
				|para los cuales es necesario eliminar los ajustes.'"), , "Source");
		Return False;
	EndIf;
	
	If UsersToClearSettingsRadioButtons = "ToSelectedUsers" Then
			
		If UsersCount = 1 Then
			SettingsClearedForNote = NStr("ru = 'пользователя ""%1""'; en = 'user ""%1.""'; pl = 'użytkownik ""%1""';de = 'Benutzer ""%1""';ro = 'utilizatorul ""%1""';tr = 'kullanıcı ""%1""'; es_ES = 'usuario ""%1""'");
			SettingsClearedForNote = StringFunctionsClientServer.SubstituteParametersToString(
				SettingsClearedForNote, UsersToClearSettings.UsersArray[0]);
		Else
			SettingsClearedForNote = NStr("ru = '%1 пользователям'; en = '%1 users.'; pl = '%1 użytkowników';de = '%1 Benutzer';ro = 'pentru %1 utilizatori';tr = '%1 Kullanıcılar'; es_ES = '%1 usuarios'");
			SettingsClearedForNote = StringFunctionsClientServer.SubstituteParametersToString(SettingsClearedForNote, UsersCount);
		EndIf;
		
	Else
		SettingsClearedForNote = NStr("ru = 'всем пользователям'; en = 'all users.'; pl = 'do wszystkich użytkowników';de = 'allen Benutzern';ro = 'tuturor utilizatorilor';tr = 'tüm kullanıcılar için'; es_ES = 'para todos los usuarios'");
	EndIf;
	
	If SettingsToClearRadioButton = "CertainSettings"
		AND SettingsCount = 0 Then
		CommonClient.MessageToUser(
			NStr("ru = 'Выберите настройки, которые необходимо очистить.'; en = 'Select the settings that you want to clear.'; pl = 'Wybierz ustawienia do oczyszczenia.';de = 'Wählen Sie die Einstellungen, die gelöscht werden sollen.';ro = 'Selectați setările pentru golire.';tr = 'Temizlenecek ayarları seçin.'; es_ES = 'Seleccionar las configuraciones para eliminar.'"), , "SettingsToClearRadioButton");
		Return False;
	EndIf;
	
	If SettingsToClearRadioButton = "CertainSettings" Then
		ClearSelectedSettings();
		
		If SettingsCount = 1 Then
			
			If StrLen(SettingPresentation) > 24 Then
				SettingPresentation = Left(SettingPresentation, 24) + "...";
			EndIf;
			
			NoteText = NStr("ru = '""%1"" очищена у %2'; en = '""%1"" is cleared for %2'; pl = '""%1"" została oczyszczona dla %2';de = '""%1"" ist gelöscht für %2';ro = '""%1"" este eliminat pentru %2';tr = '""%1"" %2 için temizlendi'; es_ES = '""%1"" está eliminado para %2'");
			NoteText = StringFunctionsClientServer.SubstituteParametersToString(NoteText, SettingPresentation, SettingsClearedForNote);
			
		Else
			SubjectInWords = Format(SettingsCount, "NFD=0") + " "
				+ UsersInternalClientServer.IntegerSubject(SettingsCount,
					"", NStr("ru = 'настройка,настройки,настроек,,,,,,0'; en = 'setting,settings,,,0'; pl = 'ustawienia,ustawienia,,,0';de = 'Einstellung, Einstellungen, Einstellungen,,,,,,0';ro = 'setare,setări,setări,,,,,,0';tr = 'ayar, ayarlar, ayarlar,,,,,,0'; es_ES = 'ajuste,ajustes,,,0'"));
			
			NoteText = NStr("ru = 'Очищено %1 у %2'; en = '%1 cleared for %2'; pl = ' %1 jest oczyszczony dla %2';de = '%1 ist gesäubert für %2';ro = '%1 este golită la %2';tr = '%1,  %2 için temizlendi'; es_ES = '%1 está eliminado para %2'");
			NoteText = StringFunctionsClientServer.SubstituteParametersToString(NoteText, SubjectInWords, SettingsClearedForNote);
		EndIf;
		
		ShowUserNotification(NStr("ru = 'Очистка настроек'; en = 'Clear settings'; pl = 'Oczyść ustawienia';de = 'Einstellungen löschen';ro = 'Ștergeți setările ';tr = 'Temizleme ayarları'; es_ES = 'Eliminar configuraciones'"), , NoteText, PictureLib.Information32);
	ElsIf SettingsToClearRadioButton = "ClearAll" Then
		ClearAllSettings();
		
		NoteText = NStr("ru = 'Очищены все настройки %1'; en = 'All settings are cleared for %1'; pl = 'Wszystkie ustawienia %1 zostały oczyszczone';de = 'Alle Einstellungen %1 werden gereinigt';ro = 'Toate setările %1 sunt curățate';tr = 'Tüm ayarlar %1 temizlendi'; es_ES = 'Todas las configuraciones %1 están eliminadas'");
		NoteText = StringFunctionsClientServer.SubstituteParametersToString(NoteText, SettingsClearedForNote);
		ShowUserNotification(NStr("ru = 'Очистка настроек'; en = 'Clear settings'; pl = 'Oczyść ustawienia';de = 'Einstellungen löschen';ro = 'Ștergeți setările ';tr = 'Temizleme ayarları'; es_ES = 'Eliminar configuraciones'"), , NoteText, PictureLib.Information32);
	EndIf;
	
	SettingsCount = 0;
	Items.SelectSettings.Title = NStr("ru='Выбрать'; en = 'Select'; pl = 'Wybór';de = 'OK';ro = 'Selectați';tr = 'Seç'; es_ES = 'Seleccionar'");
	Return True;
	
EndFunction

&AtServer
Procedure ClearSelectedSettings()
	
	Source = UsersToClearSettings.UsersArray[0];
	User = DataProcessors.UsersSettings.IBUserName(Source);
	UserInfo = New Structure;
	UserInfo.Insert("UserRef", Source);
	UserInfo.Insert("InfobaseUserName", User);
	
	If SelectedSettings.ReportSettings.Count() > 0 Then
		DataProcessors.UsersSettings.DeleteSelectedSettings(
			UserInfo, SelectedSettings.ReportSettings, "ReportsUserSettingsStorage");
		
		DataProcessors.UsersSettings.DeleteReportOptions(
			SelectedSettings.SelectedReportsOptions, SelectedSettings.ReportOptionTable, User);
	EndIf;
	
	If SelectedSettings.Interface.Count() > 0 Then
		DataProcessors.UsersSettings.DeleteSelectedSettings(
			UserInfo, SelectedSettings.Interface, "SystemSettingsStorage");
	EndIf;
	
	If SelectedSettings.OtherSettings.Count() > 0 Then
		DataProcessors.UsersSettings.DeleteSelectedSettings(
			UserInfo, SelectedSettings.OtherSettings, "SystemSettingsStorage");
	EndIf;
	
	If SelectedSettings.PersonalSettings.Count() > 0 Then
		DataProcessors.UsersSettings.DeleteSelectedSettings(
			UserInfo, SelectedSettings.PersonalSettings, "CommonSettingsStorage");
	EndIf;
	
	For Each OtherUserSettings In SelectedSettings.OtherUserSettings Do
		UsersInternal.OnDeleteOtherUserSettings(
			UserInfo, OtherUserSettings);
	EndDo;
	
EndProcedure

&AtServer
Procedure ClearAllSettings()
	
	SettingsArray = New Array;
	SettingsArray.Add("ReportSettings");
	SettingsArray.Add("InterfaceSettings");
	SettingsArray.Add("PersonalSettings");
	SettingsArray.Add("FormData");
	SettingsArray.Add("Favorites");
	SettingsArray.Add("PrintSettings");
	SettingsArray.Add("OtherUserSettings");
	
	If UsersToClearSettingsRadioButtons = "ToSelectedUsers" Then
		Sources = UsersToClearSettings.UsersArray;
	Else
		Sources = New Array;
		UsersTable = New ValueTable;
		UsersTable.Columns.Add("User");
		// Getting the list of all users.
		UsersTable = DataProcessors.UsersSettings.UsersToCopy("", UsersTable, False, True);
		
		For Each TableRow In UsersTable Do
			Sources.Add(TableRow.User);
		EndDo;
		
	EndIf;
	
	DataProcessors.UsersSettings.DeleteUserSettings(SettingsArray, Sources);
	
EndProcedure

#EndRegion
