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
	
	Title = Parameters.FormCaption;
	
	TitleWidth = StrLen(Title);
	If TitleWidth > 80 Then
		TitleWidth = 80;
	EndIf;
	If TitleWidth > 35 Then
		Width = TitleWidth;
	EndIf;
	
	IsFullUser = Users.IsFullUser(,, False);
	
	ErrorAtClient = Parameters.ErrorAtClient;
	ErrorAtServer = Parameters.ErrorAtServer;
	
	If ValueIsFilled(ErrorAtClient)
	   AND ValueIsFilled(ErrorAtServer) Then
		
		ErrorDescription =
			  NStr("ru = 'НА СЕРВЕРЕ:'; en = 'ON THE SERVER:'; pl = 'ON THE SERVER:';de = 'ON THE SERVER:';ro = 'ON THE SERVER:';tr = 'ON THE SERVER:'; es_ES = 'ON THE SERVER:'")
			+ Chars.LF + Chars.LF + ErrorAtServer.ErrorDescription
			+ Chars.LF + Chars.LF
			+ NStr("ru = 'НА КОМПЬЮТЕРЕ:'; en = 'ON THE COMPUTER:'; pl = 'ON THE COMPUTER:';de = 'ON THE COMPUTER:';ro = 'ON THE COMPUTER:';tr = 'ON THE COMPUTER:'; es_ES = 'ON THE COMPUTER:'")
			+ Chars.LF + Chars.LF + ErrorAtClient.ErrorDescription;
	Else
		ErrorDescription = ErrorAtClient.ErrorDescription;
	EndIf;
	
	ErrorDescription = TrimAll(ErrorDescription);
	Items.ErrorDescription.Title = ErrorDescription;
	
	ShowInstruction                = Parameters.ShowInstruction;
	ShowOpenApplicationsSettings = Parameters.ShowOpenApplicationsSettings;
	ShowExtensionInstallation       = Parameters.ShowExtensionInstallation;
	
	DetermineCapabilities(ShowInstruction, ShowOpenApplicationsSettings, ShowExtensionInstallation,
		ErrorAtClient, IsFullUser);
	
	DetermineCapabilities(ShowInstruction, ShowOpenApplicationsSettings, ShowExtensionInstallation,
		ErrorAtServer, IsFullUser);
	
	If Not ShowInstruction Then
		Items.Instruction.Visible = False;
	EndIf;
	
	ShowExtensionInstallation = ShowExtensionInstallation AND Not Parameters.ExtensionAttached;
	
	If Not ShowExtensionInstallation Then
		Items.FormInstallExtension.Visible = False;
	EndIf;
	
	If Not ShowOpenApplicationsSettings Then
		Items.FormOpenApplicationSettings.Visible = False;
	EndIf;
	
	ResetWindowLocationAndSize();
	
	If TypeOf(Parameters.UnsignedData) = Type("Structure") Then
		DigitalSignatureInternal.RegisterDataSigningInLog(
			Parameters.UnsignedData, ErrorDescription);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure InstructionClick(Item)
	
	DigitalSignatureInternalClient.OpenInstructionOfWorkWithApplications();
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure OpenApplicationsSettings(Command)
	
	Close();
	DigitalSignatureClient.OpenDigitalSignatureAndEncryptionSettings("Applications");
	
EndProcedure

&AtClient
Procedure InstallExtension(Command)
	
	DigitalSignatureClient.InstallExtension(True);
	Close();
	
EndProcedure

&AtClient
Procedure CopyToClipboard(Command)
	
	Row = Items.ErrorDescription.Title;
	ShowInputString(New NotifyDescription("CopyToClipboardCompletion", ThisObject),
		Row, NStr("ru = 'Текст ошибки для копирования'; en = 'Error text for copying'; pl = 'Error text for copying';de = 'Error text for copying';ro = 'Error text for copying';tr = 'Error text for copying'; es_ES = 'Error text for copying'"),, True);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure CopyToClipboardCompletion(Result, Context) Export
	
	Result = "";
	
EndProcedure

&AtServer
Procedure ResetWindowLocationAndSize()
	
	Username = InfoBaseUsers.CurrentUser().Name;
	
	If AccessRight("SaveUserData", Metadata) Then
		SystemSettingsStorage.Delete("CommonForm.Question", "", Username);
	EndIf;
	
	WindowOptionsKey = String(New UUID);
	
EndProcedure

&AtServer
Procedure DetermineCapabilities(Instruction, ApplicationsSetUp, Extension, Error, IsFullUser)
	
	DetermineCapabilitiesByProperties(Instruction, ApplicationsSetUp, Extension, Error, IsFullUser);
	
	If Not Error.Property("Errors") Or TypeOf(Error.Errors) <> Type("Array") Then
		Return;
	EndIf;
	
	For each CurrentError In Error.Errors Do
		DetermineCapabilitiesByProperties(Instruction, ApplicationsSetUp, Extension, CurrentError, IsFullUser);
	EndDo;
	
EndProcedure

&AtServer
Procedure DetermineCapabilitiesByProperties(Instruction, ApplicationsSetUp, Extension, Error, IsFullUser)
	
	If Error.Property("ApplicationsSetUp") AND Error.ApplicationsSetUp = True Then
		ApplicationsSetUp = IsFullUser
			Or Not Error.Property("ToAdministrator")
			Or Error.ToAdministrator <> True;
	EndIf;
	
	If Error.Property("Instruction") AND Error.Instruction = True Then
		Instruction = True;
	EndIf;
	
	If Error.Property("Extension") AND Error.Extension = True Then
		Extension = True;
	EndIf;
	
EndProcedure

#EndRegion
