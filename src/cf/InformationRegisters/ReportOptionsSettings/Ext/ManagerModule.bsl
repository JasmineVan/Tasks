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

// StandardSubsystems.AccessManagement

// See AccessManagementOverridable.OnFillListsWithAccessRestriction. 
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	IsAuthorizedUser(User)
	|	OR IsAuthorizedUser(Variant.Author)";
	
	Restriction.TextForExternalUsers = Restriction.Text;
	
EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Private

// Writes the settings table to the register data for the specified dimensions.
Procedure WriteSettingsPackage(SettingsTable, Dimensions, Resources, DeleteOldItems) Export
	
	RecordSet = CreateRecordSet();
	For Each KeyAndValue In Dimensions Do
		RecordSet.Filter[KeyAndValue.Key].Set(KeyAndValue.Value, True);
		SettingsTable.Columns.Add(KeyAndValue.Key);
		SettingsTable.FillValues(KeyAndValue.Value, KeyAndValue.Key);
	EndDo;
	For Each KeyAndValue In Resources Do
		SettingsTable.Columns.Add(KeyAndValue.Key);
		SettingsTable.FillValues(KeyAndValue.Value, KeyAndValue.Key);
	EndDo;
	If Not DeleteOldItems Then
		RecordSet.Read();
		OldRecords = RecordSet.Unload();
		SearchByDimensions = New Structure("User, Subsystem, Variant");
		For Each OldRecord In OldRecords Do
			FillPropertyValues(SearchByDimensions, OldRecord);
			If SettingsTable.FindRows(SearchByDimensions).Count() = 0 Then
				FillPropertyValues(SettingsTable.Add(), OldRecord);
			EndIf;
		EndDo;
	EndIf;
	RecordSet.Load(SettingsTable);
	RecordSet.Write(True);
	
EndProcedure

// Clears settings by a report option.
Procedure ClearSettings(OptionRef = Undefined) Export
	
	RecordSet = CreateRecordSet();
	If OptionRef <> Undefined Then
		RecordSet.Filter.Variant.Set(OptionRef, True);
	EndIf;
	RecordSet.Write(True);
	
EndProcedure

// Clears settings of the specified (of the current) user in the section.
Procedure ResetUserSettingsInSection(SectionRef, User = Undefined) Export
	If User = Undefined Then
		User = Users.AuthorizedUser();
	EndIf;
	
	Query = New Query;
	Query.SetParameter("SectionRef", SectionRef);
	Query.Text =
	"SELECT ALLOWED DISTINCT
	|	MetadataObjectIDs.Ref
	|FROM
	|	Catalog.MetadataObjectIDs AS MetadataObjectIDs
	|WHERE
	|	MetadataObjectIDs.Ref IN HIERARCHY(&SectionRef)";
	SubsystemsArray = Query.Execute().Unload().UnloadColumn("Ref");
	
	RecordSet = CreateRecordSet();
	RecordSet.Filter.User.Set(User, True);
	For Each SubsystemRef In SubsystemsArray Do
		RecordSet.Filter.Subsystem.Set(SubsystemRef, True);
		RecordSet.Write(True);
	EndDo;
EndProcedure

#EndRegion

#EndIf