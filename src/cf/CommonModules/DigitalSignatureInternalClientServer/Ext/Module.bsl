///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Generates a signature file name from a template.
//
Function SignatureFileName(NameWithoutExtension, CertificateOwner, SignatureFilesExtension, SeparatorRequired = True) Export
	
	Separator = ?(SeparatorRequired, " - ", " ");
	
	SignatureFileName = StringFunctionsClientServer.SubstituteParametersToString("%1%2%3.%4",
		NameWithoutExtension, Separator, CertificateOwner, SignatureFilesExtension);
		
	Return CommonClientServer.ReplaceProhibitedCharsInFileName(SignatureFileName);
	
EndFunction

// Generates a certificate file name from a template.
//
Function CertificateFileName(NameWithoutExtension, CertificateOwner, CertificateFilesExtension, SeparatorRequired = True) Export
	
	Separator = ?(SeparatorRequired, " - ", " ");
	
	CertificateFileName = StringFunctionsClientServer.SubstituteParametersToString("%1%2%3.%4",
		NameWithoutExtension, Separator, CertificateOwner, CertificateFilesExtension);
		
	Return CommonClientServer.ReplaceProhibitedCharsInFileName(CertificateFileName);
	
EndFunction

#EndRegion

#Region Private

Function ApplicationDetailsByCryptoProviderName(CryptoProviderName, ApplicationsDetailsCollection) Export
	
	ApplicationFound = False;
	For Each ApplicationDetails In ApplicationsDetailsCollection Do
		If ApplicationDetails.ApplicationName = CryptoProviderName Then
			ApplicationFound = True;
			Break;
		EndIf;
	EndDo;
	
	If ApplicationFound Then
		Return ApplicationDetails;
	EndIf;
	
	Return Undefined;
	
EndFunction

Function InteractiveModeAvailable() Export
	
	SystemInfo = New SystemInfo;
	Return CommonClientServer.CompareVersions(SystemInfo.AppVersion, "8.3.13.1549") >= 0;
	
EndFunction

// For internal use only.
Function CryptoManagerApplicationsDetails(Application, Errors, Val ApplicationsDetailsCollection) Export
	
	If Application <> Undefined Then
		ApplicationNotFound = True;
		For each ApplicationDetails In ApplicationsDetailsCollection Do
			If ApplicationDetails.Ref = Application Then
				ApplicationNotFound = False;
				Break;
			EndIf;
		EndDo;
		If ApplicationNotFound Then
			CryptoManagerAddError(Errors, Application,
				NStr("ru = 'Не предусмотрена для использования.'; en = 'Not for usage.'; pl = 'Not for usage.';de = 'Not for usage.';ro = 'Not for usage.';tr = 'Not for usage.'; es_ES = 'Not for usage.'"), True);
			Return Undefined;
		EndIf;
		ApplicationsDetailsCollection = New Array;
		ApplicationsDetailsCollection.Add(ApplicationDetails);
	EndIf;
	
	Return ApplicationsDetailsCollection;
	
EndFunction

// For internal use only.
Function CryptoManagerApplicationProperties(ApplicationDetails, IsLinux, Errors, IsServer,
			ApplicationsPathsAtLinuxServers) Export
	
	If Not ValueIsFilled(ApplicationDetails.ApplicationName) Then
		CryptoManagerAddError(Errors, ApplicationDetails.Ref,
			NStr("ru = 'Не указано имя программы.'; en = 'Application name is not specified.'; pl = 'Application name is not specified.';de = 'Application name is not specified.';ro = 'Application name is not specified.';tr = 'Application name is not specified.'; es_ES = 'Application name is not specified.'"), True);
		Return Undefined;
	EndIf;
	
	If Not ValueIsFilled(ApplicationDetails.ApplicationType) Then
		CryptoManagerAddError(Errors, ApplicationDetails.Ref,
			NStr("ru = 'Не указан тип программы.'; en = 'Application type is not specified.'; pl = 'Application type is not specified.';de = 'Application type is not specified.';ro = 'Application type is not specified.';tr = 'Application type is not specified.'; es_ES = 'Application type is not specified.'"), True);
		Return Undefined;
	EndIf;
	
	ApplicationProperties = New Structure("ApplicationName, ApplicationPath, ApplicationType");
	
	If IsLinux Then
		ApplicationPath = ApplicationsPathsAtLinuxServers.Get(ApplicationDetails.Ref);
		
		If Not ValueIsFilled(ApplicationPath) Then
			CryptoManagerAddError(Errors, ApplicationDetails.Ref,
				NStr("ru = 'Не предусмотрена для использования.'; en = 'Not for usage.'; pl = 'Not for usage.';de = 'Not for usage.';ro = 'Not for usage.';tr = 'Not for usage.'; es_ES = 'Not for usage.'"), IsServer, , , True);
			Return Undefined;
		EndIf;
	Else
		ApplicationPath = "";
	EndIf;
	
	ApplicationProperties = New Structure;
	ApplicationProperties.Insert("ApplicationName",   ApplicationDetails.ApplicationName);
	ApplicationProperties.Insert("ApplicationPath", ApplicationPath);
	ApplicationProperties.Insert("ApplicationType",   ApplicationDetails.ApplicationType);
	
	Return ApplicationProperties;
	
