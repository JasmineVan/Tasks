﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// Returns the enumeration value corresponding to the string name of the event status.
//
// Parameters:
//	Name - String - the entry transaction status.
//
// Returns:
//	EventLogEntryTransactionStatus - transaction status value.
//
Function EventLogEntryTransactionStatusValueByName(Name) Export
	
	EnumValue = Undefined;
	If Name = "Committed" Then
		EnumValue = EventLogEntryTransactionStatus.Committed;
	ElsIf Name = "Unfinished" Then
		EnumValue = EventLogEntryTransactionStatus.Unfinished;
	ElsIf Name = "NotApplicable" Then
		EnumValue = EventLogEntryTransactionStatus.NotApplicable;
	ElsIf Name = "RolledBack" Then
		EnumValue = EventLogEntryTransactionStatus.RolledBack;
	EndIf;
	Return EnumValue;
	
EndFunction

// Returns the enumeration value corresponding to the string level of the event log.
//
// Parameters:
//	Name - String - event log level.
//
// Returns:
//	EventLogLevel - event log level value.
//
Function EventLogLevelValueByName(Name) Export
	
	EnumValue = Undefined;
	If Name = "Information" Then
		EnumValue = EventLogLevel.Information;
	ElsIf Name = "Error" Then
		EnumValue = EventLogLevel.Error;
	ElsIf Name = "Warning" Then
		EnumValue = EventLogLevel.Warning;
	ElsIf Name = "Note" Then
		EnumValue = EventLogLevel.Note;
	EndIf;
	Return EnumValue;
	
EndFunction

// Sets the picture number in the row of the event log.
//
// Parameters:
//	LogEvent - Value table row - a row of the event log.
//
Procedure SetPictureNumber(LogEvent) Export
	
	// Setting relative image number.
	If LogEvent.Level = EventLogLevel.Information Then
		LogEvent.PictureNumber = 0;
	ElsIf LogEvent.Level = EventLogLevel.Warning Then
		LogEvent.PictureNumber = 1;
	ElsIf LogEvent.Level = EventLogLevel.Error Then
		LogEvent.PictureNumber = 2;
	Else
		LogEvent.PictureNumber = 3;
	EndIf;
	
	// Setting absolute image number.
	If LogEvent.TransactionStatus = EventLogEntryTransactionStatus.Unfinished
	 OR LogEvent.TransactionStatus = EventLogEntryTransactionStatus.RolledBack Then
		LogEvent.PictureNumber = LogEvent.PictureNumber + 4;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf