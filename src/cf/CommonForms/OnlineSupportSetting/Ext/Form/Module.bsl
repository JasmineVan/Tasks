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
   	
	// Filling form items according to the previous settings of the current user.
	Result = CallOnlineSupportServerCall.UserAccountSettings();
	ButtonVisibility = Result.OnlineSupportCallButtonVisibility;
	SaveUsernameAndPassword = Result.UseUP;	
	Items.Username.Enabled = Result.UseUP;
	Items.Password.Enabled = Result.UseUP;
	Username = Result.Username;
	Password = Result.Password;
	SystemInfo = New SystemInfo;
	ClientID = SystemInfo.ClientID;
	PathToFile = CallOnlineSupportServerCall.ExecutableFileLocation(ClientID);
	
	InitializeFormItems(ThisObject);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	If NOT CommonClient.IsWindowsClient() Then
		ShowMessageBox(,NStr("ru = 'Для работы с приложением необходима операционная система Microsoft Windows.'; en = 'To work with the application, Microsoft Windows OS is required.'; pl = 'To work with the application, Microsoft Windows OS is required.';de = 'To work with the application, Microsoft Windows OS is required.';ro = 'To work with the application, Microsoft Windows OS is required.';tr = 'To work with the application, Microsoft Windows OS is required.'; es_ES = 'To work with the application, Microsoft Windows OS is required.'"));
		Cancel = True;
	EndIf;
	If PathToFile="" Then
		PathToFile = CallOnlineSupportClient.PathToExecutableFileFromWindowsRegistry();
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SaveUsernamePasswordOnChange(Item)
	 
	Access = SaveUsernameAndPassword;
	Items.Username.Enabled = Access;
	Items.Password.Enabled = Access;
	
EndProcedure

&AtClient
Procedure ButtonVisibilityOnChange(Item)
	InitializeFormItems(ThisObject);
EndProcedure

&AtClient
Procedure PathToFileStartChoice(Item, ChoiceData, StandardProcessing)
	Notification = New NotifyDescription("PathToFileSelectionStartCompletion", ThisObject);
	CallOnlineSupportClient.SelectFileOnlineSupportCall(Notification, PathToFile);
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Save(Command)
	
	ClientID = CallOnlineSupportClient.ClientID();	
	SaveUserSettingsToStorage(Username, Password, SaveUsernameAndPassword, ButtonVisibility);
	NewPathToExecutableFile(ClientID, PathToFile);
	// Notify the button form to manage button visibility.
	Notify("SaveSettingsCallOnlineSupport");
    OnSettingsChange();
	RefreshInterface();
	Close();
	
EndProcedure

&AtClient
Procedure GetAccountOnlineSupportCall(Command)
	
	FileSystemClient.OpenURL("http://buhphone.com/clients/be-client/");
	
EndProcedure

&AtClient
Procedure TechnicalRequirements(Command)
	
	FileSystemClient.OpenURL("http://buhphone.com/require/#anchor_1");
	
EndProcedure

&AtClient
Procedure DownloadApplication(Command)
	
	FileSystemClient.OpenURL("http://distribs.buhphone.com/current");
	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Procedure NewPathToExecutableFile(ClientID, PathToFile)
	ContactOnlineSupport.SaveLocationOfExecutableOnlineSupportCallFile(ClientID, PathToFile);
EndProcedure 

&AtServerNoContext
Procedure SaveUserSettingsToStorage(Username, 
										 Password, 
										 SaveUsernameAndPassword,
										 ButtonVisibility)
																
	ContactOnlineSupport.SaveUserSettingsToStorage(Username, Password, SaveUsernameAndPassword, ButtonVisibility);

EndProcedure 

&AtServerNoContext
Procedure OnSettingsChange()
	CallOnlineSupportOverridable.OnSettingsChange();
EndProcedure

// Initializes form items in accordance with the application settings.
// 
//
&AtClientAtServerNoContext
Procedure InitializeFormItems(Form)
	
	Form.Items.GroupStartupParameters.Enabled = Form.ButtonVisibility;
	
EndProcedure

&AtClient
Procedure PathToFileSelectionStartCompletion(NewPathToFile, AdditionalParameters) Export
	If NewPathToFile <> "" Then
		PathToFile = NewPathToFile;
	EndIf;
EndProcedure

#EndRegion




