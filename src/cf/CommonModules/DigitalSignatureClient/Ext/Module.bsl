///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Returns the current setting of digital signature usage.
//
// Returns:
//  Boolean - if True, digital signatures are used.
//
Function UseDigitalSignature() Export
	
	Return CommonSettings().UseDigitalSignature;
	
EndFunction

// Returns the current setting of encryption usage.
//
// Returns:
//  Boolean - if True, encryption is used.
//
Function UseEncryption() Export
	
	Return CommonSettings().UseEncryption;
	
EndFunction

// Returns the current setting of digital signature check on the server.
//
// Returns:
//  Boolean - if True, digital signatures will be checked on the server.
//
Function VerifyDigitalSignaturesOnTheServer() Export
	
	Return CommonSettings().VerifyDigitalSignaturesOnTheServer;
	
EndFunction

// Returns the current setting of digital signature creation on the server.
// The setting also involves encryption and decryption on the server.
//
// Returns:
//  Boolean - if True, digital signatures will be created on the server.
//
Function GenerateDigitalSignaturesAtServer() Export
	
	Return CommonSettings().GenerateDigitalSignaturesAtServer;
	
EndFunction

// Signs data, returns a signature, and adds the signature to an object, if specified.
//
// A common method to process property values with the NotifyDescription type in the DataDetails parameter.
//  When processing a notification, the parameter structure is passed to it. This structure always 
//  has a Notification property of the NotifyDescription type, which needs to be processed to continue.
//  In addition, the structure always has the DataDetails property received when calling the procedure.
//  When calling a notification, the structure must be passed as a value. If an error occurs during 
//  the asynchronous execution, add the ErrorDescription property of String type to this structure.
// 
// Parameters:
//  DataDetails - Structure - with the following properties:
//    * Operation            - String - a title of a data signing form, for example, File signing.
//    * DataTitle     - String - a title of an item or a data set, for example, File.
//    * ReportCompletion - Boolean - (optional) if False, skip a notification on successful 
//                              completion for the data presentation specified next to the title.
//    * ShowComment - Boolean - (optional) - allow adding a comment in the data signing form.
//                               False if not specified.
//    * CertificatesFilter  - Array - (optional) - contains references to catalog items.
//                              DigitalSignatureAndEncryptionCertificates that can be selected by 
//                              the user. The filter locks the ability to select other certificates 
//                              from the personal storage.
//                         - Structure - with the following property:
//                              Company - TypeToDefine.Company - contains a reference to the company, 
//                                 by which the filter will be set in the list of user certificates.
//    * WithoutConfirmation   - Boolean - (optional) - skip user confirmation if there is only one 
//                              certificate in the CertificatesFilter property and:
//                              a) ether the certificate is issued with a strong private key protection,
//                              b) or a user has memorized the certificate password for the time of the session,
//                              c) or a password has been set earlier by the SetCertificatePassword method.
//                              If an error occurs upon signing, the form with the ability to enter 
//                              the password will be opened. The ShowComment parameter is ignored.
//    * BeforeExecute   - NotifyDescription - (optional) - details of the additional data 
//                              preparation handler after selecting the certificate, by which the data will be signed.
//                              In this handler, you can fill in the Data parameter if it depends on 
//                              the certificate that in the moment of call is already inserted in 
//                              DataDetails as SelectedCertificate (see below). Consider the common approach (see above).
//    * ExecuteAtServer - Undefined, Boolean - (optional) - when it is not specified or Undefined, 
//                              the execution will be determined automatically: if there is a server, 
//                              first execute on the server, then in case of a failure on the client, then display a message about two errors.
//                              When True: if execution on the server is allowed, execute only on 
//                              the server, in case of a failure one message about a server error is displayed.
//                              When False: execute only on the client, as if there is no server.
//    * AdditionalActionsParameters - Arbitrary - (optional) - if specified, it is passed to the 
//                              server to the BeforeOperationStart procedure of the
//                              DigitalSignatureOverridable common module as InputParameters.
//    * OperationContext   - Undefined - (optional) - if specified, the property will be set to a 
//                              specific arbitrary type value, which allows to perform an operation 
//                              with the same certificate again (the user is asked neither to enter 
//                              the password nor to confirm an action).
//    * ------ // ------   - Arbitrary - (optional) - if defined, the action will be executed with 
//                              the same certificate without requesting a password or confirmation.
//                              The WithoutConfirmation parameter is considered to be True.
//                              The Operation, DataTitle, ShowComment, CertificatesFilter, and 
//                              ExecuteAtServer parameters are ignored. They retain the values they had at the first call.
//                              The AdditionalActionsParameters parameter is ignored.
//                              The BeforeOperationStart procedure is not called.
//                              If you pass the context returned by the Decrypt procedure, the 
//                              password entered for the certificate can be used as if the password 
//                              had been saved during the session. In other cases, the context is ignored.
//    Option 1:
//    * Data                - BinaryData - data to sign.
//    * -- // --              - String - an address of a temporary storage that contains binary data.
//    * -- // --              - NotifyDescription - a data receipt handler that returns data in the 
//                                 Data property (see the common approach above). DataDetails 
//                                 already has the SelectedCertificate parameter at the time it is called (see below).
//                            - Structure - with the following properties:
//                               * XMLDSigParameters - Structure - as the XMLDSigParameters function 
//                                                                of the DigitalSignatureClient common module returns.
//                               * SOAPEnvelope      - String - a <soap:Envelope> message template.
//    * Object                - Ref - (optional) - a reference to an object to be signed.
//                                 If not specified, a signature is not required.
//    * -- // --              - NotifyDescription - (optional) - a handler for adding a signature to 
//                                 the DigitalSignatures information register. Consider the common approach (see above).
//                                 DataDetails already has the SignatureProperties parameter at the time it is called.
//                                 In case of the DataSet parameter, the DataSetCurrentItem property 
//                                 is inserted into the DataDetails. It contains the SignatureProperties parameter.
//    * ObjectVersion         - String - (optional) - a version of the object data to check and lock 
//                                 the object before adding the signature.
//    * Presentation         - Ref, String, Structure - (optional) if not specified, a presentation 
//                                 is calculated by the Object property value.
//                                 The structure contains the following properties:
//                                    * Value      - Ref, NotifyDescription - to open.
//                                    * Presentation - String - a value presentation.
//    Option 2:
//    * DataSet           - Array - structures with properties specified in Case 1.
//    * SetPresentation   - String - presentations of several data set items, for example, Files (%1).
//                                 To this presentation, the number of items is filled in parameter %1.
//                                 Click the hyperlink to open the list.
//                                 If the data set has 1 item, value in the Presentation property of 
//                                 the DataSet property is used. If not specified, the presentation 
//                                 is calculated by the Object property value of a data set item.
//    * PresentationsList   - ValueList, Array - (optional) - an arbitrary list of items or an array 
//                                 with values, like the Presentation property has, and which the 
//                                 user can open. If not specified, it is filled in from the 
//                                 Presentation or Object property in the DataSet property.
//
//  Form - ManagedForm - a form, from which you need to get a UUID that will be used to lock an 
//                                object.
//        - UUID - a UUID that will be used to lock an object.
//                                
//        - Undefined     - use a standard form.
//
//  ResultProcessing - NotifyDescription - an optional parameter.
//     Required for non-standard result processing, for example, if the Object and / or Form parameter is not specified.
//     The result gets the DataDetails parameter, to which the following properties are added in case of a success:
//     * Success - Boolean - True if everything is successfully completed. If Success = False, the 
//               partial completion is defined by having the SignatureProperties property. If there is, the step is completed.
//     * UserClickedSign - Boolean - if True, the user has clicked Sign at least once.
//                Used for scenarios where a simple signature is enough to continue the business 
//               process (the intention to set a signature), and setting a qualified signature is an 
//               addition that can be implemented later if technical problems arise.
//     * SelectedCertificate - Structure - contains the following certificate properties:
//         * Ref    - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates - a reference to the certificate.
//         * Thumbprint - String - a certificate thumbprint in the Base64 string format.
//         * Data    - String - an address of a temporary storage that contains certificate binary data.
//     * SignatureProperties - String - an address of a temporary storage that contains the structure described below.
//                         Check the property in the DataSet parameter when passing it.
//                       - Structure - a detailed signature description:
//         * Signature             - BinaryData - a signing result.
//                               - String - a signed SOAP envelope if it was passed in the data.
//         * SignedBy - CatalogRef.Users - a user who signed the infobase object.
//                                    
//         * Comment         - String - a comment if it was entered upon signing.
//         * SignatureFileName     - String - a blank string because the signature is added not from a file.
//         * SignatureDate         - Date   - a signature date. It makes sense when the date cannot 
//                                          be extracted from signature data. If the date is not 
//                                          specified or blank, the current session date is used.
//         * SignatureCheckDate - Date   - a signature check date after signing.
//         * SignatureCorrect        - Boolean - a signature check result after signing.
//
//         Derivative properties:
//         * Certificate          - BinaryData - contains export of the certificate that was used 
//                                    for signing (it is in the signature).
//         * Thumbprint           - String - a certificate thumbprint in the Base64 string format.
//         * CertificateOwner - String - a subject presentation received from the certificate binary data.
//
Procedure Sign(DataDetails, Form = Undefined, ResultProcessing = Undefined) Export
	
	ClientParameters = New Structure;
	ClientParameters.Insert("DataDetails", DataDetails);
	ClientParameters.Insert("Form", Form);
	ClientParameters.Insert("ResultProcessing", ResultProcessing);
	
	CompletionProcessing = New NotifyDescription("StandardCompletion",
		DigitalSignatureInternalClient, ClientParameters);
	
	If DataDetails.Property("OperationContext")
	   AND TypeOf(DataDetails.OperationContext) = Type("ManagedForm") Then
		
		DigitalSignatureInternalClient.ExtendStoringOperationContext(DataDetails);
		FormNameBeginning = "Catalog.DigitalSignatureAndEncryptionKeysCertificates.Form.";
		
		If DataDetails.OperationContext.FormName = FormNameBeginning + "DataSigning" Then
			DataDetails.OperationContext.PerformSigning(ClientParameters, CompletionProcessing);
			Return;
		EndIf;
		If DataDetails.OperationContext.FormName = FormNameBeginning + "DataDecryption" Then
			ClientParameters.Insert("SpecifiedContextOfOtherOperation");
		EndIf;
	EndIf;
	
	ServerParameters = New Structure;
	ServerParameters.Insert("Operation",            NStr("ru = 'Подписание данных'; en = 'Data signing'; pl = 'Data signing';de = 'Data signing';ro = 'Data signing';tr = 'Data signing'; es_ES = 'Data signing'"));
	ServerParameters.Insert("DataTitle",     NStr("ru = 'Данные'; en = 'Data'; pl = 'Data';de = 'Data';ro = 'Data';tr = 'Data'; es_ES = 'Data'"));
	ServerParameters.Insert("ShowComment", False);
	ServerParameters.Insert("CertificatesFilter");
	ServerParameters.Insert("ExecuteAtServer");
	ServerParameters.Insert("AdditionalActionParameters");
	FillPropertyValues(ServerParameters, DataDetails);
	
	DigitalSignatureInternalClient.OpenNewForm("DataSigning",
		ClientParameters, ServerParameters, CompletionProcessing);
	
