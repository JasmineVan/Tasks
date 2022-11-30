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
	
	AttributesToSkip = New Array;
	AttributesToSkip.Add("AuthorizationObject");
	AttributesToSkip.Add("SetRolesDirectly");
	AttributesToSkip.Add("IBUserID");
	AttributesToSkip.Add("ServiceUserID");
	AttributesToSkip.Add("IBUserProperies");
	AttributesToSkip.Add("DeletePassword");
	
	Return AttributesToSkip;
	
EndFunction

// End StandardSubsystems.BatchObjectsModification

// StandardSubsystems.AccessManagement

// See AccessManagementOverridable.OnFillListsWithAccessRestriction. 
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.TextForExternalUsers =
	"AllowRead
	|WHERE
	|	ValueAllowed(Ref)
	|;
	|AllowUpdateIfReadingAllowed
	|WHERE
	|	IsAuthorizedUser(Ref)";
	
EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	If NOT Parameters.Filter.Property("Invalid") Then
		Parameters.Filter.Insert("Invalid", False);
	EndIf;
	
EndProcedure

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If FormType = "ObjectForm" AND Parameters.Property("AuthorizationObject") Then
		
		StandardProcessing = False;
		SelectedForm = "ItemForm";
		
		FoundExternalUser = Undefined;
		CanAddExternalUser = False;
		
		AuthorizationObjectIsInUse = UsersInternal.AuthorizationObjectIsInUse(
			Parameters.AuthorizationObject,
			Undefined,
			FoundExternalUser,
			CanAddExternalUser);
		
		If AuthorizationObjectIsInUse Then
			Parameters.Insert("Key", FoundExternalUser);
			
		ElsIf CanAddExternalUser Then
			
			Parameters.Insert(
				"NewExternalUserAuthorizationObject", Parameters.AuthorizationObject);
		Else
			ErrorDescriptionAsWarning =
				NStr("ru = 'Разрешение на вход в программу не предоставлялось.'; en = 'The right to sign in is not granted.'; pl = 'Brak uprawnień do logowania się do aplikacji.';de = 'Keine Berechtigung zur Anmeldung bei der Anwendung.';ro = 'Nu aveți permisiunea de a vă conecta la aplicație.';tr = 'Uygulamaya giriş izni verilmedi.'; es_ES = 'No hay permiso para iniciar sesión de la aplicación.'");
				
			Raise ErrorDescriptionAsWarning;
		EndIf;
		
		Parameters.Delete("AuthorizationObject");
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
