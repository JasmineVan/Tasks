///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// For internal usage only
Function PersonalCertificates(CertificatesPropertiesAtClient, Filter, Error = "") Export
	
	CertificatesPropertiesTable = New ValueTable;
	CertificatesPropertiesTable.Columns.Add("Thumbprint", New TypeDescription("String", , , , New StringQualifiers(255)));
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
		
		CryptoManager = DigitalSignatureInternal.CryptoManager("GetCertificates", False, Error);
		If CryptoManager <> Undefined Then
			
			CertificatesArray = CryptoManager.GetCertificateStore(
				CryptoCertificateStoreType.PersonalCertificates).GetAll();
			
			DigitalSignatureInternalClientServer.AddCertificatesProperties(CertificatesPropertiesTable,
				CertificatesArray, True, DigitalSignatureInternal.TimeAddition(), CurrentSessionDate());
		EndIf;
	EndIf;
	
	If DigitalSignatureInternal.UseDigitalSignatureSaaS() Then
		ModuleCertificateStore = Common.CommonModule("CertificatesStorage");
		CertificatesArray = ModuleCertificateStore.Get("PersonalCertificates");
		
		DigitalSignatureInternalClientServer.AddCertificatesProperties(CertificatesPropertiesTable,
			CertificatesArray, True, DigitalSignatureInternal.TimeAddition(), CurrentSessionDate(), , True);
	EndIf;
	
	Return ProcessPersonalCertificates(CertificatesPropertiesTable, Filter);
	
EndFunction

// For internal usage only
Function ProcessPersonalCertificates(CertificatesPropertiesTable, Filter)
	
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
		|	Certificates.Description AS Description,
		|	Certificates.Company,
		|	Certificates.Ref,
		|	Certificates.CertificateData
		|FROM
		|	Catalog.DigitalSignatureAndEncryptionKeysCertificates AS Certificates
		|		INNER JOIN Thumbprints AS Thumbprints
		|		ON Certificates.Thumbprint = Thumbprints.Thumbprint
		|WHERE
		|	NOT Certificates.Application = VALUE(Catalog.DigitalSignatureAndEncryptionApplications.EmptyRef)
		|	AND NOT Certificates.User = VALUE(Catalog.Users.EmptyRef)
		|	AND Certificates.Company = &Company";
		
	If Not Filter.CertificatesWithFilledProgramOnly Then
		Query.Text = StrReplace(Query.Text, "NOT Certificates.Application = VALUE(Catalog.DigitalSignatureAndEncryptionApplications.EmptyRef)", "TRUE");
	EndIf;
	If Filter.IncludeCertificatesWithBlankUser Then
		Query.Text = StrReplace(Query.Text, "NOT Certificates.User = VALUE(Catalog.Users.EmptyRef)", "TRUE");
	EndIf;
	If ValueIsFilled(Filter.Company) Then
		Query.SetParameter("Company", Filter.Company);
	Else
		Query.Text = StrReplace(Query.Text, "Certificates.Company = &Company", "TRUE");
	EndIf;
	Selection = Query.Execute().Select();
	
	PersonalCertificatesArray = New Array;
	
	While Selection.Next() Do
		Row = CertificatesPropertiesTable.Find(Selection.Thumbprint, "Thumbprint");
		If Row <> Undefined Then
			CertificateStructure = New Structure("Ref, Description, Thumbprint, Data, Company");
			FillPropertyValues(CertificateStructure, Selection);
			CertificateStructure.Data = PutToTempStorage(Selection.CertificateData, Undefined);
			PersonalCertificatesArray.Add(CertificateStructure);
		EndIf;
	EndDo;
	
	Return PersonalCertificatesArray;
	
EndFunction

// For internal use only.
Function VerifySignature(SourceDataAddress, SignatureAddress, ErrorDescription) Export
	
	Return DigitalSignature.VerifySignature(Undefined, SourceDataAddress, SignatureAddress, ErrorDescription);
	
EndFunction

