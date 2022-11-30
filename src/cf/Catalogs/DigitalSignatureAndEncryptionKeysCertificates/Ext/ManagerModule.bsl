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
	AttributesToSkip.Add("IssuedTo");
	AttributesToSkip.Add("Firm");
	AttributesToSkip.Add("LastName");
	AttributesToSkip.Add("Name");
	AttributesToSkip.Add("MiddleName");
	AttributesToSkip.Add("JobPosition");
	AttributesToSkip.Add("IssuedBy");
	AttributesToSkip.Add("ValidBefore");
	AttributesToSkip.Add("Signing");
	AttributesToSkip.Add("Encryption");
	AttributesToSkip.Add("Thumbprint");
	AttributesToSkip.Add("CertificateData");
	AttributesToSkip.Add("Application");
	AttributesToSkip.Add("Revoked");
	AttributesToSkip.Add("StrongPrivateKeyProtection");
	AttributesToSkip.Add("Company");
	AttributesToSkip.Add("User");
	AttributesToSkip.Add("Added");
	
	If Metadata.DataProcessors.Find("ApplicationForNewQualifiedCertificateIssue") <> Undefined Then
		ProcessingApplicationForNewQualifiedCertificateIssue =
			Common.ObjectManagerByFullName(
				"DataProcessor.ApplicationForNewQualifiedCertificateIssue");
		ProcessingApplicationForNewQualifiedCertificateIssue.AttributesToSkipInBatchProcessing(
			AttributesToSkip);
	EndIf;
	
	Return AttributesToSkip;
	
EndFunction

// End StandardSubsystems.BatchObjectsModification

#EndRegion

#EndRegion

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If FormType = "ListForm" Then
		StandardProcessing = False;
		Parameters.Insert("ShowCertificatesPage");
		SelectedForm = Metadata.CommonForms.DigitalSignatureAndEncryptionSettings;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