EndProcedure

// It prompts the user to select signature files to add to the object, and adds them.
//
// A common method to process property values with the NotifyDescription type in the DataDetails parameter.
//  When processing a notification, the parameter structure is passed to it. This structure always 
//  has a Notification property of the NotifyDescription type, which needs to be processed to continue.
//  In addition, the structure always has the DataDetails property, got by calling the procedure.
//  When calling a notification, the structure must be passed as a value. If an error occurs during 
//  the asynchronous execution, add the ErrorDescription property of String type to this structure.
// 
// Parameters:
//  DataDetails - Structure - with the following properties:
//    * DataTitle     - String - a data item title, for example, File.
//    * ShowComment - Boolean - (optional) - allow adding a comment in the data signing form.
//                               False if not specified.
//    * Object              - Ref - (optional) - a reference to an object to be signed.
//    * -- // --            - NotifyDescription - (optional) - a handler for adding a signature to 
//                              the DigitalSignatures information register. Consider the common approach (see above).
//                              DataDetails already has the Signatures parameter at the time it is called.
//    * ObjectVersion       - String - (optional) - an object data version to check and lock the 
//                              object before adding the signature.
//    * Presentation       - Ref, String - (optional) - if not specified, a presentation is 
//                                calculated by the Object property value.
//    * Data              - BinaryData - (optional) - data to check a signature.
//    * -- // --              - String - (optional) - an address of a temporary storage that contains binary data.
//    * -- // --            - NotifyDescription (optional) - a data receipt handler that returns 
//                               data in the Data property (see the common approach above).
//
//  Form - ManagedForm - a form, from which you need to get a UUID that will be used to lock an 
//                                object.
//        - UUID - a UUID that will be used to lock an object.
//                                
//        - Undefined     - use a standard form.
//
//  ResultProcessing - NotifyDescription - an optional parameter.
//     It is required for a nonstandard result processing, for example, if the Object or Form parameters are not specified.
//     The result gets the DataDetails parameter, to which the following properties are added in case of a success:
//     * Success - Boolean - True if everything is successfully completed.
//     * Signatures - Array - an array that contains the following elements:
//       * SignatureProperties - String - an address of a temporary storage that contains the structure described below.
//                         - Structure - a detailed signature description:
//           * Signature             - BinaryData - a signing result.
//           * SignedBy - CatalogRef.Users - a user who signed the infobase object.
//                                      
//           * Comment         - String - a comment if it was entered upon signing.
//           * SignatureFileName     - String - a name of the file from which the signature was added.
//           * SignatureDate         - Date   - a signature date. It makes sense when the date 
//                                            cannot be extracted from signature data. If the date 
//                                            is not specified or blank, the current session date is used.
//           * SignatureCheckDate - Date   - date of signature check after adding from file. If the 
//                                            Data property is not specified in the DataDetails 
//                                            parameter, it returns a blank date.
//           * SignatureCorrect        - Boolean - a signature check result after adding from file. 
//                                            If the Data property is not specified in the 
//                                            DataDetails parameter, it returns False.
//
//           Derivative properties:
//           * Certificate          - BinaryData - contains export of the certificate that was used 
//                                      for signing (it is in the signature).
//           * Thumbprint           - String - a certificate thumbprint in the Base64 string format.
//           * CertificateOwner - String - a subject presentation received from the certificate binary data.
//
Procedure AddSignatureFromFile(DataDetails, Form = Undefined, ResultProcessing = Undefined) Export
	
	DataDetails.Insert("Success", False);
	
	ServerParameters = New Structure;
	ServerParameters.Insert("DataTitle", NStr("ru = 'Данные'; en = 'Data'; pl = 'Data';de = 'Data';ro = 'Data';tr = 'Data'; es_ES = 'Data'"));
	ServerParameters.Insert("ShowComment", False);
	FillPropertyValues(ServerParameters, DataDetails);
	
	ClientParameters = New Structure;
	ClientParameters.Insert("DataDetails",      DataDetails);
	ClientParameters.Insert("Form",               Form);
	ClientParameters.Insert("ResultProcessing", ResultProcessing);
	DigitalSignatureInternalClient.SetDataPresentation(ClientParameters, ServerParameters);
	
	AdditionForm = OpenForm("CommonForm.AddDigitalSignatureFromFile", ServerParameters,,,,,
		New NotifyDescription("StandardCompletion", DigitalSignatureInternalClient, ClientParameters));
	
	If AdditionForm = Undefined Then
		If ResultProcessing <> Undefined Then
			ExecuteNotifyProcessing(ResultProcessing, DataDetails);
		EndIf;
		Return;
	EndIf;
	
	AdditionForm.ClientParameters = ClientParameters;
	
	Context = New Structure;
	Context.Insert("ResultProcessing", ResultProcessing);
	Context.Insert("AdditionForm", AdditionForm);
	Context.Insert("CheckCryptoManagerAtClient", True);
	Context.Insert("DataDetails", DataDetails);
	
	If (    VerifyDigitalSignaturesOnTheServer()
	      Or GenerateDigitalSignaturesAtServer())
	   AND Not ValueIsFilled(AdditionForm.CryptographyManagerOnServerErrorDescription) Then
		
		Context.CheckCryptoManagerAtClient = False;
		DigitalSignatureInternalClient.AddSignatureFromFileAfterCreateCryptoManager(
			Undefined, Context);
	Else
		DigitalSignatureInternalClient.CreateCryptoManager(New NotifyDescription(
				"AddSignatureFromFileAfterCreateCryptoManager",
				DigitalSignatureInternalClient, Context),
			"", Undefined);
	EndIf;
	
EndProcedure

