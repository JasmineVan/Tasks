///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region ForCallsFromOtherSubsystems

// StandardSubsystems.BatchObjectsModification

// Returns the object attributes that are not recommended to be edited using batch attribute 
// modification data processor.
//
// Returns:
//  Array - a list of object attribute names.
Function AttributesToSkipInBatchProcessing() Export
	
	Result = New Array;
	
	Result.Add("BriefPresentation");
	Result.Add("Comment");
	Result.Add("ExternalRole");
	Result.Add("ExchangeNode");
	
	Return Result
EndFunction

// End StandardSubsystems.BatchObjectsModification

#EndRegion

#EndRegion

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)

	StandardProcessing = False;
	
	If Users.IsExternalUserSession() Then
		CurrentUser = ExternalUsers.CurrentExternalUser();
		AuthorizationObject = Catalogs[CurrentUser.AuthorizationObject.Metadata().Name].EmptyRef();
	Else
		AuthorizationObject = Catalogs.Users.EmptyRef();
	EndIf;
	
	Query = New Query("SELECT ALLOWED TOP 50
	                      |	AssigneeRolesAssignment.Ref AS Ref
	                      |FROM
	                      |	Catalog.PerformerRoles.Purpose AS AssigneeRolesAssignment
	                      |WHERE
	                      |	AssigneeRolesAssignment.UsersType = &Type
	                      |	AND AssigneeRolesAssignment.Ref.Description LIKE &SearchString");
	
	Query.SetParameter("Type", AuthorizationObject);
	Query.SetParameter("SearchString", "%" + Parameters.SearchString + "%");
	QueryResult = Query.Execute().Select();
	
	ChoiceData = New ValueList;
	While QueryResult.Next() Do
		ChoiceData.Add(QueryResult.Ref, QueryResult.Ref);
	EndDo;

EndProcedure

#EndRegion

#EndIf