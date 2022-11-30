///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Gets the path to the executable file from the information register.
//
// Parameters:
//		ClientID	- UUID - a client application ID.
// 		
// Returns:
// 		String - Path to executable file on PC of the current user.
//
Function ExecutableFileLocation(ClientID) Export
	
	Return CommonSettingsStorage.Load("ExecutableFilePathsCallOnlineSupport", ClientID);
	
EndFunction

// Gets application startup parameters from the information register.
//
// Parameters:
//		User - UUID - the current infobase user.
//
// Returns:
//		Structure - User settings to launch the application.
//
Function UserAccountSettings() Export 
	
	UserSettings = ContactOnlineSupport.UserSettings();
	UserSettingsStorage = CommonSettingsStorage.Load("UserAccountsCallOnlineSupport", "UserAccountSettings");
	
	If NOT UserSettingsStorage = Undefined Then
		FillPropertyValues(UserSettings, UserSettingsStorage);
		If UserSettingsStorage.Property("OneCConnectButtonVisibility") Then
			UserSettings.OnlineSupportCallButtonVisibility = UserSettingsStorage.OneCConnectButtonVisibility;
		EndIf;
	EndIf;
	
	Return UserSettings;
	
EndFunction
	
#EndRegion
 


