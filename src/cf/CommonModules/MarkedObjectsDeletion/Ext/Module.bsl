///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Check box state for the setup form of marked objects deletion.
//
// Returns:
//   Boolean - a value.
//
// Example:
//	If Common.SubsystemExists("StandardSubsystems.MarkedObjectsDeletion") Then
//		ModuleMarkedObjectsDeletion = Common.CommonModule("MarkedObjectsDeletion");
//		AutomaticallyDeleteMarkedObjects = ModuleMarkedObjectsDeletion.DeleteOnScheduleCheckBoxValue();
//	Else
//		Items.AutomaticObjectsDeletionGroup.Visibility = False;
//	EndIf;
//
Function DeleteOnScheduleCheckBoxValue() Export
	
	Filter = New Structure;
	Filter.Insert("Metadata", Metadata.ScheduledJobs.MarkedObjectsDeletion);
	Jobs = ScheduledJobsServer.FindJobs(Filter);
	
	For Each Job In Jobs Do 
		Return Job.Use;
	EndDo;
	
	Return False;
	
EndFunction

#EndRegion
