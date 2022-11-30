///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Allows you to make changes to the tree with full-text search sections displayed upon selecting a search area.
// By default, the sections tree is formed based on subsystems included in the configuration.
// The tree structure is described in the DataProcessor.FullTextSearchInData.Form.SearchAreaChoice form.
// All columns not specified in parameters will be calculated automatically.
// If you need to build a sections tree on your own, save the column content.
//
// Parameters:
//   SearchSections - ValueTree - search areas. Contains the following columns:
//       ** Section   - String   - a presentation of a section: subsystem or metadata object.
//       ** Picture - Picture - a section picture, recommended only for root sections.
//       ** MetadataObject - CatalogRef.MetadataObjectsIDs - specified only for metadata objects, 
//                     leave it blank for sections.
// Example:
//
//	NewSection = SearchSections.Rows.Add();
//	NewSection.Section = "Main";
//	NewSection.Picture = PictureLib._DemoSectionMain;
//	
//	MetadataObject = Metadata.Documents._DemoCustomerInvoice;
//	
//	If AccessRight("View", MetadataObject)
//		And Common.MetadataObjectAvailableByFunctionalOptions(MetadataObject) Then
//		
//		NewSectionObject = NewSection.Rows.Add();
//		NewSectionObject.Section = MetadataObject.ListPresentation;
//		NewSectionObject.MetadataObject = Common.MetadataObjectID(MetadataObject);
//	EndIf;
//
Procedure OnGetFullTextSearchSections(SearchSections) Export
	
	
	
EndProcedure

#EndRegion