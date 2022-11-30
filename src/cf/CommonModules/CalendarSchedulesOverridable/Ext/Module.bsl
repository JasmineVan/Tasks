///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// It is called upon changing business calendar data.
// If the separation is enabled, it runs in the shared mode.
//
// Parameters:
//	UpdateConditions - ValueTable - a table with the following columns:
//		* BusinessCalendarCode - String - a code of business calendar whose data is changed.
//		* Year - Number - a calendar year, during which data is changed.
//
Procedure OnUpdateBusinessCalendars(UpdateConditions) Export
	
EndProcedure

// It is called upon changing data dependent on business calendars.
// If the separation is enabled, the procedure runs in data areas.
//
// Parameters:
//	UpdateConditions - ValueTable - a table with the following columns:
//		* BusinessCalendarCode - String - a code of business calendar whose data is changed.
//		* Year - Number - a calendar year, during which data is changed.
//
Procedure OnUpdateDataDependentOnBusinessCalendars(UpdateConditions) Export
	
EndProcedure

// The procedure is called upon registering a deferred handler that updates data dependent on business calendars.
// Add metadata names of objects to be blocked from usage for the period of business calendar update 
// to ObjectsToBlock.
//
// Parameters:
//	ObjectsToBlock - Array - metadata names of objects to be blocked.
//
Procedure OnFillObjectsToBlockDependentOnBusinessCalendars(ObjectsToLock) Export
	
EndProcedure

#EndRegion