// It prompts the user to select signatures to save together with the object data.
//
// A common method to process property values with the NotifyDescription type in the DataDetails parameter.
//  When processing a notification, the parameter structure is passed to it. This structure always 
//  has a Notification property of the NotifyDescription type, which needs to be processed to continue.
//  In addition, the structure always has the DataDetails property, got by calling the procedure.
//  When calling a notification, the structure must be passed as a value. If an error occurs during 
//  the asynchronous execution, add the ErrorDescription property of String type to this structure.
// 
// Parameters:
//  DataDetails - Structure - with the following properties:
//    * DataTitle     - String - a data item title, for example, File.
//    * ShowComment - Boolean - (optional) - allow adding a comment in the data signing form.
//                               False if not specified.
//    * Presentation      - Ref, String - (optional) - if not specified, the presentation is 
//                                calculated by the Object property value.
//    * Object             - Ref - a reference to object, from which you need to get the signature list.
//    * -- // --           - String - an address of the temporary storage of signature array with  
//                              properties, as the AddSignatureFromFile procedure returns.
//    * Data             - NotifyDescription - a handler for saving data and receiving the full file 
//                              name with a path (after saving it), returned in the FullFileName 
//                              property of the String type for saving digital signatures (see the common approach above).
//                              If the file system extension is not attached, return file name 
//                              without a path.
//                              If the property will not be inserted or filled, it means cancelling 
//                              the continuation, and ResultProcessing with the False result will be called.
//
//                              For a batch request for permissions from the web client user to save 
//                              the file of data and signatures, you need to insert the PermissionsProcessingRequest parameter of the NotifyDescription type.
//                              The procedure will get a structure with the following parameters:
//                              * Calls               - Array - with details of calls to save signatures.
//                              * ContinuationHandler - NotifyDescription - a procedure to be 
//                                                       executed after requesting permissions, the 
//                                                       procedure parameters are the same as the notification for the BeginRequestingUserPermission method has.
//                                                       If the permission is not received, everything is canceled.
//
//  ResultProcessing - NotifyDescription - an optional parameter.
//     The parameter to be passed to the result:
//     * Boolean - True if everything was successful.
//
Procedure SaveDataWithSignature(DataDetails, ResultProcessing = Undefined) Export
	
	DigitalSignatureInternalClient.SaveDataWithSignature(DataDetails, ResultProcessing);
	
EndProcedure

// Checks the validity of the signature and the certificate.
// The certificate is always checked on the server if the administrator had set the check of digital 
// signatures on the server.
//
// Parameters:
//   Notification           - NotifyDescription - a notification about the execution result of the following types:
//     Boolean       - True if the check is completed successfully.
//     String       - a description of a signature check error.
//     Undefined - cannot get the crypto manager (because it is not specified).
//
//   SourceData       - BinaryData - binary data that was signed.
//                          Mathematical check is executed on the client side, even when the 
//                          administrator has set the check of digital signatures on the server if 
//                          the crypto manager is specified or it was received without an error.
//                          Performance and security increase when the signature is checked in the 
//                          decrypted file (it will not be passed to the server).
//                        - String - the address of temporary storage that contains initial binary data.
//                        - Structure - with the following properties:
//                          * XMLDSigParameters - Structure - as the XMLDSigParameters function of 
//                                                           the DigitalSignatureClient common module returns.
//                          * SOAPEnvelope      - String - a <soap:Envelope> message template.
//
//   Signature              - BinaryData - digital signature binary data.
//                        - String         - an address of a temporary storage that contains binary data.
//                        - Undefined   - if SourceData is a SOAP envelope.
//
//   CryptoManager - Undefined - get crypto manager by default (manager of the first application in 
//                          the list, as configured by the administrator).
//                        - CryptoManager - use the specified crypto manager.
//
//   OnDate               - Date - check the certificate on the specified date if the date cannot be 
//                          extracted from the signature.
//                          If the parameter is not filled in, check on the current session date if 
//                          the date cannot be extracted from the signature.
//
Procedure VerifySignature(Notification, SourceData, Signature, CryptoManager = Undefined, OnDate = Undefined) Export
	
	DigitalSignatureInternalClient.VerifySignature(Notification, SourceData, Signature, CryptoManager, OnDate);
	
EndProcedure

// Encrypts data, returns encryption certificates, and adds them to an object, if specified.
// 
// A common method to process property values with the NotifyDescription type in the DataDetails parameter.
//  When processing a notification, the parameter structure is passed to it. This structure always 
//  has a Notification property of the NotifyDescription type, which needs to be processed to continue.
//  In addition, the structure always has the DataDetails property, got by calling the procedure.
//  When calling a notification, the structure must be passed as a value. If an error occurs during 
//  the asynchronous execution, add the ErrorDescription property of String type to this structure.
// 
// Parameters:
//  DataDetails - Structure - with the following properties:
//    * Operation           - String - a data encryption form title, for example, File encryption.
//    * DataTitle    - String - a title of an item or a data set, for example, File.
//    * ReportCompletion - Boolean - (optional) - if False, no notification of successful operation 
//                              completion will be shown to present the data indicated next to the title.
//    * CertificatesSet  - String - (optional) an address of a temporary storage that contains the array described below.
//                         - Array - (optional) contains values of the CatalogRef.
//                              DigitalSignatureAndEncryptionKeysCertificates type or the BinaryData 
//                              type (certificate export).
//                         - Ref - (Optional) - a reference to the object that requires certificates.
//    * ChangeSet      - Boolean - if True and CertificatesSet is specified and contains only 
//                              references to certificates, you will be able to change the content of certificates.
//    * WithoutConfirmation   - Boolean - (optional) - skip user confirmation if the 
//                              CertificatesFilter property is specified.
//    * ExecuteAtServer - Undefined, Boolean - (optional) - when it is not specified or Undefined, 
//                              the execution will be determined automatically: if there is a server, 
//                              first execute on the server, then in case of a failure on the client, then display a message about two errors.
//                              When True: if execution on the server is allowed, execute only on 
//                              the server, in case of a failure one message about a server error is displayed.
//                              When False: execute only on the client, as if there is no server.
//    * OperationContext   - Undefined - (optional) - if specified, the property will be set to a 
//                              specific value of an arbitrary type, which allows to perform an 
//                              operation with the same encryption certificates again (the user is 
//                              not asked to confirm the action).
//    * ------ // ------   - Arbitrary - (optional) - if defined, the action will be executed with 
//                              the same encryption certificates.
//                              The WithoutConfirmation parameter is considered to be True.
//                              The Operation, DataTitle, CertificatesSet, ChangeSet, and 
//                              ExecuteAtServer parameters are ignored, and their values are left as they were at the first call.
//
//    Option 1:
//    * Data                - BinaryData - data to encrypt.
//    * -- // --              - String - an address of a temporary storage that contains binary data.
//    * -- // --              - NotifyDescription - a data receipt handler that returns data in the 
//                                 Data property (see the common approach above).
//    * ResultPlacement  - Undefined - (optional) - describes where to place the encrypted data.
//                                 If it is not specified or Undefined, use the ResultProcessing parameter.
//    * -- // --               - NotifyDescription - a handler of saving encrypted data.
//                                 Consider the common approach (see above).
//                                 DataDetails already has the EncryptedData parameter at the time it is called.
//                                 In case of the DataSet parameter, the DataSetCurrentItem property 
//                                 is inserted into the DataDetails. It contains the EncryptedData parameter.
//    * Object                - Ref - (optional) - a reference to the object that needs to be encrypted.
//                                 If not specified, encryption certificates are not required.
//    * ObjectVersion         - String - (optional) - version of the object data to check and lock 
//                                 the object before adding the encryption certificates.
//    * Presentation         - Ref, String, Structure - (optional) if not specified, a presentation 
//                                 is calculated by the Object property value.
//                                 The structure contains the following properties:
//                                    * Value      - Ref, NotifyDescription - to open.
//                                    * Presentation - String - a value presentation.
//    Option 2:
//    * DataSet           - Array - structures with properties specified in Case 1.
//    * SetPresentation   - String - presentations of several data set items, for example, Files (%1).
//                                 To this presentation, the number of items is filled in parameter %1.
//                                 Click the hyperlink to open the list.
//                                 If the data set has 1 item, value in the Presentation property of 
//                                 the DataSet property is used. If not specified, the presentation 
//                                 is calculated by the Object property value of a data set item.
//    * PresentationsList   - ValueList, Array - (optional) - an arbitrary list of items or an array 
//                                 with values, like the Presentation property has, and which the 
//                                 user can open. If not specified, it is filled in from the 
//                                 Presentation or Object property in the DataSet property.
//
//  Form - ManagedForm  - a form to provide an UUID used to place encrypted data to a temporary 
//                                storage.
//        - UUID -  an UUID used to place encrypted data to a temporary storage.
//                                
//        - Undefined      - use a standard form.
//
//  ResultProcessing - NotifyDescription - an optional parameter.
//     It is required for non-standard result processing, if the Form and/or the ResultPlacement parameter is not specified.
//     The result gets the DataDetails parameter, to which the following properties are added in case of a success:
//     * Success - Boolean - True if everything is successfully completed. If Success = False, the 
//               partial completion is defined by the existence of the EncryptedData property. If there is, the step is completed.
//     * EncryptionCertificates - String - the address of temporary storage that contains an array, described below.
//                             - Array - placed before starting encryption and after this it is not changed.
//                                 Contains values of the Structure type with the following properties:
//                                 * Thumbprint     - String - a certificate thumbprint in the Base64 string format.
//                                 * Presentation - String - a saved subject presentation got from 
//                                                      certificate binary data.
//                                 * Certificate    - BinaryData - contains export of the 
//                                                      certificate that was used for encryption.
//     * EncryptedData - BinaryData - an encryption result.
//                             Check the property in the DataSet parameter when passing it.
//                           - String - the address of temporary storage that contains the encryption result.
//
Procedure Encrypt(DataDetails, Form = Undefined, ResultProcessing = Undefined) Export
	
	ClientParameters = New Structure;
	ClientParameters.Insert("DataDetails", DataDetails);
	ClientParameters.Insert("Form", Form);
	ClientParameters.Insert("ResultProcessing", ResultProcessing);
	
	CompletionProcessing = New NotifyDescription("StandardCompletion",
		DigitalSignatureInternalClient, ClientParameters);
	
	If DataDetails.Property("OperationContext")
	   AND TypeOf(DataDetails.OperationContext) = Type("ManagedForm") Then
		
		DigitalSignatureInternalClient.ExtendStoringOperationContext(DataDetails);
		FormNameBeginning = "Catalog.DigitalSignatureAndEncryptionKeysCertificates.Form.";
		
		If DataDetails.OperationContext.FormName = FormNameBeginning + "DataEncryption" Then
			DataDetails.OperationContext.ExecuteEncryption(ClientParameters, CompletionProcessing);
			Return;
		EndIf;
	EndIf;
	
	ServerParameters = New Structure;
	ServerParameters.Insert("Operation",            NStr("ru = 'Шифрование данных'; en = 'Data encryption'; pl = 'Data encryption';de = 'Data encryption';ro = 'Data encryption';tr = 'Data encryption'; es_ES = 'Data encryption'"));
	ServerParameters.Insert("DataTitle",     NStr("ru = 'Данные'; en = 'Data'; pl = 'Data';de = 'Data';ro = 'Data';tr = 'Data'; es_ES = 'Data'"));
	ServerParameters.Insert("CertificatesSet");
	ServerParameters.Insert("ChangeSet");
	ServerParameters.Insert("ExecuteAtServer");
	FillPropertyValues(ServerParameters, DataDetails);
	
	DigitalSignatureInternalClient.OpenNewForm("DataEncryption",
		ClientParameters, ServerParameters, CompletionProcessing);
	
