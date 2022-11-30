///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Adds a flag of changing document deletion mark.
// Procedure parameters correspond to subscription for the BeforeWrite event of the Document object.
// See details in Syntax Assistant.
//
// Parameters:
//  Source - DocumentObject - a subscription event source.
//  Cancel     - Boolean                  - indicates that writing is canceled. If set to True, 
//                               writing is not performed, an exception will be thrown.
//  WriteMode     - DocumentWriteMode     - the current write mode of the source document.
//  PostingMode - DocumentPostingMode - the current posting mode of the source document.
//
Procedure SetDocumentDeletionMarkChangeStatus(Source, Cancel, WriteMode, PostingMode) Export
	UserNotesInternal.SetDeletionMarkChangeStatus(Source);
EndProcedure

// Adds a flag of changing object deletion mark.
// Procedure parameters correspond to the BeforeWrite event subscription of any objects except for documents.
// See details in Syntax Assistant.
//
// Parameters:
//  Source - Object - subscription event source.
//  Cancel    - Boolean - shows whether writing is canceled. If set to True, writing is not 
//                      performed, an exception will be thrown.
//
Procedure SetObjectDeletionMarkChangeStatus(Source, Cancel) Export
	UserNotesInternal.SetDeletionMarkChangeStatus(Source);
EndProcedure

#EndRegion
