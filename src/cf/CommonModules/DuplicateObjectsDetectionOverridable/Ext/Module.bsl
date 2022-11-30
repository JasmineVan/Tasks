///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Defining metadata objects, in whose manager modules parametrization of duplicates search 
// algorithm is available using the DuplicatesSearchParameters, OnDuplicatesSearch, and 
// CanReplaceItems export procedures.
//
// Parameters:
//   Objects - Map - objects, whose manager modules contain export procedures.
//       ** Key     - String - a full name of the metadata object attached to the "Duplicate object detection" subsystem.
//                              For example, "Catalog.Counterparties".
//       ** Value - String - names of export procedures defined in the manager module.
//                              You can specify:
//                              "DuplicatesSearchParameters",
//                              "OnDuplicatesSearch",
//                              "CanReplaceItems".
//                              Every name must start with a new line.
//                              Empty string means that all procedures are determined in the manager module.
//
// Example:
//  1. All procedures are defined in the catalog:
//  Objects.Insert(Metadata.Catalogs.Counterparties.FullName(), "");
//
//  2. Only the DuplicatesSearchParameters and OnDuplicatesSearch procedures are defined:
//  Objects.Insert(Metadata.Catalogs.ProjectTasks.FullName(),"DuplicatesSearchParameters
//                   |OnDuplicatesSearch");
//
Procedure OnDefineObjectsWithSearchForDuplicates(Objects) Export
	
	
	
EndProcedure

#EndRegion
