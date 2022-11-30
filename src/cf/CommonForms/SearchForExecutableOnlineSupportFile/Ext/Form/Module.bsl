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
	SystemInfo = New SystemInfo;
	ClientID = SystemInfo.ClientID;
	PathToFile = CallOnlineSupportServerCall.ExecutableFileLocation(ClientID);
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	If NOT CommonClient.IsWindowsClient() Then
		ShowMessageBox(,NStr("ru = 'Для работы с приложением необходима операционная система Microsoft Windows.'; en = 'To work with the application, Microsoft Windows OS is required.'; pl = 'To work with the application, Microsoft Windows OS is required.';de = 'To work with the application, Microsoft Windows OS is required.';ro = 'To work with the application, Microsoft Windows OS is required.';tr = 'To work with the application, Microsoft Windows OS is required.'; es_ES = 'To work with the application, Microsoft Windows OS is required.'"));
		Cancel = True;
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

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
	// Writes the path to the executable file to the information register.
	NewPathToExecutableFile(ClientID, PathToFile); 
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure PathToFileSelectionStartCompletion(NewPathToFile, AdditionalParameters) Export
	If NewPathToFile <> "" Then
		PathToFile = NewPathToFile;
	EndIf;
EndProcedure

&AtServerNoContext
Procedure NewPathToExecutableFile(ClientID, PathToFile)
	ContactOnlineSupport.SaveLocationOfExecutableOnlineSupportCallFile(ClientID, PathToFile);
EndProcedure 

#EndRegion





