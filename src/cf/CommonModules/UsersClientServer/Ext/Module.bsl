///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

#Region ObsoleteProceduresAndFunctions

// Obsolete.
// See Users.AuthorizedUser. 
// See UsersClient.AuthorizedUser. 
//
Function AuthorizedUser() Export
	
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	Return Users.AuthorizedUser();
#Else
	Return UsersClient.AuthorizedUser();
#EndIf
	
EndFunction

// Obsolete.
// See Users.CurrentUser. 
// See UsersClient.CurrentUser. 
//
Function CurrentUser() Export
	
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	Return Users.CurrentUser();
#Else
	Return UsersClient.CurrentUser();
#EndIf
	
EndFunction

// Obsolete.
// See ExternalUsers.CurrentExternalUser. 
// See ExternalUsersClient.CurrentExternalUser. 
//
Function CurrentExternalUser() Export
	
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	Return ExternalUsers.CurrentExternalUser();
#Else
	Return ExternalUsersClient.CurrentExternalUser();
#EndIf
	
EndFunction

// Obsolete.
// See Users.IsExternalUserSession. 
// See UsersClient.IsExternalUserSession. 
//
Function IsExternalUserSession() Export
	
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	Return Users.IsExternalUserSession();
#Else
	Return UsersClient.IsExternalUserSession();
#EndIf
	
EndFunction

#EndRegion

#EndRegion
