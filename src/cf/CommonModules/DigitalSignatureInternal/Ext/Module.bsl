///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Adds certificates to the passed object.
Procedure AddEncryptionCertificates(ObjectRef, ThumbprintsArray) Export
	SetPrivilegedMode(True);
	
	SequenceNumber = 1;
	For Each ThumbprintStructure In ThumbprintsArray Do
		RecordManager = InformationRegisters.EncryptionCertificates.CreateRecordManager();
		RecordManager.EncryptedObject = ObjectRef;
		RecordManager.Thumbprint = ThumbprintStructure.Thumbprint;
		RecordManager.Presentation = ThumbprintStructure.Presentation;
		RecordManager.Certificate = New ValueStorage(ThumbprintStructure.Certificate);
		RecordManager.SequenceNumber = SequenceNumber;
		SequenceNumber = SequenceNumber + 1;
		RecordManager.Write();
	EndDo;

EndProcedure

// Clears records about encryption certificates after object decryption.
Procedure ClearEncryptionCertificates(ObjectRef) Export
	SetPrivilegedMode(True);
	
	RecordSet = InformationRegisters.EncryptionCertificates.CreateRecordSet();
	RecordSet.Filter.EncryptedObject.Set(ObjectRef);
	RecordSet.Write(True);

EndProcedure

// For internal use only.
Procedure RegisterSignaturesList(Form, SignaturesListName) Export
	
	Item = Form.ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(SignaturesListName);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(SignaturesListName + ".SignatureCorrect");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.SpecialTextColor);
	
EndProcedure

// Determines digital signature availability for an object (by its type)
Function DigitalSignatureAvailable(ObjectType) Export
	
	Return DigitalSignatureInternalCached.OwnersTypes().Get(ObjectType) <> Undefined;
	
EndFunction

// Returns a certificate address in the temporary storage and its extension.
//
// Parameters:
//  DigitalSignatureInfo - Structure - a string with signatures from the array received by the DigitalSIgnature.SetSignatures method.
//  UUID     - UUID - a form ID.
// 
// Returns:
//  Structure - 
//  * CertificateExtension - String - a certificate file extension.
//  * CertificateAddress      - String - an address in the temporary storage, by which the certificate was placed.
//
Function DataByCertificate(DigitalSignatureInfo, UUID) Export
	
	Result = New Structure("CertificateExtension, CertificateAddress");
	CertificateData = DigitalSignatureInfo.Certificate.Get();
		
		If TypeOf(CertificateData) = Type("String") Then
			Result.CertificateExtension = "txt";
			Result.CertificateAddress = PutToTempStorage(
				RowBinaryData(CertificateData), UUID);
		Else
			Result.CertificateExtension = "cer";
			Result.CertificateAddress = PutToTempStorage(
				CertificateData, UUID);
		EndIf;
		
	Return Result;
	
EndFunction

// Returns the capability flag of interactive use of digital signatures and encryption for the 
// current user.
//
// Returns:
//  Boolean - if True, you can use digital signatures and encryption interactively.
//
Function UseInteractiveAdditionOfDigitalSignaturesAndEncryption() Export
	Return AccessRight("InteractiveInsert", Metadata.Catalogs.DigitalSignatureAndEncryptionKeysCertificates);
EndFunction

// Names of the data files and names of their signatures are extracted from the passed file names.
// Mapping is executed according to the signature name generation and signature file extension rules (p7s).
// Example:
//  The data file name is "example.txt"
//  the signature file name is "example-Ivanov Petr.p7s"
//  the signature file name is "example-Ivanov Petr (1).p7s"
//
// Parameters:
//  FilesNames - Array - file names of the Row type.
//
// Returns:
//  Map - contains:
//   * Key     - String - a file name.
//   * Value - Array - signature file names of the Row type.
// 
Function SignaturesFilesNamesOfDataFilesNames(FileNames) Export
	
	SignatureFilesExtension = DigitalSignature.PersonalSettings().SignatureFilesExtension;
	
	Result = New Map;
	
	// Dividing files by extension.
	DataFilesNames = New Array;
	SignatureFilesNames = New Array;
	
	For Each FileName In FileNames Do
		If StrEndsWith(FileName, SignatureFilesExtension) Then
			SignatureFilesNames.Add(FileName);
		Else
			DataFilesNames.Add(FileName);
		EndIf;
	EndDo;
	
	// Sorting data file names by their length in characters, descending.
	
	For IndexA = 1 To DataFilesNames.Count() Do
		IndexMAX = IndexA; // Considering the current file name to have the biggest number of characters.
		For IndexB = IndexA+1 To DataFilesNames.Count() Do
			If StrLen(DataFilesNames[IndexMAX-1]) > StrLen(DataFilesNames[IndexB-1]) Then
				IndexMAX = IndexB;
			EndIf;
		EndDo;
		swap = DataFilesNames[IndexA-1];
		DataFilesNames[IndexA-1] = DataFilesNames[IndexMAX-1];
		DataFilesNames[IndexMAX-1] = swap;
	EndDo;
	
	// Searching for file name mapping.
	For Each DataFileName In DataFilesNames Do
		Result.Insert(DataFileName, FindSignatureFilesNames(DataFileName, SignatureFilesNames));
	EndDo;
	
	// The remaining signature files are not recognized as signatures related to a specific file.
	For Each SignatureFileName In SignatureFilesNames Do
		Result.Insert(SignatureFileName, New Array);
	EndDo;
	
	Return Result;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Configuration subsystems event handlers.

// See InfobaseUpdateSSL.OnAddUpdateHandlers. 
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.InitialFilling = True;
	Handler.Procedure = "Catalogs.DigitalSignatureAndEncryptionApplications.FillInitialSettings";
	Handler.ExecutionMode = "Exclusive";
	
	Handler = Handlers.Add();
	Handler.Version = "2.2.4.7";
	Handler.Procedure = "DigitalSignatureInternal.MoveCryptographyManagerSettings";
	Handler.ExecutionMode = "Exclusive";
	
	Handler = Handlers.Add();
	Handler.Version = "3.0.1.69";
	Handler.Comment =
		NStr("ru = 'Заполнение справочника Программы электронной подписи и шифрования.'; en = 'Populate the ""Applications of digital signature and encryption"" catalog.'; pl = 'Populate the ""Applications of digital signature and encryption"" catalog.';de = 'Populate the ""Applications of digital signature and encryption"" catalog.';ro = 'Populate the ""Applications of digital signature and encryption"" catalog.';tr = 'Populate the ""Applications of digital signature and encryption"" catalog.'; es_ES = 'Populate the ""Applications of digital signature and encryption"" catalog.'");
	Handler.ID = New UUID("8e76369a-e16c-415d-bfeb-95e7e5f07a00");
	Handler.Procedure = "Catalogs.DigitalSignatureAndEncryptionApplications.ProcessDataForMigrationToNewVersion";
	Handler.ExecutionMode = "Deferred";
	Handler.UpdateDataFillingProcedure = "Catalogs.DigitalSignatureAndEncryptionApplications.RegisterDataToProcessForMigrationToNewVersion";
	Handler.ObjectsToBeRead      = "Catalog.DigitalSignatureAndEncryptionApplications";
	Handler.ObjectsToChange    = "Catalog.DigitalSignatureAndEncryptionApplications";
	Handler.DeferredProcessingQueue = 1;
	Handler.CheckProcedure    = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	
EndProcedure

// See CommonOverridable.OnAddMetadataObjectsRenaming. 
Procedure OnAddMetadataObjectsRenaming(Total) Export
	
	Library = "StandardSubsystems";
	
	OldName = "Role.DigitalSignatureUsage";
	NewName  = "Role.DigitalSignatureUsage";
	Common.AddRenaming(Total, "2.2.1.7", OldName, NewName, Library);
	
	OldName = "Subsystem.StandardSubsystems.Subsystem.DigitalSignature";
	NewName  = "Subsystem.StandardSubsystems.Subsystem.DigitalSignature";
	Common.AddRenaming(Total, "2.2.1.7", OldName, NewName, Library);
	
	OldName = "Role.DigitalSignatureUsage";
	NewName  = "Role.DigitalSignatureAndEncryptionUsage";
	Common.AddRenaming(Total, "2.3.1.10", OldName, NewName, Library);
	
	OldName = "Role.DigitalSignatureAndEncryptionUsage";
	NewName  = "Role.AddEditDigitalSignaturesAndEncryption";
	Common.AddRenaming(Total, "2.3.3.2", OldName, NewName, Library);
	
EndProcedure

// See CommonOverridable.OnAddClientParameters. 
Procedure OnAddClientParameters(Parameters) Export
	
	If Common.SeparatedDataUsageAvailable() Then
		SubsystemSettings = New Structure;
		SubsystemSettings.Insert("PersonalSettings", DigitalSignature.PersonalSettings());
		SubsystemSettings.Insert("CommonSettings",        DigitalSignature.CommonSettings());
		SubsystemSettings = New FixedStructure(SubsystemSettings);
		Parameters.Insert("DigitalSignature", SubsystemSettings);
	EndIf;
	
EndProcedure

// See ImportDataFromFileOverridable.OnDefineCatalogsForDataImport. 
Procedure OnDefineCatalogsForDataImport(CatalogsToImport) Export
	
	// Cannot import to the DigitalSignatureAndEncryptionApplications catalog.
	TableRow = CatalogsToImport.Find(Metadata.Catalogs.DigitalSignatureAndEncryptionApplications.FullName(), "FullName");
	If TableRow <> Undefined Then 
		CatalogsToImport.Delete(TableRow);
	EndIf;
	
	// Cannot import to the DigitalSignatureAndEncryptionKeysCertificates catalog.
	TableRow = CatalogsToImport.Find(Metadata.Catalogs.DigitalSignatureAndEncryptionKeysCertificates.FullName(), "FullName");
	If TableRow <> Undefined Then 
		CatalogsToImport.Delete(TableRow);
	EndIf;
	
EndProcedure

// See BatchObjectModificationOverridable.OnDetermineObjectsWithEditableAttributes. 
Procedure OnDefineObjectsWithEditableAttributes(Objects) Export
	Objects.Insert(Metadata.Catalogs.DigitalSignatureAndEncryptionApplications.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.DigitalSignatureAndEncryptionKeysCertificates.FullName(), "AttributesToSkipInBatchProcessing");
EndProcedure

#EndRegion

#Region Private

