///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// It is called after creation on the server, but before opening the DataSigning and DataDecryption forms.
// It is used for additional actions that require a server call not to call server once again.
// 
//
// Parameters:
//  Operation          - String - the Signing or Decryption string.
//
//  InputParameters  - Arbitrary - AdditionalActionsParameters property value of the DataDetails 
//                      parameter of the Sign and Decrypt methods of the ClientDigitalSignature 
//                      common module.
//                      
//  OutputParameters - Arbitrary - arbitrary data that was returned from the common module procedure 
//                      of the same name on the server.
//                      DigitalSignatureOverridable.
//
Procedure BeforeOperationStart(Operation, InputParameters, OutputParameters) Export
	
	
	
EndProcedure

// It is called from the CertificateCheck form if additional checks were added when creating the form.
//
// Parameters:
//  Parameters - Structure - with the following properties:
//  * WaitForContinue   - Boolean - (return value) - if True, an additional check will be performed 
//                            asynchronously and it will continue after the notification is executed.
//                            The initial value is False.
//  * Notification           - NotifyDescription - a data processor that needs to be called for 
//                              continuation after the additional check was performed asynchronously.
//  * Certificate           - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates - a certificate being checked.
//  * Check             - String - a check name, added in the OnCreateFormCertificateCheck procedure 
//                              of the DigitalSignatureOverridable common module.
//  * CryptoManager - CryptoManager - a prepared crypto manager to perform a check.
//                              
//                         - Undefiined - if standard checks are disabled in procedure
//                              OnCreateFormCertificateCheck of the DigitalSignatureOverridable common module.
//  * ErrorDescription       - String - (return value) - error escription received when performing the check.
//                              User can see the details by clicking the result picture.
//  * IsWarning    - Boolean - (return value) - a picture kind is Error/Warning, the initial value 
//                            is False.
//  * Password   - String - a password entered by the user.
//                   - Undefined - if the EnterPassword property is set to False in procedure
//                            OnCreateFormCertificateCheck of the DigitalSignatureOverridable common module.
//  * ChecksResults   - Structure - with the following properties:
//      * Key     - String - a name of a standard or an additional check.
//      * Value - Undefined - the check was not performed (ErrorDescription is still Undefined).
//                 - Boolean - an additional check execution result.
//
Procedure OnAdditionalCertificateCheck(Parameters) Export
	
	
	
EndProcedure

// It is called when opening the instruction on how to work with digital signature and encryption applications.
//
// Parameters:
//  Section - String - the initial value of BookkeepingAndTaxAccounting. You can specify  
//                    AccountingForPublicInstitutions.
//
Procedure OnDetermineArticleSectionAtITS(Section) Export
	
	
	
EndProcedure

#EndRegion
