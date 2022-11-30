///////////////////////////////////////////////////////////////////////////////////////////////////////
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

// Names of catalog attributes, whose values you can bulk change.
//
// Returns:
//   Array (String) - catalog attributes names.
//
Function AttributesToEditInBatchProcessing() Export
	
	Result = New Array;
	
	Return Result;
	
EndFunction

// End StandardSubsystems.BatchObjectsModification

// SaaSTechnology.ExportImportData

// Catalog attributes names used to control items uniqueness.
//
// Returns:
//   Array (String) - catalog attributes names.
//
Function NaturalKeyFields() Export
	
	Result = New Array();
	
	Result.Add("Report");
	Result.Add("VariantKey");
	
	Return Result;
	
EndFunction

// End SaaSTechnology.ExportImportData

#EndRegion

#EndRegion

#EndIf

#Region EventHandlers

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	LocalizationClientServer.PresentationGetProcessing(Data, Presentation, StandardProcessing);
		
EndProcedure

#EndRegion
