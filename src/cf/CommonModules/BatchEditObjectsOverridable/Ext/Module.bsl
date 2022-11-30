///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Defining metadata objects, in whose manager modules group attribute editing is prohibited.
// 
//
// Parameters:
//   Objects - Map - set the key to the full name of the metadata object attached to the "Bulk edit" 
//                            subsystem.
//                            In addition, the value can include export function names:
//                            "AttributesToSkipInBatchProcessing" and
//                            "AttributesToEditInBatchProcessing".
//                            Every name must start with a new line.
//                            In case there is a "*", the manager module has both functions specified.
//
// Example: 
//   Objects.Insert(Metadata.Documents.PurchaserOrders.FullName(), "*"); // both functions are defined.
//   Objects.Insert(Metadata.BusinessProcesses.JobWithRoleBasedAddressing.FullName(), "AttributesToEditInBatchProcessing");
//   Objects.Insert(Metadata.Catalogs.Partners.FullName(), "AttributesToEditInBatchProcessing
//		|AttributesToSkipInBatchProcessing");
//
Procedure OnDefineObjectsWithEditableAttributes(Objects) Export
	
	
	
EndProcedure

#EndRegion