EndProcedure

// Decrypts data, returns it and places into object if it is specified.
// 
// A common method to process property values with the NotifyDescription type in the DataDetails parameter.
//  When processing a notification, the parameter structure is passed to it. This structure always 
//  has a Notification property of the NotifyDescription type, which needs to be processed to continue.
//  In addition, the structure always has the DataDetails property, got by calling the procedure.
//  When calling a notification, the structure must be passed as a value. If an error occurs during 
//  the asynchronous execution, add the ErrorDescription property of String type to this structure.
// 
// Parameters:
//  DataDetails - Structure - with the following properties:
//    * Operation           - String - a data decryption form title, for example, File decryption.
//    * DataTitle    - String - a title of an item or a data set, for example, File.
//    * ReportCompletion - Boolean - (optional) if False, skip a notification on successful 
//                              completion for the data presentation specified next to the title.
//    * CertificatesFilter  - Array - (optional) - contains references to catalog items.
//                              DigitalSignatureAndEncryptionCertificates that can be selected by 
//                              the user. The filter locks the ability to select other certificates 
//                              from the personal storage.
//    * WithoutConfirmation   - Boolean - (optional) - skip user confirmation if there is only one 
//                              certificate in the CertificatesFilter property and:
//                              a) ether the certificate is issued with a strong private key protection,
//                              b) or a user has memorized the certificate password for the time of the session,
//                              c) or a password has been set earlier by the SetCertificatePassword method.
//                              If an error occurred in the process of decryption, the form will be 
//                              opened with the ability to enter the password.
//    * IsAuthentication  - Boolean - (optional) - if True, show the OK button instead of the 
//                              Decrypt button. And some labels will be corrected.
//                              Besides, the ReportCompletion parameter is set to False.
//    * BeforeExecute   - NotifyDescription - (optional) - details of the additional data 
//                              preparation handler after selecting the certificate, by which the data will be decrypted.
//                              In this handler you can fill the Data parameter if it is required.
//                              In the moment of call, DataDetails already has the selected 
//                              certificate as SelectedCertificate (see below). Consider the common approach (see above).
//    * ExecuteAtServer - Undefined, Boolean - (optional) - when it is not specified or Undefined, 
//                              the execution will be determined automatically: if there is a server, 
//                              first execute on the server, then in case of a failure on the client, then display a message about two errors.
//                              When True: if execution on the server is allowed, execute only on 
//                              the server, in case of a failure one message about a server error is displayed.
//                              When False: execute only on the client, as if there is no server.
//    * AdditionalActionsParameters - Arbitrary - (optional) - if specified, it is passed to the 
//                              server to the BeforeOperationStart common module procedure.
//                              DigitalSignatureOverridable as InputParameters.
//    * OperationContext   - Undefined - (optional) - if specified, the property will be set to a 
//                              specific arbitrary type value, which allows to perform an operation 
//                              with the same certificate again (the user is asked neither to enter 
//                              the password nor to confirm an action).
//    * ------ // ------   - Arbitrary - (optional) - if defined, the action will be executed with 
//                              the same certificate without requesting a password or confirmation.
//                              The WithoutConfirmation parameter is considered to be True.
//                              The Operation, DataTitle, CertificatesFilter, IsAuthentication and 
//                              ExecuteAtServer parameters are ignored. They retain the values they had at the first call.
//                              The AdditionalActionsParameters parameter is ignored.
//                              The BeforeOperationStart procedure is not called.
//                              If you pass the context returned by the Sign procedure, the password 
//                              entered for the certificate can be used as if the password had been 
//                              saved for the duration of session. In other cases, the context is ignored.
// 
//    Option 1:
//    * Data                - BinaryData - data to decrypt.
//    * -- // --              - String - an address of a temporary storage that contains binary data.
//    * -- // --              - NotifyDescription - a data receipt handler that returns data in the 
//                                 Data property (see the common approach above). DataDetails 
//                                 already has the SelectedCertificate parameter at the time it is called (see below).
//    * ResultPlacement  - Undefined - (optional) - describes where to place the decrypted data.
//                                 If it is not specified or Undefined, use the ResultProcessing parameter.
//    * -- // --               - NotifyDescription - a handler of saving decrypted data.
//                                 Consider the common approach (see above).
//                                 DataDetails already has the DecryptedData parameter at the time it is called.
//                                 In case of the DataSet parameter, the DataSetCurrentItem property 
//                                 is inserted into the DataDetails. It contains the DecryptedData parameter.
//    * Object                - Ref - (optional) - a reference to the object to be decrypted, as 
//                                 well as clear records from the EncryptionCertificates information 
//                                 register after decryption is completed successfully.
//                                 If not specified, you do not need to get certificates from an object and clear them.
//    * -- // --              - String - the address of temporary storage that contains an array of 
//                                 encryption certificates in the form of structures with the following properties: 
//                                 * Thumbprint     - String - a certificate thumbprint in the Base64 string format.
//                                 * Presentation - String - a saved subject presentation got from 
//                                                      certificate binary data.
//                                 * Certificate    - BinaryData - contains export of the 
//                                                      certificate that was used for encryption.
//    * Presentation         - Ref, String, Structure - (optional) if not specified, a presentation 
//                                 is calculated by the Object property value.
//                                 The structure contains the following properties:
//                                    * Value      - Ref, NotifyDescription - to open.
//                                    * Presentation - String - a value presentation.
//                                 
//    Option 2:
//    * DataSet           - Array - structures with properties specified in Case 1.
//    * SetPresentation   - String - presentations of several data set items, for example, Files (%1).
//                                 To this presentation, the number of items is filled in parameter %1.
//                                 Click the hyperlink to open the list.
//                                 If the data set has 1 item, value in the Presentation property of 
//                                 the DataSet property is used. If not specified, the presentation 
//                                 is calculated by the Object property value of a data set item.
//    * PresentationsList   - ValueList, Array - (optional) - an arbitrary list of items or an array 
//                                 with values, like the Presentation property has, and which the 
//                                 user can open. If not specified, it is filled in from the 
//                                 Presentation or Object property in the DataSet property.
//    * EncryptionCertificates - Array - (optional) values, like the Object parameter has. It is 
//                                 used to extract encryption certificate lists for items that are 
//                                 specified in the PresentationsList parameter (the order needs to correspond to it).
//                                 When specified, the Object parameter is not used.
//
//  Form - ManagedForm  - a form to provide a UUID used to place decrypted data to a temporary 
//                                storage.
//        - UUID - an UUID used to place decrypted data to a temporary storage.
//                                
//        - Undefined      - use a standard form.
//
//  ResultProcessing - NotifyDescription - an optional parameter.
//     It is required for non-standard result processing, if the Form and/or the ResultPlacement parameter is not specified.
//     The DataDetails incoming parameter is passed to the result and, in case of a success, the following properties are added to it:
//     * Success - Boolean - True if everything is successfully completed. If Success = False, the 
//               partial completion is defined by the existence of the DecryptedData property. If there is, the step is completed.
//     * SelectedCertificate - Structure - contains the following certificate properties:
//         * Ref    - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates - a reference to the certificate.
//         * Thumbprint - String - a certificate thumbprint in the Base64 string format.
//         * Data    - String - an address of a temporary storage that contains certificate binary data.
//     * DecryptedData - BinaryData - a decryption result.
//                              Check the property in the DataSet parameter when passing it.
//                            - String - an address of a temporary storage that contains the decryption result.
//
Procedure Decrypt(DataDetails, Form = Undefined, ResultProcessing = Undefined) Export
	
	ClientParameters = New Structure;
	ClientParameters.Insert("DataDetails", DataDetails);
	ClientParameters.Insert("Form", Form);
	ClientParameters.Insert("ResultProcessing", ResultProcessing);
	
	CompletionProcessing = New NotifyDescription("StandardCompletion",
		DigitalSignatureInternalClient, ClientParameters);
	
	If DataDetails.Property("OperationContext")
	   AND TypeOf(DataDetails.OperationContext) = Type("ManagedForm") Then
		
		DigitalSignatureInternalClient.ExtendStoringOperationContext(DataDetails);
		FormNameBeginning = "Catalog.DigitalSignatureAndEncryptionKeysCertificates.Form.";
		
		If DataDetails.OperationContext.FormName = FormNameBeginning + "DataDecryption" Then
			DataDetails.OperationContext.ExecuteDecryption(ClientParameters, CompletionProcessing);
			Return;
		EndIf;
		If DataDetails.OperationContext.FormName = FormNameBeginning + "DataSigning" Then
			ClientParameters.Insert("SpecifiedContextOfOtherOperation");
		EndIf;
	EndIf;
	
	ServerParameters = New Structure;
	ServerParameters.Insert("Operation",            NStr("ru = 'Расшифровка данных'; en = 'Data decryption'; pl = 'Data decryption';de = 'Data decryption';ro = 'Data decryption';tr = 'Data decryption'; es_ES = 'Data decryption'"));
	ServerParameters.Insert("DataTitle",     NStr("ru = 'Данные'; en = 'Data'; pl = 'Data';de = 'Data';ro = 'Data';tr = 'Data'; es_ES = 'Data'"));
	ServerParameters.Insert("CertificatesFilter");
	ServerParameters.Insert("EncryptionCertificates");
	ServerParameters.Insert("IsAuthentication");
	ServerParameters.Insert("ExecuteAtServer");
	ServerParameters.Insert("AdditionalActionParameters");
	ServerParameters.Insert("AllowRememberPassword");
	FillPropertyValues(ServerParameters, DataDetails);
	
	If DataDetails.Property("Data") Then
		If TypeOf(ServerParameters.EncryptionCertificates) <> Type("Array")
		   AND DataDetails.Property("Object") Then
			
			ServerParameters.Insert("EncryptionCertificates", DataDetails.Object);
		EndIf;
		
	ElsIf TypeOf(ServerParameters.EncryptionCertificates) <> Type("Array") Then
		
		ServerParameters.Insert("EncryptionCertificates", New Array);
		For each DataItem In DataDetails.DataSet Do
			If DataItem.Property("Object") Then
				ServerParameters.EncryptionCertificates.Add(DataItem.Object);
			Else
				ServerParameters.EncryptionCertificates.Add(Undefined);
			EndIf;
		EndDo;
	EndIf;
	
	DigitalSignatureInternalClient.OpenNewForm("DataDecryption",
		ClientParameters, ServerParameters, CompletionProcessing);
	
