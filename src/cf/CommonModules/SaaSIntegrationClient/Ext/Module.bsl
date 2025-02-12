﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
// Integration with Service Technology Library (STL).
// Here you can find processors of program events that make calls between SSL and STL.
// 
//


// Processing program events that occur in SSL subsystems.
// Only for calls from SSL libraries to STL.

#Region Internal

#Region Core

// See CommonClientOverridable.OnStart. 
Procedure OnStart(Parameters) Export
	
	If CommonClient.SubsystemExists("SaaSTechnology.Core") Then
		ModuleSaaSTechnologyIntegrationWithSSLClient = CommonClient.CommonModule("SaaSTechnologyIntegrationWithSSLClient");
		ModuleSaaSTechnologyIntegrationWithSSLClient.OnStart(Parameters);
	EndIf;
	
EndProcedure

// See CommonClientOverridable.BeforeExit. 
Procedure BeforeExit(Cancel, Warnings) Export
	
	If CommonClient.SubsystemExists("SaaSTechnology.Core") Then
		ModuleSaaSTechnologyIntegrationWithSSLClient = CommonClient.CommonModule("SaaSTechnologyIntegrationWithSSLClient");
		ModuleSaaSTechnologyIntegrationWithSSLClient.BeforeExit(Cancel, Warnings);
	EndIf;
	
EndProcedure

#EndRegion

#Region UserSessionsCompletion

// Called on session termination using the UserSessions subsystem.
// 
// Parameters:
//  OwnerForm - ManagedForm used to terminate the session.
//  SessionNumbers - Number (8,0,+) - the number of the session to be terminated.
//  StandardProcessing - Boolean, flag specifying whether standard session termination processing is 
//    used (accessing the server agent via COM connection or administration server, requesting the 
//    cluster connection parameters from the current user). Can be set to False in the event 
//    handler; in this case, standard session termination processing is not performed.
//    
//  NotificationAfterEndSession - NotifyDescription - the description of the notification to be 
//    displayed after a session is terminated (to automatically refresh the active user list).
//     If the StandardProcessing parameter value is set to False, after a session if completed, use 
//    the ExecuteNotifyProcessing method to process the notification details. Set the Result 
//    parameter value to DialogReturnCode.OK).
//    
//     You can omit the parameter and skip the notification processing.
//    
//
Procedure OnEndSessions(OwnerForm, Val SessionNumbers, StandardProcessing, Val NotificationAfterEndSession = Undefined) Export
	
	If CommonClient.SubsystemExists("SaaSTechnology.Core") Then
		ModuleSaaSTechnologyIntegrationWithSSLClient = CommonClient.CommonModule("SaaSTechnologyIntegrationWithSSLClient");
		ModuleSaaSTechnologyIntegrationWithSSLClient.OnEndSessions(OwnerForm, SessionNumbers, StandardProcessing, NotificationAfterEndSession);
	EndIf;
	
EndProcedure

#EndRegion

#Region SecurityProfiles

// See SafeModeManagerClientOverridable.OnConfirmRequestsToUseExternalResources. 
Procedure OnConfirmRequestsToUseExternalResources(Val RequestIDs, OwnerForm, 
	ClosingNotification, StandardProcessing) Export

	If CommonClient.SubsystemExists("SaaSTechnology.Core") Then
		ModuleSaaSTechnologyIntegrationWithSSLClient = CommonClient.CommonModule("SaaSTechnologyIntegrationWithSSLClient");
		ModuleSaaSTechnologyIntegrationWithSSLClient.OnConfirmRequestsToUseExternalResources(RequestIDs, 
			OwnerForm, ClosingNotification, StandardProcessing);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
