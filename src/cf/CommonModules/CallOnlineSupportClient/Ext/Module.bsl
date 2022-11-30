///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Controls visibility of online support call command on the form
//
// Parameters:
//  EventName - String - a message ID.
//  Item - FormButton - an online support call command on the form.
//
Procedure NotificationProcessing(EventName, Item) Export
	
	If EventName = "SaveSettingsCallOnlineSupport" Then
		UserSettings = CallOnlineSupportServerCall.UserAccountSettings();
		Item.Visible = UserSettings.OnlineSupportCallButtonVisibility;
	EndIf;
	
EndProcedure

#EndRegion 

#Region Private

// Returns the UUID of the 1C client application.
Function ClientID() Export
	
	SystemInfo = New SystemInfo;
	ClientID = SystemInfo.ClientID;
	Return ClientID;
	
EndFunction

// Returns application file path in the Windows registry.
// 
Function PathToExecutableFileFromWindowsRegistry() Export
	
#If WebClient Then
	Return "";
#Else
	
	Value = "";
	
	RegProv = GetCOMObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\default:StdRegProv");
	RegProv.GetStringValue("2147483649","Software\Buhphone","ProgramPath", Value);
	
	If Value = "" Or  Value = NULL Then
		ValueFromRegistry = "";
	Else
		ValueFromRegistry = Value;
	EndIf;
	
	Return ValueFromRegistry;
	
#EndIf
	
EndFunction

// File selection dialog box.
//
// Returns:
//		String - Path to the executable file.
Procedure SelectFileOnlineSupportCall(ClosingNotification, PathToFile = "") Export
	
	Directory = CommonClientServer.ParseFullFileName(PathToFile);
	
	Dialog = New FileDialog(FileDialogMode.Open);
	Dialog.Title = NStr("ru = 'Выберите исполняемый файл приложения'; en = 'Select an executable application file'; pl = 'Select an executable application file';de = 'Select an executable application file';ro = 'Select an executable application file';tr = 'Select an executable application file'; es_ES = 'Select an executable application file'");
	Dialog.FullFileName = PathToFile;
	Dialog.Directory = Directory.Path;
	Filter = NStr("ru = 'Файл приложения (*.exe)|*.exe'; en = 'Application file (*.exe)|*.exe'; pl = 'Application file (*.exe)|*.exe';de = 'Application file (*.exe)|*.exe';ro = 'Application file (*.exe)|*.exe';tr = 'Application file (*.exe)|*.exe'; es_ES = 'Application file (*.exe)|*.exe'");
	Dialog.Filter = Filter;
	Dialog.Multiselect = False;
	
	Notification = New NotifyDescription("SelectFileOnlineSupportCallEnd", ThisObject, ClosingNotification);
	
	FileSystemClient.ShowSelectionDialog(Notification, Dialog);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure SelectFileOnlineSupportCallEnd(SelectedFiles, ClosingNotification) Export
	
	If SelectedFiles <> Undefined AND SelectedFiles.Count() > 0 Then
		ExecuteNotifyProcessing(ClosingNotification, SelectedFiles[0]);
	Else
		ExecuteNotifyProcessing(ClosingNotification, "");
	EndIf;
	
EndProcedure

// Checks for the executable file by the specified path.
//
// Returns:
// 		Boolean - If True, the file runs by the specified path.
//
Procedure HasOnlineSupportCallFile(ClosingNotification, Path)
	Notification = New NotifyDescription("HasOnlineSupportCallFileAfterFileInitialization", ThisObject, ClosingNotification);
	CheckedFile = New File();
	CheckedFile.BeginInitialization(Notification, Path);
EndProcedure

// Continuation of the procedure (see above).
Procedure HasOnlineSupportCallFileAfterFileInitialization(File, ClosingNotification) Export
	Notification = New NotifyDescription("HasOnlineSupportCallFileAfterCheckExist", ThisObject, ClosingNotification);
	If Lower(File.Extension) <> ".exe" Then
		ExecuteNotifyProcessing(ClosingNotification, False);
	Else
		File.BeginCheckingExistence(Notification);
	EndIf;
EndProcedure

// Continuation of the procedure (see above).
Procedure HasOnlineSupportCallFileAfterCheckExist(Exists, ClosingNotification) Export
	ExecuteNotifyProcessing(ClosingNotification, Exists);
