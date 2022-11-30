///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Performs actions required to attach the subsystem in the form.
//
// Parameters:
//  Item - FormButton - an online support call command on the form.
//
Procedure OnCreateAtServer(Item) Export
	
	UserSettings = CallOnlineSupportServerCall.UserAccountSettings();
	Item.Visible = UserSettings.OnlineSupportCallButtonVisibility;
	
EndProcedure

#EndRegion

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// Configuration subsystems event handlers.

// See InfobaseUpdateSSL.OnAddUpdateHandlers. 
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.InitialFilling = True;
	Handler.Procedure = "ContactOnlineSupport.InitialFilling";		
	
EndProcedure

// See CommonOverridable.OnAddMetadataObjectsRenaming. 
Procedure OnAddMetadataObjectsRenaming(Total) Export
	
	Library = "StandardSubsystems";
	
	OldName = "Role.1CConnectIntegration";
	NewName  = "Role.ContactOnlineSupport";
	Common.AddRenaming(Total, "2.4.1.1", OldName, NewName, Library);
	
	
EndProcedure

#EndRegion

#Region Private

// Writes the path of executable online support file to the information register.
// Paths to executable files are stored drilled down by PCs, client ID is used to determine a PC as 
// ComputerName function is not available in web client.
//
// Parameters:
//		ClientID	- UUID - a client application ID.
//		NewFileLocation 	- String - location of executable file for PC running the 1C client.
Procedure SaveLocationOfExecutableOnlineSupportCallFile(ClientID, NewFileLocation) Export 
	
	CurrentFileLocation = CallOnlineSupportServerCall.ExecutableFileLocation(ClientID);

	If CurrentFileLocation = NewFileLocation Then
		Return;	
	EndIf;

	CommonSettingsStorage.Save("ExecutableFilePathsCallOnlineSupport", ClientID, NewFileLocation);
	
EndProcedure

// Writes user account settings for the application launch to the information register.
//
// Parameters:
// 		User            - UUID - the current infobase user.
// 		Username					- String - application account data.
// 		Password				- String - application account data.
//		UseUP 		- Boolean - If False, Username and Password parameters are not available.
//		OnlineSupportCallButtonVisibility - Boolean - shows whether or not application start button will be displayed on the home page.
//
Procedure SaveUserSettingsToStorage(Username, 
										 Password, 
										 UseUP, 
										 OnlineSupportCallButtonVisibility) Export
		
	UserSettings = UserSettings();
	UserSettings.Username 					= Username;
	UserSettings.Password 					= Password;
	UserSettings.UseUP 			= UseUP;
	UserSettings.OnlineSupportCallButtonVisibility 	= OnlineSupportCallButtonVisibility;		
	
	CommonSettingsStorage.Save("UserAccountsCallOnlineSupport", "UserAccountSettings", UserSettings);
	
EndProcedure

Function UserSettings() Export
	
	UserSettings = New Structure();
	UserSettings.Insert("Username", "");
	UserSettings.Insert("Password","");
	UserSettings.Insert("UseUP",False);
	UserSettings.Insert("OnlineSupportCallButtonVisibility",False);	
	
	Return UserSettings;
	
EndFunction

Procedure InitialFilling() Export
	Constants.UseOnlineSupport.Set(True);
EndProcedure
	
#EndRegion



