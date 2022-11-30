///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Fills in the passed array with the common modules used as incoming message interface handlers.
//  
//
// Parameters:
//  HandlerArray - Array - array elements are common modules.
//
Procedure FillIncomingMessageHandlers(HandlersArray) Export
	
EndProcedure

// Fills in the passed array with the common modules used as outgoing message interface handlers.
//  
//
// Parameters:
//  HandlerArray - Array - array elements are common modules.
//
Procedure FillOutgoingMessageHandlers(HandlersArray) Export
	
EndProcedure

// The procedure is called when determining a message interface version supported both by 
//  correspondent infobase and the current infobase. This procedure is used to implement 
//  functionality for supporting backward compatibility with earlier versions of correspondent infobases.
//
// Parameters:
//  MessageInterface - String - name of an application message interface whose version is to be determined.
//  ConnectionParameters - Structure - parameters for connecting to the correspondent infobase.
//  RecipientPresentation - String - infobase correspondent presentation.
//  Result - String - version to be defined. Value of this parameter can be modified in this procedure.
//
Procedure OnDefineCorrespondentInterfaceVersion(Val MessageInterface, Val ConnectionParameters, Val RecipientPresentation, Result) Export
	
EndProcedure

#EndRegion