EndProcedure

// Checks the crypto certificate validity.
//
// Parameters:
//   Notification           - NotifyDescription - a notification about the execution result of the following types:
//     Boolean       - True if the check is completed successfully.
//     String       - a description of a certificate check error.
//     Undefined - cannot get the crypto manager (because it is not specified).
//
//   Certificate           - CryptoCertificate - a certificate.
//                        - BinaryData - certificate binary data.
//                        - String - an address of a temporary storage that contains certificate binary data.
//
//   CryptoManager - Undefined - get the crypto manager automatically.
//                        - CryptoManager - use the specified crypto manager (a check on the server 
//                          will not be executed).
//
//   OnDate               - Date - check the certificate on the specified date.
//                          If parameter is not specified or a blank date is specified, check on the 
//                          current session date.
//
Procedure CheckCertificate(Notification, Certificate, CryptoManager = Undefined, OnDate = Undefined) Export
	
	DigitalSignatureInternalClient.CheckCertificate(Notification, Certificate, CryptoManager, OnDate);
	
EndProcedure

// Opens the CertificateCheck form and returns the check result.
//
// Parameters:
//  Certificate - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates - a certificate being checked.
//
//  AdditionalParameters - Undefined - an ordinary certificate check.
//                          - Structure - with optional properties:
//    * FormOwner          - ManagedForm - another form.
//    * FormTitle         - String - if specified, it replaces the form title.
//    * CheckOnChoose      - Boolean - if True, the Check button will be called
//                                  "Check and continue", and the Close button will be called "Cancel".
//    * ResultProcessing    - NotifyDescription - it is called immediately after the check, Result.
//                                 ChecksPassed (see below) is passed to the procedure with the initial value False.
//                                 If True is not set in the CheckOnChoose mode, the form will not 
//                                 be closed after a return from the notification procedure and a 
//                                 warning that it is impossible to continue will be shown.
//    * WithoutConfirmation       - Boolean - if it is set to True and you have a password, the 
//                                  check will be executed immediately without opening the form.
//                                  If the mode is CheckOnChoose and the ResultProcessing parameter 
//                                  is set, the form will not open if the ChecksPassed parameter is set to True.
//    * CompletionProcessing    - NotifyDescription - it is called when the form is closed, the 
//                                  Undefined or the ChecksPassed value are passed as its result (see below).
//    * Result              - Undefined - a check was never performed.
//                             - Structure - (return value) - it is inserted before processing the result,
//         contains the following properties:
//         * ChecksPassed  - Boolean - (return value) is set in the procedure of the parameter
//                                        ResultProcessing.
//         * ChecksAtServer - Undefined - a check was not executed on the server:
//                             - Structure - with properties, as the following parameter has.
//         * ChecksAtClient - Structure - with the following properties:
//             * CertificateExistence  - Boolean, Undefined - if True, the check was successful; if 
//                                     False - the check was not successful; if Undefined, it was not executed.
//                                     If standard checks are hidden in the 
//                                     OnCreateFormCertificateCheck of the DigitalSignatureOverridable module, there is no property.
//             * CertificateData   - Boolean, Undefined - the same as specified above.
//             * ApplicationExistence    - Boolean, Undefined - the same as specified above.
//             * Signing          - Boolean, Undefined - the same as specified above.
//             * SignatureCheck     - Boolean, Undefined - the same as specified above.
//             * Encryption          - Boolean, Undefined - the same as specified above.
//             * Decryption         - Boolean, Undefined - the same as specified above.
//             * <Additional check name> - Boolean, Undefined - the same as specified above.
//
//    * AdditionalChecksParameters - Arbitrary - parameters that are passed to the procedure named
//        OnCreateFormCertificateCheck of the DigitalSignatureOverridable common module.
//
Procedure CheckCatalogCertificate(Certificate, AdditionalParameters = Undefined) Export
	
	DigitalSignatureInternalClient.CheckCatalogCertificate(Certificate, AdditionalParameters);
	
EndProcedure

// Shows the dialog box for installing an extension to use digital signature and encryption.
// For operations using platform tools only (CryptoManager).
//
// Parameters:
//   WithoutQuestion - Boolean - if True is set, the question will not be shown.
//                It is required if the user clicked Install extension.
//
//   ResultHandler - NotifyDescription - details of the procedure that accepts the choice result in 
//    the first parameter (ExtensionInstalled) as one of the following values:
//       True - a user has confirmed the installation, after installation the extension was successfully attached.
//       False   - a user has confirmed the installation, but after installation the extension could not be attached.
//       Undefined - a user canceled the installation.
//
//   QuestionText     - String - a question text.
//   QuestionTitle - String - a question title.
//
//
Procedure InstallExtension(WithoutQuestion, ResultHandler = Undefined, QuestionText = "", QuestionTitle = "") Export
	
	DigitalSignatureInternalClient.InstallExtension(WithoutQuestion, ResultHandler, QuestionText, QuestionTitle);
	
EndProcedure

// Opens or activates the form of setting digital signature and encryption.
// 
// Parameters:
//  Page - String - allowed rows are Certificates, Settings, and Applications.
//
Procedure OpenDigitalSignatureAndEncryptionSettings(Page = "Certificates") Export
	
	FormParameters = New Structure;
	If Page = "Certificates" Then
		FormParameters.Insert("ShowCertificatesPage");
		
	ElsIf Page = "Settings" Then
		FormParameters.Insert("ShowSettingsPage");
		
	ElsIf Page = "Applications" Then
		FormParameters.Insert("ShowApplicationsPage");
	EndIf;
	
	Form = OpenForm("CommonForm.DigitalSignatureAndEncryptionSettings", FormParameters);
	
	// When re-opening the form, additional actions are required.
	If Page = "Certificates" Then
		Form.Items.Pages.CurrentPage = Form.Items.CertificatesPage;
		
	ElsIf Page = "Settings" Then
		Form.Items.Pages.CurrentPage = Form.Items.SettingsPage;
		
	ElsIf Page = "Applications" Then
		Form.Items.Pages.CurrentPage = Form.Items.ApplicationPage;
	EndIf;
	
	Form.Open();
	