// For internal use only.
Function CheckCertificate(CertificateAddress, ErrorDescription, OnDate) Export
	
	Return DigitalSignature.CheckCertificate(Undefined, CertificateAddress, ErrorDescription, OnDate);
	
EndFunction

// For internal use only.
Function CertificateRef(Thumbprint, CertificateAddress) Export
	
	If ValueIsFilled(CertificateAddress) Then
		BinaryData = GetFromTempStorage(CertificateAddress);
		Certificate = New CryptoCertificate(BinaryData);
		Thumbprint = Base64String(Certificate.Thumbprint);
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Thumbprint", Thumbprint);
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

// For internal use only.
Function SubjectPresentation(CertificateAddress) Export
	
	CertificateData = GetFromTempStorage(CertificateAddress);
	
	CryptoCertificate = New CryptoCertificate(CertificateData);
	
	CertificateAddress = PutToTempStorage(CertificateData, CertificateAddress);
	
	Return DigitalSignature.SubjectPresentation(CryptoCertificate);
	
EndFunction

// For internal use only.
Function ExecuteAtServerSide(Val Parameters, ResultAddress, OperationStarted, ErrorAtServer) Export
	
	CryptoManager = DigitalSignatureInternal.CryptoManager(Parameters.Operation,
		False, ErrorAtServer, Parameters.CertificateApplication);
	
	If CryptoManager = Undefined Then
		Return False;
	EndIf;
	
	// If a personal crypto certificate is not used, it does not need to be searched for.
	If Parameters.Operation <> "Encryption"
	 Or ValueIsFilled(Parameters.CertificateThumbprint) Then
		
		CryptoCertificate = DigitalSignatureInternal.GetCertificateByThumbprint(
			Parameters.CertificateThumbprint, True, False, Parameters.CertificateApplication, ErrorAtServer);
		
		If CryptoCertificate = Undefined Then
			Return False;
		EndIf;
	EndIf;
	
	Try
		Data = GetFromTempStorage(Parameters.DataItemForSErver.Data);
	Except
		ErrorInformation = ErrorInfo();
		ErrorAtServer.Insert("ErrorDescription",
			DigitalSignatureInternalClientServer.DataGettingErrorTitle(Parameters.Operation)
			+ Chars.LF + BriefErrorDescription(ErrorInformation));
		Return False;
	EndTry;
	
	IsXMLDSig = (TypeOf(Data) = Type("Structure")
	            AND Data.Property("XMLDSigParameters"));
	
	If IsXMLDSig Then
		
		If Parameters.Operation <> "Signing" Then
			ErrorAtServer.Insert("ErrorDescription",
				DigitalSignatureInternalClientServer.DataGettingErrorTitle(Parameters.Operation)
				+ Chars.LF + NStr("ru = 'Внешняя компонента XMLDSig может использоваться только для подписания.'; en = 'External component XMLDSig can be used only for signing.'; pl = 'External component XMLDSig can be used only for signing.';de = 'External component XMLDSig can be used only for signing.';ro = 'External component XMLDSig can be used only for signing.';tr = 'External component XMLDSig can be used only for signing.'; es_ES = 'External component XMLDSig can be used only for signing.'"));
			Return False;
		EndIf;
		
		CryptoManager.PrivateKeyAccessPassword = Parameters.PasswordValue;
		Try
			ResultBinaryData = DigitalSignatureInternal.Sign(
				Data.SOAPEnvelope,
				Data.XMLDSigParameters,
				CryptoCertificate,
				CryptoManager);
		Except
			ErrorInformation = ErrorInfo();
		EndTry;
		
	Else
		
		ErrorDescription = "";
		If Parameters.Operation = "Signing" Then
			CryptoManager.PrivateKeyAccessPassword = Parameters.PasswordValue;
			Try
				ResultBinaryData = CryptoManager.Sign(Data, CryptoCertificate);
				DigitalSignatureInternalClientServer.BlankSignatureData(ResultBinaryData, ErrorDescription);
			Except
				ErrorInformation = ErrorInfo();
			EndTry;
		ElsIf Parameters.Operation = "Encryption" Then
			Certificates = CryptoCertificates(Parameters.CertificatesAddress);
			Try
				ResultBinaryData = CryptoManager.Encrypt(Data, Certificates);
				DigitalSignatureInternalClientServer.BlankEncryptedData(ResultBinaryData, ErrorDescription);
			Except
				ErrorInformation = ErrorInfo();
			EndTry;
		Else // Decryption.
			CryptoManager.PrivateKeyAccessPassword = Parameters.PasswordValue;
			Try
				ResultBinaryData = CryptoManager.Decrypt(Data);
			Except
				ErrorInformation = ErrorInfo();
			EndTry;
		EndIf;
	
	EndIf;
	
	If ErrorInformation <> Undefined Then
		ErrorAtServer.Insert("ErrorDescription", BriefErrorDescription(ErrorInformation));
		ErrorAtServer.Insert("Instruction", True);
		Return False;
	EndIf;
	
	If ValueIsFilled(ErrorDescription) Then
		ErrorAtServer.Insert("ErrorDescription", ErrorDescription);
		Return False;
	EndIf;
	
	OperationStarted = True;
	
	If Parameters.Operation = "Signing" Then
		CertificateProperties = DigitalSignature.CertificateProperties(CryptoCertificate);
		CertificateProperties.Insert("BinaryData", CryptoCertificate.Unload());
		
		SignatureProperties = DigitalSignatureInternalClientServer.SignatureProperties(ResultBinaryData,
			CertificateProperties, Parameters.Comment, Users.AuthorizedUser());
		
		If Parameters.CertificateValid <> Undefined Then
			SignatureProperties.SignatureDate = CurrentSessionDate();
			SignatureProperties.SignatureValidationDate = SignatureProperties.SignatureDate;
			SignatureProperties.SignatureCorrect = Parameters.CertificateValid;
		EndIf;
		
		ResultAddress = PutToTempStorage(SignatureProperties, Parameters.FormID);
		
		If Parameters.DataItemForSErver.Property("Object") Then
			ObjectVersion = Undefined;
			Parameters.DataItemForSErver.Property("ObjectVersion", ObjectVersion);
			ErrorPresentation = AddSignature(Parameters.DataItemForSErver.Object,
				SignatureProperties, Parameters.FormID, ObjectVersion);
			If ValueIsFilled(ErrorPresentation) Then
				ErrorAtServer.Insert("ErrorDescription", ErrorPresentation);
				Return False;
			EndIf;
		EndIf;
	Else
		ResultAddress = PutToTempStorage(ResultBinaryData, Parameters.FormID);
	EndIf;
	
	Return True;
	
