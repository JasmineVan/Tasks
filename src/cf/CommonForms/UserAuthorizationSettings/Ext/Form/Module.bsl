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
	
	ShowExternalUsersSettings = Parameters.ShowExternalUsersSettings;
	
	RecommendedSettings = New Structure;
	RecommendedSettings.Insert("MinPasswordLength", 8);
	RecommendedSettings.Insert("MaxPasswordLifetime", 30);
	RecommendedSettings.Insert("MinPasswordLifetime", 1);
	RecommendedSettings.Insert("DenyReusingRecentPasswords", 10);
	RecommendedSettings.Insert("InactivityPeriodBeforeDenyingAuthorization", 45);
	
	If ShowExternalUsersSettings Then
		StandardSubsystemsServer.SetFormAssignmentKey(ThisObject, "ExternalUsers");
		AutoTitle = False;
		Title = NStr("ru = 'Настройки входа внешних пользователей'; en = 'External user authorization settings'; pl = 'Ustawienia wejścia użytkowników zewnętrznych';de = 'Einstellungen für die Anmeldung externer Benutzer';ro = 'Setările pentru intrare ale utilizatorilor externi';tr = 'Dış kullanıcıların oturum açma ayarları'; es_ES = 'Ajustes de la entrada de los usuarios externos'");
		FillPropertyValues(ThisObject, UsersInternal.AuthorizationSettings().ExternalUsers);
	Else
		FillPropertyValues(ThisObject, UsersInternal.AuthorizationSettings().Users);
	EndIf;
	
	For Each KeyAndValue In RecommendedSettings Do
		If ValueIsFilled(ThisObject[KeyAndValue.Key]) Then
			ThisObject[KeyAndValue.Key + "Enable"] = True;
		Else
			ThisObject[KeyAndValue.Key] = KeyAndValue.Value;
			Items[KeyAndValue.Key].Enabled = False;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PasswordMustMeetComplexityRequirementsOnChange(Item)
	
	If MinPasswordLength < 7 Then
		MinPasswordLength = 7;
	EndIf;
	
EndProcedure

&AtClient
Procedure MinPasswordLengthOnChange(Item)
	
	If MinPasswordLength < 7
	  AND PasswordMustMeetComplexityRequirements Then
		
		MinPasswordLength = 7;
	EndIf;
	
EndProcedure

&AtClient
Procedure SettingEnableOnChange(Item)
	
	SettingName = Left(Item.Name, StrLen(Item.Name) - StrLen("Enable"));
	
	If ThisObject[Item.Name] = False Then
		ThisObject[SettingName] = RecommendedSettings[SettingName];
	EndIf;
	
	Items[SettingName].Enabled = ThisObject[Item.Name];
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure WriteAndClose(Command)
	
	WriteAtServer();
	Notify("Write_ConstantsSet", New Structure, "UserAuthorizationSettings");
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure WriteAtServer()
	
	Lock = New DataLock;
	Lock.Add("Constant.UserAuthorizationSettings");
	
	BeginTransaction();
	Try
		Lock.Lock();
		AuthorizationSettings = UsersInternal.AuthorizationSettings();
		
		If ShowExternalUsersSettings Then
			Settings = AuthorizationSettings.ExternalUsers;
		Else
			Settings = AuthorizationSettings.Users;
		EndIf;
		
		Settings.PasswordMustMeetComplexityRequirements = PasswordMustMeetComplexityRequirements;
		
		If Not ValueIsFilled(InactivityPeriodBeforeDenyingAuthorization) Then
			Settings.InactivityPeriodActivationDate = '00010101';
			
		ElsIf Not ValueIsFilled(Settings.InactivityPeriodActivationDate) Then
			Settings.InactivityPeriodActivationDate = BegOfDay(CurrentSessionDate());
		EndIf;
		
		For Each KeyAndValue In RecommendedSettings Do
			If ThisObject[KeyAndValue.Key + "Enable"] Then
				Settings[KeyAndValue.Key] = ThisObject[KeyAndValue.Key];
			Else
				Settings[KeyAndValue.Key] = 0;
			EndIf;
		EndDo;
		
		Constants.UserAuthorizationSettings.Set(New ValueStorage(AuthorizationSettings));
		
		If ValueIsFilled(AuthorizationSettings.Users.InactivityPeriodBeforeDenyingAuthorization)
		 Or ValueIsFilled(AuthorizationSettings.ExternalUsers.InactivityPeriodBeforeDenyingAuthorization) Then
			
			SetPrivilegedMode(True);
			UsersInternal.ChangeUserActivityMonitoringJob(True);
			SetPrivilegedMode(False);
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	RefreshReusableValues();
	
EndProcedure

#EndRegion