EndProcedure

// Opens a reference to the "How to work with digital signature and encryption applications" ITS section.
//
Procedure OpenInstructionOfWorkWithApplications() Export
	
	DigitalSignatureInternalClient.OpenInstructionOfWorkWithApplications();
	
EndProcedure

// Opens the instruction with details of typical problems when working with digital signature 
// applications and how to solve them.
//
Procedure OpenInstructionOnTypicalProblemsOnWorkWithApplications() Export
	
	FileSystemClient.OpenURL("http://its.1c.ru/bmk/dsig/errors");
	
EndProcedure

// Returns the date extracted from the signature binary data or Undefined.
//
// Parameters:
//  Notification - NotifyDescription - it is called to pass the return value:
//                                   Date - a successfully extracted signature date.
//                                   Undefined - cannot extract date from signature data.
//  Signature - BinaryData - a signature data, from which you need to extract date.
//  CastToSessionTimeZone - Boolean - cast the universal time to the session time.
//
Procedure SigningDate(Notification, Signature, CastToSessionTimeZone = True) Export
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("Notification",                   Notification);
	NotificationParameters.Insert("CastToSessionTimeZone", CastToSessionTimeZone);
	
	DataReading = New DataReader(Signature);
	DataReading.BeginReadIntoBinaryDataBuffer(New NotifyDescription(
		"SigningDateAfterReadToBinaryDataBuffer",
		DigitalSignatureInternalClient,
		NotificationParameters));
	
EndProcedure

// Returns a certificate presentation in the directory, generated from the subject presentation 
// (IssuedTo) and certificate expiration date.
//
// Parameters:
//   Certificate   - CryptoCertificate - a crypto certificate.
//
// Returns:
//  String - a certificate presentation in the catalog.
//
Function CertificatePresentation(Certificate) Export
	
	Return DigitalSignatureInternalClientServer.CertificatePresentation(Certificate,
		DigitalSignatureInternalClient.TimeAddition(), ModuleLocalization());
	
EndFunction

// Returns the certificate subject presentation (IssuedTo).
//
// Parameters:
//   Certificate - CryptoCertificate - a crypto certificate.
//
// Returns:
//   String   - a subject presentation in the format "Last name Name, Company, Department, Position."
//              If cannot detemine FullName, then it is replaced with CommonName.
//              Company, Department, or JobPosition can be missing if they are not specified or 
//              cannot be determined.
//
Function SubjectPresentation(Certificate) Export
	
	Return DigitalSignatureInternalClientServer.SubjectPresentation(Certificate, ModuleLocalization());
	
EndFunction

// Returns a presentation of the certificate issuer (IssuedBy).
//
// Parameters:
//   Certificate - CryptoCertificate - a crypto certificate.
//
// Returns:
//   String - the issuer presentation in the format "CommonName, Company, Department",
//            Company and Department can be missing, if undefined.
//
Function IssuerPresentation(Certificate) Export
	
	Return DigitalSignatureInternalClientServer.IssuerPresentation(Certificate, ModuleLocalization());
	
EndFunction

// Returns main certificate properties as a structure.
//
// Parameters:
//   Certificate - CryptoCertificate - a crypto certificate.
//
// Returns:
//   Structure - with the following properties:
//    * Thumbprint      - String - a certificate thumbprint in the Base64 string format.
//    * SerialNumber  - BinaryData - a property of the SerialNumber certificate.
//    * Presentation  - String - see DigitalSignatureClient.CertificatePresentation. 
//    * IssuedTo      - String - see DigitalSignatureClient.SubjectPresentation. 
//    * IssuedBy       - String - see DigitalSignatureClient.IssuerPresentation. 
//    * StartDate     - Date - a StartDate certificate property in the session time zone.
//    * EndDate     - Date - an EndDate certificate property in the session time zone.
//    * Assignment     - String - an extended property details of the EKU certificate.
//    * Signing     - Boolean - the UseToSign certificate property.
//    * Encryption     - Boolean - the UseToEncrypt certificate property.
//
Function CertificateProperties(Certificate) Export
	
	Return DigitalSignatureInternalClientServer.CertificateProperties(Certificate,
		DigitalSignatureInternalClient.TimeAddition(), ModuleLocalization());
	
EndFunction

// Returns properties of the crypto certificate subject.
//
// Parameters:
//   Certificate - CryptoCertificate - a certificate to return the subject properties for.
//
// Returns:
//  Structure - with properties whose content depends on national specifics.
//              An example for the Russian Federation:
//     * CommonName         - String - (64) - extracted from the CN field.
//                          LE: depends on type of the last DS owner.
//                              - Company name
//                              - Automated system name
//                              - other displayed name as the information system requires.
//                          Individual: FullName.
//                        - Undefined - such certificate property is missing.
//
//     * Country           - String - (2) - it is extracted from the C field - the two-symbol 
//                          country code according to ISO 3166-1:1997 (GOST 7.67-2003).
//                        - Undefined - the required certificate property is not found.
//
//     * State           - String - (128) - it is extracted from the S field - the RF region name.
//                          LE - by the location address.
//                          Individual - by the registration address.
//                        - Undefined - such certificate property is missing.
//
//     * Locality  - String - (128) - extracted from the L field - a locality description.
//                          LE - by the location address.
//                          Individual - by the registration address.
//                        - Undefined - such certificate property is missing.
//
//     * Street            - String - (128) - it is extracted from the Street field - the street, house, and office names.
//                          LE - by the location address.
//                          Individual - by the registration address.
//                        - Undefined - such certificate property is missing.
//
//     * Company      - String - (64) - extracted from the O field.
//                          LE - a full or short company name.
//                        - Undefined - such certificate property is missing.
//
//     * Department    - String - (64) - it is extracted from the OU field.
//                          LE - in case of issuing the DS to official responsible - the company department.
//                              Department is a territorial structural unit of a large company, 
//                              which is not usually filled in the certificate.
//                        - Undefined - such certificate property is missing.
//
//     * Email - String - (128) - extracted from the E field (an email address).
//                          LE - an official responsible email address.
//                          Infividual - email address of an individual.
//                        - Undefined - such certificate property is missing.
//
//     * JobPosition        - String - (64) - extracted from the T field.
//                          LE - in case of issuing the DS to an official responsible - their position.
//                        - Undefined - such certificate property is missing.
//
//     * RegistrationNumber             - String - (64) - extracted from the OGRN field.
//                          BE - a company registration number.
//                        - Undefined - such certificate property is missing.
//
//     * PSRNIE           - String - (64) - extracted from the OGRNIP field.
//                          IE - a registration number of an individual entrepreneur.
//                        - Undefined - such certificate property is missing.
//
//     * IIAN            - String - (64) - extracted from the SNILS field.
//                          Individual - an IIAN
//                          LE - not required, in case of issuing the DS to official responsible - their IIAN.
//                        - Undefined - such certificate property is missing.
//
//     * TIN              - String - (12) - extracted from the INN field.
//                          Individual - a TIN.
//                          IE - a TIN.
//                          LE - not required, but it can be filled to interact with FTS.
//                        - Undefined - such certificate property is missing.
//
//     * LastName          - String - (64) - extracted from the SN field (if the field is filled in).
//                        - Undefined - such certificate property is missing.
//
//     * Name              - String - (64) - extracted from the GN field (if the field is filled in).
//                        - Undefined - such certificate property is missing.
//
//     * MiddleName         - String - (64) - extracted from the GN field (if the field is filled in).
//                        - Undefined - such certificate property is missing.
//
Function CertificateSubjectProperties(Certificate) Export
	
	Return DigitalSignatureInternalClientServer.CertificateSubjectProperties(Certificate, ModuleLocalization());
	
EndFunction