EndFunction

// For internal use only.
Function AddSignature(ObjectRef, SignatureProperties, FormID, ObjectVersion) Export
	
	DataItem = New Structure;
	DataItem.Insert("SignatureProperties",     SignatureProperties);
	DataItem.Insert("DataPresentation", ObjectRef);
	
	DigitalSignatureInternal.RegisterDataSigningInLog(DataItem);
	
	ErrorPresentation = "";
	Try
		DigitalSignature.AddSignature(ObjectRef, SignatureProperties, FormID, ObjectVersion);
	Except
		ErrorInformation = ErrorInfo();
		ErrorPresentation = NStr("ru = 'При записи подписи возникла ошибка:'; en = 'An error occurred when writing the signature:'; pl = 'An error occurred when writing the signature:';de = 'An error occurred when writing the signature:';ro = 'An error occurred when writing the signature:';tr = 'An error occurred when writing the signature:'; es_ES = 'An error occurred when writing the signature:'")
			+ Chars.LF + BriefErrorDescription(ErrorInformation);
	EndTry;
	
	Return ErrorPresentation;
	
EndFunction

// For internal use only.
Procedure RegisterDataSigningInLog(DataItem) Export
	
	DigitalSignatureInternal.RegisterDataSigningInLog(DataItem);
	
EndProcedure