EndFunction

// For internal use only.
Function CryptoManagerAlgorithmsSet(ApplicationDetails, Manager, Errors) Export
	
	SignAlgorithm = String(ApplicationDetails.SignAlgorithm);
	Try
		Manager.SignAlgorithm = SignAlgorithm;
	Except
		Manager = Undefined;
		// The platform uses the summary message "Unknown crypto algorithm". A more specific message is required.
		CryptoManagerAddError(Errors, ApplicationDetails.Ref, StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Выбран неизвестный алгоритм подписи ""%1"".'; en = 'Unknown signature algorithm ""%1"" is selected.'; pl = 'Unknown signature algorithm ""%1"" is selected.';de = 'Unknown signature algorithm ""%1"" is selected.';ro = 'Unknown signature algorithm ""%1"" is selected.';tr = 'Unknown signature algorithm ""%1"" is selected.'; es_ES = 'Unknown signature algorithm ""%1"" is selected.'"), SignAlgorithm), True);
		Return False;
	EndTry;
	
	HashAlgorithm = String(ApplicationDetails.HashAlgorithm);
	Try
		Manager.HashAlgorithm = HashAlgorithm;
	Except
		Manager = Undefined;
		// The platform uses the summary message "Unknown crypto algorithm". A more specific message is required.
		CryptoManagerAddError(Errors, ApplicationDetails.Ref, StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Выбран неизвестный алгоритм хеширования ""%1"".'; en = 'Unknown hash algorithm ""%1"" is selected.'; pl = 'Unknown hash algorithm ""%1"" is selected.';de = 'Unknown hash algorithm ""%1"" is selected.';ro = 'Unknown hash algorithm ""%1"" is selected.';tr = 'Unknown hash algorithm ""%1"" is selected.'; es_ES = 'Unknown hash algorithm ""%1"" is selected.'"), HashAlgorithm), True);
		Return False;
	EndTry;
	
	EncryptionAlgorithm = String(ApplicationDetails.EncryptAlgorithm);
	Try
		Manager.EncryptAlgorithm = EncryptionAlgorithm;
	Except
		Manager = Undefined;
		// The platform uses the summary message "Unknown crypto algorithm". A more specific message is required.
		CryptoManagerAddError(Errors, ApplicationDetails.Ref, StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Выбран неизвестный алгоритм шифрования ""%1"".'; en = 'Unknown encryption algorithm ""%1"" is selected.'; pl = 'Unknown encryption algorithm ""%1"" is selected.';de = 'Unknown encryption algorithm ""%1"" is selected.';ro = 'Unknown encryption algorithm ""%1"" is selected.';tr = 'Unknown encryption algorithm ""%1"" is selected.'; es_ES = 'Unknown encryption algorithm ""%1"" is selected.'"), EncryptionAlgorithm), True);
		Return False;
	EndTry;
	
	Return True;
	
EndFunction

// For internal use only.
Procedure CryptoManagerApplicationNotFound(ApplicationDetails, Errors, IsServer) Export
	
	CryptoManagerAddError(Errors, ApplicationDetails.Ref,
		NStr("ru = 'Программа не найдена на компьютере.'; en = 'Application was not found on computer.'; pl = 'Application was not found on computer.';de = 'Application was not found on computer.';ro = 'Application was not found on computer.';tr = 'Application was not found on computer.'; es_ES = 'Application was not found on computer.'"), IsServer, True);
	
EndProcedure

// For internal use only.
Function CryptoManagerApplicationNameMaps(ApplicationDetails, ApplicationNameReceived, Errors, IsServer) Export
	
	If ApplicationNameReceived <> ApplicationDetails.ApplicationName Then
		CryptoManagerAddError(Errors, ApplicationDetails.Ref, StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Получена другая программа с именем ""%1"".'; en = 'Another application with name ""%1"" received.'; pl = 'Another application with name ""%1"" received.';de = 'Another application with name ""%1"" received.';ro = 'Another application with name ""%1"" received.';tr = 'Another application with name ""%1"" received.'; es_ES = 'Another application with name ""%1"" received.'"), ApplicationNameReceived), IsServer, True);
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

// For internal use only.
Procedure CryptoManagerAddError(Errors, Application, Details,
			ToAdministrator, Instruction = False, FromException = False, PathNotSpecified = False) Export
	
	ErrorProperties = New Structure;
	ErrorProperties.Insert("Application",         Application);
	ErrorProperties.Insert("Details",          Details);
	ErrorProperties.Insert("ToAdministrator",   ToAdministrator);
	ErrorProperties.Insert("Instruction",        Instruction);
	ErrorProperties.Insert("FromException",      FromException);
	ErrorProperties.Insert("PathNotSpecified",      PathNotSpecified);
	ErrorProperties.Insert("ApplicationsSetUp", True);
	
	Errors.Add(ErrorProperties);
	
EndProcedure

// For internal use only.
Function CertificateCheckModes(IgnoreTimeValidity = False) Export
	
	CheckModesArray = New Array;
	CheckModesArray.Add(CryptoCertificateCheckMode.AllowTestCertificates);
	
	If IgnoreTimeValidity Then
		CheckModesArray.Add(CryptoCertificateCheckMode.IgnoreTimeValidity);
	EndIf;
	
	Return CheckModesArray;
	
EndFunction

// For internal use only.
Function CertificateOverdue(Certificate, OnDate, TimeAddition) Export
	
	If Not ValueIsFilled(OnDate) Then
		Return "";
	EndIf;
	
	CertificateDates = CertificateDates(Certificate, TimeAddition);
	
	If CertificateDates.ValidTo > BegOfDay(OnDate) Then
		Return "";
	EndIf;
	
	Return StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'На %1 просрочен сертификат.'; en = 'Certificate is overdue on %1.'; pl = 'Certificate is overdue on %1.';de = 'Certificate is overdue on %1.';ro = 'Certificate is overdue on %1.';tr = 'Certificate is overdue on %1.'; es_ES = 'Certificate is overdue on %1.'"), Format(BegOfDay(OnDate), "DLF=D"));
	
EndFunction

// For internal use only.
Function StorageTypeToSearchCertificate(InPersonalStorageOnly) Export
	
	If TypeOf(InPersonalStorageOnly) = Type("CryptoCertificateStoreType") Then
		StorageType = InPersonalStorageOnly;
	ElsIf InPersonalStorageOnly Then
		StorageType = CryptoCertificateStoreType.PersonalCertificates;
	Else
		StorageType = Undefined; // The storage that contains certificates of all available types.
	EndIf;
	
	Return StorageType;
	
EndFunction

// For internal use only.
Procedure AddCertificatesProperties(Table, CertificatesArray, NoFilter,
			TimeAddition, CurrentSessionDate, ThumbprintsOnly = False, InCloudService = False) Export
	
	If ThumbprintsOnly Then
		AlreadyAddedCertificatesThumbprints = Table;
		AtServer = False;
	Else
		AlreadyAddedCertificatesThumbprints = New Map; // To skip duplicates.
		AtServer = TypeOf(Table) <> Type("Array");
	EndIf;
	
	ModuleLocalization = ModuleLocalization();
	
	For Each CurrentCertificate In CertificatesArray Do
		Thumbprint = Base64String(CurrentCertificate.Thumbprint);
		CertificateDates = CertificateDates(CurrentCertificate, TimeAddition);
		
		If CertificateDates.ValidTo <= CurrentSessionDate Then
			If Not NoFilter Then
				Continue; // Skipping overdue certificates.
			EndIf;
		EndIf;
		
		If AlreadyAddedCertificatesThumbprints.Get(Thumbprint) <> Undefined Then
			Continue;
		EndIf;
		AlreadyAddedCertificatesThumbprints.Insert(Thumbprint, True);
		
		If ThumbprintsOnly Then
			Continue;
		EndIf;
		
		If AtServer Then
			Row = Table.Find(Thumbprint, "Thumbprint");
			If Row <> Undefined Then
				If InCloudService Then
					Row.InCloudService = True;
				EndIf;
				Continue; // Skipping certificates already added on the client.
			EndIf;
		EndIf;
		
		CertificateProperties = New Structure;
		CertificateProperties.Insert("Thumbprint", Thumbprint);
		
		CertificateProperties.Insert("Presentation",
			CertificatePresentation(CurrentCertificate, TimeAddition, ModuleLocalization));
		
		CertificateProperties.Insert("IssuedBy", IssuerPresentation(CurrentCertificate, ModuleLocalization));
		
		If TypeOf(Table) = Type("Array") Then
			Table.Add(CertificateProperties);
		Else
			If InCloudService Then
				CertificateProperties.Insert("InCloudService", True);
			ElsIf AtServer Then
				CertificateProperties.Insert("AtServer", True);
			EndIf;
			FillPropertyValues(Table.Add(), CertificateProperties);
		EndIf;
	EndDo;
	
EndProcedure

Function ModuleLocalization()
	
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	If DigitalSignatureInternalCached.CommonSettings().CertificateIssueRequestAvailable Then
		Return Common.CommonModule("DigitalSignatureLocalizationClientServer");
	EndIf;
#Else
	If StandardSubsystemsClient.ClientRunParameters().DigitalSignature.CommonSettings.CertificateIssueRequestAvailable Then
		Return CommonClient.CommonModule("DigitalSignatureLocalizationClientServer");
	EndIf;
#EndIf
	Return Undefined;

EndFunction

// For internal use only.
Procedure AddCertificatesThumbprints(Array, CertificatesArray, TimeAddition, CurrentSessionDate) Export
	
	For Each CurrentCertificate In CertificatesArray Do
		Thumbprint = Base64String(CurrentCertificate.Thumbprint);
		CertificateDates = CertificateDates(CurrentCertificate, TimeAddition);
		
		If CertificateDates.ValidTo <= CurrentSessionDate Then
			Continue; // Skipping overdue certificates.
		EndIf;
		
		Array.Add(Thumbprint);
	EndDo;
	
EndProcedure

// For internal use only.
Function SignatureProperties(SignatureBinaryData, CertificateProperties, Comment,
			AuthorizedUser, SignatureFileName = "") Export
	
	SignatureProperties = New Structure;
	SignatureProperties.Insert("Signature",             SignatureBinaryData);
	SignatureProperties.Insert("SignatureSetBy", AuthorizedUser);
	SignatureProperties.Insert("Comment",         Comment);
	SignatureProperties.Insert("SignatureFileName",     SignatureFileName);
	SignatureProperties.Insert("SignatureDate",         Date('00010101')); // It is set before write.
	SignatureProperties.Insert("SignatureValidationDate", Date('00010101')); // Last signature check date.
	SignatureProperties.Insert("SignatureCorrect",        False);             // Last signature check result.
	// Derivative properties:
	SignatureProperties.Insert("Certificate",          CertificateProperties.BinaryData);
	SignatureProperties.Insert("Thumbprint",           CertificateProperties.Thumbprint);
	SignatureProperties.Insert("CertificateOwner", CertificateProperties.IssuedTo);
	
	Return SignatureProperties;
	
EndFunction

// For internal use only.
Function DataGettingErrorTitle(Operation) Export
	
	If Operation = "Signing" Then
		Return NStr("ru = 'При получении данных для подписания возникла ошибка:'; en = 'Error occurred when receiving data for signing:'; pl = 'Error occurred when receiving data for signing:';de = 'Error occurred when receiving data for signing:';ro = 'Error occurred when receiving data for signing:';tr = 'Error occurred when receiving data for signing:'; es_ES = 'Error occurred when receiving data for signing:'");
		
	ElsIf Operation = "Encryption" Then
		Return NStr("ru = 'При получении данных для шифрования возникла ошибка:'; en = 'An error occurred when retrieving data to be encrypted:'; pl = 'An error occurred when retrieving data to be encrypted:';de = 'An error occurred when retrieving data to be encrypted:';ro = 'An error occurred when retrieving data to be encrypted:';tr = 'An error occurred when retrieving data to be encrypted:'; es_ES = 'An error occurred when retrieving data to be encrypted:'");
	Else
		Return NStr("ru = 'При получении данных для расшифровки возникла ошибка:'; en = 'An error occurred while receiving decryption data:'; pl = 'An error occurred while receiving decryption data:';de = 'An error occurred while receiving decryption data:';ro = 'An error occurred while receiving decryption data:';tr = 'An error occurred while receiving decryption data:'; es_ES = 'An error occurred while receiving decryption data:'");
	EndIf;
	
EndFunction

// For internal use only.
Function BlankSignatureData(SignatureData, ErrorDescription) Export
	
	If Not ValueIsFilled(SignatureData) Then
		ErrorDescription = NStr("ru = 'Сформирована пустая подпись.'; en = 'Empty signature is generated.'; pl = 'Empty signature is generated.';de = 'Empty signature is generated.';ro = 'Empty signature is generated.';tr = 'Empty signature is generated.'; es_ES = 'Empty signature is generated.'");
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

// For internal use only.
Function BlankEncryptedData(EncryptedData, ErrorDescription) Export
	
	If Not ValueIsFilled(EncryptedData) Then
		ErrorDescription = NStr("ru = 'Сформированы пустые данные.'; en = 'Empty data is generated.'; pl = 'Empty data is generated.';de = 'Empty data is generated.';ro = 'Empty data is generated.';tr = 'Empty data is generated.'; es_ES = 'Empty data is generated.'");
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

// For internal use only.
Function BlankDecryptedData(DecryptedData, ErrorDescription) Export
	
	If Not ValueIsFilled(DecryptedData) Then
		ErrorDescription = NStr("ru = 'Сформированы пустые данные.'; en = 'Empty data is generated.'; pl = 'Empty data is generated.';de = 'Empty data is generated.';ro = 'Empty data is generated.';tr = 'Empty data is generated.'; es_ES = 'Empty data is generated.'");
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

// For internal use only.
Function SigningDateUniversal(SignatureBinaryDataBuffer) Export
	
	SigningDate = Undefined;
	
	Position = 0;
	For Each Byte In SignatureBinaryDataBuffer Do
		If Byte = 15 AND IsDateTitle(SignatureBinaryDataBuffer, Position) Then
			DateAsString = DateAsString(SignatureBinaryDataBuffer, Position);
			If AreDigits(DateAsString) Then
				Try
					SigningDate = Date("20" + DateAsString); // Universal time.
					Break;
				Except
					SigningDate = Undefined;
				EndTry;
			EndIf;
		EndIf;
		Position = Position + 1;
	EndDo;
	
	Return SigningDate;
	
EndFunction

// Finds the tag content in XML.
//
// Parameters:
//  Text - String - a searched XML text.
//  TagName - String - a tag whose content is to be found.
//  IncludeOpeningClosingTag - Boolean - flag shows whether the items found by the tag are required. 
//                                               This tag was used for the search, the default value is False.
//  SerialNumber - Number - a position, from which the search starts, the default value is 1.
// 
// Returns:
//   String - a string, from which a new line character and a carriage return character are deleted.
//
Function FindInXML(Text, TagName, IncludeStartEndTag = False, SerialNumber = 1) Export
	
	Result = Undefined;
	
	Start    = "<"  + TagName;
	End = "</" + TagName + ">";
	
	Content = Mid(
		Text,
		StrFind(Text, Start, SearchDirection.FromBegin, 1, SerialNumber),
		StrFind(Text, End, SearchDirection.FromBegin, 1, SerialNumber) + StrLen(End) - StrFind(Text, Start, SearchDirection.FromBegin, 1, SerialNumber));
		
	If IncludeStartEndTag Then
		
		Result = TrimAll(Content);
		
	Else
		
		StartTag = Left(Content, StrFind(Content, ">"));
		Content = StrReplace(Content, StartTag, "");
		
		EndTag = Right(Content, StrLen(Content) - StrFind(Content, "<", SearchDirection.FromEnd) + 1);
		Content = StrReplace(Content, EndTag, "");
		
		Result = TrimAll(Content);
		
	EndIf;
	
	Return Result;
	
EndFunction

// See DigitalSignatureClient.CertificatePresentation. 
Function CertificatePresentation(Certificate, TimeAddition, ModuleLocalization) Export
	
	Presentation = "";
	If ModuleLocalization <> Undefined Then
		Presentation = ModuleLocalization.CertificatePresentation(Certificate, TimeAddition);
	EndIf;	
	If IsBlankString(Presentation) Then
		CertificateDates = CertificateDates(Certificate, TimeAddition);
		Return StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = '%1, до %2'; en = '%1, to %2'; pl = '%1, to %2';de = '%1, to %2';ro = '%1, to %2';tr = '%1, to %2'; es_ES = '%1, to %2'"),
			SubjectPresentation(Certificate, ModuleLocalization),
			Format(CertificateDates.ValidTo, "DF=MM.yyyy"));
	EndIf;	
	Return Presentation;
	
EndFunction

// See DigitalSignatureClient.SubjectPresentation. 
Function SubjectPresentation(Certificate, ModuleLocalization) Export 
	
	Presentation = "";
	If ModuleLocalization <> Undefined Then
		Presentation = ModuleLocalization.SubjectPresentation(Certificate);
	EndIf;	
	If IsBlankString(Presentation) Then
		Subject = CertificateSubjectProperties(Certificate, ModuleLocalization);
		If ValueIsFilled(Subject.CommonName) Then
			Presentation = Subject.CommonName;
		EndIf;
	EndIf;	
	Return Presentation;
	
EndFunction

// See DigitalSignatureClient.IssuerPresentation. 
Function IssuerPresentation(Certificate, ModuleLocalization) Export
	
	CertificateAuthority = CertificateIssuerProperties(Certificate, ModuleLocalization);
	
	Presentation = "";
	
	If ValueIsFilled(CertificateAuthority.CommonName) Then
		Presentation = CertificateAuthority.CommonName;
	EndIf;
	
	If ValueIsFilled(CertificateAuthority.CommonName)
	   AND ValueIsFilled(CertificateAuthority.Company)
	   AND StrFind(CertificateAuthority.CommonName, CertificateAuthority.Company) = 0 Then
		
		Presentation = CertificateAuthority.CommonName + ", " + CertificateAuthority.Company;
	EndIf;
	
	If ValueIsFilled(CertificateAuthority.Department) Then
		Presentation = Presentation + ", " + CertificateAuthority.Department;
	EndIf;
	
	Return Presentation;
	
EndFunction

// See DigitalSignatureClient.CertificateProperties. 
Function CertificateProperties(Certificate, TimeAddition, ModuleLocalization) Export
	
	CertificateDates = CertificateDates(Certificate, TimeAddition);
	
	Properties = New Structure;
	Properties.Insert("Thumbprint",      Base64String(Certificate.Thumbprint));
	Properties.Insert("SerialNumber",  Certificate.SerialNumber);
	Properties.Insert("Presentation",  CertificatePresentation(Certificate, TimeAddition, ModuleLocalization));
	Properties.Insert("IssuedTo",      SubjectPresentation(Certificate, ModuleLocalization));
	Properties.Insert("IssuedBy",       IssuerPresentation(Certificate, ModuleLocalization));
	Properties.Insert("ValidFrom",     CertificateDates.ValidFrom);
	Properties.Insert("ValidTo",  CertificateDates.ValidTo);
	Properties.Insert("ValidBefore", CertificateDates.ValidTo);
	Properties.Insert("Purpose",     GetPurpose(Certificate));
	Properties.Insert("Signing",     Certificate.UseToSign);
	Properties.Insert("Encryption",     Certificate.UseToEncrypt);
	
	Return Properties;
	
EndFunction

// Fills in the table of certificate description from four fields: IssuedTo, IssuedBy, ValidTo, Purpose.
Procedure FillCertificateDataDetails(Table, CertificateProperties) Export
	
	If CertificateProperties.Signing AND CertificateProperties.Encryption Then
		Purpose = NStr("ru = 'Подписание данных, Шифрование данных'; en = 'Data signing, Data encryption'; pl = 'Data signing, Data encryption';de = 'Data signing, Data encryption';ro = 'Data signing, Data encryption';tr = 'Data signing, Data encryption'; es_ES = 'Data signing, Data encryption'");
		
	ElsIf CertificateProperties.Signing Then
		Purpose = NStr("ru = 'Подписание данных'; en = 'Data signing'; pl = 'Data signing';de = 'Data signing';ro = 'Data signing';tr = 'Data signing'; es_ES = 'Data signing'");
	Else
		Purpose = NStr("ru = 'Шифрование данных'; en = 'Data encryption'; pl = 'Data encryption';de = 'Data encryption';ro = 'Data encryption';tr = 'Data encryption'; es_ES = 'Data encryption'");
	EndIf;
	
	Table.Clear();
	String = Table.Add();
	String.Property = NStr("ru = 'Кому выдан:'; en = 'Owner:'; pl = 'Owner:';de = 'Owner:';ro = 'Owner:';tr = 'Owner:'; es_ES = 'Owner:'");
	String.Value = TrimAll(CertificateProperties.IssuedTo);
	
	String = Table.Add();
	String.Property = NStr("ru = 'Кем выдан:'; en = 'Issued by:'; pl = 'Issued by:';de = 'Issued by:';ro = 'Issued by:';tr = 'Issued by:'; es_ES = 'Issued by:'");
	String.Value = TrimAll(CertificateProperties.IssuedBy);
	
	String = Table.Add();
	String.Property = NStr("ru = 'Действителен до:'; en = 'Expiration date:'; pl = 'Expiration date:';de = 'Expiration date:';ro = 'Expiration date:';tr = 'Expiration date:'; es_ES = 'Expiration date:'");
	String.Value = Format(CertificateProperties.ValidTo, "DLF=D");
	
	String = Table.Add();
	String.Property = NStr("ru = 'Назначение:'; en = 'Assignment:'; pl = 'Assignment:';de = 'Assignment:';ro = 'Assignment:';tr = 'Assignment:'; es_ES = 'Assignment:'");
	String.Value = Purpose;
	
EndProcedure

// See DigitalSignatureClient.CertificateSubjectProperties. 
Function CertificateSubjectProperties(Certificate, ModuleLocalization) Export
	
	Subject = Certificate.Subject;
	
	Properties = New Structure;
	Properties.Insert("CommonName");
	Properties.Insert("Country");
	Properties.Insert("State");
	Properties.Insert("Locality");
	Properties.Insert("Street");
	Properties.Insert("Company");
	Properties.Insert("Department");
	Properties.Insert("Email");
	Properties.Insert("LastName");
	Properties.Insert("Name");
	
	If Subject.Property("CN") Then
		Properties.CommonName = PrepareRow(Subject.CN);
	EndIf;
	
	If Subject.Property("C") Then
		Properties.Country = PrepareRow(Subject.C);
	EndIf;
	
	If Subject.Property("ST") Then
		Properties.State = PrepareRow(Subject.ST);
	EndIf;
	
	If Subject.Property("L") Then
		Properties.Locality = PrepareRow(Subject.L);
	EndIf;
	
	If Subject.Property("Street") Then
		Properties.Street = PrepareRow(Subject.Street);
	EndIf;
	
	If Subject.Property("O") Then
		Properties.Company = PrepareRow(Subject.O);
	EndIf;
	
	If Subject.Property("OU") Then
		Properties.Department = PrepareRow(Subject.OU);
	EndIf;
	
	If Subject.Property("E") Then
		Properties.Email = PrepareRow(Subject.E);
	EndIf;
	
	If ModuleLocalization <> Undefined Then
		AdvancedProperties = ModuleLocalization.ExtendedCertificateSubjectProperties(Subject);
		CommonClientServer.SupplementStructure(Properties, AdvancedProperties, True);
	EndIf;
	
	Return Properties;
	
EndFunction

// See DigitalSignatureClient.CertificateIssuerProperties. 
Function CertificateIssuerProperties(Certificate, ModuleLocalization) Export
	
	CertificateAuthority = Certificate.Issuer;
	
	Properties = New Structure;
	Properties.Insert("CommonName");
	Properties.Insert("Country");
	Properties.Insert("State");
	Properties.Insert("Locality");
	Properties.Insert("Street");
	Properties.Insert("Company");
	Properties.Insert("Department");
	Properties.Insert("Email");
	
	If CertificateAuthority.Property("CN") Then
		Properties.CommonName = PrepareRow(CertificateAuthority.CN);
	EndIf;
	
	If CertificateAuthority.Property("C") Then
		Properties.Country = PrepareRow(CertificateAuthority.C);
	EndIf;
	
	If CertificateAuthority.Property("ST") Then
		Properties.State = PrepareRow(CertificateAuthority.ST);
	EndIf;
	
	If CertificateAuthority.Property("L") Then
		Properties.Locality = PrepareRow(CertificateAuthority.L);
	EndIf;
	
	If CertificateAuthority.Property("Street") Then
		Properties.Street = PrepareRow(CertificateAuthority.Street);
	EndIf;
	
	If CertificateAuthority.Property("O") Then
		Properties.Company = PrepareRow(CertificateAuthority.O);
	EndIf;
	
	If CertificateAuthority.Property("OU") Then
		Properties.Department = PrepareRow(CertificateAuthority.OU);
	EndIf;
	
	If CertificateAuthority.Property("E") Then
		Properties.Email = PrepareRow(CertificateAuthority.E);
	EndIf;
	
	If ModuleLocalization <> Undefined Then
		AdvancedProperties = ModuleLocalization.ExtendedCertificateIssuerProperties(CertificateAuthority);
		CommonClientServer.SupplementStructure(Properties, AdvancedProperties, True);
	EndIf;
	
	Return Properties;
	
EndFunction

// See DigitalSignatureClient.XMLDSigParameters. 
Function XMLDSigParameters() Export
	
	SigningAlgorithmData = New Structure;
	
	SigningAlgorithmData.Insert("XPathSignedInfo",       "");
	SigningAlgorithmData.Insert("XPathTagToSign", "");
	
	SigningAlgorithmData.Insert("SIgnatureAlgorithmName", "");
	SigningAlgorithmData.Insert("SignatureAlgorithmOID", "");
	
	SigningAlgorithmData.Insert("HashAlgorithmName", "");
	SigningAlgorithmData.Insert("HashingAlgorithmOID", "");
	
	SigningAlgorithmData.Insert("SignAlgorithm",     "");
	SigningAlgorithmData.Insert("HashAlgorithm", "");
	
	Return SigningAlgorithmData;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Auxiliary procedures and functions.

// For the CertificateOverdue, CertificatePresentation, and CertificateProperties functions.
Function CertificateDates(Certificate, TimeAddition) Export
	
	CertificateDates = New Structure;
	CertificateDates.Insert("ValidFrom",    Certificate.ValidFrom    + TimeAddition);
	CertificateDates.Insert("ValidTo", Certificate.ValidTo + TimeAddition);
	
	Return CertificateDates;
	
EndFunction

// For the CertificateProperties function.
Function GetPurpose(Certificate)
	
	If Not Certificate.Extensions.Property("EKU") Then
		Return "";
	EndIf;
	
	FixedPropertiesArray = Certificate.Extensions.EKU;
	
	Assignment = "";
	
	For Index = 0 To FixedPropertiesArray.Count() - 1 Do
		Assignment = Assignment + FixedPropertiesArray.Get(Index);
		Assignment = Assignment + Chars.LF;
	EndDo;
	
	Return PrepareRow(Assignment);
	
EndFunction

// For the CertificateSubjectProperties and CertificateIssuerProperties functions.
Function PrepareRow(RowFromCertificate)
	
	Return TrimAll(CommonClientServer.ReplaceProhibitedXMLChars(RowFromCertificate));
	
EndFunction

// For the SigningDateUniversal procedure.
Function AreDigits(Row)
	
	For CharNumber = 1 To StrLen(Row) Do
		CurrentChar = Mid(Row, CharNumber, 1);
		If CurrentChar < "0" Or CurrentChar > "9" Then
			Return False;
		EndIf;
	EndDo;
	
	Return True;
	
EndFunction

// For the SigningDateUniversal procedure.
Function IsDateTitle(BinaryDataBuffer, Position)
	
	If BinaryDataBuffer.Size - Position < 3 Then
		Return False;
	EndIf;
	
	TitleBuffer = BinaryDataBuffer.Read(Position, 3);
	
	If TitleBuffer.Size = 3
	   AND TitleBuffer[1] = 23
	   AND TitleBuffer[2] = 13 Then
		
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

// For the SigningDateUniversal procedure.
Function DateAsString(BinaryDataBuffer, Position)
	
	DatePresentation = "";
	
	If BinaryDataBuffer.Size - (Position + 3) < 12 Then
		Return DatePresentation;
	EndIf;
	
	DateBuffer = BinaryDataBuffer.Read(Position + 3, 12);
	
	For Each Byte In DateBuffer Do
		DatePresentation = DatePresentation + Char(Byte);
	EndDo;
	
	Return DatePresentation;
	
EndFunction

#EndRegion