// Returns the crypto manager (on the server) for the specified application.
//
// Parameters:
//  Operation       - String - if it is not blank, it needs to contain one of rows that determine 
//                   the operation to insert into the error description: Signing, SignatureCheck, Encryption,
//                   Decryption, CertificateCheck, and GetCertificates.
//
//  ShowError - Boolean - if True, throw an exception that contains the error description.
//
//  ErrorDescription - String - an error description that is returned when the function returns Undefined.
//                 - Structure - contains application call errors if Undefined is returned.
//                    * ErrorDescription   - String - a full error description (when returned as a string).
//                    * ErrorTitle  - String - an error title that matches the operation.
//                    * ComputerName    - String - a computer name when receiving the crypto manager.
//                    * Details         - String - a common error description.
//                    * Common            - Boolean - if True, then it contains error description 
//                                                  for all applications, otherwise, the Errors array is described alternatively.
//                    * ToAdministrator  - Boolean - administrator rights are required to patch the common error.
//                    * Errors           - Array - it contains structure of application error descriptions with the following properties:
//                         * Application       - CatalogRef.DigitalSignatureAndEncryption.
//                         * Details       - String - it contains an error presentation.
//                         * FromException    - Boolean - a description contains a brief error description.
//                         * PathNotSpecified    - Boolean - a description contains an error that a path for Linux is not specified.
//                         * ToAdministrator - Boolean - administrator rights are required to patch an error.
//
//  Application      - Undefined - returns crypto manager of the first application from the catalog, 
//                   to which it was possible to create it.
//                 - CatalogRef.DigitalSignatureAndEncryptionApplications - an application that 
//                   requires creating and returning a crypto manager.
//
// Returns:
//   CryptoManager - a crypto manager.
//   Undefined - an error occurred. The error description is in the ErrorDescription parameter.
//
Function CryptoManager(Operation, ShowError = True, ErrorDescription = "", Application = Undefined) Export
	
	ComputerName = ComputerName();
	
	Errors = New Array;
	Manager = NewCryptoManager(Application, Errors, ComputerName);
	
	If Manager <> Undefined Then
		Return Manager;
	EndIf;
	
	If Operation = "Signing" Then
		ErrorTitle = NStr("ru = 'Не удалось подписать данные на сервере %1 по причине:'; en = 'Cannot sign data on server %1 due to:'; pl = 'Cannot sign data on server %1 due to:';de = 'Cannot sign data on server %1 due to:';ro = 'Cannot sign data on server %1 due to:';tr = 'Cannot sign data on server %1 due to:'; es_ES = 'Cannot sign data on server %1 due to:'");
		
	ElsIf Operation = "SignatureCheck" Then
		ErrorTitle = NStr("ru = 'Не удалось проверить подпись на сервере %1 по причине:'; en = 'Cannot check the signature on server %1 due to:'; pl = 'Cannot check the signature on server %1 due to:';de = 'Cannot check the signature on server %1 due to:';ro = 'Cannot check the signature on server %1 due to:';tr = 'Cannot check the signature on server %1 due to:'; es_ES = 'Cannot check the signature on server %1 due to:'");
		
	ElsIf Operation = "Encryption" Then
		ErrorTitle = NStr("ru = 'Не удалось зашифровать данные на сервере %1 по причине:'; en = 'Cannot encrypt data on server %1 due to:'; pl = 'Cannot encrypt data on server %1 due to:';de = 'Cannot encrypt data on server %1 due to:';ro = 'Cannot encrypt data on server %1 due to:';tr = 'Cannot encrypt data on server %1 due to:'; es_ES = 'Cannot encrypt data on server %1 due to:'");
		
	ElsIf Operation = "Details" Then
		ErrorTitle = NStr("ru = 'Не удалось расшифровать данные на сервере %1 по причине:'; en = 'Cannot decrypt data on server %1 due to:'; pl = 'Cannot decrypt data on server %1 due to:';de = 'Cannot decrypt data on server %1 due to:';ro = 'Cannot decrypt data on server %1 due to:';tr = 'Cannot decrypt data on server %1 due to:'; es_ES = 'Cannot decrypt data on server %1 due to:'");
		
	ElsIf Operation = "CertificateCheck" Then
		ErrorTitle = NStr("ru = 'Не удалось проверить сертификат на сервере %1 по причине:'; en = 'Cannot check the certificate on server %1 due to:'; pl = 'Cannot check the certificate on server %1 due to:';de = 'Cannot check the certificate on server %1 due to:';ro = 'Cannot check the certificate on server %1 due to:';tr = 'Cannot check the certificate on server %1 due to:'; es_ES = 'Cannot check the certificate on server %1 due to:'");
		
	ElsIf Operation = "GetCertificates" Then
		ErrorTitle = NStr("ru = 'Не удалось получить сертификаты на сервере %1 по причине:'; en = 'Cannot receive certificates on server %1 due to:'; pl = 'Cannot receive certificates on server %1 due to:';de = 'Cannot receive certificates on server %1 due to:';ro = 'Cannot receive certificates on server %1 due to:';tr = 'Cannot receive certificates on server %1 due to:'; es_ES = 'Cannot receive certificates on server %1 due to:'");
		
	ElsIf Operation <> "" Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Ошибка в функции МенеджерКриптографии.
			           |Неверное значение параметра Операция ""%1"".'; 
			           |en = 'An error occurred in function CryptoManager.
			           |Incorrect value of parameter Operation ""%1"".'; 
			           |pl = 'An error occurred in function CryptoManager.
			           |Incorrect value of parameter Operation ""%1"".';
			           |de = 'An error occurred in function CryptoManager.
			           |Incorrect value of parameter Operation ""%1"".';
			           |ro = 'An error occurred in function CryptoManager.
			           |Incorrect value of parameter Operation ""%1"".';
			           |tr = 'An error occurred in function CryptoManager.
			           |Incorrect value of parameter Operation ""%1"".'; 
			           |es_ES = 'An error occurred in function CryptoManager.
			           |Incorrect value of parameter Operation ""%1"".'"), Operation);
		
	ElsIf TypeOf(ErrorDescription) = Type("Structure")
	        AND ErrorDescription.Property("ErrorTitle") Then
		
		ErrorTitle = ErrorDescription.ErrorTitle;
	Else
		ErrorTitle = NStr("ru = 'Не удалось выполнить операцию на сервере %1 по причине:'; en = 'Cannot perform the operation on server %1. Reason:'; pl = 'Cannot perform the operation on server %1. Reason:';de = 'Cannot perform the operation on server %1. Reason:';ro = 'Cannot perform the operation on server %1. Reason:';tr = 'Cannot perform the operation on server %1. Reason:'; es_ES = 'Cannot perform the operation on server %1. Reason:'");
	EndIf;
	
	ErrorTitle = StrReplace(ErrorTitle, "%1", ComputerName);
	
	ErrorProperties = New Structure;
	ErrorProperties.Insert("ErrorTitle", ErrorTitle);
	ErrorProperties.Insert("ComputerName", ComputerName);
	ErrorProperties.Insert("ToAdministrator", True);
	ErrorProperties.Insert("Total", False);
	ErrorProperties.Insert("Errors", Errors);
	
	If Errors.Count() = 0 Then
		ErrorText = NStr("ru = 'Не предусмотрено использование ни одной программы.'; en = 'Usage of no application is possible.'; pl = 'Usage of no application is possible.';de = 'Usage of no application is possible.';ro = 'Usage of no application is possible.';tr = 'Usage of no application is possible.'; es_ES = 'Usage of no application is possible.'");
		ErrorProperties.Total = True;
		ErrorProperties.Insert("Instruction", True);
		ErrorProperties.Insert("ApplicationsSetUp", True);
		
	ElsIf Application <> Undefined Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Программа ""%1"" не доступна или не установлена.'; en = 'The ""%1"" application is not available or not installed.'; pl = 'The ""%1"" application is not available or not installed.';de = 'The ""%1"" application is not available or not installed.';ro = 'The ""%1"" application is not available or not installed.';tr = 'The ""%1"" application is not available or not installed.'; es_ES = 'The ""%1"" application is not available or not installed.'"), Application);
	Else
		ErrorText = NStr("ru = 'Ни одна из программ не доступна или не установлена.'; en = 'None of the applications are available or installed.'; pl = 'None of the applications are available or installed.';de = 'None of the applications are available or installed.';ro = 'None of the applications are available or installed.';tr = 'None of the applications are available or installed.'; es_ES = 'None of the applications are available or installed.'");
	EndIf;
	ErrorProperties.Insert("Details", ErrorText);
	
	If Not Users.IsFullUser(,, False) Then
		ErrorText = ErrorText + Chars.LF + Chars.LF
			+ NStr("ru = 'Обратитесь к администратору.'; en = 'Please contact the application administrator.'; pl = 'Please contact the application administrator.';de = 'Please contact the application administrator.';ro = 'Please contact the application administrator.';tr = 'Please contact the application administrator.'; es_ES = 'Please contact the application administrator.'");
	EndIf;
	
	ErrorProperties.Insert("ErrorDescription", ErrorTitle + Chars.LF + ErrorText);
	
	If TypeOf(ErrorDescription) = Type("Structure") Then
		ErrorDescription = ErrorProperties;
	Else
		ErrorDescription = ErrorProperties.ErrorDescription;
	EndIf;
	
	If ShowError Then
		Raise ErrorText;
	EndIf;
	
	Return Undefined;
	
EndFunction

// Finds a certificate on the computer by a thumbprint string.
//
// Parameters:
//   Thumbprint              - String - a Base64 coded certificate thumbprint.
//   InPersonalStorageOnly - Boolean - if True, search in the personal storage, otherwise, search everywhere.
//
// Returns:
//   CryptoCertificate - a certificate of digital signature and encryption.
//   Undefined - certificate is not found.
//
Function GetCertificateByThumbprint(Thumbprint, InPersonalStorageOnly,
			ShowError = True, Application = Undefined, ErrorDescription = "") Export
	
	CryptoManager = CryptoManager("GetCertificates",
		ShowError, ErrorDescription, Application);
	
	If CryptoManager = Undefined Then
		Return Undefined;
	EndIf;
	
	StorageType = DigitalSignatureInternalClientServer.StorageTypeToSearchCertificate(InPersonalStorageOnly);
	
	Try
		ThumbprintBinaryData = Base64Value(Thumbprint);
	Except
		If ShowError Then
			Raise;
		EndIf;
		ErrorInformation = ErrorInfo();
		ErrorPresentation = BriefErrorDescription(ErrorInformation);
	EndTry;
	
	If Not ValueIsFilled(ErrorPresentation) Then
		Try
			CryptoCertificateStore = CryptoManager.GetCertificateStore(StorageType);
		Except
			If ShowError Then
				Raise;
			EndIf;
			ErrorInformation = ErrorInfo();
			ErrorPresentation = BriefErrorDescription(ErrorInformation);
		EndTry;
	EndIf;
	
	If Not ValueIsFilled(ErrorPresentation) Then
		Try
			Certificate = CryptoCertificateStore.FindByThumbprint(ThumbprintBinaryData);
		Except
			If ShowError Then
				Raise;
			EndIf;
			ErrorInformation = ErrorInfo();
			ErrorPresentation = BriefErrorDescription(ErrorInformation);
		EndTry;
	EndIf;
	
	If TypeOf(Certificate) = Type("CryptoCertificate") Then
		Return Certificate;
	EndIf;
	
	If ValueIsFilled(ErrorPresentation) Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Сертификат не найден на сервере по причине:
			           |%1'; 
			           |en = 'Certificate is not found on server due to: 
			           |%1'; 
			           |pl = 'Certificate is not found on server due to: 
			           |%1';
			           |de = 'Certificate is not found on server due to: 
			           |%1';
			           |ro = 'Certificate is not found on server due to: 
			           |%1';
			           |tr = 'Certificate is not found on server due to: 
			           |%1'; 
			           |es_ES = 'Certificate is not found on server due to: 
			           |%1'")
			+ Chars.LF,
			ErrorPresentation);
	Else
		ErrorText = NStr("ru = 'Сертификат не найден на сервере.'; en = 'Certificate is not found on the server.'; pl = 'Certificate is not found on the server.';de = 'Certificate is not found on the server.';ro = 'Certificate is not found on the server.';tr = 'Certificate is not found on the server.'; es_ES = 'Certificate is not found on the server.'");
	EndIf;
		
	If Not Users.IsFullUser(,, False) Then
		ErrorText = ErrorText + Chars.LF + NStr("ru = 'Обратитесь к администратору.'; en = 'Please contact the application administrator.'; pl = 'Please contact the application administrator.';de = 'Please contact the application administrator.';ro = 'Please contact the application administrator.';tr = 'Please contact the application administrator.'; es_ES = 'Please contact the application administrator.'")
	EndIf;
	
	ErrorText = TrimR(ErrorText);
	
	If TypeOf(ErrorDescription) = Type("Structure") Then
		ErrorDescription = New Structure;
		ErrorDescription.Insert("ErrorDescription", ErrorText);
	Else
		ErrorDescription = ErrorPresentation;
	EndIf;
	
	Return Undefined;
	
EndFunction

// For internal use only.
Function TimeAddition() Export
	
	Return CurrentSessionDate() - CurrentUniversalDate();
	
EndFunction

// Saves the current user settings to work with the digital signature.
Procedure SavePersonalSettings(PersonalSettings) Export
	
	SubsystemKey = SettingsStorageKey();
	
	For Each KeyAndValue In PersonalSettings Do
		Common.CommonSettingsStorageSave(SubsystemKey, KeyAndValue.Key,
			KeyAndValue.Value);
	EndDo;
	
EndProcedure

// The key that is used to store subsystem settings.
Function SettingsStorageKey() Export
	
	Return "DS"; // Do not change to DS. It is used for backward compatibility.
	
EndFunction

