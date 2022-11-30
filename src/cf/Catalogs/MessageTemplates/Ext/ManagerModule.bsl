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

// End StandardSubsystems.BatchObjectsModification

// StandardSubsystems.AccessManagement

// See AccessManagementOverridable.OnFillListsWithAccessRestriction. 
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Author)
	|	OR NOT AvailableToAuthorOnly";
	
EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)

	If Parameters.Property("TemplateOwner") AND ValueIsFilled(Parameters.TemplateOwner) Then
		Parameters.Insert("TemplateOwner", Parameters.TemplateOwner);
		If Parameters.Property("New") AND Parameters.New <> True Then
			Parameters.Insert("Key", MessageTemplatesInternal.TemplateByOwner(Parameters.TemplateOwner));
		EndIf;
		SelectedForm = "Catalog.MessageTemplates.ObjectForm";
		StandardProcessing = False;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
