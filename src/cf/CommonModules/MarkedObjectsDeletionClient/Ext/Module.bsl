///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// The NotificationProcessing event handler for the form, on which the check box of scheduled deletion is to be displayed.
//
// Parameters:
//   EventName - String - a name of an event that is got by an event handler on the form.
//   AutomaticallyDeleteMarkedObjects - Number - an attribute, to which a value will be placed.
// 
// Example:
//	If CommonClient.SubsystemExists("StandardSubsystems.MarkedObjectsDeletion") Then
//		ModuleMarkedObjectsDeletionClient = CommonClient.CommonModule("MarkedObjectsDeletionClient");
//		ModuleMarkedObjectsDeletionClient.DeleteOnScheduleCheckBoxChangeNotificationProcessing(
//			EventName,
//			AutomaticallyDeleteMarkedObjects);
//	EndIf;
//
Procedure DeleteOnScheduleCheckBoxChangeNotificationProcessing(Val EventName, AutomaticallyDeleteMarkedObjects) Export
	
	If EventName = "ModeChangedAutomaticallyDeleteMarkedObjects" Then
		AutomaticallyDeleteMarkedObjects = 
			MarkedObjectsDeletionInternalServerCall.DeleteOnScheduleCheckBoxValue();
	EndIf;
	
EndProcedure

// The OnChange event handler for the flag that switches the automatic object deletion mode.
// The check box must be related to the Boolean type attribute.
// 
// Parameters:
//   AutomaticallyDeleteMarkedObjectsCheckBoxValue - Boolean - a new check box value to be processed.
// 
// Example:
//	If CommonClient.SubsystemExists("StandardSubsystems.MarkedObjectsDeletion") Then
//		ModuleMarkedObjectsDeletionClient = CommonClient.CommonModule("MarkedObjectsDeletionClient");
//		ModuleMarkedObjectsDeletionClient.OnChangeCheckBoxDeleteOnSchedule(AutomaticallyDeleteMarkedObjects);
//	EndIf;
//
Procedure OnChangeCheckBoxDeleteOnSchedule(AutomaticallyDeleteMarkedObjectsCheckBoxValue) Export
	
	MarkedObjectsDeletionInternalServerCall.SetDeleteOnScheduleMode(
		AutomaticallyDeleteMarkedObjectsCheckBoxValue);
	
	Notify("ModeChangedAutomaticallyDeleteMarkedObjects");
	
EndProcedure

// Opens the form for deleting marked objects.
//
Procedure StartMarkedObjectsDeletion() Export
	
	OpenForm("DataProcessor.MarkedObjectsDeletion.Form");
	
EndProcedure

#EndRegion