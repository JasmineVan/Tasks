///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Displays a request for sending dumps.
//
Procedure MonitoringCenterDumpSendingRequest() Export
	MonitoringCenterClientInternal.NotifyRequestForSendingDumps();
EndProcedure

// Displays a request for collecting and sending dumps (one time).
//
Procedure MonitoringCenterDumpCollectionAndSendingRequest() Export
	MonitoringCenterClientInternal.NotifyRequestForReceivingDumps();
EndProcedure

// Displays a request for getting administrator contact information.
//
Procedure MonitoringCenterContactInformationRequest() Export
	MonitoringCenterClientInternal.NotifyContactInformationRequest();
EndProcedure

#EndRegion
