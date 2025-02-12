﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// Adds a record to the register by the passed structure values.
Procedure AddRecord(RecordStructure) Export
	
	If Common.DataSeparationEnabled()
		AND Common.SeparatedDataUsageAvailable() Then
		
		DataExchangeServer.AddRecordToInformationRegister(RecordStructure, "DataAreasSuccessfulDataExchangeStates");
	Else
		DataExchangeServer.AddRecordToInformationRegister(RecordStructure, "SuccessfulDataExchangesStates");
	EndIf;
	
EndProcedure

#EndRegion

#EndIf