// Returns properties of the crypto certificate issuer. 
//
// Parameters:
//   Certificate - CryptoCertificate - a certificate to return the issuer properties for.
//
// Returns:
//  Structure - with properties whose content depends on national specifics.
//              An example for the Russian Federation:
//     * CommonName         - String - (64) - it is extracted from the CN field - it is an alias of the certification authority.
//                        - Undefined - such certificate property is missing.
//
//     * Country           - String - (2) - it is extracted from the C field - the two-symbol 
//                          country code according to ISO 3166-1:1997 (GOST 7.67-2003).
//                        - Undefined - such certificate property is missing.
//
//     * State           - String - (128) - it is extracted from the S field - it is the RF region 
//                          name by the location address of hardware and software complex certification authority.
//                        - Undefined - such certificate property is missing.
//
//     * Locality  - String - (128) - it is extracted from the L field - the description of the 
//                          locality  by the location address of hardware and software complex certification authority.
//                        - Undefined - such certificate property is missing.
//
//     * Street            - String - (128) - it is extracted from the S field - it is the name of 
//                          the street, house, and office by the location address of hardware and software complex certification authority.
//                        - Undefined - such certificate property is missing.
//
//     * Company      - String - (64) - a full or short name of the company is extracted from the O field.
//                        - Undefined - such certificate property is missing.
//
//     * Department    - String - (64) - extracted from the OU field (a company department).
//                            Department is a territorial structural unit of a large company, which 
//                            is not usually filled in the certificate.
//                        - Undefined - such certificate property is missing.
//
//     * Email - String - (128) - it is extracted from the E field. It is an email address of the certification authority.
//                        - Undefined - such certificate property is missing.
//
//     * PSRN             - String - (13) - it is extracted from the OGRN field - a PSRN of the certification authority company.
//                        - Undefined - such certificate property is missing.
//
//     * TIN              - String - (12) - it is extracted from the INN field - it is a TIN of the certification authority company.
//                        - Undefined - such certificate property is missing.
//
Function CertificateIssuerProperties(Certificate) Export
	
	Return DigitalSignatureInternalClientServer.CertificateIssuerProperties(Certificate, ModuleLocalization());
	
EndFunction

// Generates property structures to clarify SOAP envelope data, signing algorithms, and hash 
// algorithms.
// 
// Returns:
//  Structure - with the following properties:
//   * XPathSignedInfo         - String - for example, "(//. | //@* | //namespace::*)[ancestor-or-self::*[local-name()='SignedInfo']]".
//   * XPathTagToSign   - String - for example, "(//. | //@* | //namespace::*)[ancestor-or-self::soap:Body]".
//   * SignatureAlgorithmName     - String - for example, "GOST R 34.10-2001" + Chars.LF + "GOST R 34.11-2012" + ...
//   * SignatureAlgorithmOID     - String - for example, 1.2.643.2.2.3"     + Chars.LF + "1.2.643.7.1.1.3.2" + ...
//   * HashingAlgorithmName - String - for example, "GOST R 34.11-94"   + Chars.LF + "GOST R 34.11-12"   + ...
//   * HashingAlgorithmOID - String - for example, "1.2.643.2.2.9"     + Chars.LF + "1.2.643.7.1.1.2.2" + ...
//   * SignAlgorithm         - String - for example, "http://www.w3.org/2001/04/xmldsig-more#gostr34102001-gostr3411"
//                             + Chars.LF +
//                             "urn:ietf:params:xml:ns:cpxmlsec:algorithms:gostr34102012-gostr34112012-256"   + ...
//   * HashAlgorithm         - String - for example, "http://www.w3.org/2001/04/xmldsig-more#gostr3411"
//                             + Chars.LF + "urn:ietf:params:xml:ns:cpxmlsec:algorithms:gostr34112012-256" + ...
//
Function XMLDSigParameters() Export
	
	Return DigitalSignatureInternalClientServer.XMLDSigParameters();
	
EndFunction

#Region ForCallsFromOtherSubsystems

// OnlineInteraction

// These procedures and functions are used for integration with the 1C:Electronic document library.

// Creates and returns the crypto manager (on the client) for the specified application.
//
// Parameters:
//  Notification     - NotifyDescription - a notification about the execution result of the following types.
//                   CryptoManager - the initialized crypto manager.
//                   String - a description of a crypto manager creation error.
//
//  Operation       - String - if it is not blank, it needs to contain one of rows that determine 
//                   the operation to insert into the error description: Signing, SignatureCheck, Encryption,
//                   Decryption, CertificateCheck, and GetCertificates.
//
//  ShowError - Boolean - if True, the ApplicationCallError form will open, from which you can go to 
//                   the list of installed applications in the personal settings form on the 
//                   "Installed applications" page, where you can see why the application could not 
//                   be used, and open the installation instructions.
//                   
//
//  Application      - Undefined - returns crypto manager of the first application from the catalog, 
//                   to which it was possible to create it.
//                 - CatalogRef.DigitalSignatureAndEncryptionApplications - an application that 
//                   requires creating and returning a crypto manager.
//
Procedure CreateCryptoManager(Notification, Operation, ShowError = True, Application = Undefined) Export
	
	If TypeOf(Operation) <> Type("String") Then
		Operation = "";
	EndIf;
	
	If ShowError <> True Then
		ShowError = False;
	EndIf;
	
	DigitalSignatureInternalClient.CreateCryptoManager(Notification,
		Operation, ShowError, Application);
	
EndProcedure

// Finds a certificate on the computer by a thumbprint string.
// For operations using platform tools only (CryptoManager).
//
// Parameters:
//   Notification           - NotifyDescription - a notification about the execution result of the following types:
//     CryptoCertificate - a found certificate.
//     Undefined           - the certificate is not found in the storage.
//     String                 - a text of an error occurred when creating a crypto manager (or other error).
//
//   Thumbprint              - String - a Base64 coded certificate thumbprint.
//   InPersonalStorageOnly - Boolean - if True, search in the personal storage, otherwise, search everywhere.
//   ShowError         - Boolean - if False, hide the error text to be returned.
//
Procedure GetCertificateByThumbprint(Notification, Thumbprint, InPersonalStorageOnly, ShowError = True) Export
	
	If TypeOf(ShowError) <> Type("Boolean") Then
		ShowError = True;
	EndIf;
	
	DigitalSignatureInternalClient.GetCertificateByThumbprint(Notification,
		Thumbprint, InPersonalStorageOnly, ShowError);
	
EndProcedure

// Gets certificate thumbprints of the OS user on the computer.
// For operations using platform tools only (CryptoManager).
//
// Parameters:
//  Notification     - NotifyDescription - it is called when passing the return value:
//                   * Map - Key - a thumbprint in the Base64 string format, and Value is True.
//                   * String - a text of an error occurred when creating a crypto manager (or other error).
//
//  PersonalOnly   - Boolean - if False, recipient certificates are added to the personal certificates.
//
//  ShowError - Boolean - show a crypto manager creation error.
//
Procedure GetCertificatesThumbprints(Notification, OnlyPersonal, ShowError = True) Export
	
	DigitalSignatureInternalClient.GetCertificatesThumbprints(Notification, OnlyPersonal, ShowError);
	
EndProcedure

//  The procedure checks whether the certificate is in the personal storage, its expiration date 
//  whether the current user is specified in the certificate or no one is specified, and also that the application for working with the certificate is filled.
//
//  Parameters:
//   Notification - NotifyDescription - a notification with the result
//     Array - an array with the Structure values that has the following properties:
//         * Ref    - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates - a reference to the certificate.
//         * Description - String - a certificate presentation in the list.
//         * Thumbprint - String - a certificate thumbprint in the Base64 string format.
//         * Data    - String - an address of a temporary storage that contains certificate binary data.
//         * Company  - CatalogRef.Company - a company that owns the certificate.
//   Filter - Undefined - use default values for the structure properties that are specified below.
//            - Structure - with the following properties:
//                 * CheckExpirationDate - Boolean - if there is no property, then True.
//                 * OnlyCertificatesWithFilledApplication - Boolean - if there is no property, it 
//                         is True. In the query to the catalog, only those certificates are 
//                         selected that have the Application field filled in.
//                 * IncludeCertficatesWithBlankUser - Boolean - if there is no property, it is True. 
//                         In the query to the catalog, not only those certificates are selected, 
//                         for which the User field matches the current user, but also those for which it is not filled.
//                 * Company - TypeToDefine.Company - if there is a property and it is filled in, 
//                         only certificates with the Company field that matches the specified one 
//                         are selected in the catalog query.
//
Procedure FindValidPersonalCertificates(Notification, Filter = Undefined) Export
	
	FilterTypesArray = New Array;
	FilterTypesArray.Add(Type("Structure"));
	FilterTypesArray.Add(Type("Undefined"));
	
	CommonClientServer.CheckParameter("DigitalSignatureClient.FindValidPersonalCertificates",
		"Filter", Filter, FilterTypesArray);
	
	CommonClientServer.CheckParameter("DigitalSignatureClient.FindValidPersonalCertificates",
		"Notification", Notification, Type("NotifyDescription"));
	
	DigitalSignatureInternalClient.FindValidPersonalCertificates(Notification, Filter);
	
EndProcedure

