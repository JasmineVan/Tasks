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
	
	If Parameters.ForExternalUser Then
		AuthorizationSettings = UsersInternalCached.Settings().ExternalUsers;
	Else
		AuthorizationSettings = UsersInternalCached.Settings().Users;
	EndIf;
	
	MinPasswordLength = GetUserPasswordMinLength();
	
	If MinPasswordLength < AuthorizationSettings.MinPasswordLength Then
		MinPasswordLength = AuthorizationSettings.MinPasswordLength;
	EndIf;
	
	If MinPasswordLength <= 8 Then
		MinPasswordLength = 8;
	EndIf;
	
	PasswordParameters = UsersInternal.PasswordParameters(MinPasswordLength, True);
	
	NewPassword = UsersInternal.CreatePassword(PasswordParameters);
	
	If Common.IsMobileClient() Then
		Items.FormClose.Visible = False;
	EndIf;
	
EndProcedure

#EndRegion
