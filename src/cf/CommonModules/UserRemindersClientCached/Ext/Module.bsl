﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Executes a query on reminders for the current user 30 minutes ahead of the current time.
// The point in time is offset from the current moment to ensure that the data is relevant during cache lifetime.
// Consider this feature upon processing the function execution result.
//
// Parameters:
//	No
//
// Returns
//  Array - a value table converted to an array of structures, it contains the list of current reminders.
//           FixedArray is not used because the cached function result needs to be modified on the 
//           client. Such approach is used to minimize server calls.
Function GetCurrentUserReminders() Export
	Return UserRemindersServerCall.GetCurrentUserReminders();
EndFunction

#EndRegion
