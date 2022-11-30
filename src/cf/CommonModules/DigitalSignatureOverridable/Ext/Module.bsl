///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// It is called in the DigitalSignatureAndEncryptionKeysCertificates catalog item form and in other 
// places where certificates are created or refreshed, for example, in the SelectSigningOrDecryptionCertificate form.
// Raising an exception is allowed if you need to stop an action and report something to the user, 
// for example, when attempting to create a copy item of a certificate, access to which is limited.
//
// Parameters:
//  Ref     - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates - a blank reference for a new item.
//
//  Certificate - CryptoCertificate - a certificate, for which the catalog item is created or updated.
//
//  AttributesParameters - ValueTable - a table with the following columns:
//               * AttributeName       - String - a name of the attribute, for which you can clarify parameters.
//               * ReadOnly     - Boolean - if you set True, editing will be prohibited.
//               * FillChecking - Boolean - if you set True, filling will be checked.
//               * Visibility          - Boolean - if you set True, the attribute will become hidden.
//               * FillValue - Arbitrary - an initial attribute value of the new object.
//                                    - Undefined - filling is not required.
//
Procedure BeforeStartEditKeyCertificate(Ref, Certificate, AttributesParameters) Export
	
	
	
EndProcedure

// It is called when creating the DataSigning and DataDecryption forms on the server.
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
//  OutputParameters - Arbitrary - arbitrary returned data that will be placed to the procedure of 
//                      the same name in the common module.
//                      DigitalSignatureClientOverridable after creating a form on the server but 
//                      before opening it.
//
Procedure BeforeOperationStart(Operation, InputParameters, OutputParameters) Export
	
EndProcedure

// It is called to extend the cntent of the executed checks.
//
// Parameters:
//  Certificate - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates - a certificate being checked.
// 
//  AdditionalChecks - ValueTable - a table with the following fields:
//    * Name           - String - an additional check name, for example, AuthorizationInTaxcom.
//    * Presentation - String - a check user name, for example, "Authorization at the Taxcom server".
//    * Tooltip     - String - a tooltip that will be shown to a user when clicking the question mark.
//
//  AdditionalChecksParameters - Arbitrary - a value of the similarly named parameter, specified in 
//    the CheckCatalogCertificate procedure of the ClientDigitalSIgnature common module.
//
//  StandardChecks - Boolean - if you set False, then all standard checks will be skipped and hidden.
//     Hidden checks do not get into the Result property of the CheckCatalogCertificate procedure of 
//    the DigitalSignatureClient common module. Besides, the CryptoManager parameter will not be 
//    defined in the OnAdditionalCertificateCheck procedures of the DigitalSignatureOverridable and 
//    DigitalSignatureClientOverridable common modules.
//
//  EnterPassword - Boolean - if you set False, a password entry for the closed key part will be hidden.
//    It is not considered if the StandardChecks parameter is not set to False.
//
Procedure OnCreateFormCertificateCheck(Certificate, AdditionalChecks, AdditionalChecksParameters, StandardChecks, EnterPassword = True) Export
	
	
	
EndProcedure

// It is called from the CertificateCheck form if additional checks were added when creating the form.
//
// Parameters:
//  Parameters - Structure - with the following properties:
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
//  * Password               - String - a password entered by the user.
//                         - Undefined - if the EnterPassword property is set to False in procedure
//                              OnCreateFormCertificateCheck of the DigitalSignatureOverridable common module.
//  * ChecksResults   - Structure - with the following properties:
//      * Key     - String - a name of the additional check that is already performed.
//      * Value - Undefined - an additional check was not performed (ErrorDescription is still Undefined).
//                 - Boolean - an additional check execution result.
//
Procedure OnAdditionalCertificateCheck(Parameters) Export
	
	
	
EndProcedure

#Region ObsoleteProceduresAndFunctions

// Obsolete. Use CertificateRequestOverridable.OnFillCompanyAttributesInApplicationForCertificate instead.
//
Procedure OnFillCompanyAttributesInApplicationForCertificate(Parameters) Export
	
EndProcedure

// Obsolete. Use CertificateRequestOverridable.OnFillOwnerAttributesInApplicationForCertificate instead.
//
Procedure OnFillOwnerAttributesInApplicationForCertificate(Parameters) Export
	
EndProcedure

// Obsolete. Use CertificateRequestOverridable.OnFillOfficerAttributesInApplicationForCertificate instead.
//
Procedure OnFillOfficerAttributesInApplicationForCertificate(Parameters) Export
	
EndProcedure

// Obsolete. Use CertificateRequestOverridable.OnFillPartnerAttributesInApplicationForCertificate instead.
//
Procedure OnFillPartnerAttributesInApplicationForCertificate(Parameters) Export
	
EndProcedure

#EndRegion

#EndRegion