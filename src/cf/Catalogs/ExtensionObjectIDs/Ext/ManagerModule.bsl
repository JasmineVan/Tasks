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

// Returns object attributes allowed to be edited using batch attribute change data processor.
// 
//
// Returns:
//  Array - a list of object attribute names.
Function AttributesToEditInBatchProcessing() Export
	
	Return Catalogs.MetadataObjectIDs.AttributesToEditInBatchProcessing();
	
EndFunction

// End StandardSubsystems.BatchObjectsModification

// SaaSTechnology.ExportImportData

// Returns the catalog attributes that naturally form a catalog item key.
//
// Returns:
//  Array (String) - an array of attribute names that form a natural key.
//
Function NaturalKeyFields() Export
	
	Return Catalogs.MetadataObjectIDs.NaturalKeyFields();
	
EndFunction

// End SaaSTechnology.ExportImportData

#EndRegion

#EndRegion

#Region Internal

Function DataTablesFullNames() Export
	
	Tables = New Array;
	
	If Not ValueIsFilled(SessionParameters.AttachedExtensions) Then
		Return Tables;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("ExtensionsVersion", SessionParameters.ExtensionsVersion);
	Query.Text =
	"SELECT TOP 1
	|	TRUE AS TrueValue
	|FROM
	|	InformationRegister.ExtensionVersionObjectIDs AS IDsVersions
	|WHERE
	|	IDsVersions.ExtensionsVersion = &ExtensionsVersion
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	IDsVersions.FullObjectName AS FullObjectName
	|FROM
	|	InformationRegister.ExtensionVersionObjectIDs AS IDsVersions
	|WHERE
	|	IDsVersions.ExtensionsVersion = &ExtensionsVersion
	|	AND IDsVersions.ID.NoData = FALSE";
	
	QueryResults = Query.ExecuteBatch();
	
	If QueryResults[0].IsEmpty() Then
		Catalogs.MetadataObjectIDs.IsDataUpdated(True, True);
		QueryResults = Query.ExecuteBatch();
	EndIf;
	
	Return QueryResults[1].Unload().UnloadColumn("FullObjectName");
	
EndFunction

#EndRegion

#Region Private

// This procedure updates catalog data using the configuration metadata.
//
// Parameters:
//  HasChanges - Boolean (return value) - True is returned to this parameter if changes are saved. 
//                   Otherwise, not modified.
//
//  HasDeletedItems - Boolean - receives True if a catalog item was marked for deletion. Otherwise, 
//                   not modified.
//                   
//
//  CheckOnly - Boolean - make no changes, just set the HasChanges and HasDeleted flags.
//                   
//
Procedure UpdateCatalogData(HasChanges = False, HasDeletedItems = False, CheckOnly = False) Export
	
	Catalogs.MetadataObjectIDs.RunDataUpdate(HasChanges,
		HasDeletedItems, CheckOnly, , , True);
	
EndProcedure

// Returns True if the metadata object, which the extension object ID corresponds to, exists in the 
// catalog, does not have the deletion mark but is absent from the extension metadata cache.
// 
//
// Parameters:
//  ID - CatalogRef.ExtensionObjectIDs - the ID of a metadata object in an extension.
//                    
//
// Returns:
//  Boolean - True if disabled.
//
Function ExtensionObjectDisabled(ID) Export
	
	StandardSubsystemsCached.MetadataObjectIDsUsageCheck(True, True);
	
	Query = New Query;
	Query.SetParameter("Ref", ID);
	Query.SetParameter("ExtensionsVersion", SessionParameters.ExtensionsVersion);
	
	Query.Text =
	"SELECT TOP 1
	|	TRUE AS TrueValue
	|FROM
	|	Catalog.ExtensionObjectIDs AS IDs
	|WHERE
	|	IDs.Ref = &Ref
	|	AND NOT IDs.DeletionMark
	|	AND NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					InformationRegister.ExtensionVersionObjectIDs AS IDsVersions
	|				WHERE
	|					IDsVersions.ID = IDs.Ref
	|					AND IDsVersions.ExtensionsVersion = &ExtensionsVersion)";
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

// For internal use only.
Function CurrentVersionExtensionObjectIDsFilled() Export
	
	Query = New Query;
	Query.SetParameter("ExtensionsVersion", SessionParameters.ExtensionsVersion);
	Query.Text =
	"SELECT TOP 1
	|	TRUE AS TrueValue
	|FROM
	|	InformationRegister.ExtensionVersionObjectIDs AS IDsVersions
	|WHERE
	|	IDsVersions.ExtensionsVersion = &ExtensionsVersion";
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

#EndRegion

#EndIf
