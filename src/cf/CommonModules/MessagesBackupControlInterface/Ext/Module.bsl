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
//   String - a namespace.
//
Function Package() Export
	
	Return "http://www.1c.ru/SaaS/ControlZonesBackup/" + Version();
	
EndFunction

// Returns the current (used by the calling code) message interface version.
// 
// Returns:
//   String - an interface version.
//
Function Version() Export
	
	Return "1.0.3.1";
	
EndFunction

// Returns the name of the message API.
// 
// Returns:
//   String - an interface name.
//
Function Public() Export
	
	Return "ControlZonesBackup";
	
EndFunction

// Registers message handlers as message exchange channel handlers.
//
// Parameters:
//  HandlerArray - Array - an array of handlers.
//
Procedure MessagesChannelsHandlers(Val HandlersArray) Export
	
EndProcedure

// Registers message translation handlers.
//
// Parameters:
//  HandlerArray - Array - an array of handlers.
//
Procedure MessagesTranslationHandlers(Val HandlersArray) Export
	
	HandlersArray.Add(MessagesBackupControlTranslationHandler_1_0_2_1);
	
EndProcedure

// Returns {http://www.1c.ru/SaaS/ControlZonesBackup/a.b.c.d}ZoneBackupSuccessfull message type.
//
// Parameters:
//  PackageUsed - String - a namespace of the message interface version for which the message type is being received.
//
// Returns:
//  XDTOType - a message type.
//
Function AreaBackupCreatedMessage(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "ZoneBackupSuccessfull");
	
EndFunction

// Returns {http://www.1c.ru/SaaS/ControlZonesBackup/a.b.c.d}ZoneBackupFailed message type.
//
// Parameters:
//  PackageUsed - String - a namespace of the message interface version for which the message type is being received.
//
// Returns:
//  XDTOType - a message type.
//
Function AreaBackupErrorMessage(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "ZoneBackupFailed");
	
EndFunction

// Returns {http://www.1c.ru/SaaS/ControlZonesBackup/a.b.c.d}ZoneBackupSkipped message type.
//
// Parameters:
//  PackageUsed - String - a namespace of the message interface version for which the message type is being received.
//
// Returns:
//  XDTOType - a message type.
//
Function AreaBackupSkippedMessage(Val PackageToUse = Undefined) Export
	
	If PackageToUse = Undefined Then
		PackageToUse = "http://www.1c.ru/SaaS/ControlZonesBackup/1.0.2.1";
	EndIf;
	
	Return GenerateMessageType(PackageToUse, "ZoneBackupSkipped");
	
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
