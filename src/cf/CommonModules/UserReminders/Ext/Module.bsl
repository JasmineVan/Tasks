﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Generates a reminder with arbitrary time or execution schedule.
//
// Parameters:
//  Text - String - a reminder text.
//  EventTime - Date - date and time of the event, which needs a reminder.
//               - JobSchedule - a schedule of a periodic event.
//               - String - a name of the Subject attribute that contains time of the event start.
//  IntervalTillEvent - Number - time in seconds, prior to which it is necessary to remind of the event time.
//  Subject - AnyRef - a reminder subject.
//  ID - String - clarifies the reminder subject, for example, Birthday.
//
Procedure SetReminder(Text, EventTime, IntervalTillEvent = 0, Topic = Undefined, ID = Undefined) Export
	UserRemindersInternal.AttachArbitraryReminder(
		Text, EventTime, IntervalTillEvent, Topic, ID);
EndProcedure

// Returns a list of reminders for the current user.
//
// Parameters:
//  Subject - Reference, Array - a reminder subject or subjects.
//  ID - String - clarifies the reminder subject, for example, Birthday.
//
// Returns:
//    Array - a collection of reminders as structures with fields corresponding to the UserReminders information register fields.
//
Function FindReminders(Val Topic = Undefined, ID = Undefined) Export
	
	QueryText =
	"SELECT
	|	*
	|FROM
	|	InformationRegister.UserReminders AS UserReminders
	|WHERE
	|	UserReminders.User = &User
	|	AND &FilterBySubject
	|	AND &FilterByID";
	
	FilterBySubject = "TRUE";
	If ValueIsFilled(Topic) Then
		FilterBySubject = "UserReminders.Source IN(&Topic)";
	EndIf;
	
	FilterByID = "TRUE";
	If ValueIsFilled(ID) Then
		FilterByID = "UserReminders.ID = &ID";
	EndIf;
	
	QueryText = StrReplace(QueryText, "&FilterBySubject", FilterBySubject);
	QueryText = StrReplace(QueryText, "&FilterByID", FilterByID);
	
	Query = New Query(QueryText);
	Query.SetParameter("User", Users.CurrentUser());
	Query.SetParameter("Topic", Topic);
	Query.SetParameter("ID", ID);
	
	RemindersTable = Query.Execute().Unload();
	
	Return Common.ValueTableToArray(RemindersTable);
	
EndFunction

// Deletes a user reminder.
//
// Parameters:
//  Reminder - Structure - a collection item returned by the FindReminders() function.
//
Procedure DeleteReminder(Reminder) Export
	UserRemindersInternal.DisableReminder(Reminder, False);
EndProcedure

#EndRegion