// For the ExecuteAtServerSide function.
Function CryptoCertificates(Val CertificatesProperties)
	
	If TypeOf(CertificatesProperties) = Type("String") Then
		CertificatesProperties = GetFromTempStorage(CertificatesProperties);
	EndIf;
	
	Certificates = New Array;
	For each Properties In CertificatesProperties Do
		Certificates.Add(New CryptoCertificate(Properties.Certificate));
	EndDo;
	
	Return Certificates;
	
EndFunction

Procedure FindInstalledPrograms(Context) Export
	
	Context.Insert("IndexOf", -1);
	
	FindInstalledApplicationsAtServerLoopStart(Context);
	
EndProcedure

Procedure FindInstalledApplicationsAtServerLoopStart(Context)
	
	If Context.Applications.Count() <= Context.IndexOf + 1 Then
		// After loop.
		Return;
	EndIf;
	Context.IndexOf = Context.IndexOf + 1;
	ApplicationDetails = Context.Applications.Get(Context.IndexOf);
	
	Context.Insert("ApplicationDetails", ApplicationDetails);
	
	ApplicationsDetailsCollection = New Array;
	ApplicationsDetailsCollection.Add(Context.ApplicationDetails);
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("ApplicationsDetailsCollection",  ApplicationsDetailsCollection);
	ExecutionParameters.Insert("IndexOf",            -1);
	ExecutionParameters.Insert("ShowError",    False);
	ExecutionParameters.Insert("ErrorProperties",    New Structure("Errors", New Array));
	ExecutionParameters.Insert("IsLinux",   Common.IsLinuxServer());
	ExecutionParameters.Insert("Manager",   Undefined);
	
	Context.Insert("ExecutionParameters", ExecutionParameters);
	CreateCryptoManagerLoopStart(ExecutionParameters, Context);
	
EndProcedure

Procedure CreateCryptoManagerLoopStart(Context, ExecutionParameters)
	
	Context.Insert("ApplicationDetails", Context.ApplicationsDetailsCollection[0]);
	
	ApplicationProperties = DigitalSignatureInternalClientServer.CryptoManagerApplicationProperties(
		Context.ApplicationDetails,
		Context.IsLinux,
		Context.ErrorProperties.Errors,
		False,
		DigitalSignature.PersonalSettings().PathsToDigitalSignatureAndEncryptionApplications);
	
	If ApplicationProperties = Undefined Then
		FindInstalledApplicationsAtServerLoopStart(ExecutionParameters);
		Return;
	EndIf;
		
	Try
		ModuleInformation = CryptoTools.GetCryptoModuleInformation(
			ApplicationProperties.ApplicationName,
			ApplicationProperties.ApplicationPath,
			ApplicationProperties.ApplicationType);
	Except
		DigitalSignatureInternalClientServer.CryptoManagerAddError(Context.ErrorProperties.Errors,
			Undefined, BriefErrorDescription(ErrorInfo()),
			True, True, True);
		ErrorText = NStr("ru = 'Не установлена на сервере.'; en = 'Not installed on the server.'; pl = 'Not installed on the server.';de = 'Not installed on the server.';ro = 'Not installed on the server.';tr = 'Not installed on the server.'; es_ES = 'Not installed on the server.'") + " " + Context.ErrorProperties.Errors[0].Details;
		UpdateValue(Context.ApplicationDetails.CheckResultAtServer, ErrorText);
		FindInstalledApplicationsAtServerLoopStart(ExecutionParameters);
		Return;
	EndTry;
	
	If ModuleInformation = Undefined Then
		DigitalSignatureInternalClientServer.CryptoManagerApplicationNotFound(
			Context.ApplicationDetails, Context.Errors, True);
		
		Manager = Undefined;
		FindInstalledApplicationsAtServerLoopStart(ExecutionParameters);
		Return;
	EndIf;
	
	If Not Context.IsLinux Then
		ApplicationNameReceived = ModuleInformation.Name;
		
		ApplicationNameMatches = DigitalSignatureInternalClientServer.CryptoManagerApplicationNameMaps(
			Context.ApplicationDetails, ApplicationNameReceived, Context.ErrorProperties.Errors, True);
		
		If Not ApplicationNameMatches Then
			Manager = Undefined;
			FindInstalledApplicationsAtServerLoopStart(ExecutionParameters);
			Return;
		EndIf;
	EndIf;
	
	Try
		Manager = New CryptoManager(
			ApplicationProperties.ApplicationName,
			ApplicationProperties.ApplicationPath,
			ApplicationProperties.ApplicationType);
	Except
		DigitalSignatureInternalClientServer.CryptoManagerAddError(Context.ErrorProperties.Errors,
			Undefined, BriefErrorDescription(ErrorInfo()),
			True, True, True);
			FindInstalledApplicationsAtServerLoopStart(ExecutionParameters);
			Return;
	EndTry;
	
	AlgorithmsSet = DigitalSignatureInternalClientServer.CryptoManagerAlgorithmsSet(
		Context.ApplicationDetails, Manager, Context.ErrorProperties.Errors);
	
	If Not AlgorithmsSet Then
		FindInstalledApplicationsAtServerLoopStart(ExecutionParameters);
		Return;
	EndIf;
	
	UpdateValue(Context.ApplicationDetails.CheckResultAtServer, "");
	UpdateValue(Context.ApplicationDetails.Use, True);
	
	FindInstalledApplicationsAtServerLoopStart(ExecutionParameters);
	
