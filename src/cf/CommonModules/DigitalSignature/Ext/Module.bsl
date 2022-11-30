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

// Gets object signatures and returns them.
//
// Parameters:
//  Object - Ref - a reference to the signed object.
//         The object must have the SignedWithDS attribute.
//
// Returns:
//  Array - an array of structures described below.
//   - Structure - a detailed signature description:
//     * Signature             - BinaryData - a signing result.
//     * SignedBy - CatalogRef.Users - a user who signed the infobase object.
//                           
//     * Comment         - String - a comment if it was entered upon signing.
//     * SignatureFileName     - String - if a signature is added from a file.
//     * SignatureDate         - Date - a signature date. It makes sense when the date cannot be 
//                           extracted from signature data.
//     * SignatureCheckDate - Date - a last signature check date.
//     * SignatureCorrect        - Boolean - a last signature check result.
//     * SequenceNumber     - Number - a signature ID, by which they can be ordered in the list.
//
//     Derivative properties:
//     * Certificate          - BinaryData - contains export of the certificate that was used for 
//                           signing (it is in the signature).
//     * Thumbprint           - String - a certificate thumbprint in the Base64 string format.
//     * CertificateOwner - String - a subject presentation received from the certificate binary data.
//
Function SetSignatures(Object) Export
	
	CheckParameterObject(Object, "DigitalSignature.SetSignatures", True);
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.CheckReadAllowed(Object);
	EndIf;
	
	If Common.IsReference(TypeOf(Object)) Then
		ObjectRef = Object;
	Else
		ObjectRef = Object.Ref;
	EndIf;
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	DigitalSignatures.Signature,
		|	DigitalSignatures.SequenceNumber AS SequenceNumber,
		|	DigitalSignatures.SignatureSetBy,
		|	DigitalSignatures.Comment,
		|	DigitalSignatures.SignatureFileName,
		|	DigitalSignatures.SignatureDate,
		|	DigitalSignatures.SignatureValidationDate,
		|	DigitalSignatures.SignatureCorrect,
		|	DigitalSignatures.Certificate,
		|	DigitalSignatures.Thumbprint,
		|	DigitalSignatures.CertificateOwner
		|FROM
		|	InformationRegister.DigitalSignatures AS DigitalSignatures
		|WHERE
		|	DigitalSignatures.SignedObject = &SignedObject
		|
		|ORDER BY
		|	SequenceNumber";
	
	Query.SetParameter("SignedObject", ObjectRef);
	
	QueryResult = Query.Execute();
	DetailedRecordsSelection = QueryResult.Select();
	
	DigitalSignaturesArray = New Array;
	While DetailedRecordsSelection.Next() Do
		ThumbprintStructure = New Structure(
			"SequenceNumber, SignatureDate, SignatureSetBy,
			|SignatureValidationDate, SignatureFileName, Comment, CertificateOwner,
			|Thumbprint, Signature, SignatureCorrect, Certificate");
		FillPropertyValues(ThumbprintStructure, DetailedRecordsSelection);
		ThumbprintStructure.Signature = ThumbprintStructure.Signature.Get();
		DigitalSignaturesArray.Add(ThumbprintStructure);
	EndDo;
	
	Return DigitalSignaturesArray;
	
EndFunction

// Adds a signature to an object and writes it.
// Sets the True value for the SignedWithDS attribute.
// 
// Parameters:
//  Object - Ref - an object will be got, locked, changed, or written by reference.
//                    The object must have the SignedWithDS attribute.
//         - Object - an object will be changed without locking and writing.
//
//  SignatureProperties - Array - an array of structures or structure addresses described below.
//                  - String - a temporary storage address that contains the structure described below.
//                  - Structure - a detailed signature description:
//     * Signature             - BinaryData - a signing result.
//     * SignedBy - CatalogRef.Users - a user who signed the infobase object.
//                                
//     * Comment         - String - a comment if it was entered upon signing.
//     * SignatureFileName     - String - if a signature is added from a file.
//     * SignatureDate         - Date   - a signature date. It makes sense when the date cannot be 
//                                      extracted from signature data. If the date is not specified 
//                                      or blank, the current session date is used.
//     * SignatureCheckDate - Date   - a last signature check date.
//     * SignatureCorrect        - Boolean - a last signature check result.
//
//     Derivative properties:
//     * Certificate          - BinaryData - contains export of the certificate that was used for 
//                                signing (it is in the signature).
//     * Thumbprint           - String - a certificate thumbprint in the Base64 string format.
//     * CertificateOwner - String - a subject presentation received from the certificate binary data.
//     * CertificateDetails - Structure - an optional property that is required for certificates 
//                             that cannot be passed to the CryptoCertificate platform method with the following properties:
//        ** SerialNumber - String - a certificate serial number as in the CryptoCertificate platform object.
//        ** IssuedBy      - String - as the IssuerPresentation function returns.
//        ** IssuedTo     - String - as the SubjectPresentation function returns.
//        ** BeginDate    - String - a certificate date as in the CryptoCertificate platform object in the DLF=D format.
//        ** EndDate - String - a certificate date as in the CryptoCertificate platform object in the DLF=D format.
//
//  FormID - UUID - a form ID that is used for lock if an object reference is passed.
//                       
//
//  ObjectVersion      - String - an object data version, if an object reference is passed that is 
//                       used to lock an object before writing it, considering that signing is 
//                       performed on the client and the object could be changed during it.
//
//  WrittenObject   - Object - an object that was received and written if a reference was passed.
//
Procedure AddSignature(Object, Val SignatureProperties, FormID = Undefined,
			ObjectVersion = Undefined, WrittenObject = Undefined) Export
	
	CheckParameterObject(Object, "DigitalSignature.AddSignature");
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.CheckChangeAllowed(Object);
	EndIf;
	
	If TypeOf(SignatureProperties) = Type("String") Then
		SignatureProperties = GetFromTempStorage(SignatureProperties);
		
	ElsIf TypeOf(SignatureProperties) = Type("Array") Then
		LastItemIndex = SignatureProperties.Count()-1;
		For Index = 0 To LastItemIndex Do
			If TypeOf(SignatureProperties[Index]) = Type("String") Then
				SignatureProperties[Index] = GetFromTempStorage(SignatureProperties[Index]);
			EndIf;
		EndDo;
	EndIf;
	
	IsRef = Common.IsReference(TypeOf(Object));
	
	BeginTransaction();
	Try
		If IsRef Then
			LockDataForEdit(Object, ObjectVersion, FormID);
			DataObject = Object.GetObject();
		Else
			DataObject = Object;
		EndIf;
		
		EventLogMessage = "";
		
		If TypeOf(SignatureProperties) = Type("Array") Then
			For Each CurrentProperties In SignatureProperties Do
				AddSignatureString(DataObject, CurrentProperties, EventLogMessage);
			EndDo;
		Else
			AddSignatureString(DataObject, SignatureProperties, EventLogMessage);
		EndIf;
		
		If Not DataObject.SignedWithDS
		   AND (TypeOf(SignatureProperties) <> Type("Array")
		      Or SignatureProperties.Count() > 0) Then
			
			DataObject.SignedWithDS = True;
		EndIf;
		
		If IsRef Then
			// To determine that this is a record to add or remove a signature.
			DataObject.AdditionalProperties.Insert("WriteSignedObject", True);
			If DataObject.Modified() Then
				DataObject.Write();
			EndIf;
			UnlockDataForEdit(Object.Ref, FormID);
			WrittenObject = DataObject;
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		ErrorInformation = ErrorInfo();
		If ValueIsFilled(EventLogMessage) Then
			WriteLogEvent(
				NStr("ru = 'Электронная подпись.Ошибка добавления подписи'; en = 'Digital signature. An error occurred while adding a signature'; pl = 'Digital signature. An error occurred while adding a signature';de = 'Digital signature. An error occurred while adding a signature';ro = 'Digital signature. An error occurred while adding a signature';tr = 'Digital signature. An error occurred while adding a signature'; es_ES = 'Digital signature. An error occurred while adding a signature'", Common.DefaultLanguageCode()),
				EventLogLevel.Information,
				Object.Metadata(),
				Object.Ref,
				EventLogMessage + "
				|
				|" + BriefErrorDescription(ErrorInformation));
		EndIf;
		Raise;
	EndTry;
	
EndProcedure

// Updates an object signature.
// 
// Parameters:
//  Object - Ref - a reference to a signed object to refresh a signature for.
//
//  SignatureProperties - String - a temporary storage address that contains the structure described below.
//                  - Structure - a detailed signature description:
//     * Signature             - BinaryData - a signing result.
//     * SignedBy - CatalogRef.Users - a user who signed the infobase object.
//                                
//     * Comment         - String - a comment if it was entered upon signing.
//     * SignatureFileName     - String - if a signature is added from a file.
//     * SignatureDate         - Date   - a signature date. It makes sense when the date cannot be 
//                                      extracted from signature data. If the date is not specified 
//                                      or blank, the current session date is used.
//     * SignatureCheckDate - Date   - a last signature check date.
//     * SignatureCorrect        - Boolean - a last signature check result.
//     * SequenceNumber     - Number - a signature ID, by which they can be ordered in the list.
//
//     Derivative properties:
//     * Certificate          - BinaryData - contains export of the certificate that was used for 
//                                signing (it is in the signature).
//     * Thumbprint           - String - a certificate thumbprint in the Base64 string format.
//     * CertificateOwner - String - a subject presentation received from the certificate binary data.
//
Procedure UpdateSignature(Object, Val SignatureProperties) Export
	
	CheckParameterObject(Object, "DigitalSignature.UpdateSignature", True);
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.CheckChangeAllowed(Object);
	EndIf;
	
	If TypeOf(SignatureProperties) = Type("String") Then
		SignatureProperties = GetFromTempStorage(SignatureProperties);
	EndIf;
	
	SetPrivilegedMode(True);
	
	Lock = New DataLock;
	LockItem = Lock.Add("InformationRegister.DigitalSignatures");
	LockItem.SetValue("SignedObject", Object);
	
	BeginTransaction();
	Try
		Lock.Lock();
		ObjectSignatures = SetSignatures(Object);
		
		For Each ObjectSignature In ObjectSignatures Do
			SignatureBinaryData = ObjectSignature.Signature;
			// If binary data matches, the signature must be refreshed.
			If SignatureBinaryData = SignatureProperties.Signature Then
				SignatureToRefresh = InformationRegisters.DigitalSignatures.CreateRecordManager();
				SignatureToRefresh.SequenceNumber   = SignatureProperties.SequenceNumber;
				SignatureToRefresh.SignedObject = Object;
				SignatureToRefresh.Read();
				FillPropertyValues(SignatureToRefresh, SignatureProperties, , "Signature, Certificate");
				SignatureToRefresh.Write(True);
			EndIf;
		EndDo;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Deletes an object signature and writes it.
// 
// Parameters:
//  Object - Ref - an object will be got, locked, changed, or written by reference.
//                    The object must have the SignedWithDS attribute.
//         - Object - an object will be changed without locking and writing.
// 
//  SequenceNumber      - Number - a signature sequence number.
//                       - Array - values of the type specified above.
//
//  FormID - UUID - a form ID that is used for lock if an object reference is passed.
//                       
//
//  ObjectVersion      - String - an object data version, if an object reference is passed that is 
//                       used to lock an object before writing it, considering that signing is 
//                       performed on the client and the object could be changed during it.
//
//  WrittenObject   - Object - an object that was received and written if a reference was passed.
//
Procedure DeleteSignature(Object, SequenceNumber, FormID = Undefined,
			ObjectVersion = Undefined, WrittenObject = Undefined) Export
	
	CheckParameterObject(Object, "DigitalSignature.DeleteSignature");
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.CheckChangeAllowed(Object);
	EndIf;
	
	IsRef = Common.IsReference(TypeOf(Object));
	BeginTransaction();
	Try
		If IsRef Then
			LockDataForEdit(Object, ObjectVersion, FormID);
			DataObject = Object.GetObject();
		Else
			DataObject = Object;
		EndIf;
		
		EventLogMessage = "";
		
		If TypeOf(SequenceNumber) = Type("Array") Then
			List = New ValueList;
			List.LoadValues(SequenceNumber);
			List.SortByValue(SortDirection.Desc);
			For Each ListItem In List Do
				DeleteSignatureString(DataObject, ListItem.Value, EventLogMessage);
			EndDo;
		Else
			DeleteSignatureString(DataObject, SequenceNumber, EventLogMessage);
		EndIf;
		
		RefreshSignaturesNumbering(DataObject);
		
		If IsRef Then
			// To determine that this is a record to add or remove a signature.
			DataObject.AdditionalProperties.Insert("WriteSignedObject", True);
			If DataObject.Modified() Then
				DataObject.Write();
			EndIf;
			UnlockDataForEdit(Object.Ref, FormID);
			WrittenObject = DataObject;
		EndIf;
		CommitTransaction();
	Except
		RollbackTransaction();
		ErrorInformation = ErrorInfo();
		If ValueIsFilled(EventLogMessage) Then
			WriteLogEvent(
				NStr("ru = 'Электронная подпись.Ошибка удаления подписи'; en = 'Digital signature.Signature deletion error'; pl = 'Digital signature.Signature deletion error';de = 'Digital signature.Signature deletion error';ro = 'Digital signature.Signature deletion error';tr = 'Digital signature.Signature deletion error'; es_ES = 'Digital signature.Signature deletion error'", Common.DefaultLanguageCode()),
				EventLogLevel.Information,
				Object.Metadata(),
				Object.Ref,
				EventLogMessage + "
				|
				|" + BriefErrorDescription(ErrorInformation));
		EndIf;
		Raise;
	EndTry;
	
EndProcedure

// Gets an array of encryption certificates.
// Parameters:
//  Object - CatalogRef - a reference to the catalog called *AttachedFiles, FilesVersions, or Files.
//
// Returns:
//   Array - an array of structures.
//
Function EncryptionCertificates(Object) Export
	
	CheckParameterObject(Object, "DigitalSignature.EncryptionCertificates", True);
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.CheckReadAllowed(Object);
	EndIf;
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	EncryptionCertificates.Presentation,
		|	EncryptionCertificates.Thumbprint,
		|	EncryptionCertificates.Certificate,
		|	EncryptionCertificates.SequenceNumber AS SequenceNumber
		|FROM
		|	InformationRegister.EncryptionCertificates AS EncryptionCertificates
		|WHERE
		|	EncryptionCertificates.EncryptedObject = &EncryptedObject
		|
		|ORDER BY
		|	SequenceNumber";
	
	Query.SetParameter("EncryptedObject", Object);
	
	QueryResult = Query.Execute();
	
	DetailedRecordsSelection = QueryResult.Select();
	
	EncryptionCertificatesArray = New Array;
	While DetailedRecordsSelection.Next() Do
		ThumbprintStructure = New Structure;
		ThumbprintStructure.Insert("Thumbprint",       DetailedRecordsSelection.Thumbprint);
		ThumbprintStructure.Insert("Presentation",   DetailedRecordsSelection.Presentation);
		ThumbprintStructure.Insert("Certificate",      DetailedRecordsSelection.Certificate.Get());
		ThumbprintStructure.Insert("SequenceNumber", DetailedRecordsSelection.SequenceNumber);
		EncryptionCertificatesArray.Add(ThumbprintStructure);
	EndDo;
	
	Return EncryptionCertificatesArray;

EndFunction

// Places encryption certificates to the information register and writes an object.
// Sets the Encrypted attribute by the presence of certificates in the EncryptionCertificate information register.
// 
// Parameters:
//  Object - Ref - an object will be got, locked, changed, or written by reference.
//                    The object must have the Encrypted attribute.
//         - Object - an object will be changed without locking and writing.
//
//  EncryptionCertificates - String - a temporary storage address that contains the array described below.
//                        - Array - an array of structures described below:
//                             * Thumbprint     - String - a certificate thumbprint in the Base64 string format.
//                             * Presentation - String - a saved subject presentation got from 
//                                                  certificate binary data.
//                             * Certificate    - BinaryData - contains export of the certificate 
//                                                  that was used for encryption.
//
//  FormID - UUID - a form ID that is used for lock if an object reference is passed.
//                       
//
//  ObjectVersion      - String - an object data version, if an object reference is passed that is 
//                       used to lock an object before writing it, considering that signing is 
//                       performed on the client and the object could be changed during it.
//
//  WrittenObject   - Object - an object that was received and written if a reference was passed.
//
Procedure WriteEncryptionCertificates(Object, Val EncryptionCertificates, FormID = Undefined,
	ObjectVersion = Undefined, WrittenObject = Undefined) Export
	
	CheckParameterObject(Object, "DigitalSignature.WriteEncryptionCertificates", False);
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.CheckChangeAllowed(Object);
	EndIf;
	
	IsRef = Common.IsReference(TypeOf(Object));
	ObjectRef = ?(IsRef, Object, Object.Ref);
	
	If TypeOf(EncryptionCertificates) = Type("String") Then
		EncryptionCertificates = GetFromTempStorage(EncryptionCertificates);
	EndIf;
	
	BeginTransaction();
	Try
		If IsRef Then
			LockDataForEdit(ObjectRef, ObjectVersion, FormID);
			DataObject = Object.GetObject();
		Else
			DataObject = Object;
		EndIf;
		
		SetPrivilegedMode(True);
		RecordSet = InformationRegisters.EncryptionCertificates.CreateRecordSet();
		RecordSet.Filter.EncryptedObject.Set(DataObject.Ref);
		SequenceNumber = 1;
		For Each EncryptionCertificate In EncryptionCertificates Do
			NewCertificate = RecordSet.Add();
			NewCertificate.EncryptedObject = DataObject.Ref;
			FillPropertyValues(NewCertificate, EncryptionCertificate);
			NewCertificate.SequenceNumber = SequenceNumber;
			SequenceNumber = SequenceNumber + 1;
		EndDo;
		
		DataObject.Encrypted = RecordSet.Count() > 0;
		
		RecordSet.Write();
		If IsRef Then
			UnlockDataForEdit(ObjectRef, FormID);
			WrittenObject = DataObject;
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Returns the date extracted from the signature binary data or Undefined.
//
// Parameters:
//  Signature - BinaryData - signature data to extract a date from.
//  CastToSessionTimeZone - Boolean - cast the universal time to the session time.
//
// Returns:
//  Date - a successfully extracted signature date.
//  Undefined - cannot extract date from signature data.
//
Function SigningDate(Signature, CastToSessionTimeZone = True) Export
	
	DataReading = New DataReader(Signature);
	ReadingResult = DataReading.Read();
	Buffer = ReadingResult.GetBinaryDataBuffer();
	SigningDate = DigitalSignatureInternalClientServer.SigningDateUniversal(Buffer);
	
	If SigningDate = Undefined Then
		Return Undefined;
	EndIf;
	
	If CastToSessionTimeZone Then
		SigningDate = ToLocalTime(SigningDate, SessionTimeZone());
	EndIf;
	
	Return SigningDate;
	
EndFunction

// Searches for a certificate in the catalog and returns a reference if the certificate is found.
//
// Parameters:
//  Certificate - CryptoCertificate - a certificate.
//             - BinaryData - certificate binary data.
//             - String (28) - a certificate thumbprint in the Base64 format.
//             - String      - an address of a temporary storage that contains certificate binary data.
//
// Returns:
//  Undefined - a certificate is not found in the catalog.
//  CatalogRef.DigitalSignatureAndEncryptionKeysCertificates - a reference to the found certificate.
//
Function CertificateRef(Val Certificate) Export
	
	If TypeOf(Certificate) = Type("String") AND IsTempStorageURL(Certificate) Then
		Certificate = GetFromTempStorage(Certificate);
	EndIf;
	
	If TypeOf(Certificate) = Type("BinaryData") Then
		Certificate = New CryptoCertificate(Certificate);
	EndIf;
	
	If TypeOf(Certificate) = Type("CryptoCertificate") Then
		ThumbprintAsString = Base64String(Certificate.Thumbprint);
	Else
		ThumbprintAsString = String(Certificate);
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Thumbprint", ThumbprintAsString);
	Query.Text =
	"SELECT
	|	Certificates.Ref AS Ref
	|FROM
	|	Catalog.DigitalSignatureAndEncryptionKeysCertificates AS Certificates
	|WHERE
	|	Certificates.Thumbprint = &Thumbprint";
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		Return Selection.Ref;
	EndIf;
	
	Return Undefined;
	
EndFunction

// Allows you to create and update the DigitalSignatureAndEncryptionKeysCertificates catalog item by 
// the specified crypto certificate.
//
// Parameters:
//  Certificate - CryptoCertificate - a certificate.
//             - BinaryData - certificate binary data.
//             - String - an address of a temporary storage that contains certificate binary data.
//
//  AdditionalParameters - Undefined - without additional parameters.
//    - Structure - with an arbitrary composition of the following properties:
//      * Description - String - a certificate presentation in the list.
//
//      * User - CatalogRef.User - a user who owns the certificate.
//                       The value is used when receiving a list of personal user certificates in 
//                       the forms of signing and data encryption.
//
//      * Company  - CatalogRef.Company - a company that owns the certificate.
//
//      * Application - CatalogRef.DigitalSignatureAndEncryptionApplications - an application that 
//                      is required for signature and encryption.
//
//      * StrongPrivateKeyProtection - Boolean - a certificate was installed on the computer with 
//                      strong private key protection, which means that only a blank password is 
//                      supported at 1C:Enterprise level (no password is requested from the user; 
//                      this is done by the operating system that does not accept a non-blank password from 1C:Enterprise).
//
// Returns:
//  CatalogRef.DigitalSignatureAndEncryptionKeysCertificates - a reference to the certificate.
// 
Function WriteCertificateToCatalog(Val Certificate, AdditionalParameters = Undefined) Export
	
	If TypeOf(AdditionalParameters) <> Type("Structure") Then
		AdditionalParameters = New Structure;
	EndIf;
	
	If TypeOf(Certificate) = Type("String") AND IsTempStorageURL(Certificate) Then
		CertificateBinaryData = GetFromTempStorage(Certificate);
	
	ElsIf TypeOf(Certificate) = Type("BinaryData") Then
		CertificateBinaryData = Certificate;
	EndIf;
	
	If CertificateBinaryData = Undefined Then
		CryptoCertificate = Certificate;
		CertificateBinaryData = CryptoCertificate.Unload();
	Else
		CryptoCertificate = New CryptoCertificate(CertificateBinaryData);
	EndIf;
	
	CertificateReference = CertificateRef(Certificate);
	
	If ValueIsFilled(CertificateReference) Then
		CertificateObject = CertificateReference.GetObject();
		UpdateValue(CertificateObject.DeletionMark, False);
	Else
		CertificateObject = Catalogs.DigitalSignatureAndEncryptionKeysCertificates.CreateItem();
		CertificateObject.CertificateData = New ValueStorage(CertificateBinaryData);
		CertificateObject.Thumbprint = Base64String(CryptoCertificate.Thumbprint);
		
		CertificateObject.Added = Users.AuthorizedUser();
	EndIf;
	
	If CertificateObject.CertificateData.Get() <> CertificateBinaryData Then
		CertificateObject.CertificateData = New ValueStorage(CertificateBinaryData);
	EndIf;
	
	CertificateProperties = CertificateProperties(CryptoCertificate);
	UpdateValue(CertificateObject.Signing,     CertificateProperties.Signing);
	UpdateValue(CertificateObject.Encryption,     CertificateProperties.Encryption);
	UpdateValue(CertificateObject.IssuedTo,      CertificateProperties.IssuedTo);
	UpdateValue(CertificateObject.IssuedBy,       CertificateProperties.IssuedBy);
	UpdateValue(CertificateObject.ValidBefore, CertificateProperties.ValidTo);
	
	SubjectProperties = CertificateSubjectProperties(CryptoCertificate);
	UpdateValue(CertificateObject.LastName,   SubjectProperties.LastName,     True);
	UpdateValue(CertificateObject.Name,       SubjectProperties.Name,         True);
	UpdateValue(CertificateObject.Firm,     SubjectProperties.Company, True);
	If SubjectProperties.Property("MiddleName") Then
		UpdateValue(CertificateObject.MiddleName,  SubjectProperties.MiddleName,    True);
	EndIf;	
	If SubjectProperties.Property("JobPosition") Then
		UpdateValue(CertificateObject.JobPosition, SubjectProperties.JobPosition,   True);
	EndIf;	
	
	If CertificateObject.IsNew()
	   AND Not AdditionalParameters.Property("Description") Then
		
		AdditionalParameters.Insert("Description",
			CertificatePresentation(CryptoCertificate));
	EndIf;
	
	For Each KeyAndValue In AdditionalParameters Do
		UpdateValue(CertificateObject[KeyAndValue.Key], KeyAndValue.Value);
	EndDo;
	
	If CertificateObject.Modified() Then
		CertificateObject.Write();
	EndIf;
	
	Return CertificateObject.Ref;
	
EndFunction

// Returns a spreadsheet document that contains a digital signature visualization stamp.
//
// Parameters:
//  Certificate   - CryptoCertificate - a certificate the document is signed with.
//  SignatureDate  - Date - a date of signing the document.
//  MarkText - String - a text that appears directly below the stamp and describes the location of 
//                          the original document.
//  CompanyLogo - Picture - if it is not specified, the standard picture will be used.
//
// Returns:
//  SpreadsheetDocument - a spreadsheet document that contains the ready digital signature stamp.
//
Function DigitalSignatureVisualizationStamp(Certificate, SignatureDate = Undefined, MarkText = "", CompanyLogo = Undefined) Export
	
	CertificateProperties = CertificateProperties(Certificate);
	
	ActionPeriod = NStr("ru = 'с %1 по %2'; en = 'from %1 to %2'; pl = 'from %1 to %2';de = 'from %1 to %2';ro = 'from %1 to %2';tr = 'from %1 to %2'; es_ES = 'from %1 to %2'");
	ActionPeriod = StringFunctionsClientServer.SubstituteParametersToString(ActionPeriod,
		Format(CertificateProperties.ValidFrom,    "DLF=D"),
		Format(CertificateProperties.ValidTo, "DLF=D"));
	
	Stamp = Catalogs.DigitalSignatureAndEncryptionKeysCertificates.GetTemplate("Stamp");
	
	Stamp.Parameters.SignatureDate         = SignatureDate;
	Stamp.Parameters.CertificateNumber    = CertificateProperties.SerialNumber;
	Stamp.Parameters.CertificateIssuedBy     = CertificateProperties.IssuedBy;
	Stamp.Parameters.CertificateOwner = CertificateProperties.IssuedTo;
	Stamp.Parameters.ValidityPeriod        = ActionPeriod;
	Stamp.Parameters.MarkText        = MarkText;
	
	If CompanyLogo <> Undefined Then
		Stamp.Areas.Picture.Picture = CompanyLogo;
	EndIf;
	
	Return Stamp;
	
EndFunction

// Places stamps to the passed spreadsheet document.
//
// Parameters:
//  Document        - SpreadsheetDocument - a spreadsheet document to add stamps to.
//  StampsDetails - Array - an array of spreadsheet documents that contain stamps got by the 
//                             DigitalSignature.DigitalSignatureVisualizationStamp function.
//                             In this case, the passed stamps will be output to the end of the 
//                             document if the template of the spreadsheet document to be signed 
//                             does not define areas for placing stamps that meet the following conditions:
//                                - the stamp output area of two columns and seven rows, with an 
//                                  arbitrary column width,
//                                - the area name is specified as DSStamp + stamp sequence number, 
//                                  for example, DSStamp1 and so on.
//                             In this case, stamps will be output in the specified areas, in the 
//                             order in which the document was signed.
//                  - Map - describes stamp output locations, where:
//                       * Key     - String - an area name, where the stump must be put. For such an 
//                                    area, an arbitrary column width different from the column 
//                                    width of the rest of the document, must be set.
//                       * Value - SpreadsheetDocument - a stamp got by the
//                                       DigitalSignature.DigitalSignatureVisualizationStamp function.
//  Sizes         - Structure - an optional parameter that allows to change stamp size and has the following properties:
//                       * LeftColumn  - Number - width of the left stamp column that contains property titles.
//                                                 The default value is 10.
//                       * RightColumn - Number - width of the right stamp column that contains property titles.
//                                                 The default value is 30.
//
Procedure AddStampsToSpreadsheetDocument(Document, StampsDetails, Sizes = Undefined) Export
	
	If Sizes = Undefined Then
		Sizes = New Structure;
		Sizes.Insert("LeftColumn", 10);
		Sizes.Insert("RightColumn", 30);
	EndIf;
	
	If TypeOf(StampsDetails) = Type("Array") Then
		StampIndex = 1;
		For Each Stamp In StampsDetails Do
			AreaName = "DigitalSignatureStamp" + String(StampIndex);
			AreaFound = Document.Areas.Find(AreaName) <> Undefined;
			
			If AreaFound Then
				Document.InsertArea(Stamp.Areas.Stamp, Document.Areas[AreaName],, True);
				Document.Areas.StampLeftColumn.ColumnWidth  = Sizes.LeftColumn;
				Document.Areas.StampRightColumn.ColumnWidth = Sizes.RightColumn;
			Else
				Document.Put(Stamp.GetArea("Indent"));
				Document.Put(Stamp.GetArea("RowsAreaStamp"));
				Document.Areas.RowsAreaStamp.ColumnWidth = 10;
				
				Document.Areas.StampLeftColumn.ColumnWidth  = Sizes.LeftColumn;
				Document.Areas.StampRightColumn.ColumnWidth = Sizes.RightColumn;
				Document.Areas.StampIndent.ColumnWidth       = 3;
			EndIf;
			
			StampIndex = StampIndex + 1;
		EndDo;
	Else
		For Each StampDetails In StampsDetails Do
			AreaName = StampDetails.Key;
			Stamp      = StampDetails.Value;
			AreaFound = Document.Areas.Find(AreaName) <> Undefined;
			If AreaFound Then
				Document.InsertArea(Stamp.Areas.Stamp, Document.Areas[AreaName],, True);
				Document.Areas.StampLeftColumn.ColumnWidth  = Sizes.LeftColumn;
				Document.Areas.StampRightColumn.ColumnWidth = Sizes.RightColumn;
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

// See DigitalSignatureClient.CertificatePresentation. 
Function CertificatePresentation(Certificate) Export
	
	Return DigitalSignatureInternalClientServer.CertificatePresentation(Certificate,
		DigitalSignatureInternal.TimeAddition(), ModuleLocalization());
	
EndFunction

// See DigitalSignatureClient.SubjectPresentation. 
Function SubjectPresentation(Certificate) Export
	
	Return DigitalSignatureInternalClientServer.SubjectPresentation(Certificate, ModuleLocalization());
	
EndFunction

// See DigitalSignatureClient.IssuerPresentation. 
Function IssuerPresentation(Certificate) Export
	
	Return DigitalSignatureInternalClientServer.IssuerPresentation(Certificate, ModuleLocalization());
	
EndFunction

// See DigitalSignatureClient.CertificateProperties. 
Function CertificateProperties(Certificate) Export
	
	Return DigitalSignatureInternalClientServer.CertificateProperties(Certificate,
		DigitalSignatureInternal.TimeAddition(), ModuleLocalization());
	
EndFunction

// See DigitalSignatureClient.CertificateSubjectProperties. 
Function CertificateSubjectProperties(Certificate) Export
	
	Return DigitalSignatureInternalClientServer.CertificateSubjectProperties(Certificate, ModuleLocalization());
	
EndFunction

// See DigitalSignatureClient.CertificateIssuerProperties. 
Function CertificateIssuerProperties(Certificate) Export
	
	Return DigitalSignatureInternalClientServer.CertificateIssuerProperties(Certificate, ModuleLocalization());
	
EndFunction

#Region ForCallsFromOtherSubsystems

// OnlineInteraction

// These procedures and functions are used for integration with the 1C:Electronic document library.

// Returns a crypto manager (on the server) for the specified application.
//
// Parameters:
//  Operation       - String - if it is not blank, it needs to contain one of rows that determine 
//                   the operation to insert into the error description: Signing, SignatureCheck, Encryption,
//                   Decryption, CertificateCheck, and GetCertificates.
//
//  ShowError - Boolean - if True, throw an exception that contains the error description.
//
//  ErrorDescription - String - an error description that is returned when the function returns Undefined.
//
//  Application      - Undefined - returns a crypto manager of the first application from the 
//                   catalog for which it was possible to create it.
//                 - CatalogRef.DigitalSignatureAndEncryptionApplications - an application that 
//                   requires creating and returning a crypto manager.
//
// Returns:
//   CryptoManager - a crypto manager.
//   Undefined - an error occurred. The error description is in the ErrorDescription parameter.
//
Function CryptoManager(Operation, ShowError = True, ErrorDescription = "", Application = Undefined) Export
	
	Error = "";
	Result = DigitalSignatureInternal.CryptoManager(Operation, ShowError, Error, Application);
	
	If Result = Undefined Then
		ErrorDescription = Error;
	EndIf;
	
	Return Result;
	
EndFunction

// Checks the validity of the signature and the certificate.
// For operations using platform tools only (CryptoManager).
//
// Parameters:
//   CryptoManager - Undefined - get a crypto manager to check digital signatures as it was 
//                          configured by the administrator.
//                        - CryptoManager - use the specified crypto manager.
//
//   SourceData       - BinaryData - binary data that was signed.
//                        - String         - an address of a temporary storage that contains binary data.
//                        - String         - a full name of a file that contains signed binary data.
//                                           
//                        - Structure - with the following properties:
//                          * XMLDSigParameters - Structure - as the XMLDSigParameters function of 
//                                                           the DigitalSignature common module returns.
//                          * SOAPEnvelope      - String - a <soap:Envelope> message template.
//
//   Signature              - BinaryData - digital signature binary data.
//                        - String         - an address of a temporary storage that contains binary data.
//                        - String         - a full name of a file that contains digital signature 
//                                           binary data.
//                        - Undefined   - if SourceData is a SOAP envelope.
//
//   ErrorDescription       - Null - raise an exception if an error occurs during the check.
//                        - String - contains an error description if an error occurred.
// 
//   OnDate               - Date - check the certificate on the specified date if the date cannot be 
//                          extracted from the signature.
//                          If the parameter is not filled in, check on the current session date if 
//                          the date cannot be extracted from the signature.
//
// Returns:
//  Boolean - True if the check is completed successfully.
//         - False if the crypto manager is not received (because it is not specified) or an error 
//                   specified in the ErrorDescription parameter has occurred.
//
Function VerifySignature(CryptoManager, SourceData, Signature, ErrorDescription = Null, OnDate = Undefined) Export
	
	CryptoManagerToCheck = CryptoManager;
	If CryptoManagerToCheck = Undefined Then
		CryptoManagerToCheck = CryptoManager("SignatureCheck", ErrorDescription = Null, ErrorDescription);
		If CryptoManagerToCheck = Undefined Then
			Return False;
		EndIf;
	EndIf;
	
	SourceDataToCheck = SourceData;
	If TypeOf(SourceData) = Type("String") AND IsTempStorageURL(SourceData) Then
		SourceDataToCheck = GetFromTempStorage(SourceData);
	EndIf;
	
	SignatureToCheck = Signature;
	If TypeOf(Signature) = Type("String") AND IsTempStorageURL(Signature) Then
		SignatureToCheck = GetFromTempStorage(Signature);
	EndIf;
	
	If TypeOf(SourceDataToCheck) = Type("Structure")
		AND SourceDataToCheck.Property("XMLDSigParameters") Then
		
		Try
			Result = DigitalSignatureInternal.VerifySignature(
				SourceDataToCheck.SOAPEnvelope,
				SourceDataToCheck.XMLDSigParameters,
				CryptoManagerToCheck);
		Except
			ErrorDescription = BriefErrorDescription(ErrorInfo());
			Return False;
		EndTry;
		
		Certificate     = Result.Certificate;
		SigningDate = Result.SigningDate;
		
	Else
		
		Certificate = Undefined;
		Try
			CryptoManagerToCheck.VerifySignature(SourceDataToCheck, SignatureToCheck, Certificate);
		Except
			If ErrorDescription = Null Then
				Raise;
			EndIf;
			ErrorDescription = BriefErrorDescription(ErrorInfo());
			Return False;
		EndTry;
		
		SigningDate = SigningDate(SignatureToCheck);
		If Not ValueIsFilled(SigningDate) Then
			SigningDate = OnDate;
		EndIf;
		
	EndIf;
	
	Return CheckCertificate(CryptoManagerToCheck, Certificate, ErrorDescription, SigningDate);
	
EndFunction

// Checks the crypto certificate validity.
// For operations using platform tools only (CryptoManager).
//
// Parameters:
//   CryptoManager - Undefined - get the crypto manager automatically.
//                        - CryptoManager - use the specified crypto manager.
//
//   Certificate           - CryptoCertificate - a certificate.
//                        - BinaryData - certificate binary data.
//                        - String - an address of a temporary storage that contains certificate binary data.
//
//   ErrorDescription       - Null - raise an exception if an error occurs during the check.
//                        - String - contains an error description if an error occurred.
//
//   OnDate               - Date - check the certificate on the specified date.
//                          If parameter is not specified or a blank date is specified, check on the 
//                          current session date.
//
// Returns:
//  Boolean - True if the check is completed successfully,
//         - False if the crypto manager is not received (because it is not specified).
//
Function CheckCertificate(CryptoManager, Certificate, ErrorDescription = Null, OnDate = Undefined) Export
	
	CryptoManagerToCheck = CryptoManager;
	
	If CryptoManagerToCheck = Undefined Then
		CryptoManagerToCheck = CryptoManager("CertificateCheck", ErrorDescription = Null, ErrorDescription);
		If CryptoManagerToCheck = Undefined Then
			Return False;
		EndIf;
	EndIf;
	
	CertificateToCheck = Certificate;
	
	If TypeOf(Certificate) = Type("String") Then
		CertificateToCheck = GetFromTempStorage(Certificate);
	EndIf;
	
	If TypeOf(CertificateToCheck) = Type("BinaryData") Then
		CertificateToCheck = New CryptoCertificate(CertificateToCheck);
	EndIf;
	
	CertificateCheckModes = DigitalSignatureInternalClientServer.CertificateCheckModes(
		ValueIsFilled(OnDate));
	
	Try
		CryptoManagerToCheck.CheckCertificate(CertificateToCheck, CertificateCheckModes);
	Except
		ErrorDescription = BriefErrorDescription(ErrorInfo());
		Return False;
	EndTry;
	
	OverdueError = DigitalSignatureInternalClientServer.CertificateOverdue(CertificateToCheck,
		OnDate, DigitalSignatureInternal.TimeAddition());
	
	If ValueIsFilled(OverdueError) Then
		ErrorDescription = OverdueError;
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

// Finds a certificate on the computer by a thumbprint string.
// For operations using platform tools only (CryptoManager).
//
// Parameters:
//   Thumbprint              - String - a Base64 coded certificate thumbprint.
//   InPersonalStorageOnly - Boolean - if True, search in the personal storage, otherwise, search everywhere.
//
// Returns:
//   CryptoCertificate - a certificate of digital signature and encryption.
//   Undefined - a certificate is not found in the storage.
//
Function GetCertificateByThumbprint(Thumbprint, InPersonalStorageOnly) Export
	
	Return DigitalSignatureInternal.GetCertificateByThumbprint(Thumbprint, InPersonalStorageOnly);
	
EndFunction

// Allows you to fill in the DigitalSignatureAndEncryptionApplications catalog, for example, upon infobase update.
// For operations using platform tools only (CryptoManager).
//
// Complements the standard list of two applications: ViPNet and CryptoPro.
// If an application with the specified name and type already exists, its properties are refilled 
// with the specified ones. The correctness of the specified properties is not checked upon filling.
//
// When filling, you can use the supplied application details, the list of which is in the 
// ApplicationsSettingsToSupply of the DigitalSignatureAndEncryptionApplications catalog manager 
// module.
//
// Parameters:
//  ApplicationsDetails - Array - contains values of the Structure type. See DigitalSignature. NewApplicationDetails.
//                              Structure properties:
//   * ApplicationName  - String - a unique application name given by its developer, for example, 
//                       Signal-COM CPGOST Cryptographic Provider.
//   * ApplicationType  - Number - a special number that describes an application type and 
//                       complements the application name, for example, 75.
//
//   The following parameters are required if Name and Type of the application, whose details are 
//   not supplied, are specified or individual properties need to be updated.
//
//   * Presentation       - String - an application name that a user will see, for example, 
//                             Signal-COM CSP (RFC 4357).
//   * SignAlgorithm     - String - a name of the signature algorithm that the specified application 
//                             supports, for example, ECR3410-CP.
//   * HashAlgorithm - String - a name of the data hash algorithm that the specified application 
//                             supports, for example, ENG-HASH-CP. Used to create data on signature 
//                             generation with the signing algorithm.
//   * EncryptionAlgorithm  - String - a name of the encryption algorithm that the specified 
//                             application supports, for example, GOST28147.
//
// Example:
//	ApplicationsDetails = New Array;
//	
//	// Filling in additional application Signal-COM CSP (RFC 4357).
//	ApplicationDetails = DigitalSignature.NewApplicationDetails();
//	ApplicationDetails.ApplicationName = Signal-COM CPGOST Cryptographic Provider;
//	ApplicationDetails.ApplicationType = 75;
//	ApplicationsDetails.Add(ApplicationDetails);
//	
//	// Changing the supplied application ViPNet CSP algorithm.
//	ApplicationDetails = DigitalSignature.NewApplicationDetails();
//	ApplicationDetails.ApplicationName = Infotecs Cryptographic Service Provider;
//	ApplicationDetails.ApplicationType = 2;
//	ApplicationDetails.SignAlgorithm = GOST 34.10-2012 512;
//	ApplicationsDetails.Add(ApplicationDetails);
//	
//	DigitalSignature.FillApplicationsList(ApplicationsDetails);
//
Procedure FillApplicationsList(ApplicationsDetails) Export
	
	SettingsToSupply = Catalogs.DigitalSignatureAndEncryptionApplications.ApplicationsSettingsToSupply();
	
	InfobaseUpdateInProgress =
		    InfobaseUpdate.InfobaseUpdateInProgress()
		Or InfobaseUpdate.IsCallFromUpdateHandler();
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Applications.Ref AS Ref,
	|	Applications.ApplicationName,
	|	Applications.ApplicationType
	|FROM
	|	Catalog.DigitalSignatureAndEncryptionApplications AS Applications";
	
	Lock = New DataLock;
	Lock.Add("Catalog.DigitalSignatureAndEncryptionApplications");
	
	BeginTransaction();
	Try
		Lock.Lock();
		DataExported = Query.Execute().Unload();
		
		For Each ApplicationDetails In ApplicationsDetails Do
			Filter = New Structure;
			Filter.Insert("ApplicationName", ApplicationDetails.ApplicationName);
			Filter.Insert("ApplicationType", ApplicationDetails.ApplicationType);
			
			Rows = DataExported.FindRows(Filter);
			If Rows.Count() > 0 Then
				ApplicationObject = Rows[0].Ref.GetObject();
			Else
				ApplicationObject = Catalogs.DigitalSignatureAndEncryptionApplications.CreateItem();
			EndIf;
			UpdateValue(ApplicationObject.DeletionMark, False);
			
			Rows = SettingsToSupply.FindRows(Filter);
			For Each KeyAndValue In ApplicationDetails Do
				FieldName = ?(KeyAndValue.Key = "Presentation", "Description", KeyAndValue.Key);
				If KeyAndValue.Value <> Undefined Then
					UpdateValue(ApplicationObject[FieldName], KeyAndValue.Value, True);
				ElsIf Rows.Count() > 0 Then
					UpdateValue(ApplicationObject[FieldName], Rows[0][KeyAndValue.Key], True);
				EndIf;
			EndDo;
			
			If Not ApplicationObject.Modified() Then
				Continue;
			EndIf;
			
			If InfobaseUpdateInProgress Then
				InfobaseUpdate.WriteData(ApplicationObject);
			Else
				ApplicationObject.Write();
			EndIf;
		EndDo;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// To use in the DigitalSignature.FillApplicationsList procedure.
// For operations using platform tools only (CryptoManager).
//
// Parameters:
//  ApplicationName - String - a name of the digital signature and encryption application.
//  ApplicationType - String - an application type.
//
// Returns:
//  Structure - to pass in the DigitalSignature.FillApplicationsList procedure (see the property 
//              details in it).
//
Function NewApplicationDetails(ApplicationName = Undefined, ApplicationType = Undefined) Export
	
	ApplicationDetails = New Structure;
	ApplicationDetails.Insert("ApplicationName", ApplicationName);
	ApplicationDetails.Insert("ApplicationType", ApplicationType);
	ApplicationDetails.Insert("Presentation");
	ApplicationDetails.Insert("SignAlgorithm");
	ApplicationDetails.Insert("HashAlgorithm");
	ApplicationDetails.Insert("EncryptAlgorithm");
	
	Return ApplicationDetails;
	
EndFunction

// See DigitalSignatureClient.XMLDSigParameters. 
Function XMLDSigParameters() Export
	
	Return DigitalSignatureInternalClientServer.XMLDSigParameters();
	
EndFunction

// End OnlineInteraction

#EndRegion

#EndRegion

#Region Internal

// Extracts certificates from signature data.
//
// Parameters:
//   Signature - BinaryData - a signature file.
//
// Returns:
//   Undefined - if an error occurred when parsing.
//   Structure - signature data.
//       * Thumbprint                 - String.
//       * CertificateOwner       - String.
//       * CertificateBinaryData - BinaryData.
//       * Signature                   - ValueStorage.
//       * Certificate                - ValueStorage.
//
Function ReadSignatureData(Signature) Export
	
	Result = Undefined;
	
	CryptoManager = CryptoManager("GetCertificates");
	If CryptoManager = Undefined Then
		Return Result;
	EndIf;
	
	Try
		Certificates = CryptoManager.GetCertificatesFromSignature(Signature);
	Except
		Return Result;
	EndTry;
	
	If Certificates.Count() > 0 Then
		Certificate = Certificates[0];
		
		Result = New Structure;
		Result.Insert("Thumbprint", Base64String(Certificate.Thumbprint));
		Result.Insert("CertificateOwner", SubjectPresentation(Certificate));
		Result.Insert("CertificateBinaryData", Certificate.Unload());
		Result.Insert("Signature", New ValueStorage(Signature));
		Result.Insert("Certificate", New ValueStorage(Certificate.Unload()));
	EndIf;
	
	Return Result;
	
EndFunction

// Returns the current user settings to work with the digital signature.
//
// Returns:
//   Structure - personal settings to work with the digital signature.
//       * ActionsOnSaveWithDS - String - what to do when saving files with a digital signature:
//           ** Ask - show the signature selection dialog box to save a signature.
//           ** SaveAllSignatures - all signatures, always.
//       * DigitalSignatureAndEncryptionApplicationsPaths - Map - where:
//           ** Key     - CatalogRef.DigitalSignatureAndEncryptionApplications - an application.
//           ** Value - String - an application path on the user computer.
//       * ExtensionForSignatureFiles - String - an extension for DS files.
//       * ExtensionForEncryptedFiles - String - an extension for encrypted files.
//
// See also:
//   CommonForm.DigitalSignatureAndEncryptionSettings - a location to determine these parameters and 
//   their text descriptions.
//
Function PersonalSettings() Export
	
	PersonalSettings = New Structure;
	// Initial values.
	PersonalSettings.Insert("ActionsOnSavingWithDS", "Prompt");
	PersonalSettings.Insert("PathsToDigitalSignatureAndEncryptionApplications", New Map);
	PersonalSettings.Insert("SignatureFilesExtension", "p7s");
	PersonalSettings.Insert("EncryptedFilesExtension", "p7m");
	PersonalSettings.Insert("SaveCertificateWithSignature", False);
	
	SubsystemKey = DigitalSignatureInternal.SettingsStorageKey();
	
	For Each KeyAndValue In PersonalSettings Do
		SavedValue = Common.CommonSettingsStorageLoad(SubsystemKey,
			KeyAndValue.Key);
		
		If ValueIsFilled(SavedValue)
		   AND TypeOf(KeyAndValue.Value) = TypeOf(SavedValue) Then
			
			PersonalSettings.Insert(KeyAndValue.Key, SavedValue);
		EndIf;
	EndDo;
	
	Return PersonalSettings;
	
EndFunction

#EndRegion

#Region Private

// Returns common settings of all users to work with the digital signature.
//
// Returns:
//   Structure - common subsystem settings to work with the digital signature.
//     * UseDigitalSignatures       - Boolean - if True, digital signatures are used.
//     * UseEncryption               - Boolean - if True, encryption is used.
//     * CheckDigitalSignaturesAtServer - Boolean - if True, digital signatures and certificates are 
//                                                       checked on the server.
//     * CreateDigitalSignaturesAtServer - Boolean - if True, digital signatures are created on the 
//                                                       server, and if creation failed, they are created on the client.
//
// See also:
//   CommonForm.DigitalSignatureAndEncryptionSettings - a location to determine these parameters and 
//   their text descriptions.
//
Function CommonSettings() Export
	
	Return DigitalSignatureInternalCached.CommonSettings();
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Auxiliary procedures and functions.

// For the AddSignature procedure.
Procedure AddSignatureString(DataObject, SignatureProperties, EventLogMessage)
	
	SetPrivilegedMode(True);
	
	NewRecord = InformationRegisters.DigitalSignatures.CreateRecordManager();
	
	FillPropertyValues(NewRecord, SignatureProperties, , "Signature, Certificate");
	
	NewRecord.SignedObject = DataObject.Ref;
	NewRecord.Signature    = New ValueStorage(SignatureProperties.Signature);
	NewRecord.Certificate = New ValueStorage(SignatureProperties.Certificate);
	
	SequenceNumber = 1;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	COUNT(DigitalSignatures.SignedObject) AS LastSequenceNumber
	|FROM
	|	InformationRegister.DigitalSignatures AS DigitalSignatures
	|WHERE
	|	DigitalSignatures.SignedObject = &SignedObject";
	
	Query.SetParameter("SignedObject", DataObject.Ref);
	
	QueryResult = Query.Execute();
	
	DetailedRecordsSelection = QueryResult.Select();
	
	While DetailedRecordsSelection.Next() Do
		SequenceNumber = DetailedRecordsSelection.LastSequenceNumber + 1;
	EndDo;
	
	NewRecord.SequenceNumber = SequenceNumber;
	
	If Not ValueIsFilled(NewRecord.SignatureSetBy) Then
	 	NewRecord.SignatureSetBy = Users.AuthorizedUser();
	EndIf;
	
	SignatureDate = SigningDate(SignatureProperties.Signature);
	
	If SignatureDate <> Undefined Then
		NewRecord.SignatureDate = SignatureDate;
	
	ElsIf Not ValueIsFilled(NewRecord.SignatureDate) Then
		NewRecord.SignatureDate = CurrentSessionDate();
	EndIf;
	
	EventLogMessage = DigitalSignatureInternal.SignatureInfoForEventLog(
		NewRecord.SignatureDate, SignatureProperties);
	
	NewRecord.Write();
	
	WriteLogEvent(
		NStr("ru = 'Электронная подпись.Добавление подписи'; en = 'Digital signature.Add signature'; pl = 'Digital signature.Add signature';de = 'Digital signature.Add signature';ro = 'Digital signature.Add signature';tr = 'Digital signature.Add signature'; es_ES = 'Digital signature.Add signature'", Common.DefaultLanguageCode()),
		EventLogLevel.Information,
		DataObject.Metadata(),
		DataObject.Ref,
		EventLogMessage,
		EventLogEntryTransactionMode.Transactional);
	
EndProcedure

// For the DeleteSignature procedure.
Procedure DeleteSignatureString(SignedObject, SequenceNumber, EventLogMessage)
	
	IsFullUser = Users.IsFullUser();
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	DigitalSignatures.SequenceNumber AS SequenceNumber,
	|	DigitalSignatures.SignedObject AS SignedObject
	|FROM
	|	InformationRegister.DigitalSignatures AS DigitalSignatures
	|WHERE
	|	DigitalSignatures.SequenceNumber = &SequenceNumber
	|	AND DigitalSignatures.SignedObject = &SignedObject";
	
	Query.SetParameter("SequenceNumber",   SequenceNumber);
	Query.SetParameter("SignedObject", SignedObject.Ref);
	
	QueryResult = Query.Execute();
	
	DetailedRecordsSelection = QueryResult.Select();
	
	If DetailedRecordsSelection.Count() = 0 Then
		Raise NStr("ru = 'Строка с подписью не найдена.'; en = 'String with signature was not found.'; pl = 'String with signature was not found.';de = 'String with signature was not found.';ro = 'String with signature was not found.';tr = 'String with signature was not found.'; es_ES = 'String with signature was not found.'");
	EndIf;
	
	RecordManager = InformationRegisters.DigitalSignatures.CreateRecordManager();
	While DetailedRecordsSelection.Next() Do
		FillPropertyValues(RecordManager, DetailedRecordsSelection);
	EndDo;
	RecordManager.Read();
	
	HasRights = IsFullUser
		Or RecordManager.SignatureSetBy = Users.AuthorizedUser();
	
	SignatureProperties = New Structure;
	SignatureProperties.Insert("Certificate",          RecordManager.Certificate.Get());
	SignatureProperties.Insert("CertificateOwner", RecordManager.CertificateOwner);
	
	EventLogMessage = DigitalSignatureInternal.SignatureInfoForEventLog(
		RecordManager.SignatureDate, SignatureProperties);
	
	If HasRights Then
		RecordManager.Delete();
	Else
		Raise NStr("ru = 'Недостаточно прав на удаление подписи.'; en = 'Insufficient rights to delete the signature.'; pl = 'Insufficient rights to delete the signature.';de = 'Insufficient rights to delete the signature.';ro = 'Insufficient rights to delete the signature.';tr = 'Insufficient rights to delete the signature.'; es_ES = 'Insufficient rights to delete the signature.'");
	EndIf;
	
	WriteLogEvent(
		NStr("ru = 'Электронная подпись.Удаление подписи'; en = 'Digital signature.Delete signature'; pl = 'Digital signature.Delete signature';de = 'Digital signature.Delete signature';ro = 'Digital signature.Delete signature';tr = 'Digital signature.Delete signature'; es_ES = 'Digital signature.Delete signature'", Common.DefaultLanguageCode()),
		EventLogLevel.Information,
		SignedObject.Metadata(),
		SignedObject.Ref,
		EventLogMessage,
		EventLogEntryTransactionMode.Transactional);
	
EndProcedure

// For the DeleteSignature procedure.
Procedure RefreshSignaturesNumbering(SignedObject)
	
	SetPrivilegedMode(True);
	
	SignedWithDS = False;
	
	RecordSet = InformationRegisters.DigitalSignatures.CreateRecordSet();
	RecordSet.Filter.SignedObject.Set(SignedObject.Ref);
	RecordSet.Read();
	
	SequenceNumber = 1;
	For Each ObjectDigitalSignature In RecordSet Do
		ObjectDigitalSignature.SequenceNumber = SequenceNumber;
		SequenceNumber = SequenceNumber + 1;
		SignedWithDS = True;
	EndDo;
	
	If SignedObject.SignedWithDS <> SignedWithDS Then
		SignedObject.SignedWithDS = SignedWithDS;
	EndIf;
	
	RecordSet.Write(True);
	
	SetPrivilegedMode(False);
	
EndProcedure

// For the WriteCertificateToCatalog procedure.
Procedure UpdateValue(PreviousValue, NewValue, SkipNotDefinedValues = False)
	
	If NewValue = Undefined AND SkipNotDefinedValues Then
		Return;
	EndIf;
	
	If PreviousValue <> NewValue Then
		PreviousValue = NewValue;
	EndIf;
	
EndProcedure

Procedure CheckParameterObject(Object, ProcedureName, RefsOnly = False)
	
	CommonClientServer.CheckParameter(ProcedureName, "Object", Object,
		DigitalSignatureInternalCached.OwnersTypes(RefsOnly));
	
	If Common.SubsystemExists("StandardSubsystems.FilesOperations") Then
		ModuleFilesOperationsInternal = Common.CommonModule("FilesOperationsInternal");
		ModuleFilesOperationsInternal.CheckFileProcessed(Object, ProcedureName);
	EndIf;
	
EndProcedure

Function ModuleLocalization()
	
	If DigitalSignatureInternalCached.CommonSettings().CertificateIssueRequestAvailable Then
		Return Common.CommonModule("DigitalSignatureLocalizationClientServer");
	EndIf;
	Return Undefined;

EndFunction

#EndRegion