// For internal use only.
Procedure BeforeStartEditKeyCertificate(Ref, Certificate, AttributesParameters) Export
	
	Table = New ValueTable;
	Table.Columns.Add("AttributeName",       New TypeDescription("String"));
	Table.Columns.Add("ReadOnly",     New TypeDescription("Boolean"));
	Table.Columns.Add("FillChecking", New TypeDescription("Boolean"));
	Table.Columns.Add("Visible",          New TypeDescription("Boolean"));
	Table.Columns.Add("FillingValue");
	
	DigitalSignatureOverridable.BeforeStartEditKeyCertificate(Ref, Certificate, Table);
	
	AttributesParameters = New Structure;
	
	For each Row In Table Do
		Parameters = New Structure;
		Parameters.Insert("ReadOnly",     Row.ReadOnly);
		Parameters.Insert("FillChecking", Row.FillChecking);
		Parameters.Insert("Visible",          Row.Visible);
		Parameters.Insert("FillingValue", Row.FillingValue);
		AttributesParameters.Insert(Row.AttributeName, Parameters);
	EndDo;
	
EndProcedure

// For internal use only.
Procedure CheckPresentationUniqueness(Presentation, CertificateReference, Field, Cancel) Export
	
	If Not ValueIsFilled(Presentation) Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Ref",       CertificateReference);
	Query.SetParameter("Description", Presentation);
	
	Query.Text =
	"SELECT
	|	TRUE AS TrueValue
	|FROM
	|	Catalog.DigitalSignatureAndEncryptionKeysCertificates AS Certificates
	|WHERE
	|	Certificates.Ref <> &Ref
	|	AND Certificates.Description = &Description";
	
	If Not Query.Execute().IsEmpty() Then
		MessageText = NStr("ru = 'Сертификат с таким представлением уже существует.'; en = 'Certificate with such presentation already exists'; pl = 'Certificate with such presentation already exists';de = 'Certificate with such presentation already exists';ro = 'Certificate with such presentation already exists';tr = 'Certificate with such presentation already exists'; es_ES = 'Certificate with such presentation already exists'");
		Common.MessageToUser(MessageText,, Field,, Cancel);
	EndIf;
	
EndProcedure

// For internal use only.
Function SignatureInfoForEventLog(SignatureDate, SignatureProperties, IsSigningError = False) Export
	
	If SignatureProperties.Property("CertificateDetails") Then
		CertificateProperties = SignatureProperties.CertificateDetails;
	Else
		CertificateProperties = New Structure;
		CertificateProperties.Insert("SerialNumber", Base64Value(""));
		CertificateProperties.Insert("IssuedBy",      "");
		CertificateProperties.Insert("IssuedTo",     "");
		CertificateProperties.Insert("ValidFrom",    '00010101');
		CertificateProperties.Insert("ValidTo", '00010101');
		
		If TypeOf(SignatureProperties.Certificate) = Type("String")
		   AND IsTempStorageURL(SignatureProperties.Certificate) Then
			Certificate = GetFromTempStorage(SignatureProperties.Certificate);
		Else
			Certificate = SignatureProperties.Certificate;
		EndIf;
		
		If TypeOf(Certificate) = Type("BinaryData") Then
			CryptoCertificate = New CryptoCertificate(Certificate);
			CertificateProperties = DigitalSignature.CertificateProperties(CryptoCertificate);
			
		ElsIf SignatureProperties.Property("CertificateOwner") Then
			CertificateProperties.IssuedTo = SignatureProperties.CertificateOwner;
		EndIf;
	EndIf;
	
	If IsSigningError Then
		SignatureInformation = "";
	Else
		SignatureInformation = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Дата подписи: %1'; en = 'Date signed: %1'; pl = 'Date signed: %1';de = 'Date signed: %1';ro = 'Date signed: %1';tr = 'Date signed: %1'; es_ES = 'Date signed: %1'"), Format(SignatureDate, "DLF=DT")) + Chars.LF;
	EndIf;
	
	SignatureInformation = SignatureInformation + StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Сертификат: %1
		           |Кем выдан: %2
		           |Владелец: %3
		           |Действителен: с %4 по %5'; 
		           |en = 'Certificate: %1
		           |Issued by: %2
		           |Owner: %3
		           |Valid: from %4 to %5'; 
		           |pl = 'Certificate: %1
		           |Issued by: %2
		           |Owner: %3
		           |Valid: from %4 to %5';
		           |de = 'Certificate: %1
		           |Issued by: %2
		           |Owner: %3
		           |Valid: from %4 to %5';
		           |ro = 'Certificate: %1
		           |Issued by: %2
		           |Owner: %3
		           |Valid: from %4 to %5';
		           |tr = 'Certificate: %1
		           |Issued by: %2
		           |Owner: %3
		           |Valid: from %4 to %5'; 
		           |es_ES = 'Certificate: %1
		           |Issued by: %2
		           |Owner: %3
		           |Valid: from %4 to %5'"),
		String(CertificateProperties.SerialNumber),
		CertificateProperties.IssuedBy,
		CertificateProperties.IssuedTo,
		Format(CertificateProperties.ValidFrom,    "DLF=D"),
		Format(CertificateProperties.ValidTo, "DLF=D"));
	
	Return SignatureInformation;
	
EndFunction

// For internal use only.
Procedure RegisterDataSigningInLog(DataItem, ErrorDescription = "") Export
	
	IsSigningError = ValueIsFilled(ErrorDescription);
	
	If TypeOf(DataItem.SignatureProperties) = Type("String") Then
		SignatureProperties = GetFromTempStorage(DataItem.SignatureProperties);
	Else
		SignatureProperties = DataItem.SignatureProperties;
	EndIf;
	
	EventLogMessage = SignatureInfoForEventLog(
		SignatureProperties.SignatureDate, SignatureProperties, IsSigningError);
	
	If IsSigningError Then
		EventName = NStr("ru = 'Электронная подпись.Ошибка подписания данных'; en = 'Digital signature.Data signing error'; pl = 'Digital signature.Data signing error';de = 'Digital signature.Data signing error';ro = 'Digital signature.Data signing error';tr = 'Digital signature.Data signing error'; es_ES = 'Digital signature.Data signing error'",
			Common.DefaultLanguageCode());
		
		EventLogMessage = EventLogMessage + "
		|
		|" + ErrorDescription;
	Else
		EventName = NStr("ru = 'Электронная подпись.Подписание данных'; en = 'Digital signature.Data signing'; pl = 'Digital signature.Data signing';de = 'Digital signature.Data signing';ro = 'Digital signature.Data signing';tr = 'Digital signature.Data signing'; es_ES = 'Digital signature.Data signing'",
			Common.DefaultLanguageCode());
	EndIf;
	
	If Common.IsReference(TypeOf(DataItem.DataPresentation)) Then
		DataItemMetadata = DataItem.DataPresentation.Metadata();
	Else
		DataItemMetadata = Undefined;
	EndIf;
	
	WriteLogEvent(EventName,
		EventLogLevel.Information,
		DataItemMetadata,
		DataItem.DataPresentation,
		EventLogMessage);
	
EndProcedure

// For internal use only.
Procedure UpdateCertificatesList(Certificates, CertificatesPropertiesAtClient, ButAlreadyAddedOnes,
				Personal, Error, NoFilter, FilterByCompany = Undefined) Export
	
	CertificatesPropertiesTable = New ValueTable;
	CertificatesPropertiesTable.Columns.Add("Thumbprint", New TypeDescription("String", , New StringQualifiers(255)));
	CertificatesPropertiesTable.Columns.Add("IssuedBy");
	CertificatesPropertiesTable.Columns.Add("Presentation");
	CertificatesPropertiesTable.Columns.Add("AtClient",        New TypeDescription("Boolean"));
	CertificatesPropertiesTable.Columns.Add("AtServer",        New TypeDescription("Boolean"));
	CertificatesPropertiesTable.Columns.Add("IsRequest",     New TypeDescription("Boolean"));
	CertificatesPropertiesTable.Columns.Add("InCloudService", New TypeDescription("Boolean"));
	
	For Each CertificateProperties In CertificatesPropertiesAtClient Do
		NewRow = CertificatesPropertiesTable.Add();
		FillPropertyValues(NewRow, CertificateProperties);
		NewRow.AtClient = True;
	EndDo;
	
	CertificatesPropertiesTable.Indexes.Add("Thumbprint");
	
	If DigitalSignature.GenerateDigitalSignaturesAtServer() Then
		
		CryptoManager = CryptoManager("GetCertificates", False, Error);
		If CryptoManager <> Undefined Then
			
			CertificatesArray = CryptoManager.GetCertificateStore(
				CryptoCertificateStoreType.PersonalCertificates).GetAll();
			
			DigitalSignatureInternalClientServer.AddCertificatesProperties(CertificatesPropertiesTable,
				CertificatesArray, NoFilter, TimeAddition(), CurrentSessionDate());
			
			If Not Personal Then
				CertificatesArray = CryptoManager.GetCertificateStore(
					CryptoCertificateStoreType.RecipientCertificates).GetAll();
				
				DigitalSignatureInternalClientServer.AddCertificatesProperties(CertificatesPropertiesTable,
					CertificatesArray, NoFilter, TimeAddition(), CurrentSessionDate());
			EndIf;
		EndIf;
	EndIf;
	
	If UseDigitalSignatureSaaS() Then
		ModuleCertificateStore = Common.CommonModule("CertificatesStorage");
		CertificatesArray = ModuleCertificateStore.Get("PersonalCertificates");
		
		DigitalSignatureInternalClientServer.AddCertificatesProperties(CertificatesPropertiesTable,
			CertificatesArray, NoFilter, TimeAddition(), CurrentSessionDate(), , True);
		
		If Not Personal Then
			CertificatesArray = ModuleCertificateStore.Get("RecipientCertificates");
			
			DigitalSignatureInternalClientServer.AddCertificatesProperties(CertificatesPropertiesTable,
				CertificatesArray, NoFilter, TimeAddition(), CurrentSessionDate(), , True);
		EndIf;
	EndIf;
	
	ProcessAddedCertificates(CertificatesPropertiesTable, Not NoFilter AND ButAlreadyAddedOnes, FilterByCompany);
	
	CertificatesPropertiesTable.Indexes.Add("Presentation");
	CertificatesPropertiesTable.Sort("Presentation Asc");
	
	ProcessedRows  = New Map;
	Index = 0;
	Filter = New Structure("Thumbprint", "");
	
	For each CertificateProperties In CertificatesPropertiesTable Do
		Filter.Thumbprint = CertificateProperties.Thumbprint;
		Rows = Certificates.FindRows(Filter);
		If Rows.Count() = 0 Then
			If Certificates.Count()-1 < Index Then
				Row = Certificates.Add();
			Else
				Row = Certificates.Insert(Index);
			EndIf;
		Else
			Row = Rows[0];
			RowIndex = Certificates.IndexOf(Row);
			If RowIndex <> Index Then
				Certificates.Move(RowIndex, Index - RowIndex);
			EndIf;
		EndIf;
		// Updating only changed values not to update the form table once again.
		UpdateValue(Row.Thumbprint,          CertificateProperties.Thumbprint);
		UpdateValue(Row.Presentation,      CertificateProperties.Presentation);
		UpdateValue(Row.IssuedBy,           CertificateProperties.IssuedBy);
		UpdateValue(Row.AtClient,          CertificateProperties.AtClient);
		UpdateValue(Row.AtServer,          CertificateProperties.AtServer);
		UpdateValue(Row.IsRequest,       CertificateProperties.IsRequest);
		UpdateValue(Row.InCloudService,   CertificateProperties.InCloudService);
		ProcessedRows.Insert(Row, True);
		Index = Index + 1;
	EndDo;
	
	Index = Certificates.Count()-1;
	While Index >=0 Do
		Row = Certificates.Get(Index);
		If ProcessedRows.Get(Row) = Undefined Then
			Certificates.Delete(Index);
		EndIf;
		Index = Index-1;
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Common procedures and functions of the managed forms.