// Searches for installed applications both on the client and on the server.
// For operations using platform tools only (CryptoManager).
//
// Parameters:
//   Notification - NotifyDescription - a notification with the result
//     Array - with Structure values of properties like ApplicationsDetails and with the following additional properties:
//       * ActiveUsersCheckResult           - Boolean - if True, it is set either on the client or on the server.
//       * CheckResultAtClient  - String - if a string is blank, then it is set, otherwise, error description.
//       * CheckResultAtServer  - String - if a string is blank, then it is set, otherwise, error description.
//                                     - Undefined - the check was not executed.
//
//   ApplicationsDetails   - Array - as in the FillApplicationsList procedure.
//                                 The specified details will be added to the supplied details or 
//                                 will replace them in terms of matching the name and type of the application.
//
//   CheckAtServer - Boolean - True, if signing or encryption is enabled on the server and the value 
//                                 is not specified explicitly.
//
Procedure FindInstalledPrograms(Notification, ApplicationsDetails = Undefined, CheckAtServer = Undefined) Export
	
	TypesArrayCheckAtServer = New Array;
	TypesArrayCheckAtServer.Add(Type("Boolean"));
	TypesArrayCheckAtServer.Add(Type("Undefined"));
	
	CommonClientServer.CheckParameter("DigitalSignatureClient.FindInstalledPrograms", "CheckAtServer", 
		CheckAtServer, TypesArrayCheckAtServer);
		
	CommonClientServer.CheckParameter("DigitalSignatureClient.FindInstalledPrograms", "Notification", 
		Notification, Type("NotifyDescription"));
		
	CommonClientServer.CheckParameter("DigitalSignatureClient.FindInstalledPrograms", "ApplicationsDetails", 
		ApplicationsDetails, Type("Array"));
	
	DigitalSignatureInternalClient.FindInstalledPrograms(Notification, ApplicationsDetails, CheckAtServer);
	
EndProcedure

// Sets password in the password storage on the client for the time of session.
// For operations using platform tools only (CryptoManager).
//
// Setting a password allows the user not to enter the password during the next operation, which is 
// useful when performing a package of operations.
// If a password is set for the certificate, the RememberPassword check box in the DataSigning and 
// DataDecryption forms becomes hidden.
// To cancel the set password, set the password value to Undefined.
//
// Parameters:
//  CertificateRef - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates - a certificate for 
//                        which password is being set.
//
//  Password           - String - a password to be set. It can be blank.
//                   - Undefined - reset the set password, if any.
//
//  PasswordNote - Structure - with properties that describe the note that will be written under the 
//                      password instead of the RememberPassword check box.
//     * NoteText - String - text only;
//     * NoteHyperlink - Boolean - if True, then call ActionProcessing by clicking the note.
//     * TooltipText       - String, FormattedString - a text or a text with hyperlinks.
//     * ActionProcessing    - NotifyDescription - calls the procedure, where the structure with the 
//          following properties is passed:
//          * Certificate - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates - a reference 
//                         to the selected certificate.
//          * Action - String - NoteClick or the tooltip URL.
// 
Procedure SetCertificatePassword(CertificateReference, Password, PasswordNote = Undefined) Export
	
	DigitalSignatureInternalClient.SetCertificatePassword(CertificateReference, Password, PasswordNote);
	
EndProcedure

// Overrides the usual certificate choice from the catalog to certificate selection from the 
// personal storage with password confirmation and automatic addition to the catalog if there is no 
// certificate in the catalog yet.
//
// Parameters:
//  Item    - FormField - a form item, where the selected value will be passed.
//  Certificate - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates - the current value 
//               selected in the Item field required to select the matching list line.
//
//  StandardProcessing - Boolean - the StartChoice event standard parameter that you need to reset to False.
//  
//  ForEncryptionAndDecryption - Boolean - manages the choice form title. The initial value is False.
//                              False is to sign, True is to encrypt and decrypt.
//                            - Undefined is to sign and encrypt.
//
Procedure CertificateStartChoiceWithConfirmation(Item, Certificate, StandardProcessing, ToEncryptAndDecrypt = False) Export
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	FormParameters.Insert("SelectedCertificate", Certificate);
	FormParameters.Insert("ToEncryptAndDecrypt", ToEncryptAndDecrypt);
	
	DigitalSignatureInternalClient.SelectSigningOrDecryptionCertificate(FormParameters, Item);
	
EndProcedure

// End OnlineInteraction

#EndRegion

#EndRegion

#Region Internal

// Opens the DS view form.
Procedure OpenSignature(CurrentData) Export
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	SignatureProperties = New Structure(
		"SignatureDate, Comment, CertificateOwner, Thumbprint,
		|SignatureAddress, SignatureSetBy, CertificateAddress,
		|Status, ErrorDescription, SignatureCorrect, SignatureValidationDate");
	
	FillPropertyValues(SignatureProperties, CurrentData);
	
	FormParameters = New Structure("SignatureProperties", SignatureProperties);
	OpenForm("CommonForm.DigitalSignature", FormParameters);
	
EndProcedure

// Saves signature to the hard drive
Procedure SaveSignature(SignatureAddress) Export
	
	DigitalSignatureInternalClient.SaveSignature(SignatureAddress);
	
EndProcedure

// Opens the certificate data view form.
//
// Parameters:
//  CertificateData - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates - a reference to the certificate.
//                    - CryptoCertificate - an existing certificate.
//                    - BinaryData - certificate binary data.
//                    - String - an address of temporary storage that contains the certificate BinaryData.
//                    - String - a certificate thumbprint to be searched in all storages.
//
//  OpenData     - Boolean - open the certificate data and not the form of catalog item.
//                      If not a reference is passed to the catalog item and the catalog item could 
//                      not be found by thumbprint, the certificate data will be opened.
//
Procedure OpenCertificate(CertificateData, OpenData = False) Export
	
	DigitalSignatureInternalClient.OpenCertificate(CertificateData, OpenData);
	
EndProcedure

// It reports the signing once it is completed.
//
// Parameters:
//  DataPresentation - Arbitrary - a reference to the object, to which digital signature is added.
//                          
//  DataSet     - Boolean - determines the type of message and whether there are multiple items or 
//                          one item.
//  FromFile             - Boolean - determines the type of message to add a digital signature or a 
//                          file.
//
Procedure ObjectSigningInfo(DataPresentation, DataSet = False, FromFile = False) Export
	
	If FromFile Then
		If DataSet Then
			MessageText = NStr("ru = 'Добавлены подписи из файлов:'; en = 'Signatures from files added:'; pl = 'Signatures from files added:';de = 'Signatures from files added:';ro = 'Signatures from files added:';tr = 'Signatures from files added:'; es_ES = 'Signatures from files added:'");
		Else
			MessageText = NStr("ru = 'Добавлена подпись из файла:'; en = 'Signature from file is added:'; pl = 'Signature from file is added:';de = 'Signature from file is added:';ro = 'Signature from file is added:';tr = 'Signature from file is added:'; es_ES = 'Signature from file is added:'");
		EndIf;
	Else
		If DataSet Then
			MessageText = NStr("ru = 'Установлены подписи:'; en = 'Digitally signed:'; pl = 'Digitally signed:';de = 'Digitally signed:';ro = 'Digitally signed:';tr = 'Digitally signed:'; es_ES = 'Digitally signed:'");
		Else
			MessageText = NStr("ru = 'Установлена подпись:'; en = 'Digitally signed:'; pl = 'Digitally signed:';de = 'Digitally signed:';ro = 'Digitally signed:';tr = 'Digitally signed:'; es_ES = 'Digitally signed:'");
		EndIf;
	EndIf;
	
	ShowUserNotification(MessageText, , DataPresentation);
	
EndProcedure

// Reports completion at the end of encryption.
//
// Parameters:
//  DataPresentation - Arbitrary - a reference to an object whose data is encrypted.
//                          
//  DataSet     - Boolean - determines the type of message and whether there are multiple items or 
//                          one item.
//
Procedure InformOfObjectEncryption(DataPresentation, DataSet = False) Export
	
	MessageText = NStr("ru = 'Выполнено шифрование:'; en = 'Encrypted:'; pl = 'Encrypted:';de = 'Encrypted:';ro = 'Encrypted:';tr = 'Encrypted:'; es_ES = 'Encrypted:'");
	
	ShowUserNotification(MessageText, , DataPresentation);
	
EndProcedure

// Reports completion at the end of decryption.
//
// Parameters:
//  DataPresentation - Arbitrary - a reference to an object whose data is decrypted.
//                          
//  DataSet     - Boolean - determines the type of message and whether there are multiple items or 
//                          one item.
//
Procedure InformOfObjectDecryption(DataPresentation, DataSet = False) Export
	
	MessageText = NStr("ru = 'Выполнена расшифровка:'; en = 'Decrypted:'; pl = 'Decrypted:';de = 'Decrypted:';ro = 'Decrypted:';tr = 'Decrypted:'; es_ES = 'Decrypted:'");
	
	ShowUserNotification(MessageText, , DataPresentation);
	
EndProcedure

// See DigitalSignature.PersonalSettings. 
Function PersonalSettings() Export
	
	Return StandardSubsystemsClient.ClientRunParameters().DigitalSignature.PersonalSettings;
	
EndFunction

#EndRegion

#Region Private

// See DigitalSignature.CommonSettings. 
Function CommonSettings() Export
	
	Return StandardSubsystemsClient.ClientRunParameters().DigitalSignature.CommonSettings;
	
EndFunction

Function ModuleLocalization()
	
	If StandardSubsystemsClient.ClientRunParameters().DigitalSignature.CommonSettings.CertificateIssueRequestAvailable Then
		Return CommonClient.CommonModule("DigitalSignatureLocalizationClientServer");
	EndIf;
	Return Undefined;

EndFunction

#EndRegion
