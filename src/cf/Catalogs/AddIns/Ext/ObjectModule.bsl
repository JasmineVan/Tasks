///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// Attribute connection with deletion mark.
	If DeletionMark Then
		Use = Enums.AddInUsageOptions.Disabled;
	EndIf;
	
	// Attribute connection with usage option.
	If Use = Enums.AddInUsageOptions.Disabled Then
		UpdateFrom1CITSPortal = False;
	EndIf;
	
	// Each add-in must have its own ID with the UpdateFrom1CITSPortal flag set.
	If Not ThisIsTheLatestVersionComponent() Then
		UpdateFrom1CITSPortal = False;
	EndIf;
	
	// Uniqueness control of component ID and version.
	If Not ThisIsTheUniqueComponent() Then 
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Внешняя компонента со значениями Идентификатор ""%1"" и версия ""%2"" уже загружена в программу.'; en = 'The add-in with ID ""%1"" and version ""%2"" is already imported to the application.'; pl = 'The add-in with ID ""%1"" and version ""%2"" is already imported to the application.';de = 'The add-in with ID ""%1"" and version ""%2"" is already imported to the application.';ro = 'The add-in with ID ""%1"" and version ""%2"" is already imported to the application.';tr = 'The add-in with ID ""%1"" and version ""%2"" is already imported to the application.'; es_ES = 'The add-in with ID ""%1"" and version ""%2"" is already imported to the application.'"),
			ID,
			Version);
	EndIf;
	
	// Storing binary add-in data.
	ComponentBinaryData = Undefined;
	If AdditionalProperties.Property("ComponentBinaryData", ComponentBinaryData) Then
		AddInStorage = New ValueStorage(ComponentBinaryData);
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// If a component of the new version is downloaded and one of the old components has the 
	// UpdateFrom1CITSPortal flag, this flag is unset upon overwriting components of previous versions.
	If ThisIsTheLatestVersionComponent() Then
		RewriteComponentsOfEarlierVersions();
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Function ThisIsTheLatestVersionComponent() Export
	
	Query = New Query;
	Query.SetParameter("ID", ID);
	Query.SetParameter("Ref", Ref);
	Query.Text = 
		"SELECT
		|	MAX(AddIns.VersionDate) AS VersionDate
		|FROM
		|	Catalog.AddIns AS AddIns
		|WHERE
		|	AddIns.ID = &ID
		|	AND AddIns.Ref <> &Ref";
	
	Result = Query.Execute();
	Selection = Result.Select();
	Selection.Next();
	Return (Selection.VersionDate = Null) Or (Selection.VersionDate <= VersionDate)
	
EndFunction

Function ThisIsTheUniqueComponent()
	
	Query = New Query;
	Query.SetParameter("ID", ID);
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("VersionDate", VersionDate);
	Query.Text = 
		"SELECT TOP 1
		|	1 AS Field1
		|FROM
		|	Catalog.AddIns AS AddIns
		|WHERE
		|	AddIns.ID = &ID
		|	AND AddIns.Use = VALUE(Enum.AddInUsageOptions.Used)
		|	AND AddIns.Ref <> &Ref
		|	AND AddIns.VersionDate = &VersionDate";
	
	Result = Query.Execute();
	Return Result.IsEmpty();
	
EndFunction

Procedure RewriteComponentsOfEarlierVersions()
	
	Query = New Query;
	Query.SetParameter("ID", ID);
	Query.SetParameter("VersionDate", VersionDate);
	Query.Text = 
		"SELECT
		|	AddIns.Ref AS Ref
		|FROM
		|	Catalog.AddIns AS AddIns
		|WHERE
		|	AddIns.ID = &ID
		|	AND AddIns.Use = VALUE(Enum.AddInUsageOptions.Used)
		|	AND AddIns.VersionDate < &VersionDate";
	
	Result = Query.Execute();
	Selection = Result.Select();
	While Selection.Next() Do 
		Object = Selection.Ref.GetObject();
		Object.Write();
	EndDo;
	
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Invalid object call on the client.';de = 'Invalid object call on the client.';ro = 'Invalid object call on the client.';tr = 'Invalid object call on the client.'; es_ES = 'Invalid object call on the client.'");
#EndIf