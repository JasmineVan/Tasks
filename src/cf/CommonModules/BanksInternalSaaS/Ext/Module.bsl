///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// Configuration subsystems event handlers.

// The procedure is called when a new data notification is received.
// In the procedure body, check whether the application requires this data. If it requires, select 
// the Import check box.
// 
// Parameters:
//   Descriptor - XDTODataObject - a descriptor.
//   Import - Boolean - True if import, False otherwise.
//
Procedure NewDataAvailable(Val Descriptor, Import) Export
	
	If Descriptor.DataType = "RussianBanks" Then
		Import = True;
	EndIf;
	
EndProcedure

// The procedure is called after calling NewDataAvailable, it parses the data.
//
// Parameters:
//   Descriptor - XDTODataObject - a descriptor.
//   PathToFile - String – extracted file full name. The file is automatically deleted once the 
//                  procedure is executed. If a file is not specified in the service manager, the 
//                  parameter value is Undefined.
//
Procedure ProcessNewData(Val Descriptor, Val PathToFile) Export
	
	If Descriptor.DataType = "RussianBanks" AND ValueIsFilled(PathToFile) Then
		DataProcessorName = "ImportBankClassifier";
		If Metadata.DataProcessors.Find(DataProcessorName) <> Undefined Then
			DataProcessors[DataProcessorName].ImportDataFromFile(PathToFile);
		EndIf;
	EndIf;
	
EndProcedure

// The procedure is called if data processing is canceled due to an error.
//
// Parameters:
//   Descriptor - XDTODataObject - a descriptor.
//
Procedure DataProcessingCanceled(Val Descriptor) Export 
	
	// do nothing.
	
EndProcedure	

// See SuppliedDataOverridable.GetSuppliedDataHandlers. 
Procedure OnDefineSuppliedDataHandlers(Handlers) Export
	
	RegisterSuppliedDataHandlers(Handlers);
	
EndProcedure

#EndRegion

#Region Private

// Registers supplied data handlers.
//
// Parameters:
//     Handlers - ValueTable - table for adding handlers. Contains the following columns.
//       * DataKind - String - code of the data kind processed by the handler.
//       * HandlerCode - Sting - used for recovery after a data processing error.
//       * Handler - CommonModule - module contains the following export procedures:
//                                          NewDataAvailable(Descriptor, Import) Export
//                                          ProcessNewData(Descriptor, FilePath) Export
//                                          DataProcessingCanceled(Descriptor) Export
//
Procedure RegisterSuppliedDataHandlers(Val Handlers)
	
	Handler = Handlers.Add();
	Handler.DataKind = "RussianBanks";
	Handler.HandlerCode = "ImportNationalBankClassifier";
	Handler.Handler = BanksInternalSaaS;
	
EndProcedure

#EndRegion