///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// Defines the endpoints (subscribers) for broadcast channel of the "Publication/Subscription" type.
// 
//
// Parameters:
//  MessageChannel - String - broadcast message channel ID.
//
// Returns:
//  Array - Endpoints items array that contains items of ExchangePlanRef.MessageExchange type.
//
Function MessageChannelSubscribers(Val MessagesChannel) Export
	
	QueryText =
	"SELECT
	|	RecipientSubscriptions.Recipient AS Recipient
	|FROM
	|	InformationRegister.RecipientSubscriptions AS RecipientSubscriptions
	|WHERE
	|	RecipientSubscriptions.MessagesChannel = &MessagesChannel";
	
	Query = New Query;
	Query.SetParameter("MessagesChannel", MessagesChannel);
	Query.Text = QueryText;
	
	Return Query.Execute().Unload().UnloadColumn("Recipient");
EndFunction

#EndRegion

#EndIf