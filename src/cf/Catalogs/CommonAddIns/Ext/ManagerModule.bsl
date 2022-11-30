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

// Returns object attributes allowed to be edited using batch attribute change data processor.
// 
//
// Returns:
//  Array - a list of object attribute names.
Function AttributesToEditInBatchProcessing() Export
	
	Result = New Array;
	Return Result;
	
EndFunction

// End StandardSubsystems.BatchObjectsModification

#EndRegion

#EndRegion

#Region Private

// Returns a reference to the external component catalog by ID and version.
//
// Parameters:
//  ID – String – an external component object ID.
//  Version – String – (optional) a component version.
//
// Returns:
//  CatalogRef.AddIns - a reference to an add-in container in the infobase.
//
Function FindByID(ID, Version = Undefined) Export
	
	Query = New Query;
	Query.SetParameter("ID", ID);
	
	If Not ValueIsFilled(Version) Then 
		Query.Text = 
			"SELECT TOP 1
			|	AddIns.Ref AS Ref
			|FROM
			|	Catalog.CommonAddIns AS AddIns
			|WHERE
			|	AddIns.ID = &ID
			|
			|ORDER BY
			|	AddIns.VersionDate DESC";
	Else 
		Query.SetParameter("Version", Version);
		Query.Text = 
			"SELECT TOP 1
			|	AddIns.Ref AS Ref
			|FROM
			|	Catalog.CommonAddIns AS AddIns
			|WHERE
			|	AddIns.ID = &ID
			|	AND AddIns.Version = &Version";
		
	EndIf;
	
	Result = Query.Execute();
	
	If Result.IsEmpty() Then 
		Return EmptyRef();
	EndIf;
	
	Selection = Result.Select();
	Selection.Next();
	
	Return Result.Unload()[0].Ref;
	
EndFunction

#EndRegion

#EndIf