// For internal use only.
Procedure SetSigningEncryptionDecryptionForm(Form, Encryption = False, Details = False) Export
	
	Items  = Form.Items;
	Parameters = Form.Parameters;
	
	Items.Certificate.DropListButton = True;
	Items.Certificate.ChoiceButtonRepresentation = ChoiceButtonRepresentation.ShowInDropList;
	
	Form.Title = Parameters.Operation;
	Form.ExecuteAtServer = Parameters.ExecuteAtServer;
	
	If Encryption Then
		If Form.SpecifiedImmutableCertificateSet Then
			Form.NoConfirmation = Parameters.NoConfirmation;
		EndIf;
	Else
		Form.CertificatesFilter = New ValueList;
		If TypeOf(Parameters.CertificatesFilter) = Type("Array") Then
			Form.CertificatesFilter.LoadValues(Parameters.CertificatesFilter);
		ElsIf TypeOf(Parameters.CertificatesFilter) = Type("Structure") Then
			Form.CertificatesFilter = Parameters.CertificatesFilter.Company;
		EndIf;
		Form.NoConfirmation = Parameters.NoConfirmation;
	EndIf;
	
	If ValueIsFilled(Parameters.DataTitle) Then
		Items.DataPresentation.Title = Parameters.DataTitle;
	Else
		Items.DataPresentation.TitleLocation = FormItemTitleLocation.None;
	EndIf;
	
	Form.DataPresentation = Parameters.DataPresentation;
	Items.DataPresentation.Hyperlink = Parameters.DataPresentationCanOpen;
	
	If Not ValueIsFilled(Form.DataPresentation) Then
		Items.DataPresentation.Visible = False;
	EndIf;
	
	If Details Then
		FillThumbprintsFilter(Form);
	ElsIf Not Encryption Then // Signing
		Items.Comment.Visible = Parameters.ShowComment AND Not Form.NoConfirmation;
	EndIf;
	
	FillExistingUserCertificates(Form.CertificatePicklist,
		Parameters.CertificatesThumbprintsAtClient, Form.CertificatesFilter, Form.ThumbprintsFilter);
	
	Certificate = Undefined;
	
	If Details Then
		For each ListItem In Form.CertificatePicklist Do
			If TypeOf(ListItem.Value) = Type("String") Then
				Continue;
			EndIf;
			Certificate = ListItem.Value;
			Break;
		EndDo;
		
	ElsIf AccessRight("SaveUserData", Metadata) Then
		If Encryption Then
			Certificate = CommonSettingsStorage.Load("Cryptography", "CertificateToEncrypt");
		Else
			Certificate = CommonSettingsStorage.Load("Cryptography", "CertificateToSign");
		EndIf;
	EndIf;
	
	If TypeOf(Form.CertificatesFilter) = Type("ValueList") Then
		If Form.CertificatePicklist.Count() = 0 Then
			Certificate = Undefined;
		Else
			Certificate = Form.CertificatePicklist[0].Value;
		EndIf;
	EndIf;
	
	If Not (Encryption AND Form.SpecifiedImmutableCertificateSet) Then
		Form.Certificate = Certificate;
	EndIf;
	
	If ValueIsFilled(Form.Certificate)
	   AND Common.ObjectAttributeValue(Form.Certificate, "Ref") <> Form.Certificate Then
		
		Form.Certificate = Undefined;
	EndIf;
	
	If ValueIsFilled(Form.Certificate) Then
		If Encryption Then
			Form.DefaultFieldNameToActivate = "EncryptionCertificates";
		Else
			Form.DefaultFieldNameToActivate = "Password";
		EndIf;
	Else
		If Not (Encryption AND Form.SpecifiedImmutableCertificateSet) Then
			Form.DefaultFieldNameToActivate = "Certificate";
		EndIf;
	EndIf;
	
	FillCertificateAdditionalProperties(Form);
	
	Form.CryptographyManagerOnServerErrorDescription = New Structure;
	If DigitalSignature.GenerateDigitalSignaturesAtServer() Then
		CryptoManager("GetCertificates",
			False, Form.CryptographyManagerOnServerErrorDescription);
	EndIf;
	
	If Not Encryption Then
		DigitalSignatureOverridable.BeforeOperationStart(?(Details, "Details", "Signing"),
			Parameters.AdditionalActionParameters, Form.AdditionalActionsOutputParameters);
	EndIf;
	
EndProcedure

// For internal use only.
Procedure CertificateOnChangeAtServer(Form, CertificatesThumbprintsAtClient, Encryption = False, Details = False) Export
	
	If TypeOf(Form.CertificatesFilter) <> Type("ValueList") AND AccessRight("SaveUserData", Metadata) Then
		
		If Encryption Then
			CommonSettingsStorage.Save("Cryptography", "CertificateToEncrypt", Form.Certificate);
		ElsIf Not Details Then
			CommonSettingsStorage.Save("Cryptography", "CertificateToSign", Form.Certificate);
		EndIf;
		
	EndIf;
	
	FillExistingUserCertificates(Form.CertificatePicklist,
		CertificatesThumbprintsAtClient, Form.CertificatesFilter, Form.ThumbprintsFilter);
	
	FillCertificateAdditionalProperties(Form);
	
EndProcedure

// For internal use only.
Function SavedCertificateProperties(Thumbprint, Address, AttributesParameters, ToEncrypt = False) Export
	
	SavedProperties = New Structure;
	SavedProperties.Insert("Ref");
	SavedProperties.Insert("Description");
	SavedProperties.Insert("User");
	SavedProperties.Insert("Company");
	SavedProperties.Insert("StrongPrivateKeyProtection");
	
	Query = New Query;
	Query.SetParameter("Thumbprint", Thumbprint);
	Query.Text =
	"SELECT
	|	Certificates.Ref AS Ref,
	|	Certificates.Description AS Description,
	|	Certificates.User,
	|	Certificates.Company,
	|	Certificates.StrongPrivateKeyProtection,
	|	Certificates.CertificateData
	|FROM
	|	Catalog.DigitalSignatureAndEncryptionKeysCertificates AS Certificates
	|WHERE
	|	Certificates.Thumbprint = &Thumbprint";
	
	CryptoCertificate = New CryptoCertificate(GetFromTempStorage(Address));
	
	FillingValues = AttributesParameters;
	AttributesParameters = Undefined; // It is filled in the BeforeStartEditKeyCertificate procedure.
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		FillPropertyValues(SavedProperties, Selection);
	Else
		SavedProperties.Ref = Catalogs.DigitalSignatureAndEncryptionKeysCertificates.EmptyRef();
		
		If TypeOf(FillingValues) = Type("Structure")
		   AND FillingValues.Property("Company")
		   AND ValueIsFilled(FillingValues.Company) Then
			
			SavedProperties.Company = FillingValues.Company;
			
		ElsIf Not Metadata.DefinedTypes.Company.Type.ContainsType(Type("String")) Then
			FullName = Metadata.FindByType(Metadata.DefinedTypes.Company.Type.Types()[0]).FullName();
			OrganizationsCatalogName = "Catalogs." + StrSplit(FullName, ".")[1];
			ModuleOrganization = Common.CommonModule(OrganizationsCatalogName);
			If Not ToEncrypt Then
				SavedProperties.Company = ModuleOrganization.DefaultCompany();
			EndIf;
		EndIf;
		SavedProperties.Description = DigitalSignature.CertificatePresentation(CryptoCertificate);
		If Not ToEncrypt Then
			SavedProperties.User = Users.CurrentUser();
		EndIf;
	EndIf;
	
	BeforeStartEditKeyCertificate(
		SavedProperties.Ref, CryptoCertificate, AttributesParameters);
	
	If Not ValueIsFilled(SavedProperties.Ref) Then
		FillAttribute(SavedProperties, AttributesParameters, "Description");
		FillAttribute(SavedProperties, AttributesParameters, "User");
		FillAttribute(SavedProperties, AttributesParameters, "Company");
		FillAttribute(SavedProperties, AttributesParameters, "StrongPrivateKeyProtection");
	EndIf;
	
	If Not ValueIsFilled(SavedProperties.Ref)
	   AND TypeOf(FillingValues) = Type("Structure")
	   AND FillingValues.Property("Company")
	   AND ValueIsFilled(FillingValues.Company)
	   AND Not AttributesParameters.Property("Company") Then
	
		Parameters = New Structure;
		Parameters.Insert("ReadOnly",     True);
		Parameters.Insert("FillChecking", False);
		Parameters.Insert("Visible",          True);
		AttributesParameters.Insert("Company", Parameters);
	EndIf;
	
	Return SavedProperties;
	
EndFunction

// For internal use only.
Procedure WriteCertificateToCatalog(Form, Application = Undefined, ToEncrypt = False) Export
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Description", Form.CertificateDescription);
	AdditionalParameters.Insert("User", Form.CertificateUser);
	AdditionalParameters.Insert("Company",  Form.CertificateCompany);
	
	If Not ToEncrypt Then
		AdditionalParameters.Insert("Application", Application);
		AdditionalParameters.Insert("StrongPrivateKeyProtection",
			Form.CertificatePrivateKeyAdvancedProtection);
	EndIf;
	
	If Not ValueIsFilled(Form.Certificate) Then
		AttributesToSkip = New Map;
		AttributesToSkip.Insert("Ref",       True);
		AttributesToSkip.Insert("Description", True);
		AttributesToSkip.Insert("Company",  True);
		AttributesToSkip.Insert("StrongPrivateKeyProtection", True);
		If Not ToEncrypt AND Form.PersonalListOnAdd Then
			AttributesToSkip.Insert("User",  True);
		EndIf;
		For each KeyAndValue In Form.CertificateAttributeParameters Do
			AttributeName = KeyAndValue.Key;
			Properties     = KeyAndValue.Value;
			If AttributesToSkip.Get(AttributeName) <> Undefined Then
				Continue;
			EndIf;
			If Properties.FillingValue = Undefined Then
				Continue;
			EndIf;
			AdditionalParameters.Insert(AttributeName, Properties.FillingValue);
		EndDo;
	EndIf;
	
	Form.Certificate = DigitalSignature.WriteCertificateToCatalog(Form.CertificateAddress,
		AdditionalParameters);
	
EndProcedure

// For internal use only.
Procedure SetCertificateListConditionalAppearance(List, ExcludeApplications = False) Export
	
	ConditionalAppearanceItem = List.ConditionalAppearance.Items.Add();
	
	AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("TextColor");
	AppearanceColorItem.Value = Metadata.StyleItems.InaccessibleCellTextColor.Value;
	AppearanceColorItem.Use = True;
	
	If ExcludeApplications AND Metadata.DataProcessors.Find("ApplicationForNewQualifiedCertificateIssue") <> Undefined Then
		ProcessingApplicationForNewQualifiedCertificateIssue =
			Common.ObjectManagerByFullName(
				"DataProcessor.ApplicationForNewQualifiedCertificateIssue");
		ProcessingApplicationForNewQualifiedCertificateIssue.SetCertificateListConditionalAppearance(
			ConditionalAppearanceItem);
	EndIf;
	
	FilterItemsGroup = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterItemsGroup.GroupType = DataCompositionFilterItemsGroupType.NotGroup;
	
	DataFilterItem = FilterItemsGroup.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue  = New DataCompositionField("Revoked");
	DataFilterItem.ComparisonType   = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = False;
	DataFilterItem.Use  = True;
	
	DataFilterItem = FilterItemsGroup.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue  = New DataCompositionField("ValidBefore");
	DataFilterItem.ComparisonType   = DataCompositionComparisonType.Greater;
	DataFilterItem.RightValue = New StandardBeginningDate(StandardBeginningDateVariant.BeginningOfThisDay);
	DataFilterItem.Use  = True;
	
	AppearanceFieldItem = ConditionalAppearanceItem.Fields.Items.Add();
	AppearanceFieldItem.Field = New DataCompositionField("");
	AppearanceFieldItem.Use = True;
	
EndProcedure

