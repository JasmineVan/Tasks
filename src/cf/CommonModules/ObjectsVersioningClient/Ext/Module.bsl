///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Opens object version report in version comparison mode.
//
// Parameters:
//  Reference                       - AnyRef - reference to the versioned object;
//  SerializedObjectAddress - String - address of binary data of the compared object version in the 
//                                          temporary storage.
//
Procedure OpenReportOnChanges(Ref, SerializedObjectAddress) Export
	
	Parameters = New Structure;
	Parameters.Insert("Ref", Ref);
	Parameters.Insert("SerializedObjectAddress", SerializedObjectAddress);
	
	OpenForm("InformationRegister.ObjectsVersions.Form.ObjectVersionsReport", Parameters);
	
EndProcedure

// Shows an object's saved version.
//
// Parameters:
//  Reference                       - AnyRef - reference to the versioned object;
//  SerializedObjectAddress - String - address of the object version binary data in the temporary storage.
//
Procedure OpenReportOnObjectVersion(Ref, SerializedObjectAddress) Export
	
	Parameters = New Structure;
	Parameters.Insert("Ref", Ref);
	Parameters.Insert("SerializedObjectAddress", SerializedObjectAddress);
	Parameters.Insert("ByVersion", True);
	
	OpenForm("InformationRegister.ObjectsVersions.Form.ObjectVersionsReport", Parameters);
	
EndProcedure

// The NotificationProcessing event handler for the form that requires a changes history storing check box to be displayed.
//
// Parameters:
//   EventName - String - a name of an event that is got by an event handler on the form.
//   StoreChangesHistory - Number - an attribute, to which a value will be placed.
// 
// Example:
//	If CommonClient.SubsystemExists("StandardSubsystems.ObjectsVersioning") Then
//		ModuleObjectVersioningClient = CommonClient.CommonModule("ObjectsVersioningClient");
//		ModuleObjectVersioningClient.StoreHistoryCheckBoxChangeNotificationProcessing(
//			EventName,
//			StoreChangeHistory);
//	EndIf.
//
Procedure StoreHistoryCheckBoxChangeNotificationProcessing(Val EventName, StoreChangeHistory) Export
	
	If EventName = "ChangelogStorageModeChanged" Then
		StoreChangeHistory = ObjectsVersioningInternalServerCall.StoreHistoryCheckBoxValue();
	EndIf;
	
EndProcedure

// The OnChange event handler for the heck box that switches change history storage modes.
// The check box must be related to the Boolean type attribute.
// 
// Parameters:
//   StoreChangesHistoryCheckBoxValue - Boolean - a new check box value to be processed.
// 
// Example:
//	If CommonClient.SubsystemExists("StandardSubsystems.ObjectsVersioning") Then
//		ModuleObjectVersioningClient = CommonClient.CommonModule("ObjectsVersioningClient");
//		ModuleObjectVersioningClient.OnStoreHistoryCheckBoxChange(StoreChangesHistory);
//	EndIf.
//
Procedure OnStoreHistoryCheckBoxChange(StoreChangesHistoryCheckBoxValue) Export
	
	ObjectsVersioningInternalServerCall.SetChangeHistoryStorageMode(
		StoreChangesHistoryCheckBoxValue);
	
	Notify("ChangelogStorageModeChanged");
	
EndProcedure

// Opens up an object versioning control form.
// Remember to set the command that calls the procedure dependent on the UseObjectsVersioning 
// functional option.
//
// Example:
//	If CommonClient.SubsystemExists("StandardSubsystems.ObjectsVersioning") Then
//		ModuleObjectVersioningClient = CommonClient.CommonModule("ObjectsVersioningClient");
//		ModuleObjectVersioningClient.ShowSetting();
//	EndIf.
//
Procedure ShowSetting() Export
	
	OpenForm("InformationRegister.ObjectVersioningSettings.ListForm");
	
EndProcedure

#EndRegion

#Region Internal

// Opens a report on a version or version comparison.
//
// Parameters:
//  Ref - AnyRef - a reference to an object;
//  VersionsToCompare - Array - a collection of versions to compare. If there is only one version, the report on the version will be opened.
//
Procedure OpenVersionComparisonReport(Ref, VersionsToCompare) Export
	
	ReportParameters = New Structure;
	ReportParameters.Insert("Ref", Ref);
	ReportParameters.Insert("VersionsToCompare", VersionsToCompare);
	OpenForm("InformationRegister.ObjectsVersions.Form.ObjectVersionsReport", ReportParameters);
	
EndProcedure

#EndRegion
