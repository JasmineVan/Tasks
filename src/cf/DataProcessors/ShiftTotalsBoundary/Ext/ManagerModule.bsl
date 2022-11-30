///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// Moves a totals border.
Procedure ExecuteCommand(CommandParameters, StorageAddress) Export
	SetPrivilegedMode(True);
	TotalsAndAggregatesManagementIntenal.CalculateTotals();
EndProcedure

#EndRegion

#EndIf
