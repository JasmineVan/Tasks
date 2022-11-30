///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Allows you to add registers with document records as additional registers.
//
// Parameters:
//    Document - DocumentRef - a document whose register records collection is to be supplemented.
//    RegistersWithRecords - Map - a map with the data:
//        * Key - MetadataObject - a register as a metadata object.
//        * Value - String - a name of the recorder field.
//
Procedure OnDetermineRegistersWithRecords(Document, RegistersWithRecords) Export
	
	
	
EndProcedure

// Allows you to calculate the number of records for additional sets added by the procedure
// OnDetermineRegistersWithRecords.
//
// Parameters:
//    Document - DocumentRef - a document whose register records collection is to be supplemented.
//    RegistersWithRecords - Map - a map with the data:
//        * Key - String - a full name of the register (underscore is used instead of dots).
//        * Value - Number - a calculated number of records.
//
Procedure OnCalculateRecordsCount(Document, CalculatedCount) Export
	
	
	
EndProcedure

// Allows to supplement or override the collection of data sets for the input of documents records.
//
// Parameters:
//    Document - DocumentRef - a document whose register records collection is to be supplemented.
//    DataSets - Array - info about data sets (the Structure item type).
//
Procedure OnPrepareDataSet(Document, DataSets) Export
	
	
	
EndProcedure

#EndRegion
