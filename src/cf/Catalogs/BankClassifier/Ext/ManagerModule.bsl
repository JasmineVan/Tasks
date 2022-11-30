﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region ForCallsFromOtherSubsystems

// StandardSubsystems.BatchObjectsModification

// Returns the object attributes that are not recommended to be edited using batch attribute 
// modification data processor.
//
// Returns:
//  Array - a list of object attribute names.
Function AttributesToSkipInBatchProcessing() Export
	
	Result = New Array;
	Result.Add("*");
	Return Result;
	
EndFunction

// End StandardSubsystems.BatchObjectsModification

// SaaSTechnology.ExportImportData

// Returns the catalog attributes that naturally form a catalog item key.
// 
//
// Returns:
//  Array - an array of attribute names that form a natural key.
//
Function NaturalKeyFields() Export
	
	Result = New Array();
	
	Result.Add("Code");
	
	Return Result;
	
EndFunction

// End SaaSTechnology.ExportImportData

#EndRegion

#EndRegion

#EndIf