// For internal use only.
Function CertificateFromBinaryData(CertificateData) Export
	
	If TypeOf(CertificateData) <> Type("BinaryData") Then
		Return Undefined;
	EndIf;
	
	Try
		CryptoCertificate = New CryptoCertificate(CertificateData);
	Except
		CryptoCertificate = Undefined;
	EndTry;
	
	If CryptoCertificate <> Undefined Then
		Return CryptoCertificate;
	EndIf;
	
	TempFileFullName = GetTempFileName("cer");
	CertificateData.Write(TempFileFullName);
	Text = New TextDocument;
	Text.Read(TempFileFullName);
	
	Try
		DeleteFiles(TempFileFullName);
	Except
		WriteLogEvent(
			NStr("ru = 'Электронная подпись.Удаление временного файла'; en = 'Digital signature.Remove temporary file'; pl = 'Digital signature.Remove temporary file';de = 'Digital signature.Remove temporary file';ro = 'Digital signature.Remove temporary file';tr = 'Digital signature.Remove temporary file'; es_ES = 'Digital signature.Remove temporary file'",
				Common.DefaultLanguageCode()),
			EventLogLevel.Error, , ,
			DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	If Text.LineCount() < 3
	 Or Text.GetLine(1) <> "-----BEGIN CERTIFICATE-----"
	 Or Text.GetLine(Text.LineCount()) <> "-----END CERTIFICATE-----" Then
		
		Return Undefined;
	EndIf;
	
	Text.DeleteLine(1);
	Text.DeleteLine(Text.LineCount());
	Base64Row = Text.GetText();
	
	Try
		CertificateData = Base64Value(Base64Row);
	Except
		Return Undefined;
	EndTry;
	
	If TypeOf(CertificateData) <> Type("BinaryData") Then
		Return Undefined;
	EndIf;
	
	Try
		CryptoCertificate = New CryptoCertificate(CertificateData);
	Except
		CryptoCertificate = Undefined;
	EndTry;
	
	Return CryptoCertificate;
	
EndFunction

// For internal use only.
Procedure SetPasswordEntryNote(Form, ItemNameStrongPrivateKeyProtection = "", ItemNameEnhancedPasswordNote = "") Export
	
	If Not DigitalSignatureInternalClientServer.InteractiveModeAvailable() Then
		Return;
	EndIf;
	
	If ValueIsFilled(ItemNameStrongPrivateKeyProtection) Then
		Item = Form.Items[ItemNameStrongPrivateKeyProtection];
		Item.Title = NStr("ru = 'Ввод и сохранение пароля в программе'; en = 'Enter and save password in the application'; pl = 'Enter and save password in the application';de = 'Enter and save password in the application';ro = 'Enter and save password in the application';tr = 'Enter and save password in the application'; es_ES = 'Enter and save password in the application'");
		Item.ToolTip =
			NStr("ru = '- Включается интерактивный режим работы программы электронной подписи,
			           |  при котором она запрашивает пароль и позволяет его сохранить.
			           |- Отключается запрос пароля в форме 1С:Предприятия.
			           |
			           |Обязательно для закрытых ключей сертификатов, для которых в ОС включена усиленная защита.'; 
			           |en = '- Interactive mode of the digital signature application is enabled,
			           | the application requests a password and allows you to save it.
			           |- In 1C:Enterprise form, password request is disabled.
			           |
			           |It is required for private keys of certificates for which strong protection is enabled in the OS.'; 
			           |pl = '- Interactive mode of the digital signature application is enabled,
			           | the application requests a password and allows you to save it.
			           |- In 1C:Enterprise form, password request is disabled.
			           |
			           |It is required for private keys of certificates for which strong protection is enabled in the OS.';
			           |de = '- Interactive mode of the digital signature application is enabled,
			           | the application requests a password and allows you to save it.
			           |- In 1C:Enterprise form, password request is disabled.
			           |
			           |It is required for private keys of certificates for which strong protection is enabled in the OS.';
			           |ro = '- Interactive mode of the digital signature application is enabled,
			           | the application requests a password and allows you to save it.
			           |- In 1C:Enterprise form, password request is disabled.
			           |
			           |It is required for private keys of certificates for which strong protection is enabled in the OS.';
			           |tr = '- Interactive mode of the digital signature application is enabled,
			           | the application requests a password and allows you to save it.
			           |- In 1C:Enterprise form, password request is disabled.
			           |
			           |It is required for private keys of certificates for which strong protection is enabled in the OS.'; 
			           |es_ES = '- Interactive mode of the digital signature application is enabled,
			           | the application requests a password and allows you to save it.
			           |- In 1C:Enterprise form, password request is disabled.
			           |
			           |It is required for private keys of certificates for which strong protection is enabled in the OS.'");
	EndIf;
	
	If ValueIsFilled(ItemNameEnhancedPasswordNote) Then
		Item = Form.Items[ItemNameEnhancedPasswordNote];
		Item.ToolTip =
			NStr("ru = 'Пароль запрашивает программа электронной подписи, а не программа 1С:Предприятие,
			           |так как для выбранного сертификата включен режим ""Ввод и сохранение пароля в программе"".'; 
			           |en = 'Password is requested by the digital signature application, not by 1C:Enterprise
			           |as the ""Enter and save password in the application"" mode is enabled for the selected certificate.'; 
			           |pl = 'Password is requested by the digital signature application, not by 1C:Enterprise
			           |as the ""Enter and save password in the application"" mode is enabled for the selected certificate.';
			           |de = 'Password is requested by the digital signature application, not by 1C:Enterprise
			           |as the ""Enter and save password in the application"" mode is enabled for the selected certificate.';
			           |ro = 'Password is requested by the digital signature application, not by 1C:Enterprise
			           |as the ""Enter and save password in the application"" mode is enabled for the selected certificate.';
			           |tr = 'Password is requested by the digital signature application, not by 1C:Enterprise
			           |as the ""Enter and save password in the application"" mode is enabled for the selected certificate.'; 
			           |es_ES = 'Password is requested by the digital signature application, not by 1C:Enterprise
			           |as the ""Enter and save password in the application"" mode is enabled for the selected certificate.'");
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Updating an infobase.

// Handler of data conversion in the transition to support the use of several digital signature and 
// encryption applications in one infobase.
//
Procedure MoveCryptographyManagerSettings() Export
	
	ApplicationObject = OldApplication();
	Application = Undefined;
	
	BeginTransaction();
	Try
		If ApplicationObject <> Undefined Then
			If Not Common.IsSubordinateDIBNode() Then
				InfobaseUpdate.WriteData(ApplicationObject);
			EndIf;
			Application = ApplicationObject.Ref;
		EndIf;
		
		If Constants.UseDigitalSignature.Get()
		   AND Not Constants.UseEncryption.Get() Then
		
			ValueManager = Constants.UseEncryption.CreateValueManager();
			ValueManager.Value = True;
			InfobaseUpdate.WriteData(ValueManager);
		EndIf;
		
		ClearConstant(Constants.DeleteDigitalSignatureProvider);
		ClearConstant(Constants.DeleteDigitalSignatureProviderType);
		ClearConstant(Constants.DeleteSignatureAlgorithm);
		ClearConstant(Constants.DeleteHashingAlgorithm);
		ClearConstant(Constants.DeleteEncryptionAlgorithm);
		ProcessPathsAtLinuxServers(Application);
		ProcessPathsAtLinuxClients(Application);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// XMLDSig operations

// Signs message by inserting signature data into the SOAP template.
//
// Parameters:
//  SOAPEnvelope               - String - a template of the message to be generated in the SOAP format.
//  SigningAlgorithmData - Structure:
//     XPathTagToSign   - String - a query to get the signature tag.
//     XPathSignedInfo         - String - a query to get the signed information tag.
//     HashingAlgorithmOID - String - a hashing algorithm ID.
//     SignatureAlgorithmName     - a signature algorithm name.
//     HashAlgorithm         - String - a hash algorithm in the SOAP envelope.
//     SignAlgorithm         - String - a signing algorithm in the SOAP envelope.
//  CryptoCertificate     - CryptoCertificate - a crypto certificate to be used.
//  CryptoManager       - CryptoManager - a crypto manager to be used.
// 
// Returns:
//  String - an SOAP template with inserted signature data.
//
Function Sign(Val SOAPEnvelope, SigningAlgorithmData, CryptoCertificate, CryptoManager) Export
	
	XPathTagToSign = SigningAlgorithmData.XPathTagToSign;
	XPathSignedInfo       = SigningAlgorithmData.XPathSignedInfo;
	
	Password = CryptoManager.PrivateKeyAccessPassword;
	
	ComponentObject = ExternalComponentObjectXMLDSig();
	
	CryptoProviderProperties = CryptoProviderProperties(CryptoManager);
	ComponentObject.PathToCryptoServiceProvider = CryptoProviderProperties.Path;
	
	SOAPEnvelope = StrReplace(
		SOAPEnvelope,
		"%BinarySecurityToken%",
		Base64CryptoCertificate(CryptoCertificate.Unload()));
	
	CheckChooseSignAlgorithm(ComponentObject,
		Base64CryptoCertificate(CryptoCertificate.Unload()),
		SigningAlgorithmData);
	
	DigestValue = Hash(
		ComponentObject,
		C14N(ComponentObject, SOAPEnvelope, XPathTagToSign),
		SigningAlgorithmData.SelectedHashAlgorithmOID,
		CryptoProviderProperties.Type);
	
	SOAPEnvelope = StrReplace(SOAPEnvelope, "%DigestValue%",     DigestValue);
	SOAPEnvelope = StrReplace(SOAPEnvelope, "%SignatureMethod%", SigningAlgorithmData.SelectedSignatureAlgorithm);
	SOAPEnvelope = StrReplace(SOAPEnvelope, "%DigestMethod%",    SigningAlgorithmData.SelectedHashAlgorithm);
	
	SignatureValue = SignImpl(
		ComponentObject,
		C14N(ComponentObject, SOAPEnvelope, XPathSignedInfo),
		CryptoCertificate,
		Password);
	
	SOAPEnvelope = StrReplace(SOAPEnvelope, "%SignatureValue%", SignatureValue);
	
	Return SOAPEnvelope;
	
EndFunction

// The parameter returns a certificate, by which the signature was made (if the certificate is included in the signature data).
// If the signature check fails, an exception is generated.
Function VerifySignature(Val SOAPEnvelope, SigningAlgorithmData, CryptoManager) Export
	
	XPathTagToSign = SigningAlgorithmData.XPathTagToSign;
	XPathSignedInfo       = SigningAlgorithmData.XPathSignedInfo;
	
	ComponentObject = ExternalComponentObjectXMLDSig();
	
	CryptoProviderProperties = CryptoProviderProperties(CryptoManager);
	ComponentObject.PathToCryptoServiceProvider = CryptoProviderProperties.Path;
	
	Base64CryptoCertificate = DigitalSignatureInternalClientServer.FindInXML(SOAPEnvelope, "wsse:BinarySecurityToken");
	
	CheckChooseSignAlgorithm(ComponentObject, Base64CryptoCertificate, SigningAlgorithmData);
	
	SignatureCorrect = VerifySign(
		ComponentObject,
		C14N(ComponentObject, SOAPEnvelope, XPathSignedInfo),
		DigitalSignatureInternalClientServer.FindInXML(SOAPEnvelope, "SignatureValue"),
		Base64CryptoCertificate,
		CryptoProviderProperties.Type);
	
	DigestValue = Hash(
		ComponentObject,
		C14N(ComponentObject, SOAPEnvelope, XPathTagToSign),
		SigningAlgorithmData.SelectedHashAlgorithmOID,
		CryptoProviderProperties.Type);
	
	HashMaps = False;
	If DigestValue = DigitalSignatureInternalClientServer.FindInXML(SOAPEnvelope, "DigestValue") Then
		HashMaps = True;
	EndIf;
	
	If HashMaps AND SignatureCorrect Then
		
		BinaryData = Base64Value(Base64CryptoCertificate);
		
		SigningDate = DigitalSignature.SigningDate(BinaryData);
		If Not ValueIsFilled(SigningDate) Then
			SigningDate = Undefined;
		EndIf;
		
		ReturnValue = New Structure;
		ReturnValue.Insert("Certificate", New CryptoCertificate(BinaryData));
		ReturnValue.Insert("SigningDate", SigningDate);

		Return ReturnValue;
		
	Else
		
		If SignatureCorrect Then
			Raise NStr("ru = 'Подпись не верна (SignatureValue корректно, отличается DigestValue).'; en = 'Signature is invalid (SignatureValue correct, DigestValue different).'; pl = 'Signature is invalid (SignatureValue correct, DigestValue different).';de = 'Signature is invalid (SignatureValue correct, DigestValue different).';ro = 'Signature is invalid (SignatureValue correct, DigestValue different).';tr = 'Signature is invalid (SignatureValue correct, DigestValue different).'; es_ES = 'Signature is invalid (SignatureValue correct, DigestValue different).'")
		Else
			Raise NStr("ru = 'Подпись не верна (SignatureValue некорректно.'; en = 'Signature is invalid (SignatureValue incorrect.'; pl = 'Signature is invalid (SignatureValue incorrect.';de = 'Signature is invalid (SignatureValue incorrect.';ro = 'Signature is invalid (SignatureValue incorrect.';tr = 'Signature is invalid (SignatureValue incorrect.'; es_ES = 'Signature is invalid (SignatureValue incorrect.'");
		EndIf;
		
	EndIf;
	
EndFunction

Function ExternalComponentObjectXMLDSig()
	
	ComponentObject = Common.AttachAddInFromTemplate("XMLDSignAddIn",
		"Catalog.DigitalSignatureAndEncryptionKeysCertificates.Template.XMLDSIGComponent");
	
	If ComponentObject = Undefined Then
		Raise NStr("ru='Не удалось подключить внешнюю компоненту XMLDSig.'; en = 'Cannot attach add-in component XMLDSig.'; pl = 'Cannot attach add-in component XMLDSig.';de = 'Cannot attach add-in component XMLDSig.';ro = 'Cannot attach add-in component XMLDSig.';tr = 'Cannot attach add-in component XMLDSig.'; es_ES = 'Cannot attach add-in component XMLDSig.'");
	EndIf;
	
	Return ComponentObject;
	
EndFunction

Function CryptoProviderProperties(CryptoManager)
	
	CryptoModuleInformation = CryptoManager.GetCryptoModuleInformation();
	
	CryptoProviderName = CryptoModuleInformation.Name;
	ApplicationDetails = DigitalSignatureInternalClientServer.ApplicationDetailsByCryptoProviderName(CryptoProviderName,
		DigitalSignature.CommonSettings().ApplicationsDetailsCollection);
	
	If ApplicationDetails = Undefined Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Не удалось определить тип криптопровайдера %1'; en = 'Cannot define a type of cryptographic service provider %1'; pl = 'Cannot define a type of cryptographic service provider %1';de = 'Cannot define a type of cryptographic service provider %1';ro = 'Cannot define a type of cryptographic service provider %1';tr = 'Cannot define a type of cryptographic service provider %1'; es_ES = 'Cannot define a type of cryptographic service provider %1'"), CryptoProviderName);
	EndIf;
	
	Properties = New Structure("Type, Path", ApplicationDetails.ApplicationType, "");
	
	If Common.IsLinuxServer() Then
		ApplicationsPathsAtLinuxServers = ApplicationsPathsAtLinuxServers(ComputerName());
		Properties.Path = ApplicationsPathsAtLinuxServers.Get(ApplicationDetails.Ref);
	Else
		Properties.Path = "";
	EndIf;
	
	Return Properties;
	
EndFunction

Function GetSignOIDFromCert(ComponentObject, Base64CryptoCertificate)
	
	Try
		SignatureAlgorithmOID = ComponentObject.GetSignOIDFromCert(Base64CryptoCertificate);
	Except
		Raise NStr("ru = 'Ошибка вызова метода GetSignOIDFromCert компоненты XMLDSig.'; en = 'An error occurred when calling method GetSignOIDFromCert of component XMLDSig.'; pl = 'An error occurred when calling method GetSignOIDFromCert of component XMLDSig.';de = 'An error occurred when calling method GetSignOIDFromCert of component XMLDSig.';ro = 'An error occurred when calling method GetSignOIDFromCert of component XMLDSig.';tr = 'An error occurred when calling method GetSignOIDFromCert of component XMLDSig.'; es_ES = 'An error occurred when calling method GetSignOIDFromCert of component XMLDSig.'") + Chars.LF + DetailErrorDescription(ErrorInfo());
	EndTry;
	
	If SignatureAlgorithmOID = Undefined Then
		Raise NStr("ru = 'Ошибка вызова метода GetSignOIDFromCert компоненты XMLDSig.'; en = 'An error occurred when calling method GetSignOIDFromCert of component XMLDSig.'; pl = 'An error occurred when calling method GetSignOIDFromCert of component XMLDSig.';de = 'An error occurred when calling method GetSignOIDFromCert of component XMLDSig.';ro = 'An error occurred when calling method GetSignOIDFromCert of component XMLDSig.';tr = 'An error occurred when calling method GetSignOIDFromCert of component XMLDSig.'; es_ES = 'An error occurred when calling method GetSignOIDFromCert of component XMLDSig.'") + Chars.LF + ComponentObject.GetLastError();
	EndIf;
	
	Return SignatureAlgorithmOID;
	
EndFunction

Function C14N(ComponentObject, SOAPEnvelope, XPath)
	
	Try
		CanonicalizedXMLText = ComponentObject.C14N(
			SOAPEnvelope,
			XPath);
	Except
		Raise NStr("ru = 'Ошибка вызова метода C14N компоненты XMLDSig.'; en = 'An error occurred when calling method C14N of component XMLDSig.'; pl = 'An error occurred when calling method C14N of component XMLDSig.';de = 'An error occurred when calling method C14N of component XMLDSig.';ro = 'An error occurred when calling method C14N of component XMLDSig.';tr = 'An error occurred when calling method C14N of component XMLDSig.'; es_ES = 'An error occurred when calling method C14N of component XMLDSig.'") + Chars.LF + DetailErrorDescription(ErrorInfo());
	EndTry;
	
	If CanonicalizedXMLText = Undefined Then
		Raise NStr("ru = 'Ошибка вызова метода C14N компоненты XMLDSig.'; en = 'An error occurred when calling method C14N of component XMLDSig.'; pl = 'An error occurred when calling method C14N of component XMLDSig.';de = 'An error occurred when calling method C14N of component XMLDSig.';ro = 'An error occurred when calling method C14N of component XMLDSig.';tr = 'An error occurred when calling method C14N of component XMLDSig.'; es_ES = 'An error occurred when calling method C14N of component XMLDSig.'") + Chars.LF + ComponentObject.GetLastError();
	EndIf;
	
	Return CanonicalizedXMLText;
	
EndFunction

Function Hash(ComponentObject, CanonicalizedXMLText, HashingAlgorithmOID, CryptoProviderType)
	
	Try
		DigestValue = ComponentObject.Hash(
			CanonicalizedXMLText,
			HashingAlgorithmOID,
			CryptoProviderType);
	Except
		Raise NStr("ru = 'Ошибка вызова метода Hash компоненты XMLDSig.'; en = 'An error occurred when calling method Hash of component XMLDSig.'; pl = 'An error occurred when calling method Hash of component XMLDSig.';de = 'An error occurred when calling method Hash of component XMLDSig.';ro = 'An error occurred when calling method Hash of component XMLDSig.';tr = 'An error occurred when calling method Hash of component XMLDSig.'; es_ES = 'An error occurred when calling method Hash of component XMLDSig.'") + Chars.LF + DetailErrorDescription(ErrorInfo());
	EndTry;
	
	If DigestValue = Undefined Then
		Raise NStr("ru = 'Ошибка вызова метода Hash компоненты XMLDSig.'; en = 'An error occurred when calling method Hash of component XMLDSig.'; pl = 'An error occurred when calling method Hash of component XMLDSig.';de = 'An error occurred when calling method Hash of component XMLDSig.';ro = 'An error occurred when calling method Hash of component XMLDSig.';tr = 'An error occurred when calling method Hash of component XMLDSig.'; es_ES = 'An error occurred when calling method Hash of component XMLDSig.'") + Chars.LF + ComponentObject.GetLastError();
	EndIf;
	
	Return DigestValue;
	
EndFunction

Function SignImpl(ComponentObject, CanonicalizedXMLTextSignedInfo, CryptoCertificate, PrivateKeyAccessPassword)
	
	Try
		SignatureValue = ComponentObject.Sign(
			CanonicalizedXMLTextSignedInfo,
			Base64CryptoCertificate(CryptoCertificate.Unload()),
			PrivateKeyAccessPassword);
	Except
		Raise NStr("ru = 'Ошибка вызова метода Sign компоненты XMLDSig.'; en = 'An error occurred when calling method Sign of component XMLDSig.'; pl = 'An error occurred when calling method Sign of component XMLDSig.';de = 'An error occurred when calling method Sign of component XMLDSig.';ro = 'An error occurred when calling method Sign of component XMLDSig.';tr = 'An error occurred when calling method Sign of component XMLDSig.'; es_ES = 'An error occurred when calling method Sign of component XMLDSig.'") + Chars.LF + DetailErrorDescription(ErrorInfo());
	EndTry;
	
	If SignatureValue = Undefined Then
		Raise NStr("ru = 'Ошибка вызова метода Sign компоненты XMLDSig.'; en = 'An error occurred when calling method Sign of component XMLDSig.'; pl = 'An error occurred when calling method Sign of component XMLDSig.';de = 'An error occurred when calling method Sign of component XMLDSig.';ro = 'An error occurred when calling method Sign of component XMLDSig.';tr = 'An error occurred when calling method Sign of component XMLDSig.'; es_ES = 'An error occurred when calling method Sign of component XMLDSig.'") + Chars.LF + ComponentObject.GetLastError();
	EndIf;
	
	Return SignatureValue;
	
EndFunction

Function VerifySign(ComponentObject, CanonicalizedXMLTextSignedInfo, SignatureValue, Base64CryptoCertificate, CryptoProviderType)
	
	Try
		SignatureCorrect = ComponentObject.VerifySign(
			CanonicalizedXMLTextSignedInfo,
			SignatureValue,
			Base64CryptoCertificate,
			CryptoProviderType);
	Except
		Raise NStr("ru = 'Ошибка вызова метода VerifySign компоненты XMLDSig.'; en = 'An error occurred when calling method VerifySign of component XMLDSig.'; pl = 'An error occurred when calling method VerifySign of component XMLDSig.';de = 'An error occurred when calling method VerifySign of component XMLDSig.';ro = 'An error occurred when calling method VerifySign of component XMLDSig.';tr = 'An error occurred when calling method VerifySign of component XMLDSig.'; es_ES = 'An error occurred when calling method VerifySign of component XMLDSig.'") + Chars.LF + DetailErrorDescription(ErrorInfo());
	EndTry;
	
	If SignatureCorrect = Undefined Then
		Raise NStr("ru = 'Ошибка вызова метода VerifySign компоненты XMLDSig.'; en = 'An error occurred when calling method VerifySign of component XMLDSig.'; pl = 'An error occurred when calling method VerifySign of component XMLDSig.';de = 'An error occurred when calling method VerifySign of component XMLDSig.';ro = 'An error occurred when calling method VerifySign of component XMLDSig.';tr = 'An error occurred when calling method VerifySign of component XMLDSig.'; es_ES = 'An error occurred when calling method VerifySign of component XMLDSig.'") + Chars.LF + ComponentObject.GetLastError();
	EndIf;
	
	Return SignatureCorrect;
	
EndFunction

Procedure CheckChooseSignAlgorithm(ComponentObject, Base64CryptoCertificate, SigningAlgorithmData)
	
	SignatureAlgorithmOID = GetSignOIDFromCert(ComponentObject, Base64CryptoCertificate);
	
	SignAlgorithmsOID     = StrSplit(SigningAlgorithmData.SignatureAlgorithmOID,     Chars.LF);
	HashAlgorithmsOID = StrSplit(SigningAlgorithmData.HashingAlgorithmOID, Chars.LF);
	SignAlgorithms         = StrSplit(SigningAlgorithmData.SignAlgorithm,         Chars.LF);
	HashAlgorithms     = StrSplit(SigningAlgorithmData.HashAlgorithm,     Chars.LF);
	
	SigningAlgorithmData.Insert("SelectedSignatureAlgorithmOID",     Undefined);
	SigningAlgorithmData.Insert("SelectedHashAlgorithmOID", Undefined);
	SigningAlgorithmData.Insert("SelectedSignatureAlgorithm",          Undefined);
	SigningAlgorithmData.Insert("SelectedHashAlgorithm",      Undefined);
	For Index = 0 To SignAlgorithmsOID.Count() - 1 Do
		
		If SignatureAlgorithmOID = SignAlgorithmsOID[Index] Then
			
			SigningAlgorithmData.SelectedSignatureAlgorithmOID     = SignAlgorithmsOID[Index];
			SigningAlgorithmData.SelectedHashAlgorithmOID = HashAlgorithmsOID[Index];
			SigningAlgorithmData.SelectedSignatureAlgorithm          = SignAlgorithms[Index];
			SigningAlgorithmData.SelectedHashAlgorithm      = HashAlgorithms[Index];
			
			Break;
			
		EndIf;
		
	EndDo;
	
	If Not ValueIsFilled(SigningAlgorithmData.SelectedSignatureAlgorithmOID) Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Алгоритм подписи сертификата криптографии отличается от алгоритма %1.'; en = 'Certificate signature algorithm of cryptography differs from algorithm %1.'; pl = 'Certificate signature algorithm of cryptography differs from algorithm %1.';de = 'Certificate signature algorithm of cryptography differs from algorithm %1.';ro = 'Certificate signature algorithm of cryptography differs from algorithm %1.';tr = 'Certificate signature algorithm of cryptography differs from algorithm %1.'; es_ES = 'Certificate signature algorithm of cryptography differs from algorithm %1.'"),
			SigningAlgorithmData.SIgnatureAlgorithmName);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Auxiliary procedures and functions.


// For the TransferCryptoManagerSettings update procedure.
Procedure ClearConstant(Constant)
	
	If Not ValueIsFilled(Constant.Get()) Then
		Return;
	EndIf;
	
	ValueManager = Constant.CreateValueManager();
	ValueManager.Value = Undefined;
	InfobaseUpdate.WriteData(ValueManager);
	
EndProcedure

// For the TransferCryptoManagerSettings update procedure.
Procedure ProcessPathsAtLinuxServers(Application)
	
	// Processing server paths
	RecordSet = InformationRegisters.PathsToDigitalSignatureAndEncryptionApplicationsOnLinuxServers.CreateRecordSet();
	RecordSet.Filter.Application.Set(Catalogs.DigitalSignatureAndEncryptionApplications.EmptyRef());
	RecordSet.Read();
	
	If RecordSet.Count() = 0 Then
		Return;
	EndIf;
	
	If ValueIsFilled(Application) Then
		ApplicationRecordSet = InformationRegisters.PathsToDigitalSignatureAndEncryptionApplicationsOnLinuxServers.CreateRecordSet();
		ApplicationRecordSet.Filter.Application.Set(Application);
		ApplicationRecordSet.Read();
		Table = ApplicationRecordSet.Unload(, "ComputerName, ApplicationPath");
		Filter = New Structure("ComputerName, ApplicationPath");
		
		For each Record In RecordSet Do
			FillPropertyValues(Filter, Record);
			Rows = Table.FindRows(Filter);
			If Rows.Count() = 0 Then
				NewRecord = ApplicationRecordSet.Add();
				FillPropertyValues(NewRecord, Record);
				NewRecord.Application = Application;
			EndIf;
		EndDo;
		If ApplicationRecordSet.Modified() Then
			InfobaseUpdate.WriteData(ApplicationRecordSet);
		EndIf;
	EndIf;
	
	RecordSet.Clear();
	InfobaseUpdate.WriteData(RecordSet);
	
EndProcedure

// For the TransferCryptoManagerSettings update procedure.
Procedure ProcessPathsAtLinuxClients(Application)
	
	// Processing client paths
	IBUsers = InfoBaseUsers.GetUsers();
	SubsystemKey = "DS"; // Do not change to DS. It is used for backward compatibility.
	OldSettingsKey = "CryptoModulePath";
	NewSettingsKey  = "PathsToDigitalSignatureAndEncryptionApplications";
	For each InfobaseUser In IBUsers Do
		Path = Common.CommonSettingsStorageLoad(SubsystemKey, OldSettingsKey,,,
			InfobaseUser.Name);
		If Not ValueIsFilled(Path) Then
			Continue;
		EndIf;
		Settings = New Map;
		Settings.Insert(Application, Path);
		Common.CommonSettingsStorageSave(SubsystemKey, NewSettingsKey, Settings,,
			InfobaseUser.Name)
	EndDo;
	
EndProcedure

// For the TransferCryptoManagerSettings update procedure.
Function OldApplication()
	
	ApplicationName = TrimAll(Constants.DeleteDigitalSignatureProvider.Get());
	ApplicationType = Constants.DeleteDigitalSignatureProviderType.Get();
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	TRUE AS TrueValue
	|FROM
	|	InformationRegister.PathsToDigitalSignatureAndEncryptionApplicationsOnLinuxServers AS Paths
	|WHERE
	|	Paths.Application = VALUE(Catalog.DigitalSignatureAndEncryptionKeysCertificates.EmptyRef)";
	
	If Not ValueIsFilled(ApplicationName)
	   AND Not ValueIsFilled(ApplicationType)
	   AND Query.Execute().IsEmpty() Then
	
		Return Undefined;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("ApplicationName", ApplicationName);
	Query.SetParameter("ApplicationType", ApplicationType);
	Query.Text =
	"SELECT
	|	Applications.Ref AS Ref
	|FROM
	|	Catalog.DigitalSignatureAndEncryptionApplications AS Applications
	|WHERE
	|	Applications.ApplicationName = &ApplicationName
	|	AND Applications.ApplicationType = &ApplicationType";
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		ApplicationObject = Catalogs.DigitalSignatureAndEncryptionApplications.CreateItem();
		ApplicationObject.Description = ApplicationName;
		ApplicationObject.ApplicationName = ApplicationName;
		ApplicationObject.ApplicationType = ApplicationType;
	Else
		ApplicationObject = QueryResult.Unload()[0].Ref.GetObject();
	EndIf;
	
	ApplicationObject.SignAlgorithm     = Constants.DeleteSignatureAlgorithm.Get();
	ApplicationObject.HashAlgorithm = Constants.DeleteHashingAlgorithm.Get();
	ApplicationObject.EncryptAlgorithm  = Constants.DeleteEncryptionAlgorithm.Get();
	
	Return ApplicationObject;
	
EndFunction

// For the UpdateCertificatesList procedure.
Procedure ProcessAddedCertificates(CertificatesPropertiesTable, ButAlreadyAddedOnes, FilterByCompany = Undefined)
	
	Query = New Query;
	Query.SetParameter("Thumbprints", CertificatesPropertiesTable.Copy(, "Thumbprint"));
	Query.Text =
	"SELECT
	|	Thumbprints.Thumbprint
	|INTO Thumbprints
	|FROM
	|	&Thumbprints AS Thumbprints
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Certificates.Thumbprint,
	|	Certificates.Description AS Presentation,
	|	FALSE AS IsRequest,
	|	Certificates.Company
	|FROM
	|	Catalog.DigitalSignatureAndEncryptionKeysCertificates AS Certificates
	|		INNER JOIN Thumbprints AS Thumbprints
	|		ON Certificates.Thumbprint = Thumbprints.Thumbprint";
	
	If Metadata.DataProcessors.Find("ApplicationForNewQualifiedCertificateIssue") <> Undefined Then
		ProcessingApplicationForNewQualifiedCertificateIssue =
			Common.ObjectManagerByFullName(
				"DataProcessor.ApplicationForNewQualifiedCertificateIssue");
		ProcessingApplicationForNewQualifiedCertificateIssue.UpdateQueryOnAddCertificates(
			Query.Text);
	EndIf;
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		Row = CertificatesPropertiesTable.Find(Selection.Thumbprint, "Thumbprint");
		If ButAlreadyAddedOnes Then
			If Row <> Undefined Then // Protection against data errors (duplicate certificates).
				CertificatesPropertiesTable.Delete(Row);
			EndIf;
		ElsIf ValueIsFilled(FilterByCompany) Then
			If Row <> Undefined AND Selection.Company <> FilterByCompany Then // Protection against data errors (duplicate certificates).
				CertificatesPropertiesTable.Delete(Row);
			EndIf;
		Else
			Row.Presentation = Selection.Presentation;
			Row.IsRequest  = Selection.IsRequest;
		EndIf;
	EndDo;
	
EndProcedure

// For the UpdateCertificatesList procedure.
Procedure UpdateValue(PreviousValue, NewValue, SkipNotDefinedValues = False)
	
	If NewValue = Undefined AND SkipNotDefinedValues Then
		Return;
	EndIf;
	
	If PreviousValue <> NewValue Then
		PreviousValue = NewValue;
	EndIf;
	
EndProcedure

// For the SavedCertificateProperties procedure.
Procedure FillAttribute(SavedProperties, AttributesParameters, AttributeName)
	
	If AttributesParameters.Property(AttributeName)
	   AND AttributesParameters[AttributeName].FillingValue <> Undefined Then
		
		SavedProperties[AttributeName] = AttributesParameters[AttributeName].FillingValue;
	EndIf;
	
EndProcedure

// For the SetSigningEncryptionDecryptionForm procedure.
Procedure FillThumbprintsFilter(Form)
	
	Parameters = Form.Parameters;
	
	Filter = New Map;
	
	If TypeOf(Parameters.EncryptionCertificates) = Type("Array") Then
		DetailsList = New Map;
		Thumbprints = New Map;
		ThumbprintsPresentations = New Map;
		
		For each Details In Parameters.EncryptionCertificates Do
			If DetailsList[Details] <> Undefined Then
				Continue;
			EndIf;
			DetailsList.Insert(Details, True);
			Certificates = EncryptionCertificatesFromDetails(Details);
			
			For each Properties In Certificates Do
				Value = Thumbprints[Properties.Thumbprint];
				Value = ?(Value = Undefined, 1, Value + 1);
				Thumbprints.Insert(Properties.Thumbprint, Value);
				ThumbprintsPresentations.Insert(Properties.Thumbprint, Properties.Presentation);
			EndDo;
		EndDo;
		DataItemsCount = Parameters.EncryptionCertificates.Count();
		For each KeyAndValue In Thumbprints Do
			If KeyAndValue.Value = DataItemsCount Then
				Filter.Insert(KeyAndValue.Key, ThumbprintsPresentations[KeyAndValue.Key]);
			EndIf;
		EndDo;
		
	ElsIf Parameters.EncryptionCertificates <> Undefined Then
		
		Certificates = EncryptionCertificatesFromDetails(Parameters.EncryptionCertificates);
		For each Properties In Certificates Do
			Filter.Insert(Properties.Thumbprint, Properties.Presentation);
		EndDo;
	EndIf;
	
	Form.ThumbprintsFilter = PutToTempStorage(Filter, Form.UUID);
	
EndProcedure

// For the FillThumbprintsFilter procedure.
Function EncryptionCertificatesFromDetails(Details)
	
	If TypeOf(Details) = Type("String") Then
		Return GetFromTempStorage(Details);
	EndIf;
	
	Certificates = New Array;
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	EncryptionCertificates.Presentation,
		|	EncryptionCertificates.Thumbprint,
		|	EncryptionCertificates.Certificate
		|FROM
		|	InformationRegister.EncryptionCertificates AS EncryptionCertificates
		|WHERE
		|	EncryptionCertificates.EncryptedObject = &EncryptedObject";
	
	Query.SetParameter("EncryptedObject", Details);
	
	QueryResult = Query.Execute();
	
	DetailedRecordsSelection = QueryResult.Select();
	
	While DetailedRecordsSelection.Next() Do
		CertificateProperties = New Structure("Thumbprint, Presentation, Certificate");
		FillPropertyValues(CertificateProperties, DetailedRecordsSelection);
		CertificateProperties.Certificate = CertificateProperties.Certificate.Get();
		Certificates.Add(CertificateProperties);
	EndDo;
	
	Return Certificates;
	
EndFunction

Function RowBinaryData(RowData)
	
	TempFile = GetTempFileName();
	
	TextWriter = New TextWriter(TempFile, TextEncoding.UTF8);
	TextWriter.Write(RowData);
	TextWriter.Close();
	
	CertificateBinaryData = New BinaryData(TempFile);
	
	DeleteFiles(TempFile);
	
	Return CertificateBinaryData;
	
EndFunction

// For the SetSigningEncryptionDecryptionForm and CertificateOnChangeAtServer procedures.

Procedure FillExistingUserCertificates(ChoiceList, CertificatesThumbprintsAtClient,
			CertificatesFilter, ThumbprintsFilter = Undefined)
	
	ChoiceList.Clear();
	
	If DigitalSignature.GenerateDigitalSignaturesAtServer() Then
		
		CryptoManager = CryptoManager("GetCertificates", False);
		
		If CryptoManager <> Undefined Then
			StorageType = CryptoCertificateStoreType.PersonalCertificates;
			CertificatesArray = CryptoManager.GetCertificateStore(StorageType).GetAll();
			
			DigitalSignatureInternalClientServer.AddCertificatesThumbprints(
				CertificatesThumbprintsAtClient, CertificatesArray, TimeAddition(), CurrentSessionDate());
		EndIf;
	EndIf;
	
	If UseDigitalSignatureSaaS() Then
		ModuleCertificateStore = Common.CommonModule("CertificatesStorage");
		CertificatesArray = ModuleCertificateStore.Get("PersonalCertificates");
		
		DigitalSignatureInternalClientServer.AddCertificatesThumbprints(
			CertificatesThumbprintsAtClient, CertificatesArray, TimeAddition(), CurrentSessionDate());
	EndIf;
	
	FilterByCompany = False;
	
	If TypeOf(CertificatesFilter) = Type("ValueList") Then
		If CertificatesFilter.Count() > 0 Then
			CurrentList = New ValueList;
			For each ListItem In CertificatesFilter Do
				Properties = Common.ObjectAttributesValues(
					ListItem.Value, "Ref, Description, Thumbprint, User");
				
				If CertificatesThumbprintsAtClient.Find(Properties.Thumbprint) <> Undefined Then
					CurrentList.Add(Properties.Ref, Properties.Description,
						Properties.User = Users.AuthorizedUser());
				EndIf;
			EndDo;
			For Each ListItem In CurrentList Do
				If ListItem.Check Then
					ChoiceList.Add(ListItem.Value, ListItem.Presentation);
				EndIf;
			EndDo;
			For Each ListItem In CurrentList Do
				If Not ListItem.Check Then
					ChoiceList.Add(ListItem.Value, ListItem.Presentation);
				EndIf;
			EndDo;
			Return;
		EndIf;
	ElsIf Metadata.DefinedTypes.Company.Type.ContainsType(TypeOf(CertificatesFilter)) Then
		FilterByCompany = True;
	EndIf;
	
	If ThumbprintsFilter <> Undefined Then
		Filter = GetFromTempStorage(ThumbprintsFilter);
		For each Thumbprint In CertificatesThumbprintsAtClient Do
			If Filter[Thumbprint] = Undefined Then
				Continue;
			EndIf;
			ChoiceList.Add(Thumbprint, Filter[Thumbprint]);
		EndDo;
		Query = New Query;
		Query.Parameters.Insert("Thumbprints", ChoiceList.UnloadValues());
		Query.Text =
		"SELECT
		|	Certificates.Ref AS Ref,
		|	Certificates.Description AS Description,
		|	Certificates.Thumbprint
		|FROM
		|	Catalog.DigitalSignatureAndEncryptionKeysCertificates AS Certificates
		|WHERE
		|	Certificates.Thumbprint IN(&Thumbprints)";
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			ListItem = ChoiceList.FindByValue(Selection.Thumbprint);
			If ListItem <> Undefined Then
				ListItem.Value = Selection.Ref;
				ListItem.Presentation = Selection.Description;
			EndIf;
		EndDo;
		ChoiceList.SortByPresentation();
		Return;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("User", Users.CurrentUser());
	Query.Parameters.Insert("Thumbprints", CertificatesThumbprintsAtClient);
	Query.Text =
	"SELECT
	|	Certificates.Ref AS Ref,
	|	Certificates.Description AS Description
	|FROM
	|	Catalog.DigitalSignatureAndEncryptionKeysCertificates AS Certificates
	|WHERE
	|	Certificates.Application <> VALUE(Catalog.DigitalSignatureAndEncryptionApplications.EmptyRef)
	|	AND Certificates.User = &User
	|	AND Certificates.Revoked = FALSE
	|	AND Certificates.Thumbprint IN(&Thumbprints)
	|	AND TRUE
	|
	|ORDER BY
	|	Description";
	
	If FilterByCompany Then
		Query.Text = StrReplace(Query.Text, "TRUE", "Certificates.Company = &Company");
		Query.SetParameter("Company", CertificatesFilter);
	EndIf;
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		ChoiceList.Add(Selection.Ref, Selection.Description);
	EndDo;
	
EndProcedure

Procedure FillCertificateAdditionalProperties(Form)
	
	If Not ValueIsFilled(Form.Certificate) Then
		Return;
	EndIf;
	
	AttributesValues = Common.ObjectAttributesValues(Form.Certificate,
		"StrongPrivateKeyProtection, Thumbprint, Application,
		|ValidBefore, UserNotifiedOfExpirationDate, CertificateData");
	
	Try
		CertificateBinaryData = AttributesValues.CertificateData.Get();
		Certificate = New CryptoCertificate(CertificateBinaryData);
	Except
		ErrorInformation = ErrorInfo();
		Certificate = Form.Certificate;
		Form.Certificate = Undefined;
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'При получении данных сертификата ""%1""
			           |из информационной базы возникла ошибка:
			           |%2'; 
			           |en = 'An error occurred during data retrieval of certificate ""%1"" 
			           |from the infobase:
			           |%2'; 
			           |pl = 'An error occurred during data retrieval of certificate ""%1"" 
			           |from the infobase:
			           |%2';
			           |de = 'An error occurred during data retrieval of certificate ""%1"" 
			           |from the infobase:
			           |%2';
			           |ro = 'An error occurred during data retrieval of certificate ""%1"" 
			           |from the infobase:
			           |%2';
			           |tr = 'An error occurred during data retrieval of certificate ""%1"" 
			           |from the infobase:
			           |%2'; 
			           |es_ES = 'An error occurred during data retrieval of certificate ""%1"" 
			           |from the infobase:
			           |%2'"),
			Certificate,
			BriefErrorDescription(ErrorInformation));
	EndTry;
	
	Form.CertificateAddress = PutToTempStorage(CertificateBinaryData, Form.UUID);
	
	Form.CertificateThumbprint      = AttributesValues.Thumbprint;
	Form.CertificateApplication      = AttributesValues.Application;
	Form.ExecuteInSaaS  = AttributesValues.Application.IsCloudServiceApplication;
	Form.CertificateExpiresOn = AttributesValues.ValidBefore;
	Form.CertificatePrivateKeyAdvancedProtection = AttributesValues.StrongPrivateKeyProtection;
	
	Form.NotifyOfCertificateAboutToExpire =
		Not AttributesValues.UserNotifiedOfExpirationDate
		AND AddMonth(CurrentSessionDate(), 1) > Form.CertificateExpiresOn;
	
	Form.CertificateAtServerErrorDescription = New Structure;
	
	If Not DigitalSignature.GenerateDigitalSignaturesAtServer() Then
		Return;
	EndIf;
	
	GetCertificateByThumbprint(Form.CertificateThumbprint,
		True, False, Form.CertificateApplication, Form.CertificateAtServerErrorDescription);
	
EndProcedure

// For the CryptoManager function.
Function NewCryptoManager(Application, Errors, ComputerName)
	
	ApplicationsDetailsCollection = DigitalSignatureInternalClientServer.CryptoManagerApplicationsDetails(
		Application, Errors, DigitalSignature.CommonSettings().ApplicationsDetailsCollection);
	
	If ApplicationsDetailsCollection = Undefined Then
		Return Undefined;
	EndIf;
	
	IsLinux = Common.IsLinuxServer();
	
	If IsLinux Then
		ApplicationsPathsAtLinuxServers = ApplicationsPathsAtLinuxServers(ComputerName);
	Else
		ApplicationsPathsAtLinuxServers = Undefined;
	EndIf;
	
	Manager = Undefined;
	For each ApplicationDetails In ApplicationsDetailsCollection Do
		
		ApplicationProperties = DigitalSignatureInternalClientServer.CryptoManagerApplicationProperties(
			ApplicationDetails, IsLinux, Errors, True, ApplicationsPathsAtLinuxServers);
		
		If ApplicationProperties = Undefined Then
			Continue;
		EndIf;
		
		Try
			ModuleInformation = CryptoTools.GetCryptoModuleInformation(
				ApplicationProperties.ApplicationName,
				ApplicationProperties.ApplicationPath,
				ApplicationProperties.ApplicationType);
		Except
			DigitalSignatureInternalClientServer.CryptoManagerAddError(Errors,
				ApplicationDetails.Ref, BriefErrorDescription(ErrorInfo()),
				True, True, True);
			Continue;
		EndTry;
		
		If ModuleInformation = Undefined Then
			DigitalSignatureInternalClientServer.CryptoManagerApplicationNotFound(
				ApplicationDetails, Errors, True);
			
			Manager = Undefined;
			Continue;
		EndIf;
		
		If Not IsLinux Then
			ApplicationNameReceived = ModuleInformation.Name;
			
			ApplicationNameMatches = DigitalSignatureInternalClientServer.CryptoManagerApplicationNameMaps(
				ApplicationDetails, ApplicationNameReceived, Errors, True);
			
			If Not ApplicationNameMatches Then
				Manager = Undefined;
				Continue;
			EndIf;
		EndIf;
		
		Try
			Manager = New CryptoManager(
				ApplicationProperties.ApplicationName,
				ApplicationProperties.ApplicationPath,
				ApplicationProperties.ApplicationType);
		Except
			DigitalSignatureInternalClientServer.CryptoManagerAddError(Errors,
				ApplicationDetails.Ref, BriefErrorDescription(ErrorInfo()),
				True, True, True);
			Continue;
		EndTry;
		
		AlgorithmsSet = DigitalSignatureInternalClientServer.CryptoManagerAlgorithmsSet(
			ApplicationDetails, Manager, Errors);
		
		If Not AlgorithmsSet Then
			Continue;
		EndIf;
		
		Break; // The required crypto manager is received.
	EndDo;
	
	Return Manager;
	
EndFunction

Function UseDigitalSignatureSaaS() Export
	
	If Not Common.SubsystemExists("SaaSTechnology.SaaS.DigitalSignatureSaaS") Then
		Return False;
	EndIf;
	
	ModuleDigitalSignatureSaaSClientServer =
		Common.CommonModule("DigitalSignatureSaaSClientServer");
	
	Return ModuleDigitalSignatureSaaSClientServer.UsageAllowed();
	
EndFunction

Function ApplicationsPathsAtLinuxServers(ComputerName)
	
	Query = New Query;
	Query.SetParameter("ComputerName", ComputerName);
	Query.Text =
	"SELECT
	|	ApplicationPaths.Application,
	|	ApplicationPaths.ApplicationPath
	|FROM
	|	InformationRegister.PathsToDigitalSignatureAndEncryptionApplicationsOnLinuxServers AS ApplicationPaths
	|WHERE
	|	ApplicationPaths.ComputerName = &ComputerName";
	
	ApplicationsPathsAtLinuxServers = New Map;
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		ApplicationsPathsAtLinuxServers.Insert(Selection.Application, Selection.ApplicationPath);
	EndDo;
	
	Return ApplicationsPathsAtLinuxServers;
	
EndFunction

// For the GetFilesAndSignaturesMap function.
Function FindSignatureFilesNames(DataFileName, SignatureFilesNames)
	
	SignatureNames = New Array;
	
	NameStructure = CommonClientServer.ParseFullFileName(DataFileName);
	NameWithoutExtension = NameStructure.BaseName;
	
	For Each SignatureFileName In SignatureFilesNames Do
		If StrFind(SignatureFileName, NameWithoutExtension) > 0 Then
			SignatureNames.Add(SignatureFileName);
		EndIf;
	EndDo;
	
	For Each SignatureFileName In SignatureNames Do
		SignatureFilesNames.Delete(SignatureFilesNames.Find(SignatureFileName));
	EndDo;
	
	Return SignatureNames;
	
EndFunction

// For the Sign functions.

// Transforms a crypto certificate into the correctly formatted row in the Base64 format.
//
// Parameters:
//  CertificateData - BinaryData - certificate data that is to be transformed.
// 
// Returns:
//  Row - a certificate transformed into a row in the Base64 format.
//
Function Base64CryptoCertificate(CertificateData)
	
	Base64Row = Base64String(CertificateData);
	
	Value = StrReplace(Base64Row, Chars.CR, "");
	Value = StrReplace(Value, Chars.LF, "");
	
	Return Value;
	
EndFunction

#EndRegion