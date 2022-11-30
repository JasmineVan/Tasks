///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Returns a namespace of the current (used by the calling code) message interface version.
//
// Returns:
//  String - a package description.
//
Function Package() Export
	
	Return "http://www.1c.ru/SaaS/ManageZonesBackup/" + Version();
	
EndFunction

// Returns the current (used by the calling code) message interface version.
//
// Returns:
//  String - a package version.
//
Function Version() Export
	
	Return "1.0.3.1";
	
EndFunction

// Returns the name of the message API.
//
// Returns:
//  String - an application interface ID.
//
Function Public() Export
	
	Return "ManageZonesBackup";
	
EndFunction

// Registers message handlers as message exchange channel handlers.
//
// Parameters:
//  HandlerArray - Array - an array of handlers.
//
Procedure MessagesChannelsHandlers(Val HandlersArray) Export
	
	HandlersArray.Add(MessagesBackupManagementMessageHandler_1_0_2_1);
	HandlersArray.Add(MessagesBackupManagementMessageHandler_1_0_3_1);
	
EndProcedure

// Registers message translation handlers.
//
// Parameters:
//  HandlerArray - Array - an array of handlers.
//
Procedure MessagesTranslationHandlers(Val HandlersArray) Export
	
EndProcedure

// Returns {http://www.1c.ru/SaaS/ManageZonesBackup/a.b.c.d}PlanZoneBackup message type.
//
// Parameters:
//  PackageUsed - String - a namespace of the message interface version for which the message type 
//    is being received.
//
// Returns:
//  XDTOType - a message.
//
Function MessageScheduleAreaBackup(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "PlanZoneBackup");
	
EndFunction

// Returns {http://www.1c.ru/SaaS/ManageZonesBackup/a.b.c.d}CancelZoneBackup message type.
//
// Parameters:
//  PackageUsed - String - a namespace of the message interface version for which the message type 
//    is being received.
//
// Returns:
//  XDTOType - message.
//
Function MessageCancelAreaBackup(Val PackageToUse = Undefined) Export
	
	If PackageToUse = Undefined Then
		PackageToUse = "http://www.1c.ru/SaaS/ManageZonesBackup/1.0.2.1";
	EndIf;
	
	Return GenerateMessageType(PackageToUse, "CancelZoneBackup");
	
EndFunction

// Returns {http://www.1c.ru/SaaS/ManageZonesBackup/a.b.c.d}UpdateScheduledZoneBackupSettings message type.
//
// Parameters:
//  PackageUsed - String - a namespace of the message interface version for which the message type 
//    is being received.
//
// Returns:
//  XDTOType - message.
//
Function MessageUpdatePeriodicBackupSettings(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "UpdateScheduledZoneBackupSettings");
	
EndFunction

// Returns {http://www.1c.ru/SaaS/ManageZonesBackup/a.b.c.d}CancelScheduledZoneBackup message type.
//
// Parameters:
//  PackageUsed - String - a namespace of the message interface version for which the message type 
//    is being received.
//
// Returns:
//  XDTOType - message.
//
Function MessageCancelPeriodicBackup(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "CancelScheduledZoneBackup");
	
EndFunction

#EndRegion

#Region Private

Function GenerateMessageType(Val PackageToUse, Val Type)
	
	If PackageToUse = Undefined Then
		PackageToUse = Package();
	EndIf;
	
	Return XDTOFactory.Type(PackageToUse, Type);
	
EndFunction

#EndRegion