EndProcedure

Procedure UpdateValue(PreviousValue, NewValue)
	
	If PreviousValue <> NewValue Then
		PreviousValue = NewValue;
	EndIf;
	
EndProcedure

// For the FindInstalledApplications procedure.
Function FillApplicationsListForSearch(ApplicationsDetails) Export
	
	SettingsToSupply = Catalogs.DigitalSignatureAndEncryptionApplications.ApplicationsSettingsToSupply();
	
	UpdatedApplicationsDetails = New Array;
	
	ExceptionsArray = New Array;
	ExceptionsArray.Add("Use");
	ExceptionsArray.Add("Ref");
	ExceptionsArray.Add("CheckResultAtClient");
	ExceptionsArray.Add("CheckResultAtServer");
	
	For Each ApplicationDetails In ApplicationsDetails Do
		Filter = New Structure;
		Filter.Insert("ApplicationName", ApplicationDetails.ApplicationName);
		Filter.Insert("ApplicationType", ApplicationDetails.ApplicationType);
	
		Rows = SettingsToSupply.FindRows(Filter);
		If Rows.Count() = 0 Then
			NewApplicationDetails = ExtendedApplicationDetails();
			FillPropertyValues(NewApplicationDetails, ApplicationDetails);
			UpdatedApplicationsDetails.Add(NewApplicationDetails);
		Else
			For Each KeyAndValue In ApplicationDetails Do
				If ExceptionsArray.Find(KeyAndValue.Key) <> Undefined Then
					Continue;
				EndIf;
				If KeyAndValue.Value <> Undefined Then
					UpdateValue(Rows[0][KeyAndValue.Key], KeyAndValue.Value);
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
	For Each ApplicationToSupply In SettingsToSupply Do
		ApplicationDetails = ExtendedApplicationDetails();
		FillPropertyValues(ApplicationDetails, ApplicationToSupply);
		UpdatedApplicationsDetails.Add(ApplicationDetails);
	EndDo;
	
	Return UpdatedApplicationsDetails;
	
EndFunction

// For the FindInstalledApplications procedure.
Function ExtendedApplicationDetails()
	
	ApplicationDetails = DigitalSignature.NewApplicationDetails();
	ApplicationDetails.Insert("Ref", Undefined);
	ApplicationDetails.Insert("Use", False);
	ApplicationDetails.Insert("CheckResultAtClient", "");
	ApplicationDetails.Insert("CheckResultAtServer", Undefined);
	
	Return ApplicationDetails;
	
EndFunction

#EndRegion
