///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// The NotificationProcessing event handler for the form, on which the flag of search usage is to be displayed.
//
// Parameters:
//   EventName - String - a name of an event that is got by an event handler on the form.
//   UseFullTextSearch - Number - an attribute, to which a value will be placed.
// 
// Example:
//	If CommonClient.SubsystemExists("StandardSubsystems.FullTextSearch") Then
//		ModuleFullTextSearchClient = CommonClient.CommonModule("FullTextSearchClient");
//		ModuleFullTextSearchClient.UseSearchFlagChangeNotificationProcessing(
//			EventName,
//			UseFullTextSearch);
//	EndIf;
//
Procedure UseSearchFlagChangeNotificationProcessing(Val EventName, UseFullTextSearch) Export
	
	If EventName = "FullTextSearchModeChanged" Then
		UseFullTextSearch = FullTextSearchInternalServerCall.UseSearchFlagValue();
	EndIf;
	
EndProcedure

// The OnChange event handler for the flag that switches the full text search mode.
// The flag is to be related to an attribute of the Number type.
// 
// Parameters:
//   UseSearchFlagValue - Number - a new flag value to be processed.
// 
// Example:
//	If CommonClient.SubsystemExists("StandardSubsystems.FullTextSearch") Then
//		ModuleFullTextSearchClient = CommonClient.CommonModule("FullTextSearchClient");
//		ModuleFullTextSearchClient.OnChangeUseSearchFlag(UseFullTextSearch);
//	EndIf;
//
Procedure OnChangeUseSearchFlag(UseSearchFlagValue) Export
	
	UseFullTextSearch = (UseSearchFlagValue = 1);
	
	IsSet = FullTextSearchInternalServerCall.SetFullTextSearchMode(
		UseFullTextSearch);
	
	If Not IsSet Then
		FullTextSearchInternalClient.ShowExclusiveChangeModeWarning();
	EndIf;
	
	Notify("FullTextSearchModeChanged");
	
EndProcedure

// Opens the form of full-text search and text extraction management.
// Remember to set the command calling the procedure dependent on the UseFullTextSearch functional 
// option.
//
// Example:
//	If CommonClient.SubsystemExists("StandardSubsystems.FullTextSearch") Then
//		ModuleFullTextSearchClient = CommonClient.CommonModule("FullTextSearchClient");
//		ModuleFullTextSearchClient.ShowSetting();
//	EndIf;
//
Procedure ShowSetting() Export
	
	OpenForm("DataProcessor.FullTextSearchInData.Form.FullTextSearchAndTextExtractionControl");
	
EndProcedure

#Region ObsoleteProceduresAndFunctions

// Obsolete. Use ShowSetting.
// Opens the form of full-text search and text extraction management.
//
Procedure ShowFullTextSearchAndTextExtractionManagement() Export
	
	ShowSetting();
	
EndProcedure

#EndRegion

#EndRegion