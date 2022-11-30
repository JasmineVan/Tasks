///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Sends and receives system messages.
//
// Parameters:
//  Cancel - Boolean. A cancellation flag. Appears on errors during operations.
//
Procedure SendAndReceiveMessages(Cancel) Export
	
	DataExchangeServer.CheckCanSynchronizeData();
	
	MessageExchangeInternal.SendAndReceiveMessages(Cancel);
	
EndProcedure

#EndRegion