EndProcedure

// Procedure runs executable application file.
// If there is no application file, it opens a search form for the path to the executable file.
//
Procedure CallOnlineSupport() Export
	
	If Not CommonClient.IsWindowsClient() Then
		ShowMessageBox(,NStr("ru = 'Для работы с приложением необходима операционная система Microsoft Windows.'; en = 'To work with the application, Microsoft Windows OS is required.'; pl = 'To work with the application, Microsoft Windows OS is required.';de = 'To work with the application, Microsoft Windows OS is required.';ro = 'To work with the application, Microsoft Windows OS is required.';tr = 'To work with the application, Microsoft Windows OS is required.'; es_ES = 'To work with the application, Microsoft Windows OS is required.'"));
		Return
	EndIf;
	
	Notification = New NotifyDescription("CallOnlineSupportAfterInstallExtension", ThisObject);
	MessageText = NStr("ru = 'Для запуска приложения необходимо установить расширение работы с файлами.'; en = 'To run the application, install the file operation extension.'; pl = 'To run the application, install the file operation extension.';de = 'To run the application, install the file operation extension.';ro = 'To run the application, install the file operation extension.';tr = 'To run the application, install the file operation extension.'; es_ES = 'To run the application, install the file operation extension.'");
	FileSystemClient.AttachFileOperationsExtension(Notification, MessageText, False);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure CallOnlineSupportAfterInstallExtension(ExtensionAttached, AdditionalParameters) Export
	
	If NOT ExtensionAttached Then
		Return;
	EndIf;
	
	// Define start parameters.
	ClientID = ClientID();
	PathFromRegistry = PathToExecutableFileFromWindowsRegistry();
	PathFromStorage = CallOnlineSupportServerCall.ExecutableFileLocation(ClientID);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("PathFromRegistry", PathFromRegistry);
	AdditionalParameters.Insert("PathFromStorage", PathFromStorage);
	
	Notification = New NotifyDescription("CallOnlineSupportAfterCheckPathFromRegistry", ThisObject, AdditionalParameters);
	HasOnlineSupportCallFile(Notification, PathFromRegistry);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure CallOnlineSupportAfterCheckPathFromRegistry(PathFromRegistryIsCorrect, AdditionalParameters) Export
	
	AdditionalParameters.Insert("PathFromRegistryIsCorrect", PathFromRegistryIsCorrect);
	Notification = New NotifyDescription("CallOnlineSupportAfterCheckPathFromStorage", ThisObject, AdditionalParameters);
	HasOnlineSupportCallFile(Notification, AdditionalParameters.PathFromStorage);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure CallOnlineSupportAfterCheckPathFromStorage(PathFromStorageIsCorrect, Context) Export
	
	Account = CallOnlineSupportServerCall.UserAccountSettings();
	OnlineSupportCallStartParameters = New Array;
	OnlineSupportCallStartParameters.Add("/StartedFrom1CConf");
	
	If Account.UseUP Then
		
		If Not IsBlankString(Account.Username) AND Not IsBlankString(Account.Password) Then
			OnlineSupportCallStartParameters.Add("/login:");
			OnlineSupportCallStartParameters.Add(Account.Username);
			OnlineSupportCallStartParameters.Add("/password:");
			OnlineSupportCallStartParameters.Add(Account.Password);
		EndIf;
		
	EndIf;
	
	If PathFromStorageIsCorrect Then
		StartupCommand = New Array;
		StartupCommand.Add(Context.PathFromStorage);
		CommonClientServer.SupplementArray(StartupCommand, OnlineSupportCallStartParameters);
		FileSystemClient.StartApplication(StartupCommand);
		Return;
	EndIf;
	
	If Context.PathFromRegistryIsCorrect Then
		StartupCommand = New Array;
		StartupCommand.Add(Context.PathFromRegistry);
		CommonClientServer.SupplementArray(StartupCommand, OnlineSupportCallStartParameters);
		FileSystemClient.StartApplication(StartupCommand);
		Return;
	EndIf;
	
	OpenForm("CommonForm.SearchForExecutableOnlineSupportFile");
	
EndProcedure

#EndRegion





 