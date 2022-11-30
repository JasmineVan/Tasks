///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

Function InteractiveCryptographyModeUsed(CryptoManager) Export
	
	If Not DigitalSignatureInternalClientServer.InteractiveModeAvailable() Then
		Return False;
	EndIf;
	
	If CryptoManager["InteractiveModeUsage"] = InteractiveCryptoModeUsageUse() Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

// Continue the SigningDate procedure.
Procedure SigningDateAfterReadToBinaryDataBuffer(SignatureDataBuffer, Context) Export
	
	SigningDate = DigitalSignatureInternalClientServer.SigningDateUniversal(SignatureDataBuffer);
	
	If SigningDate = Undefined Then
		ExecuteNotifyProcessing(Context.Notification, Undefined);
		Return;
	EndIf;
	
	If Context.CastToSessionTimeZone Then
		SigningDate = SigningDate + (CommonClient.SessionDate()
			- CommonClient.UniversalDate());
	EndIf;
	
	ExecuteNotifyProcessing(Context.Notification, SigningDate);
	
EndProcedure

// Continue the FindValidPersonalCertificates procedure.
Procedure FindValidPersonalCertificates(Notification, Filter = Undefined) Export
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("CompletionNotification", Notification);
	
	If Filter = Undefined Then
		Filter = New Structure;
	EndIf;
	
	If Not Filter.Property("CheckExpirationDate") Then
		Filter.Insert("CheckExpirationDate", True);
	EndIf;
	
	If Not Filter.Property("CertificatesWithFilledProgramOnly") Then
		Filter.Insert("CertificatesWithFilledProgramOnly", True);
	EndIf;
	
	If Not Filter.Property("IncludeCertificatesWithBlankUser") Then
		Filter.Insert("IncludeCertificatesWithBlankUser", True);
	EndIf;
	
	If Not Filter.Property("Company") Then
		Filter.Insert("Company", Undefined);
	EndIf;

	NotificationParameters.Insert("Filter",                 Filter);
	
	Notification = New NotifyDescription("FindValidPersonalCertificatesAfterGetSignaturesAtClient", ThisObject, NotificationParameters);
	GetCertificatesPropertiesAtClient(Notification, Not Filter.CheckExpirationDate, True);
	
EndProcedure

// Continue the FindValidPersonalCertificates procedure.
Procedure FindValidPersonalCertificatesAfterGetSignaturesAtClient(Result, AdditionalParameters) Export

	PersonalCertificates = DigitalSignatureServerServiceCall.PersonalCertificates(Result.CertificatesPropertiesAtClient, AdditionalParameters.Filter);
	ExecuteNotifyProcessing(AdditionalParameters.CompletionNotification, PersonalCertificates);
	
EndProcedure

// Continues the FindInstalledApplications procedure.
Procedure FindInstalledPrograms(Notification, ApplicationsDetails, CheckAtServer) Export
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("Applications",             DigitalSignatureServerServiceCall.FillApplicationsListForSearch(ApplicationsDetails));
	NotificationParameters.Insert("CompletionNotification", Notification);
	If CheckAtServer = Undefined Then
		CheckAtServer = DigitalSignatureClient.VerifyDigitalSignaturesOnTheServer()
		                 Or DigitalSignatureClient.GenerateDigitalSignaturesAtServer();
	EndIf;
	NotificationParameters.Insert("CheckAtServer",    CheckAtServer);
	
	Notification = New NotifyDescription("FindInstalledApplicationsAfterAttachExtension", ThisObject, NotificationParameters);
	
	DigitalSignatureClient.InstallExtension(True, Notification);
	
EndProcedure

// Continues the FindInstalledApplications procedure.
Procedure FindInstalledApplicationsAfterAttachExtension(Attached, AdditionalParameters) Export
	
	If Not Attached Then
		Return;
	EndIf;
	
	Context = New Structure;
	Context.Insert("IndexOf",                -1);
	Context.Insert("Applications",             AdditionalParameters.Applications);
	Context.Insert("CheckAtServer",    AdditionalParameters.CheckAtServer);
	Context.Insert("CompletionNotification", AdditionalParameters.CompletionNotification);
	
	FindInstalledApplicationsLoopStart(Context);
	
EndProcedure

// Continues the FindInstalledApplications procedure.
Procedure FindInstalledApplicationsLoopStart(Context)
	
	If Context.Applications.Count() <= Context.IndexOf + 1 Then
		// After loop.
		CompletionNotification = Context.CompletionNotification;
		If Context.CheckAtServer Then
				Context.ExecutionParameters.Insert("Manager", Undefined);
				Context.ExecutionParameters.Insert("Notification", Undefined);
				Context.Insert("CompletionNotification", Undefined);
				DigitalSignatureServerServiceCall.FindInstalledPrograms(Context);
		EndIf;
		ExecuteNotifyProcessing(CompletionNotification, Context.Applications);
		Return;
	EndIf;
	Context.IndexOf = Context.IndexOf + 1;
	ApplicationDetails = Context.Applications.Get(Context.IndexOf);
	
	Context.Insert("ApplicationDetails", ApplicationDetails);
	
	ApplicationsDetailsCollection = New Array;
	ApplicationsDetailsCollection.Add(Context.ApplicationDetails);
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("ApplicationsDetailsCollection",   ApplicationsDetailsCollection);
	ExecutionParameters.Insert("IndexOf",             -1);
	ExecutionParameters.Insert("ShowError",     False);
	ExecutionParameters.Insert("ErrorProperties",     New Structure("Errors", New Array));
	ExecutionParameters.Insert("IsLinux",           Not CommonClient.IsWindowsClient());
	ExecutionParameters.Insert("Manager",           Undefined);
	ExecutionParameters.Insert("InteractiveMode", False);
	ExecutionParameters.Insert("Notification", New NotifyDescription(
		"FindInstalledApplicationsLoopFollowUp", ThisObject, Context));
	
	Context.Insert("ExecutionParameters", ExecutionParameters);
	CreateCryptoManagerLoopStart(ExecutionParameters);
	
EndProcedure

// Continues the FindInstalledApplications procedure.
Procedure FindInstalledApplicationsLoopFollowUp(Manager, Context) Export
	
	ApplicationDetails = Context.ApplicationDetails;
	Errors            = Context.ExecutionParameters.ErrorProperties.Errors;
	
	If Manager <> Undefined Then
		UpdateValue(ApplicationDetails.CheckResultAtClient, "");
		UpdateValue(ApplicationDetails.Use, True);
		FindInstalledApplicationsLoopStart(Context);
		Return;
	EndIf;
	
	For each Error In Errors Do
		Break;
	EndDo;
	
	If Error.PathNotSpecified Then
		UpdateValue(ApplicationDetails.CheckResultAtClient, NStr("ru = 'Не указан путь к программе.'; en = 'Path to the application is not specified.'; pl = 'Path to the application is not specified.';de = 'Path to the application is not specified.';ro = 'Path to the application is not specified.';tr = 'Path to the application is not specified.'; es_ES = 'Path to the application is not specified.'"));
		UpdateValue(ApplicationDetails.Use, "");
	Else
		ErrorText = NStr("ru = 'Не установлена на компьютере.'; en = 'It is not installed on the computer.'; pl = 'It is not installed on the computer.';de = 'It is not installed on the computer.';ro = 'It is not installed on the computer.';tr = 'It is not installed on the computer.'; es_ES = 'It is not installed on the computer.'") + " " + Error.Details;
		UpdateValue(ApplicationDetails.CheckResultAtClient, ErrorText);
		UpdateValue(ApplicationDetails.Use, False);
	EndIf;
	
	FindInstalledApplicationsLoopStart(Context);
	
EndProcedure

// For the FindInstalledApplications procedure.
Procedure UpdateValue(PreviousValue, NewValue)
	
	If PreviousValue <> NewValue Then
		PreviousValue = NewValue;
	EndIf;
	
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
	
	Context = New Structure;
	Context.Insert("CertificateData", CertificateData);
	Context.Insert("OpenData", OpenData);
	Context.Insert("CertificateAddress", Undefined);
	
	If TypeOf(CertificateData) = Type("CryptoCertificate") Then
		CertificateData.BeginUnloading(New NotifyDescription(
			"OpenCertificateAfterCertificateExport", ThisObject, Context));
	Else
		OpenCertificateFollowUp(Context);
	EndIf;
	
EndProcedure

// Continue the OpenCertificate procedure.
Procedure OpenCertificateAfterCertificateExport(ExportedData, Context) Export
	
	Context.CertificateAddress = PutToTempStorage(ExportedData);
	
	OpenCertificateFollowUp(Context);
	
EndProcedure

// Continue the OpenCertificate procedure.
Procedure OpenCertificateFollowUp(Context)
	
	If Context.CertificateAddress <> Undefined Then
		// The certificate is prepared.
		
	ElsIf TypeOf(Context.CertificateData) = Type("CatalogRef.DigitalSignatureAndEncryptionKeysCertificates") Then
		Ref = Context.CertificateData;
		
	ElsIf TypeOf(Context.CertificateData) = Type("BinaryData") Then
		Context.CertificateAddress = PutToTempStorage(Context.CertificateData);
		
	ElsIf TypeOf(Context.CertificateData) <> Type("String") Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Ошибка при вызове процедуры ОткрытьСертификат общего модуля ЭлектроннаяПодписьКлиент:
			           |Некорректное значение параметра ДанныеСертификата ""%1"".'; 
			           |en = 'An error occurred when calling procedure OpenCertificate of common module DigitalSignatureClient:
			           |Incorrect value of parameter CertificateData ""%1"".'; 
			           |pl = 'An error occurred when calling procedure OpenCertificate of common module DigitalSignatureClient:
			           |Incorrect value of parameter CertificateData ""%1"".';
			           |de = 'An error occurred when calling procedure OpenCertificate of common module DigitalSignatureClient:
			           |Incorrect value of parameter CertificateData ""%1"".';
			           |ro = 'An error occurred when calling procedure OpenCertificate of common module DigitalSignatureClient:
			           |Incorrect value of parameter CertificateData ""%1"".';
			           |tr = 'An error occurred when calling procedure OpenCertificate of common module DigitalSignatureClient:
			           |Incorrect value of parameter CertificateData ""%1"".'; 
			           |es_ES = 'An error occurred when calling procedure OpenCertificate of common module DigitalSignatureClient:
			           |Incorrect value of parameter CertificateData ""%1"".'"),
			String(Context.CertificateData));
		
	ElsIf IsTempStorageURL(Context.CertificateData) Then
		Context.CertificateAddress = Context.CertificateData;
	Else
		Thumbprint = Context.CertificateData;
	EndIf;
	
	If Not Context.OpenData Then
		If Ref = Undefined Then
			Ref = DigitalSignatureServerServiceCall.CertificateRef(Thumbprint, Context.CertificateAddress);
		EndIf;
		If ValueIsFilled(Ref) Then
			ShowValue(, Ref);
			Return;
		EndIf;
	EndIf;
	
	Context.Insert("Ref", Ref);
	Context.Insert("Thumbprint", Thumbprint);
	
	If Context.CertificateAddress = Undefined
	   AND Ref = Undefined Then
		
		GetCertificateByThumbprint(New NotifyDescription(
			"OpenCertificateAfterCertificateSearch", ThisObject, Context), Thumbprint, False);
	Else
		OpenCertificateEnd(Context);
	EndIf;
	
EndProcedure

// Continue the OpenCertificate procedure.
Procedure OpenCertificateAfterCertificateSearch(Result, Context) Export
	
	If TypeOf(Result) = Type("CryptoCertificate") Then
		Result.BeginUnloading(New NotifyDescription(
			"OpenCertificateAfterExportFoundCertificate", ThisObject, Context));
	Else
		OpenCertificateEnd(Context);
	EndIf;
	
EndProcedure

// Continue the OpenCertificate procedure.
Procedure OpenCertificateAfterExportFoundCertificate(ExportedData, Context) Export
	
	Context.CertificateAddress = PutToTempStorage(ExportedData);
	
	OpenCertificateEnd(Context);
	
EndProcedure

// Continue the OpenCertificate procedure.
Procedure OpenCertificateEnd(Context)
	
	FormParameters = New Structure;
	FormParameters.Insert("Ref",           Context.Ref);
	FormParameters.Insert("CertificateAddress", Context.CertificateAddress);
	FormParameters.Insert("Thumbprint",        Context.Thumbprint);
	
	OpenForm("CommonForm.Certificate", FormParameters);
	
EndProcedure

// Saves the certificate to file on hard drive.
// 
// Parameters:
//   Notification - NotifyDescription - called after saving.
//              - Undefined - follow up is not required.
//
//   Certificate - CryptoCertificate - a certificate.
//              - BinaryData - certificate binary data.
//              - String - an address of a temporary storage that contains certificate binary data.
//
Procedure SaveCertificate(Notification, Certificate, FileNameWithoutExtension = "") Export
	
	Context =  New Structure;
	Context.Insert("Notification",            Notification);
	Context.Insert("Certificate",            Certificate);
	Context.Insert("FileNameWithoutExtension", FileNameWithoutExtension);
	Context.Insert("CertificateAddress",      Undefined);
	
	If TypeOf(Context.Certificate) = Type("CryptoCertificate") Then
		Context.Certificate.BeginUnloading(New NotifyDescription(
			"SaveCertificateAfterCertificateExport", ThisObject, Context));
	Else
		SaveCertificateFollowUp(Context);
	EndIf;
	
EndProcedure

// Continue the SaveCertificate procedure.
Procedure SaveCertificateAfterCertificateExport(ExportedData, Context) Export
	
	Context.CertificateAddress = PutToTempStorage(ExportedData, New UUID);
	SaveCertificateFollowUp(Context);
	
EndProcedure

// Continue the SaveCertificate procedure.
Procedure SaveCertificateFollowUp(Context)
	
	If Context.CertificateAddress <> Undefined Then
		// The certificate is prepared.
		
	ElsIf TypeOf(Context.Certificate) = Type("BinaryData") Then
		Context.CertificateAddress = PutToTempStorage(Context.Certificate, New UUID);
		
	ElsIf TypeOf(Context.Certificate) = Type("String")
		AND IsTempStorageURL(Context.Certificate) Then
		
		Context.CertificateAddress = Context.Certificate;
	Else
		If Context.Notification <> Undefined Then
			ExecuteNotifyProcessing(Context.Notification, False);
		EndIf;
		Return;
	EndIf;
	
	If Not ValueIsFilled(Context.FileNameWithoutExtension) Then
		Context.FileNameWithoutExtension = DigitalSignatureServerServiceCall.SubjectPresentation(Context.CertificateAddress);
	EndIf;
	
	FileName = PrepareStringForFileName(Context.FileNameWithoutExtension) + ".cer";
	Notification = New NotifyDescription("SaveCertificatesAfterFilesReceipt", ThisObject, Context);
	
	SavingParameters = FileSystemClient.FileSavingParameters();
	SavingParameters.Dialog.Title = NStr("ru = 'Выберите файл для сохранения сертификата'; en = 'Select a file to save the certificate to'; pl = 'Select a file to save the certificate to';de = 'Select a file to save the certificate to';ro = 'Select a file to save the certificate to';tr = 'Select a file to save the certificate to'; es_ES = 'Select a file to save the certificate to'");
	SavingParameters.Dialog.Filter    = NStr("ru = 'Файлы сертификатов (*.cer)|*.cer|Все файлы (*.*)|*.*'; en = 'Certificate files (*.cer)|*.cer|All files (*.*)|*.*'; pl = 'Certificate files (*.cer)|*.cer|All files (*.*)|*.*';de = 'Certificate files (*.cer)|*.cer|All files (*.*)|*.*';ro = 'Certificate files (*.cer)|*.cer|All files (*.*)|*.*';tr = 'Certificate files (*.cer)|*.cer|All files (*.*)|*.*'; es_ES = 'Certificate files (*.cer)|*.cer|All files (*.*)|*.*'");
	
	FileSystemClient.SaveFile(Notification, Context.CertificateAddress, FileName, SavingParameters);
	
EndProcedure

// Continue the SaveCertificate procedure.
Procedure SaveCertificatesAfterFilesReceipt(ReceivedFiles, Context) Export
	
	If ReceivedFiles = Undefined
	 Or ReceivedFiles.Count() = 0 Then
		
		HasObtainedFiles = False;
	Else
		HasObtainedFiles = True;
		ShowUserNotification(NStr("ru = 'Сертификат сохранен в файл:'; en = 'Certificate is saved to file:'; pl = 'Certificate is saved to file:';de = 'Certificate is saved to file:';ro = 'Certificate is saved to file:';tr = 'Certificate is saved to file:'; es_ES = 'Certificate is saved to file:'"),,
			ReceivedFiles[0].Name);
	EndIf;
	
	If Context.Notification <> Undefined Then
		ExecuteNotifyProcessing(Context.Notification, HasObtainedFiles);
	EndIf;
	
EndProcedure

// Saves the certificate application to file on hard disk.
// 
// Parameters:
//   Notification - NotifyDescription - called after saving.
//              - Undefined - follow up is not required.
//
//   CertificateRequest    - BinaryData - certificate request data.
//                         - String - the address of the temporary storage containing the certificate application data.
//   FileNameWithoutExtension - String - an initial file name without an extension.
//
Procedure SaveApplicationForCertificate(Notification, ApplicationForCertificate, FileNameWithoutExtension = "") Export
	
	FileName = PrepareStringForFileName(FileNameWithoutExtension + ".p10");
	SaveNotification = New NotifyDescription("SaveApplicationForCertificateAfterFilesReceipt", ThisObject, Notification);
	
	SavingParameters = FileSystemClient.FileSavingParameters();
	SavingParameters.Dialog.Title = NStr("ru = 'Выберите файл для сохранения запроса на сертификат'; en = 'Select a file to save the certificate request to'; pl = 'Select a file to save the certificate request to';de = 'Select a file to save the certificate request to';ro = 'Select a file to save the certificate request to';tr = 'Select a file to save the certificate request to'; es_ES = 'Select a file to save the certificate request to'");
	SavingParameters.Dialog.Filter    = NStr("ru = 'Файлы сертификатов (*.p10)|*.p10|Все файлы (*.*)|*.*'; en = 'Certificate files (*.p10)|*.p10|All files (*.*)|*.*'; pl = 'Certificate files (*.p10)|*.p10|All files (*.*)|*.*';de = 'Certificate files (*.p10)|*.p10|All files (*.*)|*.*';ro = 'Certificate files (*.p10)|*.p10|All files (*.*)|*.*';tr = 'Certificate files (*.p10)|*.p10|All files (*.*)|*.*'; es_ES = 'Certificate files (*.p10)|*.p10|All files (*.*)|*.*'");
	
	If TypeOf(ApplicationForCertificate) = Type("BinaryData") Then
		FileSystemClient.SaveFile(SaveNotification, 
			PutToTempStorage(ApplicationForCertificate, New UUID), FileName, SavingParameters);
	ElsIf TypeOf(ApplicationForCertificate) = Type("String")
		AND IsTempStorageURL(ApplicationForCertificate) Then
		
		FileSystemClient.SaveFile(SaveNotification, ApplicationForCertificate, FileName, SavingParameters);
		
	Else
		If Notification <> Undefined Then
			ExecuteNotifyProcessing(Notification, False);
		EndIf;
		Return;
	EndIf;
	
EndProcedure

// Continue the SaveApplicationForCertificate procedure.
Procedure SaveApplicationForCertificateAfterFilesReceipt(ReceivedFiles, Notification) Export
	
	If ReceivedFiles = Undefined
	 Or ReceivedFiles.Count() = 0 Then
		
		HasObtainedFiles = False;
	Else
		HasObtainedFiles = True;
		ShowUserNotification(NStr("ru = 'Запрос на сертификат сохранен в файл:'; en = 'Certificate application is saved to file:'; pl = 'Certificate application is saved to file:';de = 'Certificate application is saved to file:';ro = 'Certificate application is saved to file:';tr = 'Certificate application is saved to file:'; es_ES = 'Certificate application is saved to file:'"),,
			ReceivedFiles[0].Name);
	EndIf;
	
	If Notification <> Undefined Then
		ExecuteNotifyProcessing(Notification, HasObtainedFiles);
	EndIf;
	
EndProcedure

// Saves signature to the hard drive
Procedure SaveSignature(SignatureAddress) Export
	
	Notification = New NotifyDescription("SaveSignatureAfterFileReceipt", ThisObject, Undefined);
	Filter = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Файлы электронных подписей (*.%1)|*.%1|Все файлы (*.*)|*.*'; en = 'Digital signature files (*.%1)|*.%1|All files (*.*)|*.*'; pl = 'Digital signature files (*.%1)|*.%1|All files (*.*)|*.*';de = 'Digital signature files (*.%1)|*.%1|All files (*.*)|*.*';ro = 'Digital signature files (*.%1)|*.%1|All files (*.*)|*.*';tr = 'Digital signature files (*.%1)|*.%1|All files (*.*)|*.*'; es_ES = 'Digital signature files (*.%1)|*.%1|All files (*.*)|*.*'"),
		DigitalSignatureClient.PersonalSettings().SignatureFilesExtension);
	
	SavingParameters = FileSystemClient.FileSavingParameters();
	SavingParameters.Dialog.Filter = Filter;
	SavingParameters.Dialog.Title = NStr("ru = 'Выберите файл для сохранения подписи'; en = 'Select a file to save the signature to'; pl = 'Select a file to save the signature to';de = 'Select a file to save the signature to';ro = 'Select a file to save the signature to';tr = 'Select a file to save the signature to'; es_ES = 'Select a file to save the signature to'");
	
	FileSystemClient.SaveFile(Notification, SignatureAddress, "", SavingParameters);
	
EndProcedure

// Continue the SaveSignature procedure.
Procedure SaveSignatureAfterFileReceipt(ReceivedFiles, Context) Export
	
	If ReceivedFiles = Undefined
	 Or ReceivedFiles.Count() = 0 Then
		
		Return;
	EndIf;
	
	ShowUserNotification(NStr("ru = 'Электронная подпись сохранена в файл:'; en = 'Digital signature is saved to file:'; pl = 'Digital signature is saved to file:';de = 'Digital signature is saved to file:';ro = 'Digital signature is saved to file:';tr = 'Digital signature is saved to file:'; es_ES = 'Digital signature is saved to file:'"),,
		ReceivedFiles[0].Name);
	
EndProcedure

// Finds a certificate on the computer by a thumbprint string.
//
// Parameters:
//   Notification - NotifyDescription - a notification about execution result of the following types:
//     CryptoCertificate - a found certificate.
//     Undefined           - the certificate is not found in the storage.
//     String                 - a text of an error occurred when creating a crypto manager (or other error).
//     Structure              - an error description as a structure.
//
//   Thumbprint              - String - a Base64 coded certificate thumbprint.
//   InPersonalStorageOnly - Boolean - if True, search in the personal storage, otherwise, search everywhere.
//                          - CryptoCertificatesStorageType - the specified storage type.
//
//   ShowError - Boolean - show the error of creating crypto manager.
//                  - Undefined - do not show the error and return the error structure, including 
//                    the addition of the CertificateNotFound property.
//
//   Application  - Undefined - search using any application.
//              - CatalogRef.DigitalSignatureAndEncryption - search using the specified application.
//                   
//              - CryptoManager - an initialized crypto manager to use for search.
//                   
//
Procedure GetCertificateByThumbprint(Notification, Thumbprint, InPersonalStorageOnly,
			ShowError = True, Application = Undefined) Export
	
	Context = New Structure;
	Context.Insert("Notification",             Notification);
	Context.Insert("Thumbprint",              Thumbprint);
	Context.Insert("InPersonalStorageOnly", InPersonalStorageOnly);
	Context.Insert("ShowError",         ShowError);
	
	If TypeOf(Application) = Type("CryptoManager") Then
		GetCertificateByThumbprintAfterCreateCryptoManager(Application, Context);
	Else
		CreateCryptoManager(New NotifyDescription(
			"GetCertificateByThumbprintAfterCreateCryptoManager", ThisObject, Context),
			"GetCertificates", ShowError, Application);
	EndIf;
	
EndProcedure

// Continue the GetCertificateByThumbprint procedure.
Procedure GetCertificateByThumbprintAfterCreateCryptoManager(Result, Context) Export
	
	If TypeOf(Result) <> Type("CryptoManager") Then
		ExecuteNotifyProcessing(Context.Notification, Result);
		Return;
	EndIf;
	Context.Insert("CryptoManager", Result);
	
	StorageType = DigitalSignatureInternalClientServer.StorageTypeToSearchCertificate(
		Context.InPersonalStorageOnly);
	
	Try
		Context.Insert("ThumbprintBinaryData", Base64Value(Context.Thumbprint));
	Except
		If Context.ShowError = True Then
			Raise;
		EndIf;
		ErrorInformation = ErrorInfo();
		ErrorPresentation = BriefErrorDescription(ErrorInformation);
		GetCertificateByThumbprintCompletion(Undefined, ErrorPresentation, Context);
		Return;
	EndTry;
	
	Context.CryptoManager.BeginGettingCertificateStore(
		New NotifyDescription(
			"GetCertificateByThumbprintAfterGetStorage", ThisObject, Context,
			"GetCertificateByThumbprintAfterGetStorageError", ThisObject),
		StorageType);
	
EndProcedure

// Continue the GetCertificateByThumbprint procedure.
Procedure GetCertificateByThumbprintAfterGetStorageError(ErrorInformation, StandardProcessing, Context) Export
	
	If Context.ShowError = True Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	ErrorPresentation = BriefErrorDescription(ErrorInformation);
	GetCertificateByThumbprintCompletion(Undefined, ErrorPresentation, Context);
	
EndProcedure

// Continue the GetCertificateByThumbprint procedure.
Procedure GetCertificateByThumbprintAfterGetStorage(CryptoCertificateStore, Context) Export
	
	CryptoCertificateStore.BeginFindingByThumbprint(New NotifyDescription(
			"GetCertificateByThumbprintAfterSearch", ThisObject, Context,
			"GetCertificateByThumbprintAfterSearchError", ThisObject),
		Context.ThumbprintBinaryData);
	
EndProcedure

// Continue the GetCertificateByThumbprint procedure.
Procedure GetCertificateByThumbprintAfterSearchError(ErrorInformation, StandardProcessing, Context) Export
	
	If Context.ShowError = True Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	ErrorPresentation = BriefErrorDescription(ErrorInformation);
	
	GetCertificateByThumbprintCompletion(Undefined, ErrorPresentation, Context);
	
EndProcedure

// Continue the GetCertificateByThumbprint procedure.
Procedure GetCertificateByThumbprintAfterSearch(Certificate, Context) Export
	
	GetCertificateByThumbprintCompletion(Certificate, "", Context);
	
EndProcedure

// Continue the GetCertificateByThumbprint procedure.
Procedure GetCertificateByThumbprintCompletion(Certificate, ErrorPresentation, Context)
	
	If TypeOf(Certificate) = Type("CryptoCertificate") Then
		ExecuteNotifyProcessing(Context.Notification, Certificate);
		Return;
	EndIf;
	
	If ValueIsFilled(ErrorPresentation) Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Сертификат не найден на компьютере по причине:
			           |%1'; 
			           |en = 'Certificate is not found on the computer due to:
			           |%1'; 
			           |pl = 'Certificate is not found on the computer due to:
			           |%1';
			           |de = 'Certificate is not found on the computer due to:
			           |%1';
			           |ro = 'Certificate is not found on the computer due to:
			           |%1';
			           |tr = 'Certificate is not found on the computer due to:
			           |%1'; 
			           |es_ES = 'Certificate is not found on the computer due to:
			           |%1'"),
			ErrorPresentation);
	Else
		ErrorText = NStr("ru = 'Сертификат не найден на компьютере.'; en = 'Certificate is not found on the computer.'; pl = 'Certificate is not found on the computer.';de = 'Certificate is not found on the computer.';ro = 'Certificate is not found on the computer.';tr = 'Certificate is not found on the computer.'; es_ES = 'Certificate is not found on the computer.'");
	EndIf;
	
	If Context.ShowError = Undefined Then
		Result = New Structure;
		Result.Insert("ErrorDescription", ErrorText);
		If Not ValueIsFilled(ErrorPresentation) Then
			Result.Insert("CertificateNotFound");
		EndIf;
	ElsIf Not ValueIsFilled(ErrorPresentation) Then
		Result = Undefined;
	Else
		Result = ErrorPresentation;
	EndIf;
	
	ExecuteNotifyProcessing(Context.Notification, Result);
	
EndProcedure


// Gets certificate thumbprints of the OS user on the computer.
//
// Parameters:
//  Notification     - NotifyDescription - it is called when passing the return value:
//                   * Map - Key - a thumbprint in the Base64 string format, and Value is True.
//                   * String - a text of an error occurred when creating a crypto manager (or other error).
//
//  PersonalOnly   - Boolean - if False, recipient certificates are added to the personal certificates.
//
//  ShowError - Boolean - show the error of creating crypto manager.
//
Procedure GetCertificatesThumbprints(Notification, OnlyPersonal, ShowError = True) Export
	
	Context = New Structure;
	Context.Insert("Notification",     Notification);
	Context.Insert("OnlyPersonal",   OnlyPersonal);
	Context.Insert("ShowError", ShowError = True);
	
	GetCertificatesPropertiesAtClient(New NotifyDescription(
			"GetCertificatesThumbprintsAfterExecute", ThisObject, Context),
		OnlyPersonal, False, True, ShowError);
	
EndProcedure

// Continues the GetCertificatesThumbprints procedure.
Procedure GetCertificatesThumbprintsAfterExecute(Result, Context) Export
	
	If ValueIsFilled(Result.ErrorOnGetCertificatesAtClient) Then
		ExecuteNotifyProcessing(Context.Notification, Result.ErrorOnGetCertificatesAtClient);
		Return;
	EndIf;
	
	ExecuteNotifyProcessing(Context.Notification, Result.CertificatesPropertiesAtClient);
	
EndProcedure

// For internal use only.
Function TimeAddition() Export
	
	Return CommonClient.SessionDate() - CommonClient.UniversalDate();
	
EndFunction

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
//
//   Signature              - BinaryData - digital signature binary data.
//                        - String         - an address of a temporary storage that contains binary data.
//
//   CryptoManager - Undefined - get crypto manager by default (manager of the first application in 
//                          the list, as configured by the administrator).
//                        - CryptoManager - use the specified crypto manager.
//
//   OnDate               - Date - check the certificate on the specified date if the date cannot be 
//                          extracted from the signature automatically.
//                          If the parameter is not filled in, check on the current date if date 
//                          cannot be extracted from the signature automatically.
//
//   ShowError       - Boolean - show the crypto manager creation error (when it is not specified).
//
Procedure VerifySignature(Notification, SourceData, Signature, CryptoManager = Undefined, OnDate = Undefined, ShowError = True) Export
	
	Context = New Structure;
	Context.Insert("Notification",     Notification);
	Context.Insert("RawData", SourceData);
	Context.Insert("Signature",        Signature);
	Context.Insert("OnDate",         OnDate);
	Context.Insert("CheckAtServer",
		DigitalSignatureClient.VerifyDigitalSignaturesOnTheServer());
	
	If CryptoManager = Undefined Then
		CreateCryptoManager(New NotifyDescription(
				"CheckSignatureAfterCreateCryptoManager", ThisObject, Context),
				"SignatureCheck", ShowError AND Not Context.CheckAtServer);
	Else
		CheckSignatureAfterCreateCryptoManager(CryptoManager, Context);
	EndIf;
	
EndProcedure

// Continues the CheckSignature procedure.
Procedure CheckSignatureAfterCreateCryptoManager(Result, Context) Export
	
	If TypeOf(Result) = Type("CryptoManager") Then
		CryptoManager = Result;
	Else
		CryptoManager = Undefined;
	EndIf;
	
	Context.Insert("CryptoManager", CryptoManager);
	
	If Not DigitalSignatureClient.VerifyDigitalSignaturesOnTheServer() Then
		// Checking the signature and certificate on the client side.
		If CryptoManager = Undefined Then
			ExecuteNotifyProcessing(Context.Notification, Undefined);
			Return;
		EndIf;
		
		If TypeOf(Context.RawData) = Type("String")
		   AND IsTempStorageURL(Context.RawData) Then
			
			Context.RawData = GetFromTempStorage(Context.RawData);
		EndIf;
		
		Context.Insert("CheckCertificateAtClient");
		
		CheckSignatureAtClient(Context);
		Return;
	EndIf;
	
	If CryptoManager <> Undefined
	   AND Not (  TypeOf(Context.RawData) = Type("String")
	         AND IsTempStorageURL(Context.RawData)) Then
		// Mathematical check of the signature on the client side to improve performance and security in 
		// case if the SourceData is the result of decrypting the secret file.
		
		// The certificate is checked both on the client and on the server.
		CheckSignatureAtClient(Context);
		Return;
	EndIf;
	
	If UseDigitalSignatureSaaS() Then
		// Checking certificate signature in SaaS.
		CheckSignatureSaaS(Context);
	Else
		// Checking the signature and certificate on the server.
		If TypeOf(Context.RawData) = Type("String")
		   AND IsTempStorageURL(Context.RawData) Then
			
			SourceDataAddress = Context.RawData;
			
		ElsIf TypeOf(Context.RawData) = Type("BinaryData") Then
			SourceDataAddress = PutToTempStorage(Context.RawData);
		EndIf;
		
		If TypeOf(Context.Signature) = Type("String")
		   AND IsTempStorageURL(Context.Signature) Then
			
			SignatureAddress = Context.Signature;
			
		ElsIf TypeOf(Context.Signature) = Type("BinaryData") Then
			SignatureAddress = PutToTempStorage(Context.Signature);
		EndIf;
		
		ErrorDescription = "";
		Result = DigitalSignatureServerServiceCall.VerifySignature(
			SourceDataAddress, SignatureAddress, ErrorDescription);
		
		If Result <> True Then
			Result = ErrorDescription;
		EndIf;
		
		ExecuteNotifyProcessing(Context.Notification, Result);
		
	EndIf;
	
EndProcedure

// Continues the CheckSignature procedure.
Procedure CheckSignatureAtClient(Context)
	
	Signature = Context.Signature;
	
	If TypeOf(Signature) = Type("String") AND IsTempStorageURL(Signature) Then
		Signature = GetFromTempStorage(Signature);
	EndIf;
	
	Context.Insert("SignatureData", Signature);
	
	IsXMLDSig = (TypeOf(Context) = Type("Structure")
	            AND TypeOf(Context.RawData) = Type("Structure")
	            AND Context.RawData.Property("XMLDSigParameters"));
	
	If IsXMLDSig Then
		
		NotificationSuccess = New NotifyDescription(
			"CheckSignatureAtClientAfterXMLDSigSignatureCheck", ThisObject, Context);
		
		NotificationError = New NotifyDescription(
			"CheckSignatureAtClientAfterXMLDSigSignatureCheckError", ThisObject, Context);
		
		Notifications = New Structure;
		Notifications.Insert("Success", NotificationSuccess);
		Notifications.Insert("Error", NotificationError);
		
		BeginVerifyingSignature(
			Notifications,
			Context.RawData.SOAPEnvelope,
			Context.RawData.XMLDSigParameters,
			Context.CryptoManager);
		
	Else
		Context.CryptoManager.BeginVerifyingSignature(New NotifyDescription(
			"CheckSignatureAtClientAfterSignatureCheck", ThisObject, Context,
			"CheckSignatureAtClientAfterSignatureCheckError", ThisObject),
			Context.RawData, Context.SignatureData);
	EndIf;
	
EndProcedure

// Continues the CheckSignature procedure.
Procedure CheckSignatureAtClientAfterXMLDSigSignatureCheckError(ErrorText, Context) Export
	
	ExecuteNotifyProcessing(Context.Notification, ErrorText);
	
EndProcedure

// Continues the CheckSignature procedure.
Procedure CheckSignatureAtClientAfterXMLDSigSignatureCheck(Data, Context) Export
	
	If Context.Property("CheckCertificateAtClient") Then
		CryptoManager = Context.CryptoManager;
	Else
		// Checking the certificate both on the server and on the client.
		CryptoManager = Undefined;
	EndIf;
	
	CheckCertificate(Context.Notification, Data.Certificate, CryptoManager, Data.SigningDate);
	
EndProcedure


// Continues the CheckSignature procedure.
Procedure CheckSignatureAtClientAfterSignatureCheckError(ErrorInformation, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	ExecuteNotifyProcessing(Context.Notification, BriefErrorDescription(ErrorInformation));
	
EndProcedure

// Continues the CheckSignature procedure.
Procedure CheckSignatureAtClientAfterSignatureCheck(Certificate, Context) Export
	
	If Certificate = Undefined Then
		ExecuteNotifyProcessing(Context.Notification,
			NStr("ru = 'Сертификат не найден в данных подписи.'; en = 'Certificate is not found in signature data.'; pl = 'Certificate is not found in signature data.';de = 'Certificate is not found in signature data.';ro = 'Certificate is not found in signature data.';tr = 'Certificate is not found in signature data.'; es_ES = 'Certificate is not found in signature data.'"));
		Return;
	EndIf;
	
	If Context.Property("CheckCertificateAtClient") Then
		CryptoManager = Context.CryptoManager;
	Else
		// Checking the certificate both on the server and on the client.
		CryptoManager = Undefined;
	EndIf;
	
	Context.Insert("Certificate",           Certificate);
	Context.Insert("CryptoManager", CryptoManager);
	
	DigitalSignatureClient.SigningDate(
		New NotifyDescription("CheckSignatureAtClientAfterGetSigningDate", ThisObject, Context),
		Context.SignatureData);
	
EndProcedure

// Continues the CheckSignature procedure.
Procedure CheckSignatureAtClientAfterGetSigningDate(SigningDate, Context) Export
	
	If Not ValueIsFilled(SigningDate) Then
		SigningDate = Context.OnDate;
	EndIf;
	
	CheckCertificate(Context.Notification, Context.Certificate, Context.CryptoManager, SigningDate);
	
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
//                          If parameter is not specified or a blank date is specified, then check on the current date.
//
//   ShowError       - Boolean - show the crypto manager creation error (when it is not specified).
//
Procedure CheckCertificate(Notification, Certificate, CryptoManager = Undefined, OnDate = Undefined, ShowError = True) Export
	
	Context = New Structure;
	Context.Insert("Notification",              Notification);
	Context.Insert("Certificate",              Certificate);
	Context.Insert("CryptoManager",    CryptoManager);
	Context.Insert("OnDate",                  OnDate);
	Context.Insert("ShowError",          ShowError);
	Context.Insert("ErrorDescriptionAtServer", Undefined);
	
	If Context.CryptoManager = Undefined
	   AND DigitalSignatureClient.VerifyDigitalSignaturesOnTheServer() Then
		
		// Check on the server before checking on the client.
		If TypeOf(Certificate) = Type("CryptoCertificate") Then
			
			Certificate.BeginUnloading(New NotifyDescription(
				"CheckCertificateAfterExportCertificate", ThisObject, Context));
		Else
			CheckCertificateAfterExportCertificate(Certificate, Context);
		EndIf;
	Else
		// When the crypto manager is specified, the check is executed only on the client.
		CheckCertificateAtClient(Context);
	EndIf;
	
EndProcedure

// Continues the CheckCertificate procedure.
Procedure CheckCertificateAfterExportCertificate(Certificate, Context) Export
	
	// Checking the certificate on the server.
	If TypeOf(Certificate) = Type("BinaryData") Then
		CertificateAddress = PutToTempStorage(Certificate);
	Else
		CertificateAddress = Certificate;
	EndIf;
	
	If DigitalSignatureServerServiceCall.CheckCertificate(CertificateAddress,
			Context.ErrorDescriptionAtServer, Context.OnDate) Then
		
		ExecuteNotifyProcessing(Context.Notification, True);
	Else
		CheckCertificateAtClient(Context);
	EndIf;
	
EndProcedure

// Continues the CheckCertificate procedure.
Procedure CheckCertificateAtClient(Context)
	
	If Context.CryptoManager = Undefined Then
		CreateCryptoManager(New NotifyDescription(
				"CheckCertificateAfterCreateCryptoManager", ThisObject, Context),
			"CertificateCheck", Context.ShowError AND Context.ErrorDescriptionAtServer = Undefined);
	Else
		If Context.CryptoManager = "CryptographyService" Then
			CheckCertificateSaaS(Context.CryptoManager, Context);
		Else
			CheckCertificateAfterCreateCryptoManager(Context.CryptoManager, Context);
		EndIf;
	EndIf;
	
EndProcedure

// Continues the CheckCertificate procedure.
Procedure CheckCertificateAfterCreateCryptoManager(Result, Context) Export
	
	If TypeOf(Result) <> Type("CryptoManager") Then
		ExecuteNotifyProcessing(Context.Notification, Context.ErrorDescriptionAtServer);
		Return;
	EndIf;
	
	Context.CryptoManager = Result;
	
	CertificateToCheck = Context.Certificate;
	
	If TypeOf(CertificateToCheck) = Type("String") Then
		CertificateToCheck = GetFromTempStorage(CertificateToCheck);
	EndIf;
	
	If TypeOf(CertificateToCheck) = Type("BinaryData") Then
		CryptoCertificate = New CryptoCertificate;
		CryptoCertificate.BeginInitialization(New NotifyDescription(
				"CheckCertificateAfterInitializeCertificate", ThisObject, Context),
			CertificateToCheck);
	Else
		CheckCertificateAfterInitializeCertificate(CertificateToCheck, Context)
	EndIf;
	
EndProcedure

// Continues the CheckCertificate procedure.
Procedure CheckCertificateAfterInitializeCertificate(CryptoCertificate, Context) Export
	
	CertificateCheckModes = DigitalSignatureInternalClientServer.CertificateCheckModes(
		ValueIsFilled(Context.OnDate));
	
	Context.Insert("CryptoCertificate", CryptoCertificate);
	
	Context.CryptoManager.BeginCheckingCertificate(New NotifyDescription(
		"CheckCertificateAtClientAfterCheck", ThisObject, Context,
		"CheckCertificateAtClientAfterCheckError", ThisObject),
		Context.CryptoCertificate, CertificateCheckModes);
	
EndProcedure

// Continues the CheckCertificate procedure.
Procedure CheckCertificateAtClientAfterCheckError(ErrorInformation, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	If TypeOf(ErrorInformation) = Type("ErrorInfo") Then
		ErrorDescription = BriefErrorDescription(ErrorInformation);
	Else
		ErrorDescription = String(ErrorInformation);
	EndIf;
	
	If Context.ErrorDescriptionAtServer <> Undefined Then
		ErrorDescription = Context.ErrorDescriptionAtServer + " " + NStr("ru = '(на сервере)'; en = '(on the server)'; pl = '(on the server)';de = '(on the server)';ro = '(on the server)';tr = '(on the server)'; es_ES = '(on the server)'") + Chars.LF
			+ ErrorDescription + " " + NStr("ru = '(на клиенте)'; en = '(on the client)'; pl = '(on the client)';de = '(on the client)';ro = '(on the client)';tr = '(on the client)'; es_ES = '(on the client)'");
	EndIf;
	
	ExecuteNotifyProcessing(Context.Notification, ErrorDescription);
	
EndProcedure

// Continues the CheckCertificate procedure.
Procedure CheckCertificateAtClientAfterCheck(Context) Export
	
	OverdueError = DigitalSignatureInternalClientServer.CertificateOverdue(
		Context.CryptoCertificate, Context.OnDate, TimeAddition());
	
	If ValueIsFilled(OverdueError) Then
		CheckCertificateAtClientAfterCheckError(OverdueError, False, Context);
	Else
		ExecuteNotifyProcessing(Context.Notification, True);
	EndIf;
	
EndProcedure


// Creates and returns the crypto manager (on the client) for the specified application.
//
// Parameters:
//  Notification     - NotifyDescription - a notification about executing the following types:
//    CryptoManager - the initialized crypto manager.
//    String - a description of a crypto manager creation error.
//    Structure - if ShowError = Undefined. Contains application call errors.
//      * ErrorDescription   - String - an error description (when returned as a string).
//      * ErrorTitle  - String - an error title that matches the operation.
//      * Details         - String - a common error description.
//      * Common            - Boolean - if True, then it contains error description for all 
//                               applications, otherwise, the Errors array is described alternatively.
//      * ToAdministrator  - Boolean - administrator rights are required to patch the common error.
//      * Errors           - Array - it contains structure of application error descriptions  with the following properties:
//           * Application       - CatalogRef.DigitalSignatureAndEncryption.
//           * Details       - String - it contains an error presentation.
//           * FromException    - Boolean - a description contains a brief error description.
//           * PathNotSpecified    - Boolean - a description contains an error that a path for Linux is not specified.
//           * ToAdministrator - Boolean - administrator rights are required to patch an error.
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
//                 - Undefined - return all application call errors (see above).
//
//  Application      - Undefined - returns crypto manager of the first application from the catalog, 
//                   to which it was possible to create it.
//                 - CatalogRef.DigitalSignatureAndEncryptionApplications - an application that 
//                   requires creating and returning a crypto manager.
//  InteractiveMode - Boolean - if True, then the crypto manager will be created in the interactive 
//                       crypto mode (setting the PrivateKeyAccessPassword property will be 
//                       prohibited).
//
Procedure CreateCryptoManager(Notification, Operation, ShowError = True, Application = Undefined, InteractiveMode = False) Export
	
	Context = New Structure;
	Context.Insert("Notification",     Notification);
	Context.Insert("Operation",       Operation);
	Context.Insert("ShowError", ShowError);
	Context.Insert("Application",      Application);
	Context.Insert("InteractiveMode", InteractiveMode);
	
	BeginAttachingCryptoExtension(New NotifyDescription(
		"CreateCryptoManagerAfterAttachCryptoExtension", ThisObject, Context));
	
EndProcedure

// Continues the CreateCryptoManager procedure.
Procedure CreateCryptoManagerAfterAttachCryptoExtension(Attached, Context) Export
	
	FormHeader = NStr("ru = 'Требуется программа электронной подписи и шифрования'; en = 'Digital signature and encryption application is required'; pl = 'Digital signature and encryption application is required';de = 'Digital signature and encryption application is required';ro = 'Digital signature and encryption application is required';tr = 'Digital signature and encryption application is required'; es_ES = 'Digital signature and encryption application is required'");
	Operation       = Context.Operation;
	
	If Operation = "Signing" Then
		ErrorTitle = NStr("ru = 'Не удалось подписать данные по причине:'; en = 'Cannot sign data due to:'; pl = 'Cannot sign data due to:';de = 'Cannot sign data due to:';ro = 'Cannot sign data due to:';tr = 'Cannot sign data due to:'; es_ES = 'Cannot sign data due to:'");
		
	ElsIf Operation = "SignatureCheck" Then
		ErrorTitle = NStr("ru = 'Не удалось проверить подпись по причине:'; en = 'Cannot check the signature due to:'; pl = 'Cannot check the signature due to:';de = 'Cannot check the signature due to:';ro = 'Cannot check the signature due to:';tr = 'Cannot check the signature due to:'; es_ES = 'Cannot check the signature due to:'");
		
	ElsIf Operation = "Encryption" Then
		ErrorTitle = NStr("ru = 'Не удалось зашифровать данные по причине:'; en = 'Cannot encrypt data due to:'; pl = 'Cannot encrypt data due to:';de = 'Cannot encrypt data due to:';ro = 'Cannot encrypt data due to:';tr = 'Cannot encrypt data due to:'; es_ES = 'Cannot encrypt data due to:'");
		
	ElsIf Operation = "Details" Then
		ErrorTitle = NStr("ru = 'Не удалось расшифровать данные по причине:'; en = 'Cannot decrypt data due to:'; pl = 'Cannot decrypt data due to:';de = 'Cannot decrypt data due to:';ro = 'Cannot decrypt data due to:';tr = 'Cannot decrypt data due to:'; es_ES = 'Cannot decrypt data due to:'");
		
	ElsIf Operation = "CertificateCheck" Then
		ErrorTitle = NStr("ru = 'Не удалось проверить сертификат по причине:'; en = 'Cannot check the certificate due to:'; pl = 'Cannot check the certificate due to:';de = 'Cannot check the certificate due to:';ro = 'Cannot check the certificate due to:';tr = 'Cannot check the certificate due to:'; es_ES = 'Cannot check the certificate due to:'");
		
	ElsIf Operation = "GetCertificates" Then
		ErrorTitle = NStr("ru = 'Не удалось получить сертификаты по причине:'; en = 'Cannot receive certificates due to:'; pl = 'Cannot receive certificates due to:';de = 'Cannot receive certificates due to:';ro = 'Cannot receive certificates due to:';tr = 'Cannot receive certificates due to:'; es_ES = 'Cannot receive certificates due to:'");
		
	ElsIf Operation = Null AND Context.ShowError <> True Then
		ErrorTitle = "";
		
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
	Else
		ErrorTitle = NStr("ru = 'Не удалось выполнить операцию по причине:'; en = 'Cannot perform the operation. Reason:'; pl = 'Cannot perform the operation. Reason:';de = 'Cannot perform the operation. Reason:';ro = 'Cannot perform the operation. Reason:';tr = 'Cannot perform the operation. Reason:'; es_ES = 'Cannot perform the operation. Reason:'");
	EndIf;
	
	ErrorProperties = New Structure;
	ErrorProperties.Insert("ErrorTitle", ErrorTitle);
	ErrorProperties.Insert("Total", False);
	ErrorProperties.Insert("ToAdministrator", False);
	
	If Not Attached Then
		ErrorText =
			NStr("ru = 'В браузере требуется установить расширение
			           |для работы с электронной подписью и шифрованием.'; 
			           |en = 'It is required to install
			           |a browser extension to use digital signature and encryption.'; 
			           |pl = 'It is required to install
			           |a browser extension to use digital signature and encryption.';
			           |de = 'It is required to install
			           |a browser extension to use digital signature and encryption.';
			           |ro = 'It is required to install
			           |a browser extension to use digital signature and encryption.';
			           |tr = 'It is required to install
			           |a browser extension to use digital signature and encryption.'; 
			           |es_ES = 'It is required to install
			           |a browser extension to use digital signature and encryption.'");
		
		ErrorProperties.Insert("Details", ErrorText);
		ErrorProperties.Insert("Total",  True);
		ErrorProperties.Insert("Errors", New Array);
		ErrorProperties.Insert("Extension", True);
		
		ErrorProperties.Insert("ErrorDescription", TrimAll(ErrorTitle + Chars.LF + ErrorText));
		If Context.ShowError = Undefined Then
			ErrorDescription = ErrorProperties;
		Else
			ErrorDescription = ErrorProperties.ErrorDescription;
		EndIf;
		If Context.ShowError = True Then
			ShowApplicationCallError(
				FormHeader, ErrorTitle, ErrorProperties, New Structure);
		EndIf;
		ExecuteNotifyProcessing(Context.Notification, ErrorDescription);
		Return;
	EndIf;
	
	Context.Insert("FormCaption",  FormHeader);
	Context.Insert("ErrorTitle", ErrorTitle);
	Context.Insert("ErrorProperties",  ErrorProperties);
	// Checking whether it is Linux or OS X client.
	Context.Insert("IsLinux", Not CommonClient.IsWindowsClient());
	
	ErrorProperties.Insert("Errors", New Array);
	
	ApplicationsDetailsCollection = DigitalSignatureInternalClientServer.CryptoManagerApplicationsDetails(
		Context.Application, ErrorProperties.Errors, DigitalSignatureClient.CommonSettings().ApplicationsDetailsCollection);
	
	Context.Insert("Manager", Undefined);
	
	If ApplicationsDetailsCollection = Undefined
	 Or ApplicationsDetailsCollection.Count() = 0 Then
		
		CreateCryptoManagerAfterLoop(Context);
		Return;
	EndIf;
	
	Context.Insert("ApplicationsDetailsCollection",  ApplicationsDetailsCollection);
	Context.Insert("IndexOf", -1);
	
	CreateCryptoManagerLoopStart(Context);
	
EndProcedure

// Continues the CreateCryptoManager procedure.
Procedure CreateCryptoManagerLoopStart(Context) Export
	
	If Context.ApplicationsDetailsCollection.Count() <= Context.IndexOf + 1 Then
		CreateCryptoManagerAfterLoop(Context);
		Return;
	EndIf;
	Context.IndexOf = Context.IndexOf + 1;
	Context.Insert("ApplicationDetails", Context.ApplicationsDetailsCollection[Context.IndexOf]);
	
	ApplicationProperties = DigitalSignatureInternalClientServer.CryptoManagerApplicationProperties(
		Context.ApplicationDetails,
		Context.IsLinux,
		Context.ErrorProperties.Errors,
		False,
		DigitalSignatureClient.PersonalSettings().PathsToDigitalSignatureAndEncryptionApplications);
	
	If ApplicationProperties = Undefined Then
		CreateCryptoManagerLoopStart(Context);
		Return;
	EndIf;
	
	Context.Insert("ApplicationProperties", ApplicationProperties);
	
	CryptoTools.BeginGettingCryptoModuleInformation(New NotifyDescription(
			"CreateCryptoManagerLoopAfterGetInformation", ThisObject, Context,
			"CreateCryptographyManagerLoopAfterInformationReceiptError", ThisObject),
		Context.ApplicationProperties.ApplicationName,
		Context.ApplicationProperties.ApplicationPath,
		Context.ApplicationProperties.ApplicationType);
	
EndProcedure

// Continues the CreateCryptoManager procedure.
Procedure CreateCryptographyManagerLoopAfterInformationReceiptError(ErrorInformation, StandardProcessing, Context) Export
	
	CreateCryptographyManagerLoopOnInitializationError(ErrorInformation, StandardProcessing, Context);
	
EndProcedure

// Continues the CreateCryptoManager procedure.
Procedure CreateCryptoManagerLoopAfterGetInformation(ModuleInformation, Context) Export
	
	If ModuleInformation = Undefined Then
		DigitalSignatureInternalClientServer.CryptoManagerApplicationNotFound(
			Context.ApplicationDetails, Context.ErrorProperties.Errors, False);
		
		Context.Manager = Undefined;
		CreateCryptoManagerLoopStart(Context);
		Return;
	EndIf;
	
	If Not Context.IsLinux Then
		ApplicationNameReceived = ModuleInformation.Name;
		
		ApplicationNameMatches = DigitalSignatureInternalClientServer.CryptoManagerApplicationNameMaps(
			Context.ApplicationDetails, ApplicationNameReceived, Context.ErrorProperties.Errors, False);
		
		If Not ApplicationNameMatches Then
			Context.Manager = Undefined;
			CreateCryptoManagerLoopStart(Context);
			Return;
		EndIf;
	EndIf;
	
	Context.Manager = New CryptoManager;
	
	If Not Context.InteractiveMode
	 Or Not DigitalSignatureInternalClientServer.InteractiveModeAvailable() Then
		
		Context.Manager.BeginInitialization(New NotifyDescription(
				"CreateCryptoManagerLoopAfterInitialize", ThisObject, Context,
				"CreateCryptographyManagerLoopOnInitializationError", ThisObject),
			Context.ApplicationProperties.ApplicationName,
			Context.ApplicationProperties.ApplicationPath,
			Context.ApplicationProperties.ApplicationType);
	Else
		Context.Manager.BeginInitialization(New NotifyDescription(
				"CreateCryptoManagerLoopAfterInitialize", ThisObject, Context,
				"CreateCryptographyManagerLoopOnInitializationError", ThisObject),
			Context.ApplicationProperties.ApplicationName,
			Context.ApplicationProperties.ApplicationPath,
			Context.ApplicationProperties.ApplicationType,
			InteractiveCryptoModeUsageUse());
	EndIf;
	
EndProcedure

// Continues the CreateCryptoManager procedure.
Procedure CreateCryptographyManagerLoopOnInitializationError(ErrorInformation, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	Context.Manager = Undefined;
	
	DigitalSignatureInternalClientServer.CryptoManagerAddError(
		Context.ErrorProperties.Errors,
		Context.ApplicationDetails.Ref,
		BriefErrorDescription(ErrorInformation),
		False, True, True);
	
	CreateCryptoManagerLoopStart(Context);
	
EndProcedure

// Continues the CreateCryptoManager procedure.
Procedure CreateCryptoManagerLoopAfterInitialize(NotDefined, Context) Export
	
	AlgorithmsSet = DigitalSignatureInternalClientServer.CryptoManagerAlgorithmsSet(
		Context.ApplicationDetails,
		Context.Manager,
		Context.ErrorProperties.Errors);
	
	If Not AlgorithmsSet Then
		CreateCryptoManagerLoopStart(Context);
		Return;
	EndIf;
	
	// The required crypto manager is received.
	CreateCryptoManagerAfterLoop(Context);
	
EndProcedure

// Continues the CreateCryptoManager procedure.
Procedure CreateCryptoManagerAfterLoop(Context)
	
	If Context.Manager <> Undefined Or Not Context.Property("ErrorTitle") Then
		ExecuteNotifyProcessing(Context.Notification, Context.Manager);
		Return;
	EndIf;
	
	ErrorProperties = Context.ErrorProperties;
	
	If ErrorProperties.Errors.Count() = 0 Then
		ErrorText = NStr("ru = 'Не предусмотрено использование ни одной программы.'; en = 'Usage of no application is possible.'; pl = 'Usage of no application is possible.';de = 'Usage of no application is possible.';ro = 'Usage of no application is possible.';tr = 'Usage of no application is possible.'; es_ES = 'Usage of no application is possible.'");
		ErrorProperties.Insert("Details", ErrorText);
		ErrorProperties.Total = True;
		ErrorProperties.ToAdministrator = True;
		If Not StandardSubsystemsClient.ClientRunParameters().IsFullUser Then
			ErrorText = ErrorText + Chars.LF + Chars.LF + NStr("ru = 'Обратитесь к администратору.'; en = 'Please contact the application administrator.'; pl = 'Please contact the application administrator.';de = 'Please contact the application administrator.';ro = 'Please contact the application administrator.';tr = 'Please contact the application administrator.'; es_ES = 'Please contact the application administrator.'");
		EndIf;
		ErrorProperties.Insert("Instruction", True);
		ErrorProperties.Insert("ApplicationsSetUp", True);
	Else
		If Context.Application <> Undefined Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Программа ""%1"" не доступна или не установлена на компьютере по причине:
				           |%2'; 
				           |en = 'The ""%1"" application is not available or not installed on the computer due to:
				           |%2'; 
				           |pl = 'The ""%1"" application is not available or not installed on the computer due to:
				           |%2';
				           |de = 'The ""%1"" application is not available or not installed on the computer due to:
				           |%2';
				           |ro = 'The ""%1"" application is not available or not installed on the computer due to:
				           |%2';
				           |tr = 'The ""%1"" application is not available or not installed on the computer due to:
				           |%2'; 
				           |es_ES = 'The ""%1"" application is not available or not installed on the computer due to:
				           |%2'"),
				Context.Application,
				ErrorProperties.Errors[0].Details);
		Else
			ErrorText = NStr("ru = 'Ни одна из программ не доступна или не установлена на компьютере.'; en = 'None of the applications are available or installed on computer.'; pl = 'None of the applications are available or installed on computer.';de = 'None of the applications are available or installed on computer.';ro = 'None of the applications are available or installed on computer.';tr = 'None of the applications are available or installed on computer.'; es_ES = 'None of the applications are available or installed on computer.'");
			For Each Error In ErrorProperties.Errors Do
				ErrorText = ErrorText + Chars.LF + Chars.LF
					+ StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Программу ""%1"" не удалось использовать по причине:
						           |%2'; 
						           |en = 'Cannot use the ""%1"" application due to:
						           |%2'; 
						           |pl = 'Cannot use the ""%1"" application due to:
						           |%2';
						           |de = 'Cannot use the ""%1"" application due to:
						           |%2';
						           |ro = 'Cannot use the ""%1"" application due to:
						           |%2';
						           |tr = 'Cannot use the ""%1"" application due to:
						           |%2'; 
						           |es_ES = 'Cannot use the ""%1"" application due to:
						           |%2'"),
						Error.Application,
						Error.Details);
			EndDo;
		EndIf;
		ErrorProperties.Insert("Details", ErrorText);
	EndIf;
	
	ErrorProperties.Insert("ErrorDescription", Context.ErrorTitle + Chars.LF + ErrorText);
	If Context.ShowError = Undefined Then
		ErrorDescription = ErrorProperties;
	Else
		ErrorDescription = ErrorProperties.ErrorDescription;
	EndIf;
	
	If Context.ShowError = True Then
		ShowApplicationCallError(
			Context.FormCaption, Context.ErrorTitle, ErrorProperties, New Structure);
	EndIf;
	
	ExecuteNotifyProcessing(Context.Notification, ErrorDescription);
	
EndProcedure


// For internal purpose only.
//
// Parameters:
//  CreationParameters - Structure - with the following properties:
//   * ToPrivateList - Boolean - False if not specified
//                        If True, the User attribute will be filled by the current user.
//   * Company      - CatalogRef.Company - the default value.
//   * HideApplication - Boolean - do not offer to create an application to issue a certificate.
//   * CreateApplication - Boolean - immediately open the certificate creation application form.
//
Procedure AddCertificate(CreationParameters = Undefined) Export
	
	If TypeOf(CreationParameters) <> Type("Structure") Then
		CreationParameters = New Structure;
	EndIf;
	
	If Not CreationParameters.Property("ToPersonalList") Then
		CreationParameters.Insert("ToPersonalList", False);
	EndIf;
	
	If Not CreationParameters.Property("Company") Then
		CreationParameters.Insert("Company", Undefined);
	EndIf;
	
	If CreationParameters.Property("CreateRequest") AND CreationParameters.CreateRequest = True Then
		AddCertificateAfterPurposeChoice("CertificateIssueRequest", CreationParameters);
		Return;
	EndIf;
	
	If Not CreationParameters.Property("HideApplication") Then
		CreationParameters.Insert("HideApplication", True);
	EndIf;
	
	Form = OpenForm("Catalog.DigitalSignatureAndEncryptionKeysCertificates.Form.AddCertificate",
		New Structure("HideApplication", CreationParameters.HideApplication),,,,,
		New NotifyDescription("AddCertificateAfterPurposeChoice", ThisObject, CreationParameters));
	
	If Form = Undefined Then
		AddCertificateAfterPurposeChoice("ToSignEncryptAndDecrypt", CreationParameters);
	EndIf;
	
EndProcedure


// For internal purpose only.
Procedure AddCertificateAfterPurposeChoice(Assignment, CreationParameters) Export
	
	FormParameters = New Structure;
	
	If Assignment = "CertificateIssueRequest" Then
		FormParameters.Insert("PersonalListOnAdd", CreationParameters.ToPersonalList);
		FormParameters.Insert("Company", CreationParameters.Company);
		FormName = "DataProcessor.ApplicationForNewQualifiedCertificateIssue.Form.Form";
		OpenForm(FormName, FormParameters);
		Return;
	EndIf;
	
	If Assignment = "OnlyForEncryptionFromFile" Then
		AddCertificateOnlyToEncryptFromFile(CreationParameters);
		Return;
	EndIf;
	
	If Assignment <> "ToEncryptOnly" Then
		FormParameters.Insert("ToEncryptAndDecrypt", Undefined);
		
		If Assignment = "ToEncryptAndDecrypt" Then
			FormParameters.Insert("ToEncryptAndDecrypt", True);
		
		ElsIf Assignment <> "ToSignEncryptAndDecrypt" Then
			Return;
		EndIf;
		
		FormParameters.Insert("AddToList", True);
		FormParameters.Insert("PersonalListOnAdd", CreationParameters.ToPersonalList);
		FormParameters.Insert("Company", CreationParameters.Company);
		SelectSigningOrDecryptionCertificate(FormParameters);
		Return;
	EndIf;
	
	Context = New Structure;
	Context.Insert("CreationParameters", CreationParameters);
	
	GetCertificatesPropertiesAtClient(New NotifyDescription(
			"AddCertificateAfterGetCertificatesPropertiesAtClient", ThisObject, Context),
		False, False);
	
EndProcedure

// Continues the AddCertificateAfterPurposeChoice procedure.
Procedure AddCertificateAfterGetCertificatesPropertiesAtClient(Result, Context) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("CertificatesPropertiesAtClient",        Result.CertificatesPropertiesAtClient);
	FormParameters.Insert("ErrorOnGetCertificatesAtClient", Result.ErrorOnGetCertificatesAtClient);
	
	If Context.CreationParameters.Property("ToPersonalList") Then
		FormParameters.Insert("PersonalListOnAdd", Context.CreationParameters.ToPersonalList);
	EndIf;
	If Context.CreationParameters.Property("Company") Then
		FormParameters.Insert("Company", Context.CreationParameters.Company);
	EndIf;
	OpenForm("Catalog.DigitalSignatureAndEncryptionKeysCertificates.Form.AddEncryptionCertificate",
		FormParameters);
	
EndProcedure


// For internal purpose only.
Procedure GetCertificatesPropertiesAtClient(Notification, Personal, NoFilter, ThumbprintsOnly = False, ShowError = Undefined) Export
	
	Result = New Structure;
	Result.Insert("ErrorOnGetCertificatesAtClient", New Structure);
	Result.Insert("CertificatesPropertiesAtClient", ?(ThumbprintsOnly, New Map, New Array));
	
	Context = New Structure;
	Context.Insert("Notification",      Notification);
	Context.Insert("Personal",          Personal);
	Context.Insert("NoFilter",       NoFilter);
	Context.Insert("ThumbprintsOnly", ThumbprintsOnly);
	Context.Insert("Result",       Result);
	
	CreateCryptoManager(New NotifyDescription(
			"GetCertificatesPropertiesAtClientAfterCreateCryptoManager", ThisObject, Context),
		"GetCertificates", ShowError);
	
EndProcedure

// Continues the GetCertificatesPropertiesAtClient procedure.
Procedure GetCertificatesPropertiesAtClientAfterCreateCryptoManager(CryptoManager, Context) Export
	
	If TypeOf(CryptoManager) <> Type("CryptoManager") Then
		Context.Result.ErrorOnGetCertificatesAtClient = CryptoManager;
		ExecuteNotifyProcessing(Context.Notification, Context.Result);
		Return;
	EndIf;
	
	Context.Insert("CryptoManager", CryptoManager);
	
	Context.CryptoManager.BeginGettingCertificateStore(
		New NotifyDescription(
			"GetCertificatesPropertiesAtClientAfterGetPersonalStorage", ThisObject, Context),
		CryptoCertificateStoreType.PersonalCertificates);
	
EndProcedure

// Continues the GetCertificatesPropertiesAtClient procedure.
Procedure GetCertificatesPropertiesAtClientAfterGetPersonalStorage(Storage, Context) Export
	
	Storage.BeginGettingAll(New NotifyDescription(
		"GetCertificatesPropertiesAtClientAfterGetAllPersonalCertificates", ThisObject, Context));
	
EndProcedure

// Continues the GetCertificatesPropertiesAtClient procedure.
Procedure GetCertificatesPropertiesAtClientAfterGetAllPersonalCertificates(Array, Context) Export
	
	Context.Insert("CertificatesArray", Array);
	
	If Context.Personal Then
		GetCertificatesPropertiesAtClientAfterGetAll(Context);
		Return;
	EndIf;
	
	Context.CryptoManager.BeginGettingCertificateStore(
		New NotifyDescription(
			"GetCertificatesPropertiesAtClientAfterGetRecipientsStorage", ThisObject, Context),
		CryptoCertificateStoreType.RecipientCertificates);
	
EndProcedure

// Continues the GetCertificatesPropertiesAtClient procedure.
Procedure GetCertificatesPropertiesAtClientAfterGetRecipientsStorage(Storage, Context) Export
	
	Storage.BeginGettingAll(New NotifyDescription(
		"GetCertificatesPropertiesAtClientAfterGetAllRecipientsCertificates", ThisObject, Context));
	
EndProcedure

// Continues the GetCertificatesPropertiesAtClient procedure.
Procedure GetCertificatesPropertiesAtClientAfterGetAllRecipientsCertificates(Array, Context) Export
	
	For each Certificate In Array Do
		Context.CertificatesArray.Add(Certificate);
	EndDo;
	
	GetCertificatesPropertiesAtClientAfterGetAll(Context);
	
EndProcedure

// Continues the GetCertificatesPropertiesAtClient procedure.
Procedure GetCertificatesPropertiesAtClientAfterGetAll(Context)
	
	DigitalSignatureInternalClientServer.AddCertificatesProperties(
		Context.Result.CertificatesPropertiesAtClient,
		Context.CertificatesArray,
		Context.NoFilter,
		TimeAddition(),
		CommonClient.SessionDate(),
		Context.ThumbprintsOnly);
	
	ExecuteNotifyProcessing(Context.Notification, Context.Result);
	
EndProcedure


// For internal purpose only.
Procedure AddCertificateOnlyToEncryptFromFile(CreationParameters) Export
	
	Notification = New NotifyDescription("AddCertificateOnlyToEncryptFromFileAfterPutFiles",
		ThisObject, CreationParameters);
	
	ImportParameters = FileSystemClient.FileImportParameters();
	ImportParameters.Dialog.Title = NStr("ru = 'Выберите файл сертификата (только для шифрования)'; en = 'Select a certificate file (only for encryption)'; pl = 'Select a certificate file (only for encryption)';de = 'Select a certificate file (only for encryption)';ro = 'Select a certificate file (only for encryption)';tr = 'Select a certificate file (only for encryption)'; es_ES = 'Select a certificate file (only for encryption)'");
	ImportParameters.Dialog.Filter = NStr("ru = 'Сертификат X.509 (*.cer;*.crt)|*.cer;*.crt|Все файлы(*.*)|*.*'; en = 'Certificate X.509 (*.cer;*.crt)|*.cer;*.crt|All files(*.*)|*.*'; pl = 'Certificate X.509 (*.cer;*.crt)|*.cer;*.crt|All files(*.*)|*.*';de = 'Certificate X.509 (*.cer;*.crt)|*.cer;*.crt|All files(*.*)|*.*';ro = 'Certificate X.509 (*.cer;*.crt)|*.cer;*.crt|All files(*.*)|*.*';tr = 'Certificate X.509 (*.cer;*.crt)|*.cer;*.crt|All files(*.*)|*.*'; es_ES = 'Certificate X.509 (*.cer;*.crt)|*.cer;*.crt|All files(*.*)|*.*'");
	
	FileSystemClient.ImportFile(Notification, ImportParameters);
	
EndProcedure

// Continues the AddCertificateOnlyToEncryptFromFile procedure.
Procedure AddCertificateOnlyToEncryptFromFileAfterPutFiles(FilesThatWerePut, Context) Export
	
	If Not ValueIsFilled(FilesThatWerePut) Then
		Return;
	EndIf;
	
	AddCertificateOnlyToEncryptFromFileAfterPutFile(FilesThatWerePut[0].Location, Context);
	
EndProcedure

// Continues the AddCertificateOnlyToEncryptFromFile procedure.
Procedure AddCertificateOnlyToEncryptFromFileAfterPutFile(Address, Context)
	
	FormParameters = New Structure;
	FormParameters.Insert("CertificateDataAddress", Address);
	FormParameters.Insert("PersonalListOnAdd", Context.CreationParameters.ToPersonalList);
	FormParameters.Insert("Company",               Context.CreationParameters.Company);
	Form = OpenForm("Catalog.DigitalSignatureAndEncryptionKeysCertificates.Form.AddEncryptionCertificate",
		FormParameters);
	
	If Form = Undefined Then
		ShowMessageBox(,
			NStr("ru = 'Файл сертификата должен быть в формате DER X.509, операция прервана.'; en = 'Certificate file must have DER X.509 format, operation aborted.'; pl = 'Certificate file must have DER X.509 format, operation aborted.';de = 'Certificate file must have DER X.509 format, operation aborted.';ro = 'Certificate file must have DER X.509 format, operation aborted.';tr = 'Certificate file must have DER X.509 format, operation aborted.'; es_ES = 'Certificate file must have DER X.509 format, operation aborted.'"));
		Return;
	EndIf;
	
	If Not Form.IsOpen() Then
		Buttons = New ValueList;
		Buttons.Add("Open", NStr("ru = 'Открыть'; en = 'Open'; pl = 'Open';de = 'Open';ro = 'Open';tr = 'Open'; es_ES = 'Open'"));
		Buttons.Add("Cancel",  NStr("ru = 'Отмена'; en = 'Cancel'; pl = 'Cancel';de = 'Cancel';ro = 'Cancel';tr = 'Cancel'; es_ES = 'Cancel'"));
		ShowQueryBox(
			New NotifyDescription("AddCertificateOnlyToEncryptFromFileAfterNotifyOfExisting",
				ThisObject, Form.Certificate),
			NStr("ru = 'Сертификат уже добавлен.'; en = 'Certificate is already added.'; pl = 'Certificate is already added.';de = 'Certificate is already added.';ro = 'Certificate is already added.';tr = 'Certificate is already added.'; es_ES = 'Certificate is already added.'"), Buttons);
	EndIf;
	
EndProcedure

// Continues the AddCertificateOnlyToEncryptFromFile procedure.
Procedure AddCertificateOnlyToEncryptFromFileAfterNotifyOfExisting(Response, Certificate) Export
	
	If Response <> "Open" Then
		Return;
	EndIf;
	
	OpenCertificate(Certificate);
	
EndProcedure


// For internal use only.
Procedure ShowApplicationCallError(FormHeader, ErrorTitle, ErrorAtClient, ErrorAtServer,
				AdditionalParameters = Undefined, ContinuationHandler = Undefined) Export
	
	If TypeOf(ErrorAtClient) <> Type("Structure") Then
		Raise
			NStr("ru = 'Для процедуры ПоказатьОшибкуОбращенияКПрограмме
			           |указан некорректный тип параметра ОшибкаНаКлиенте.'; 
			           |en = 'Incorrect type of the ErrorAtClient parameter is specified for the
			           |ShowApplicationCallError procedure.'; 
			           |pl = 'Incorrect type of the ErrorAtClient parameter is specified for the
			           |ShowApplicationCallError procedure.';
			           |de = 'Incorrect type of the ErrorAtClient parameter is specified for the
			           |ShowApplicationCallError procedure.';
			           |ro = 'Incorrect type of the ErrorAtClient parameter is specified for the
			           |ShowApplicationCallError procedure.';
			           |tr = 'Incorrect type of the ErrorAtClient parameter is specified for the
			           |ShowApplicationCallError procedure.'; 
			           |es_ES = 'Incorrect type of the ErrorAtClient parameter is specified for the
			           |ShowApplicationCallError procedure.'");
	EndIf;
	
	If TypeOf(ErrorAtServer) <> Type("Structure") Then
		Raise
			NStr("ru = 'Для процедуры ПоказатьОшибкуОбращенияКПрограмме
			           |указан некорректный тип параметра ОшибкаНаСервере.'; 
			           |en = 'Incorrect type of the ErrorAtServer parameter is specified for the
			           |ShowApplicationCallError procedure.'; 
			           |pl = 'Incorrect type of the ErrorAtServer parameter is specified for the
			           |ShowApplicationCallError procedure.';
			           |de = 'Incorrect type of the ErrorAtServer parameter is specified for the
			           |ShowApplicationCallError procedure.';
			           |ro = 'Incorrect type of the ErrorAtServer parameter is specified for the
			           |ShowApplicationCallError procedure.';
			           |tr = 'Incorrect type of the ErrorAtServer parameter is specified for the
			           |ShowApplicationCallError procedure.'; 
			           |es_ES = 'Incorrect type of the ErrorAtServer parameter is specified for the
			           |ShowApplicationCallError procedure.'");
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("ShowInstruction",                False);
	FormParameters.Insert("ShowOpenApplicationsSettings", False);
	FormParameters.Insert("ShowExtensionInstallation",       False);
	FormParameters.Insert("UnsignedData");
	
	If TypeOf(AdditionalParameters) = Type("Structure") Then
		FillPropertyValues(FormParameters, AdditionalParameters);
	EndIf;
	
	FormParameters.Insert("FormCaption",  FormHeader);
	FormParameters.Insert("ErrorTitle", ErrorTitle);
	
	FormParameters.Insert("ErrorAtClient", ErrorAtClient);
	FormParameters.Insert("ErrorAtServer", ErrorAtServer);
	
	Context = New Structure;
	Context.Insert("FormParameters", FormParameters);
	Context.Insert("ContinuationHandler", ContinuationHandler);
	
	BeginAttachingCryptoExtension(New NotifyDescription(
		"ShowApplicationCallErrorAfterAttachExtension", ThisObject, Context));
	
EndProcedure

// Continues the ShowApplicationCallError procedure.
Procedure ShowApplicationCallErrorAfterAttachExtension(Attached, Context) Export
	
	Context.FormParameters.Insert("ExtensionAttached", Attached);
	
	OpenForm("Catalog.DigitalSignatureAndEncryptionApplications.Form.ApplicationCallError",
		Context.FormParameters,,,, , Context.ContinuationHandler);
	
EndProcedure


// For internal use only.
Procedure SetCertificatePassword(CertificateReference, Password, PasswordNote = Undefined) Export
	
	PassParametersForm().SetCertificatePassword(CertificateReference, Password, PasswordNote);
	
EndProcedure

// For internal use only.
Procedure OpenNewForm(FormKind, ClientParameters, ServerParameters, CompletionProcessing) Export
	
	DataDetails = ClientParameters.DataDetails;
	
	ServerParameters.Insert("NoConfirmation", False);
	
	If ServerParameters.Property("CertificatesFilter")
	   AND TypeOf(ServerParameters.CertificatesFilter) = Type("Array")
	   AND ServerParameters.CertificatesFilter.Count() = 1
	   AND DataDetails.Property("NoConfirmation")
	   AND DataDetails.NoConfirmation Then
		
		ServerParameters.Insert("NoConfirmation", True);
	EndIf;
	
	If ServerParameters.Property("CertificatesSet")
	   AND DataDetails.Property("NoConfirmation")
	   AND DataDetails.NoConfirmation Then
		
		ServerParameters.Insert("NoConfirmation", True);
	EndIf;
	
	SetDataPresentation(ClientParameters, ServerParameters);
	
	Context = New Structure;
	Context.Insert("FormKind",            FormKind);
	Context.Insert("ClientParameters", ClientParameters);
	Context.Insert("ServerParameters",  ServerParameters);
	Context.Insert("CompletionProcessing", CompletionProcessing);
	
	GetCertificatesThumbprintsAtClient(New NotifyDescription(
		"OpenNewFormCompletion", ThisObject, Context));
	
EndProcedure

// Continues the OpenNewForm procedure.
Procedure OpenNewFormCompletion(CertificatesThumbprintsAtClient, Context) Export
	
	Context.ServerParameters.Insert("CertificatesThumbprintsAtClient",
		CertificatesThumbprintsAtClient);
	
	PassParametersForm().OpenNewForm(
		Context.FormKind,
		Context.ServerParameters,
		Context.ClientParameters,
		Context.CompletionProcessing);
	
EndProcedure

// For internal use only.
Procedure RefreshFormBeforeSecondUse(Form, ClientParameters) Export
	
	ServerParameters  = New Structure;
	SetDataPresentation(ClientParameters, ServerParameters);
	
	Form.DataPresentation  = ServerParameters.DataPresentation;
	
EndProcedure

// For internal use only.
Procedure SetDataPresentation(ClientParameters, ServerParameters) Export
	
	DataDetails = ClientParameters.DataDetails;
	
	If DataDetails.Property("PresentationsList") Then
		PresentationsList = DataDetails.PresentationsList;
	Else
		PresentationsList = New Array;
		
		If DataDetails.Property("Data")
		 Or DataDetails.Property("Object") Then
			
			FillPresentationsList(PresentationsList, DataDetails);
		Else
			For each DataItem In DataDetails.DataSet Do
				FillPresentationsList(PresentationsList, DataItem);
			EndDo;
		EndIf;
	EndIf;
	
	CurrentPresentationsList = New ValueList;
	
	For each ListItem In PresentationsList Do
		If TypeOf(ListItem) = Type("String") Then
			Presentation = ListItem.Presentation;
			Value = Undefined;
		ElsIf TypeOf(ListItem) = Type("Structure") Then
			Presentation = ListItem.Presentation;
			Value = ListItem.Value;
		Else // Ref
			Presentation = "";
			Value = ListItem.Value;
		EndIf;
		If ValueIsFilled(ListItem.Presentation) Then
			Presentation = ListItem.Presentation;
		Else
			Presentation = String(ListItem.Value);
		EndIf;
		CurrentPresentationsList.Add(Value, Presentation);
	EndDo;
	
	If CurrentPresentationsList.Count() > 1 Then
		ServerParameters.Insert("DataPresentationCanOpen", True);
		ServerParameters.Insert("DataPresentation", StrReplace(
			DataDetails.SetPresentation, "%1", DataDetails.DataSet.Count()));
	Else
		ServerParameters.Insert("DataPresentationCanOpen",
			TypeOf(CurrentPresentationsList[0].Value) = Type("NotifyDescription")
			Or ValueIsFilled(CurrentPresentationsList[0].Value));
		
		ServerParameters.Insert("DataPresentation",
			CurrentPresentationsList[0].Presentation);
	EndIf;
	
	ClientParameters.Insert("CurrentPresentationsList", CurrentPresentationsList);
	
EndProcedure

// For internal use only.
Procedure StartChooseCertificateAtSetFilter(Form) Export
	
	AvailableCertificates = "";
	UnavailableCertificates = "";
	
	Text = NStr("ru = 'Сертификаты, которые могут быть использованы для этой операции ограничены.'; en = 'Certificates that can be used for this operation are limited.'; pl = 'Certificates that can be used for this operation are limited.';de = 'Certificates that can be used for this operation are limited.';ro = 'Certificates that can be used for this operation are limited.';tr = 'Certificates that can be used for this operation are limited.'; es_ES = 'Certificates that can be used for this operation are limited.'");
	
	For each ListItem In Form.CertificatesFilter Do
		If Form.CertificatePicklist.FindByValue(ListItem.Value) = Undefined Then
			UnavailableCertificates = UnavailableCertificates + Chars.LF + String(ListItem.Value);
		Else
			AvailableCertificates = AvailableCertificates + Chars.LF + String(ListItem.Value);
		EndIf;
	EndDo;
	
	If ValueIsFilled(AvailableCertificates) Then
		Title = NStr("ru = 'Следующие разрешенные сертификаты доступны для выбора:'; en = 'The following trusted certificates are available for selection:'; pl = 'The following trusted certificates are available for selection:';de = 'The following trusted certificates are available for selection:';ro = 'The following trusted certificates are available for selection:';tr = 'The following trusted certificates are available for selection:'; es_ES = 'The following trusted certificates are available for selection:'");
		Text = Text + Chars.LF + Chars.LF + Title + Chars.LF + TrimAll(AvailableCertificates);
	EndIf;
	
	If ValueIsFilled(UnavailableCertificates) Then
		If DigitalSignatureClient.GenerateDigitalSignaturesAtServer() Then
			If ValueIsFilled(AvailableCertificates) Then
				Title = NStr("ru = 'Следующие разрешенные сертификаты не найдены ни на компьютере, ни на сервере:'; en = 'The following trusted certificates were not found either on computer, or on server:'; pl = 'The following trusted certificates were not found either on computer, or on server:';de = 'The following trusted certificates were not found either on computer, or on server:';ro = 'The following trusted certificates were not found either on computer, or on server:';tr = 'The following trusted certificates were not found either on computer, or on server:'; es_ES = 'The following trusted certificates were not found either on computer, or on server:'");
			Else
				Title = NStr("ru = 'Ни один из следующих разрешенных сертификатов не найден ни на компьютере, ни на сервере:'; en = 'None of the following trusted certificates was found either on the computer, or on the server:'; pl = 'None of the following trusted certificates was found either on the computer, or on the server:';de = 'None of the following trusted certificates was found either on the computer, or on the server:';ro = 'None of the following trusted certificates was found either on the computer, or on the server:';tr = 'None of the following trusted certificates was found either on the computer, or on the server:'; es_ES = 'None of the following trusted certificates was found either on the computer, or on the server:'");
			EndIf;
		Else
			If ValueIsFilled(AvailableCertificates) Then
				Title = NStr("ru = 'Следующие разрешенные сертификаты не найдены на компьютере:'; en = 'The following trusted certificates were not found on computer:'; pl = 'The following trusted certificates were not found on computer:';de = 'The following trusted certificates were not found on computer:';ro = 'The following trusted certificates were not found on computer:';tr = 'The following trusted certificates were not found on computer:'; es_ES = 'The following trusted certificates were not found on computer:'");
			Else
				Title = NStr("ru = 'Ни один из следующих разрешенных сертификатов не найден на компьютере:'; en = 'None of the following trusted certificates was found on the computer:'; pl = 'None of the following trusted certificates was found on the computer:';de = 'None of the following trusted certificates was found on the computer:';ro = 'None of the following trusted certificates was found on the computer:';tr = 'None of the following trusted certificates was found on the computer:'; es_ES = 'None of the following trusted certificates was found on the computer:'");
			EndIf;
		EndIf;
		Text = Text + Chars.LF + Chars.LF + Title + Chars.LF + TrimAll(UnavailableCertificates);
	EndIf;
	
	ShowMessageBox(, Text);
	
EndProcedure

// For internal use only.
Procedure SelectSigningOrDecryptionCertificate(ServerParameters, NewFormOwner = Undefined) Export
	
	If NewFormOwner = Undefined Then
		NewFormOwner = New UUID;
	EndIf;
	
	Context = New Structure;
	Context.Insert("ServerParameters", ServerParameters);
	Context.Insert("NewFormOwner", NewFormOwner);
	
	GetCertificatesPropertiesAtClient(New NotifyDescription(
		"ChooseCertificateToSignOrDecryptFollowUp", ThisObject, Context), True, False);
	
EndProcedure

// Continues the SelectSigningOrDecryptionCertificate procedure.
Procedure ChooseCertificateToSignOrDecryptFollowUp(Result, Context) Export
	
	Context.ServerParameters.Insert("CertificatesPropertiesAtClient",
		Result.CertificatesPropertiesAtClient);
	
	Context.ServerParameters.Insert("ErrorOnGetCertificatesAtClient",
		Result.ErrorOnGetCertificatesAtClient);
	
	PassParametersForm().OpenNewForm("SelectSigningOrDecryptionCertificate",
		Context.ServerParameters, , , Context.NewFormOwner);
	
EndProcedure

// For internal use only.
Procedure CheckCatalogCertificate(Certificate, AdditionalParameters) Export
	
	ServerParameters = New Structure;
	ServerParameters.Insert("FormCaption");
	ServerParameters.Insert("CheckOnSelection");
	ServerParameters.Insert("AdditionalChecksParameters");
	
	If TypeOf(AdditionalParameters) = Type("Structure") Then
		FillPropertyValues(ServerParameters, AdditionalParameters);
	EndIf;
	
	ServerParameters.Insert("Certificate", Certificate);
	
	If TypeOf(AdditionalParameters) = Type("Structure") Then
		ClientParameters = AdditionalParameters;
	Else
		ClientParameters = New Structure;
	EndIf;
	
	FormOwner = Undefined;
	ClientParameters.Property("FormOwner", FormOwner);
	
	CompletionProcessing = Undefined;
	ClientParameters.Property("CompletionProcessing", CompletionProcessing);
	
	PassParametersForm().OpenNewForm("CertificateCheck",
		ServerParameters, ClientParameters, CompletionProcessing, FormOwner);
	
EndProcedure


// For internal use only.
Procedure StandardCompletion(Success, ClientParameters) Export
	
	ClientParameters.DataDetails.Insert("Success", Success = True);
	
	If ClientParameters.ResultProcessing <> Undefined Then
		ResultProcessing = ClientParameters.ResultProcessing;
		ClientParameters.ResultProcessing = Undefined;
		ExecuteNotifyProcessing(ResultProcessing, ClientParameters.DataDetails);
	EndIf;
	
EndProcedure


// Continues the DigitalSignatureClient.AddSignatureFromFile procedure.
Procedure AddSignatureFromFileAfterCreateCryptoManager(Result, Context) Export
	
	If Context.CheckCryptoManagerAtClient
	   AND TypeOf(Result) <> Type("CryptoManager") Then
		
		ShowApplicationCallError(
			NStr("ru = 'Требуется программа электронной подписи и шифрования'; en = 'Digital signature and encryption application is required'; pl = 'Digital signature and encryption application is required';de = 'Digital signature and encryption application is required';ro = 'Digital signature and encryption application is required';tr = 'Digital signature and encryption application is required'; es_ES = 'Digital signature and encryption application is required'"),
			"", Result, Context.AdditionForm.CryptographyManagerOnServerErrorDescription);
	Else
		Context.AdditionForm.Open();
		If Context.AdditionForm.IsOpen() Then
			Context.AdditionForm.RefreshDataRepresentation();
			Return;
		EndIf;
	EndIf;
	
	If Context.ResultProcessing <> Undefined Then
		ExecuteNotifyProcessing(Context.ResultProcessing, Context.DataDetails);
	EndIf;
	
EndProcedure


// It prompts the user to select signatures to save together with the object data.
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
//    * DataTitle     - String - a data item title, for example, File.
//    * ShowComment - Boolean - (optional) - allow adding a comment in the data signing form.
//                               False if not specified.
//    * Presentation      - Ref, String - (optional) - if not specified, the presentation is 
//                                calculated by the Object property value.
//    * Object             - Ref - a reference to object with the DigitalSIgnatures tabular section, 
//                              from which you need to get the signatures list.
//    * --// --           - String - a temporary storage address of a signature array with 
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
	
	Context = New Structure;
	Context.Insert("DataDetails", DataDetails);
	Context.Insert("ResultProcessing", ResultProcessing);
	
	PersonalSettings = DigitalSignatureClient.PersonalSettings();
	SaveAllSignatures = PersonalSettings.ActionsOnSavingWithDS = "SaveAllSignatures";
	SaveCertificateWithSignature = PersonalSettings.SaveCertificateWithSignature;
	
	ServerParameters = New Structure;
	ServerParameters.Insert("DataTitle",     NStr("ru = 'Данные'; en = 'Data'; pl = 'Data';de = 'Data';ro = 'Data';tr = 'Data'; es_ES = 'Data'"));
	ServerParameters.Insert("ShowComment", False);
	FillPropertyValues(ServerParameters, DataDetails);
	
	Context.Insert("SaveCertificateWithSignature", SaveCertificateWithSignature);
	
	ServerParameters.Insert("SaveAllSignatures", SaveAllSignatures);
	ServerParameters.Insert("Object", DataDetails.Object);
	
	ClientParameters = New Structure;
	ClientParameters.Insert("DataDetails", DataDetails);
	SetDataPresentation(ClientParameters, ServerParameters);
	
	SaveForm = OpenForm("CommonForm.SaveWithDigitalSignature", ServerParameters,,,,,
		New NotifyDescription("SaveDataWithSignatureAfterSignaturesChoice", ThisObject, Context));
	
	ExitApplication = False;
	Context.Insert("Form", SaveForm);
	
	If SaveForm = Undefined Then
		ExitApplication = True;
	Else
		SaveForm.ClientParameters = ClientParameters;
		
		If SaveAllSignatures Then
			SaveDataWithSignatureAfterSignaturesChoice(SaveForm.SignatureTable, Context);
			Return;
			
		ElsIf Not SaveForm.IsOpen() Then
			ExitApplication = True;
		EndIf;
	EndIf;
	
	If ExitApplication AND Context.ResultProcessing <> Undefined Then
		ExecuteNotifyProcessing(Context.ResultProcessing, False);
	EndIf;
	
EndProcedure

// Continue the DigitalSignatureClient.SaveDataWithSignature procedure.
Procedure SaveDataWithSignatureAfterSignaturesChoice(SignaturesCollection, Context) Export
	
	If TypeOf(SignaturesCollection) <> Type("FormDataCollection") Then
		If Context.ResultProcessing <> Undefined Then
			ExecuteNotifyProcessing(Context.ResultProcessing, False);
		EndIf;
		Return;
	EndIf;
	
	Context.Insert("SignaturesCollection", SignaturesCollection);
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("DataDetails", Context.DataDetails);
	ExecutionParameters.Insert("Notification", New NotifyDescription(
		"SaveDataWithSignatureAfterSaveFileData", ThisObject, Context));
	
	Try
		ExecuteNotifyProcessing(Context.DataDetails.Data, ExecutionParameters);
	Except
		ErrorInformation = ErrorInfo();
		SaveDataWithSignatureAfterSaveFileData(
			New Structure("ErrorDescription", BriefErrorDescription(ErrorInformation)), Context);
	EndTry;
	
EndProcedure

// Continue the DigitalSignatureClient.SaveDataWithSignature procedure.
Procedure SaveDataWithSignatureAfterSaveFileData(Result, Context) Export
	
	If Result.Property("ErrorDescription") Then
		Error = New Structure("ErrorDescription",
			NStr("ru = 'При записи файла возникла ошибка:'; en = 'An error occurred when writing file:'; pl = 'An error occurred when writing file:';de = 'An error occurred when writing file:';ro = 'An error occurred when writing file:';tr = 'An error occurred when writing file:'; es_ES = 'An error occurred when writing file:'") + Chars.LF + Result.ErrorDescription);
		
		ShowApplicationCallError(
			NStr("ru = 'Не удалось сохранить подписи вместе с файлом'; en = 'Cannot save signatures with the file'; pl = 'Cannot save signatures with the file';de = 'Cannot save signatures with the file';ro = 'Cannot save signatures with the file';tr = 'Cannot save signatures with the file'; es_ES = 'Cannot save signatures with the file'"), "", Error, New Structure);
		Return;
		
	ElsIf Not Result.Property("FullFileName")
		Or TypeOf(Result.FullFileName) <> Type("String")
		Or IsBlankString(Result.FullFileName) Then
		
		If Context.ResultProcessing <> Undefined Then
			ExecuteNotifyProcessing(Context.ResultProcessing, False);
		EndIf;
		Return;
	EndIf;
	
	If Result.Property("PremissionRequestProcessing") Then
		Context.Insert("PremissionRequestProcessing", Result.PremissionRequestProcessing);
	EndIf;
	
	Context.Insert("FullFileName", Result.FullFileName);
	Context.Insert("DataFileNameContent",
		CommonClientServer.ParseFullFileName(Context.FullFileName));
	
	If ValueIsFilled(Context.DataFileNameContent.Path) Then
		FileSystemClient.AttachFileOperationsExtension(New NotifyDescription(
			"SaveDataWithSignatureAfterAttachFileSystemExtention", ThisObject, Context));
	Else
		SaveDataWithSignatureAfterAttachFileSystemExtention(False, Context);
	EndIf;
	
EndProcedure

// Continue the DigitalSignatureClient.SaveDataWithSignature procedure.
Procedure SaveDataWithSignatureAfterAttachFileSystemExtention(Attached, Context) Export
	
	Context.Insert("Attached", Attached);
	
	Context.Insert("SignatureFilesExtension",
		DigitalSignatureClient.PersonalSettings().SignatureFilesExtension);
	
	If Context.Attached Then
		Context.Insert("FilesToGet", New Array);
		Context.Insert("FilesPath", CommonClientServer.AddLastPathSeparator(
			Context.DataFileNameContent.Path));
	EndIf;
	
	Context.Insert("FileNames", New Map);
	Context.FileNames.Insert(Context.DataFileNameContent.Name, True);
	
	Context.Insert("IndexOf", -1);
	
	SaveDataWithSignatureLoopStart(Context);
	
EndProcedure

// Continue the DigitalSignatureClient.SaveDataWithSignature procedure.
Procedure SaveDataWithSignatureLoopStart(Context)
	
	If Context.SignaturesCollection.Count() <= Context.IndexOf + 1 Then
		SaveDataWithSignatureAfterLoop(Context);
		Return;
	EndIf;
	Context.IndexOf = Context.IndexOf + 1;
	Context.Insert("SignatureDetails", Context.SignaturesCollection[Context.IndexOf]);
	
	If Not Context.SignatureDetails.Check Then
		SaveDataWithSignatureLoopStart(Context);
		Return;
	EndIf;
	
	Context.Insert("SignatureFileName", Context.SignatureDetails.SignatureFileName);
	
	If IsBlankString(Context.SignatureFileName) Then 
		Context.SignatureFileName = DigitalSignatureInternalClientServer.SignatureFileName(Context.DataFileNameContent.BaseName,
			String(Context.SignatureDetails.CertificateOwner), Context.SignatureFilesExtension);
	Else
		Context.SignatureFileName = CommonClientServer.ReplaceProhibitedCharsInFileName(Context.SignatureFileName);
	EndIf;
	
	SignatureFileNameContent = CommonClientServer.ParseFullFileName(Context.SignatureFileName);
	Context.Insert("SignatureFileNameWithoutExtension", SignatureFileNameContent.BaseName);
	
	Context.Insert("Counter", 1);
	
	SaveDataWithSignatureLoopInternalLoopStart(Context);
	
EndProcedure

// Continue the DigitalSignatureClient.SaveDataWithSignature procedure.
Procedure SaveDataWithSignatureLoopInternalLoopStart(Context)
	
	Context.Counter = Context.Counter + 1;
	
	If Context.Attached Then
		Context.Insert("SignatureFileFullName", Context.FilesPath + Context.SignatureFileName);
	Else
		Context.Insert("SignatureFileFullName", Context.SignatureFileName);
	EndIf;
	
	If Context.FileNames[Context.SignatureFileName] <> Undefined Then
		SaveDataWithSignatureLoopInternalLoopAfterCheckFileExistence(True, Context);
		
	ElsIf Context.Attached Then
		File = New File;
		File.BeginInitialization(New NotifyDescription(
				"SaveDataWithSignatureLoopInternalLoopAfterInitializeFile", ThisObject, Context),
			Context.SignatureFileFullName);
	Else
		SaveDataWithSignatureLoopInternalLoopAfterCheckFileExistence(False, Context);
	EndIf;
	
EndProcedure

// Continue the DigitalSignatureClient.SaveDataWithSignature procedure.
Procedure SaveDataWithSignatureLoopInternalLoopAfterInitializeFile(File, Context) Export
	
	File.BeginCheckingExistence(New NotifyDescription(
		"SaveDataWithSignatureLoopInternalLoopAfterCheckFileExistence", ThisObject, Context));
	
EndProcedure

// Continue the DigitalSignatureClient.SaveDataWithSignature procedure.
Procedure SaveDataWithSignatureLoopInternalLoopAfterCheckFileExistence(Exists, Context) Export
	
	If Not Exists Then
		SaveDataWithSignatureLoopAfterInternalLoop(Context);
		Return;
	EndIf;
	
	Context.SignatureFileName = DigitalSignatureInternalClientServer.SignatureFileName(Context.SignatureFileNameWithoutExtension,
		"(" + String(Context.Counter) + ")", Context.SignatureFilesExtension, False);
	
	SaveDataWithSignatureLoopInternalLoopStart(Context);
	
EndProcedure

// Continue the DigitalSignatureClient.SaveDataWithSignature procedure.
Procedure SaveDataWithSignatureLoopAfterInternalLoop(Context)
	
	SignatureFileNameContent = CommonClientServer.ParseFullFileName(Context.SignatureFileFullName);
	Context.FileNames.Insert(SignatureFileNameContent.Name, False);
	
	If Context.Attached Then
		Details = New TransferableFileDescription(SignatureFileNameContent.Name, Context.SignatureDetails.SignatureAddress);
		Context.FilesToGet.Add(Details);
	Else
		// Saving file from database to the hard disk.
		GetFile(Context.SignatureDetails.SignatureAddress, SignatureFileNameContent.Name);
	EndIf;
	
	If Context.SaveCertificateWithSignature Then
		SaveCertificateDataWithSignatureLoopStart(Context);
	Else
		SaveDataWithSignatureLoopStart(Context);
	EndIf;
	
EndProcedure

// Continue the DigitalSignatureClient.SaveDataWithSignature procedure.
Procedure SaveCertificateDataWithSignatureLoopInternalLoopStart(Context)
	
	If Context.Attached Then
		Context.Insert("CertificateFileFullName", Context.FilesPath + Context.CertificateFileName);
	Else
		Context.Insert("CertificateFileFullName", Context.CertificateFileName);
	EndIf;
	
	If Context.FileNames[Context.CertificateFileName] <> Undefined Then
		SaveCertificateDataWithSignatureLoopInternalLoopAfterCheckFileExistence(True, Context);
		
	ElsIf Context.Attached Then
		File = New File;
		File.BeginInitialization(New NotifyDescription(
				"SaveCertificateDataWithSignatureLoopInternalLoopAfterInitializeFile", ThisObject, Context),
			Context.CertificateFileFullName);
	Else
		SaveCertificateDataWithSignatureLoopInternalLoopAfterCheckFileExistence(False, Context);
	EndIf;
	
EndProcedure

// Continue the DigitalSignatureClient.SaveDataWithSignature procedure.
Procedure SaveCertificateDataWithSignatureLoopInternalLoopAfterInitializeFile(File, Context) Export
	
	File.BeginCheckingExistence(New NotifyDescription(
		"SaveCertificateDataWithSignatureLoopInternalLoopAfterCheckFileExistence", ThisObject, Context));
	
EndProcedure

// Continue the DigitalSignatureClient.SaveDataWithSignature procedure.
Procedure SaveCertificateDataWithSignatureLoopInternalLoopAfterCheckFileExistence(Exists, Context) Export
	
	If Not Exists Then
		SaveCertificateDataWithSignatureLoopAfterInternalLoop(Context);
		Return;
	EndIf;
	
	Context.CertificateFileName = DigitalSignatureInternalClientServer.CertificateFileName(Context.CertificateFileNameWithoutExtension,
		"(" + String(Context.Counter) + ")", Context.SignatureDetails.CertificateExtension, False);
	
	SaveCertificateDataWithSignatureLoopInternalLoopStart(Context);
	
EndProcedure

// Continue the DigitalSignatureClient.SaveDataWithSignature procedure.
Procedure SaveCertificateDataWithSignatureLoopStart(Context)
	
	Context.Insert("CertificateFileName", "");
	
	Context.CertificateFileName = DigitalSignatureInternalClientServer.CertificateFileName(Context.DataFileNameContent.BaseName,
		String(Context.SignatureDetails.CertificateOwner), Context.SignatureDetails.CertificateExtension);
	
	CertificateFileNameComposition  = CommonClientServer.ParseFullFileName(Context.CertificateFileName);
	Context.Insert("CertificateFileNameWithoutExtension", CertificateFileNameComposition.BaseName);
	
	SaveCertificateDataWithSignatureLoopInternalLoopStart(Context);
	
EndProcedure

// Continue the DigitalSignatureClient.SaveDataWithSignature procedure.
Procedure SaveCertificateDataWithSignatureLoopAfterInternalLoop(Context)
	
	CertificateFileNameComposition = CommonClientServer.ParseFullFileName(Context.CertificateFileFullName);
	Context.FileNames.Insert(CertificateFileNameComposition.Name, False);
	
	If Context.Attached Then
		Details = New TransferableFileDescription(CertificateFileNameComposition.Name, Context.SignatureDetails.CertificateAddress);
		Context.FilesToGet.Add(Details);
	Else
		// Saving file from database to the hard disk.
		GetFile(Context.SignatureDetails.CertificateAddress, CertificateFileNameComposition.Name);
	EndIf;
	
	SaveDataWithSignatureLoopStart(Context);
	
EndProcedure

// Continue the DigitalSignatureClient.SaveDataWithSignature procedure.
Procedure SaveDataWithSignatureAfterLoop(Context)
	
	If Not Context.Attached Then
		If Context.ResultProcessing <> Undefined Then
			ExecuteNotifyProcessing(Context.ResultProcessing, True);
		EndIf;
		Return;
	EndIf;
	
	// Saving file from database to the hard disk.
	If Context.FilesToGet.Count() > 0 Then
		Context.Insert("FilesToGet", Context.FilesToGet);
		
		Calls = New Array;
		Call = New Array;
		Call.Add("StartGetFiles");
		Call.Add(Context.FilesToGet);
		Call.Add(Context.FilesPath);
		Call.Add(False);
		Calls.Add(Call);
		
		ContinuationHandler = New NotifyDescription(
			"SaveDataWithSignatureAfterGetExtensions", ThisObject, Context);
		
		If Context.Property("PremissionRequestProcessing") Then
			ExecutionParameters = New Structure;
			ExecutionParameters.Insert("Calls", Calls);
			ExecutionParameters.Insert("ContinuationHandler", ContinuationHandler);
			ExecuteNotifyProcessing(Context.PremissionRequestProcessing, ExecutionParameters);
		Else
			BeginRequestingUserPermission(ContinuationHandler, Calls);
		EndIf;
	Else
		SaveDataWithSignatureAfterGetExtensions(False, Context);
	EndIf;
	
EndProcedure

// Continue the DigitalSignatureClient.SaveDataWithSignature procedure.
Procedure SaveDataWithSignatureAfterGetExtensions(PermissionsReceived, Context) Export
	
	If Not PermissionsReceived
	   AND Context.FilesToGet.Count() > 0
	   AND Context.Property("PremissionRequestProcessing") Then
		
		// The data file was not got - the report is not required.
		If Context.ResultProcessing <> Undefined Then
			ExecuteNotifyProcessing(Context.ResultProcessing, False);
		EndIf;
		
	ElsIf PermissionsReceived Then
		
		SavingParameters = FileSystemClient.FilesSavingParameters();
		SavingParameters.Dialog.Directory = Context.FilesPath;
		FileSystemClient.SaveFiles(New NotifyDescription(
			"SaveDataWithSignatureAfterGetFiles", ThisObject, Context), 
			Context.FilesToGet, SavingParameters);		
	Else
		SaveDataWithSignatureAfterGetFiles(Undefined, Context);
	EndIf;
	
EndProcedure

// Continue the DigitalSignatureClient.SaveDataWithSignature procedure.
Procedure SaveDataWithSignatureAfterGetFiles(ReceivedFiles, Context) Export
	
	ReceivedFilesNames = New Map;
	ReceivedFilesNames.Insert(Context.DataFileNameContent.Name, True);
	
	If TypeOf(ReceivedFiles) = Type("Array") Then
		For each ReceivedFile In ReceivedFiles Do
			SignatureFileNameContent = CommonClientServer.ParseFullFileName(ReceivedFile.Name);
			ReceivedFilesNames.Insert(SignatureFileNameContent.Name, True);
		EndDo;
	EndIf;
	
	Text = NStr("ru = 'Папка с файлами:'; en = 'Folder with files:'; pl = 'Folder with files:';de = 'Folder with files:';ro = 'Folder with files:';tr = 'Folder with files:'; es_ES = 'Folder with files:'") + Chars.LF;
	Text = Text + Context.FilesPath;
	Text = Text + Chars.LF + Chars.LF;
	
	Text = Text + NStr("ru = 'Файлы:'; en = 'Files:'; pl = 'Files:';de = 'Files:';ro = 'Files:';tr = 'Files:'; es_ES = 'Files:'") + Chars.LF;
	
	For Each KeyAndValue In ReceivedFilesNames Do
		Text = Text + KeyAndValue.Key + Chars.LF;
	EndDo;
	
	FormParameters = New Structure;
	FormParameters.Insert("Text", Text);
	FormParameters.Insert("FilesFolder", Context.DataFileNameContent.Path);
	
	OpenForm("CommonForm.ReportOnSavingFilesOfDigitalSignatures", FormParameters,,,,,
		New NotifyDescription("SaveDataWithSignatureAfterCloseReport", ThisObject, Context));
	
EndProcedure

// Continue the DigitalSignatureClient.SaveDataWithSignature procedure.
Procedure SaveDataWithSignatureAfterCloseReport(Result, Context) Export
	
	If Context.ResultProcessing <> Undefined Then
		ExecuteNotifyProcessing(Context.ResultProcessing, True);
	EndIf;
	
EndProcedure

// For internal use only.
Procedure OpenInstructionOfWorkWithApplications() Export
	
	Section = "BookkeepingAndTaxAccounting";
	DigitalSignatureClientOverridable.OnDetermineArticleSectionAtITS(Section);
	
	If Section = "AccountingForPublicInstitutions" Then
		FileSystemClient.OpenURL("http://its.1c.ru/bmk/bud/digsig");
	Else
		FileSystemClient.OpenURL("http://its.1c.ru/bmk/comm/digsig");
	EndIf;
	
EndProcedure

// Shows the dialog box for installing an extension to use digital signature and encryption.
//
// Parameters:
//   WithoutQuestion           - Boolean - if True is set, the question will not be shown.
//                                   It is required if the user clicked Install extension.
//
//   ResultHandler - NotifyDescription - details of the procedure that receives the selection result.
//   QuestionText         - String - a question text.
//   QuestionTitle     - String - a question title.
//
// The first parameter value that is returned to the calling code handler:
//   ExtensionInstalled
//       * True - a user has confirmed the installation, after installation the extension was successfully attached.
//       * False   - a user has confirmed the installation, but after installation the extension could not be attached.
//       * Undefined - a user canceled the installation.
//
Procedure InstallExtension(WithoutQuestion, ResultHandler = Undefined, QuestionText = "", QuestionTitle = "") Export
	
	Context = New Structure;
	Context.Insert("Notification",       ResultHandler);
	Context.Insert("QuestionText",     QuestionText);
	Context.Insert("QuestionTitle", QuestionTitle);
	Context.Insert("WithoutQuestion",       WithoutQuestion);
	
	BeginAttachingCryptoExtension(New NotifyDescription(
		"InstallExtensionAfterCheckCryptoExtensionAttachment", ThisObject, Context));
	
EndProcedure

// Continue the InstallExtension procedure.
Procedure InstallExtensionAfterCheckCryptoExtensionAttachment(Attached, Context) Export
	
	If Attached Then
		ExecuteNotifyProcessing(Context.Notification, True);
		Return;
	EndIf;
	
	BeginAttachingCryptoExtension(New NotifyDescription(
		"InstallExtensionAfterAttachCryptoExtension", ThisObject, Context));
	
EndProcedure

// Continue the InstallExtension procedure.
Procedure InstallExtensionAfterAttachCryptoExtension(Attached, Context) Export
	
	If Attached Then
		If Context.Notification <> Undefined Then
			ExecuteNotifyProcessing(Context.Notification, True);
		EndIf;
		Return;
	EndIf;
	
	Handler = New NotifyDescription("InstallExtensionAfterResponse", ThisObject, Context);
	
	If Context.WithoutQuestion Then
		ExecuteNotifyProcessing(Handler, DialogReturnCode.Yes);
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("QuestionTitle", Context.QuestionTitle);
	FormParameters.Insert("QuestionText",     Context.QuestionText);
	
	OpenForm("CommonForm.QuestionInstallCryptographyExtension",
		FormParameters,,,,, Handler);
	
EndProcedure

// Continue the InstallExtension procedure.
Procedure InstallExtensionAfterResponse(Response, Context) Export
	
	If Response = DialogReturnCode.Yes Then
		BeginInstallCryptoExtension(New NotifyDescription(
			"InstallExtensionAfterInstallCryptoExtension", ThisObject, Context));
	Else
		If Context.Notification <> Undefined Then
			ExecuteNotifyProcessing(Context.Notification, Undefined);
		EndIf;
	EndIf;
	
EndProcedure

// Continue the InstallExtension procedure.
Procedure InstallExtensionAfterInstallCryptoExtension(Context) Export
	
	BeginAttachingCryptoExtension(New NotifyDescription(
		"InstallExtensionAfterAttachInstalledCryptoExtension", ThisObject, Context));
	
EndProcedure

// Continue the InstallExtension procedure.
Procedure InstallExtensionAfterAttachInstalledCryptoExtension(Attached, Context) Export
	
	If Attached Then
		Notify("Install_CryptoExtension");
	EndIf;
	
	If Context.Notification <> Undefined Then
		ExecuteNotifyProcessing(Context.Notification, Attached);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Common procedures and functions of the managed forms.

// For internal use only.
Procedure ContinueOpeningStart(Notification, Form, ClientParameters, Encryption = False, Details = False) Export
	
	If Not Encryption Then
		InputParameters = Undefined;
		ClientParameters.DataDetails.Property("AdditionalActionParameters", InputParameters);
		OutputParameters = Form.AdditionalActionsOutputParameters;
		Form.AdditionalActionsOutputParameters = Undefined;
		DigitalSignatureClientOverridable.BeforeOperationStart(
			?(Details, "Details", "Signing"), InputParameters, OutputParameters);
	EndIf;
	
	Context = New Structure;
	Context.Insert("Notification", Notification);
	Context.Insert("ErrorAtServer", New Structure);
	
	If DigitalSignatureClient.GenerateDigitalSignaturesAtServer() Then
		If Not ValueIsFilled(Form.CryptographyManagerOnServerErrorDescription) Then
			ExecuteNotifyProcessing(Notification, True);
			Return;
		EndIf;
		Context.ErrorAtServer = Form.CryptographyManagerOnServerErrorDescription;
	EndIf;
	
	CreateCryptoManager(New NotifyDescription(
			"ContinueOpeningStartAfterCreateCryptoManager", ThisObject, Context),
		"GetCertificates", Undefined);
	
EndProcedure

// Continues the ContinueOpeningStart procedure.
Procedure ContinueOpeningStartAfterCreateCryptoManager(Result, Context) Export
	
	If TypeOf(Result) <> Type("CryptoManager") AND Not UseDigitalSignatureSaaS() Then
		
		ShowApplicationCallError(
			NStr("ru = 'Требуется программа электронной подписи и шифрования'; en = 'Digital signature and encryption application is required'; pl = 'Digital signature and encryption application is required';de = 'Digital signature and encryption application is required';ro = 'Digital signature and encryption application is required';tr = 'Digital signature and encryption application is required'; es_ES = 'Digital signature and encryption application is required'"),
			"", Result, Context.ErrorAtServer);
		
		ExecuteNotifyProcessing(Context.Notification, False);
		Return;
	EndIf;
	
	ExecuteNotifyProcessing(Context.Notification, True);
	
EndProcedure


// For internal use only.
Procedure GetCertificatesThumbprintsAtClient(Notification) Export
	
	Context = New Structure;
	Context.Insert("Notification", Notification);
	
	CreateCryptoManager(New NotifyDescription(
			"GetCertificatesThumbprintsAtClientAfterCreateCryptoManager", ThisObject, Context),
		"GetCertificates", False);
	
EndProcedure

// Continues the GetCertificatesThumbprintsAtClient procedure.
Procedure GetCertificatesThumbprintsAtClientAfterCreateCryptoManager(CryptoManager, Context) Export
	
	If TypeOf(CryptoManager) <> Type("CryptoManager") Then
		ExecuteNotifyProcessing(Context.Notification, New Array);
		Return;
	EndIf;
	
	CryptoManager.BeginGettingCertificateStore(
		New NotifyDescription(
			"GetCertificatesThumbprintsAtClientAfterGetStorage", ThisObject, Context),
		CryptoCertificateStoreType.PersonalCertificates);
	
EndProcedure

// Continues the GetCertificatesThumbprintsAtClient procedure.
Procedure GetCertificatesThumbprintsAtClientAfterGetStorage(CryptoCertificateStore, Context) Export
	
	CryptoCertificateStore.BeginGettingAll(New NotifyDescription(
		"GetCertificatesThumbprintsAtClientAfterGetAll", ThisObject, Context));
	
EndProcedure

// Continues the GetCertificatesThumbprintsAtClient procedure.
Procedure GetCertificatesThumbprintsAtClientAfterGetAll(CertificatesArray, Context) Export
	
	CertificatesThumbprintsAtClient = New Array;
	
	DigitalSignatureInternalClientServer.AddCertificatesThumbprints(CertificatesThumbprintsAtClient,
		CertificatesArray, TimeAddition(), CommonClient.SessionDate());
	
	ExecuteNotifyProcessing(Context.Notification, CertificatesThumbprintsAtClient);
	
EndProcedure


// For internal use only.
Procedure ProcessPasswordInForm(Form, InternalData, PasswordProperties, AdditionalParameters = Undefined, NewPassword = Null) Export
	
	If TypeOf(PasswordProperties) <> Type("Structure") Then
		PasswordProperties = New Structure;
		PasswordProperties.Insert("Value", Undefined);
		PasswordProperties.Insert("PasswordNoteHandler", Undefined);
		// The PasswordChecked property allows memorizing without a check.
		// It is turned on when the NewPassword is specified and upon the successful operation completion.
		PasswordProperties.Insert("PasswordVerified", False);
	EndIf;
	
	If AdditionalParameters = Undefined Then
		AdditionalParameters = New Structure;
	EndIf;
	
	AdditionalParameters.Insert("Certificate", Form.Certificate);
	AdditionalParameters.Insert("StrongPrivateKeyProtection",
		Form.CertificatePrivateKeyAdvancedProtection);
	
	If Not AdditionalParameters.Property("OnSetPasswordFromAnotherOperation") Then
		AdditionalParameters.Insert("OnSetPasswordFromAnotherOperation", False);
	EndIf;

	If Not AdditionalParameters.Property("OnChangeAttributePassword") Then
		AdditionalParameters.Insert("OnChangeAttributePassword", False);
	EndIf;
	
	If Not AdditionalParameters.Property("OnChangeAttributeRememberPassword") Then
		AdditionalParameters.Insert("OnChangeAttributeRememberPassword", False);
	EndIf;
	
	If Not AdditionalParameters.Property("OnOperationSuccess") Then
		AdditionalParameters.Insert("OnOperationSuccess", False);
	EndIf;
	
	If Not AdditionalParameters.Property("OnChangeCertificateProperties") Then
		AdditionalParameters.Insert("OnChangeCertificateProperties", False);
	EndIf;
	
	AdditionalParameters.Insert("PasswordInMemory", False);
	AdditionalParameters.Insert("PasswordSetProgrammatically", False);
	AdditionalParameters.Insert("PasswordNote");
	
	ProcessPassword(InternalData, Form.Password, PasswordProperties, Form.RememberPassword,
		AdditionalParameters, NewPassword);
	
	Items = Form.Items;
	
	If Items.Find("Pages") = Undefined
	 Or Items.Find("EnhancedPasswordNotePage") = Undefined
	 Or Items.Find("RememberPasswordPage") = Undefined Then
		
		Return;
	EndIf;
	
	If AdditionalParameters.StrongPrivateKeyProtection Then
		Items.Password.Enabled = False;
		Items.Pages.CurrentPage = Items.EnhancedPasswordNotePage;
	Else
		
		If AdditionalParameters.PasswordSetProgrammatically Then
			Items.Pages.CurrentPage = Items.SpecifiedPasswordNotePage;
			PasswordNote = AdditionalParameters.PasswordNote;
			Items.SpecifiedPasswordNote.Title   = PasswordNote.NoteText;
			Items.SpecifiedPasswordNote.Hyperlink = PasswordNote.HyperlinkNote;
			Items.SpecifiedPasswordNoteExtendedTooltip.Title = PasswordNote.ToolTipText;
			PasswordProperties.PasswordNoteHandler = PasswordNote.ProcessAction;
			Items.Password.Enabled = True;
		Else
			Items.Pages.CurrentPage = Items.RememberPasswordPage;
			Items.Password.Enabled = Not AdditionalParameters.PasswordInMemory;
		EndIf;
	EndIf;
	
	AdditionalParameters.Insert("PasswordSpecified",
		    AdditionalParameters.PasswordSetProgrammatically
		Or AdditionalParameters.PasswordInMemory
		Or AdditionalParameters.OnSetPasswordFromAnotherOperation);
	
EndProcedure

// For internal use only.
Procedure SpecifiedPasswordNoteClick(Form, Item, PasswordProperties) Export
	
	If TypeOf(PasswordProperties.PasswordNoteHandler) = Type("NotifyDescription") Then
		Result = New Structure;
		Result.Insert("Certificate", Form.Certificate);
		Result.Insert("Action", "NoteClick");
		ExecuteNotifyProcessing(PasswordProperties.PasswordNoteHandler, Result);
	EndIf;
	
EndProcedure

// For internal use only.
Procedure SpecifiedPasswordNoteURLProcessing(Form, Item, URL,
			StandardProcessing, PasswordProperties) Export
	
	StandardProcessing = False;
	
	If TypeOf(PasswordProperties.PasswordNoteHandler) = Type("NotifyDescription") Then
		Result = New Structure;
		Result.Insert("Certificate", Form.Certificate);
		Result.Insert("Action", URL);
		ExecuteNotifyProcessing(PasswordProperties.PasswordNoteHandler, Result);
	EndIf;
	
EndProcedure

// For internal use only.
Procedure DataPresentationClick(Form, Item, StandardProcessing, CurrentPresentationsList) Export
	
	StandardProcessing = False;
	
	If CurrentPresentationsList.Count() > 1 Then
		ListDataPresentations = New Array;
		For Each ListItem In CurrentPresentationsList Do
			ListDataPresentations.Add(ListItem.Presentation);
		EndDo;
		FormParameters = New Structure;
		FormParameters.Insert("DataPresentationsList", ListDataPresentations);
		FormParameters.Insert("DataPresentation", Form.DataPresentation);
		NewForm = OpenForm("Catalog.DigitalSignatureAndEncryptionKeysCertificates.Form.DataView",
			FormParameters, Item);
		If NewForm = Undefined Then
			Return;
		EndIf;
		NewForm.SetPresentationList(CurrentPresentationsList, Undefined);
	Else
		Value = CurrentPresentationsList[0].Value;
		If TypeOf(Value) = Type("NotifyDescription") Then
			ExecuteNotifyProcessing(Value);
		Else
			ShowValue(, Value);
		EndIf;
	EndIf;
	
EndProcedure

// For internal use only.
Function FullDataPresentation(Form) Export
	
	Items = Form.Items;
	
	If Items.DataPresentation.TitleLocation <> FormItemTitleLocation.None
	   AND ValueIsFilled(Items.DataPresentation.Title) Then
	
		Return Items.DataPresentation.Title + ": " + Form.DataPresentation;
	Else
		Return Form.DataPresentation;
	EndIf;
	
EndFunction

// For internal use only.
Procedure CertificatePickupFromSelectionList(Form, Text, ChoiceData, StandardProcessing) Export
	
	If Text = "" AND Form.CertificatePicklist.Count() = 0 Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	ChoiceData = New ValueList;
	
	For each ListItem In Form.CertificatePicklist Do
		If StrFind(Upper(ListItem.Presentation), Upper(Text)) > 0 Then
			ChoiceData.Add(ListItem.Value, ListItem.Presentation);
		EndIf;
	EndDo;
	
EndProcedure


// For internal use only.
Procedure ExecuteAtSide(Notification, Operation, ExecutionSide, ExecutionParameters) Export
	
	Context = New Structure("DataDetails, Form, FormID, PasswordValue,
		|CertificateValid, CertificateAddress, CurrentPresentationsList, FullDataPresentation");
	
	FillPropertyValues(Context, ExecutionParameters);
	
	Context.Insert("Notification",       Notification);
	Context.Insert("Operation",         Operation); // Signing, Encryption, Decryption.
	Context.Insert("OnClientSide", ExecutionSide = "OnClientSide");
	
	If Context.OnClientSide Then
		If Context.Operation = "Encryption" AND UseDigitalSignatureSaaS() Then
			Context.Insert("CryptoManager", "CryptographyService");
			ExecuteAtSIdeSaaS(Null, Context);
		ElsIf (Context.Operation = "Details" Or Context.Operation = "Signing")
			AND UseDigitalSignatureSaaS()
			AND Context.Form.ExecuteInSaaS Then
				Context.Insert("CryptoManager", "CryptographyService");
				ExecuteAtSIdeSaaS(Null, Context);
		Else
			CreateCryptoManager(New NotifyDescription(
					"ExecuteAtSideAfterCreateCryptoManager", ThisObject, Context),
				Null, Undefined, Context.Form.CertificateApplication, Context.Form.CertificatePrivateKeyAdvancedProtection);
		EndIf;
	Else
		ExecuteAtSideLoopRun(Context);
	EndIf;
	
EndProcedure

// Continues the ExecuteAtSide procedure.
Procedure ExecuteAtSideAfterCreateCryptoManager(Result, Context) Export
	
	If TypeOf(Result) <> Type("CryptoManager") Then
		ExecuteNotifyProcessing(Context.Notification, New Structure("Error", Result));
		Return;
	EndIf;
	Context.Insert("CryptoManager", Result);
	
	// If a personal crypto certificate is not used, it does not need to be searched for.
	If Context.Operation <> "Encryption"
	 Or ValueIsFilled(Context.Form.CertificateThumbprint) Then
		
		GetCertificateByThumbprint(New NotifyDescription(
				"ExecuteAtSideAfterCertificateSearch", ThisObject, Context),
			Context.Form.CertificateThumbprint, True, Undefined, Context.Form.CertificateApplication);
	Else
		ExecuteAtSideAfterCertificateSearch(Null, Context);
	EndIf;
	
EndProcedure

// Continues the ExecuteAtSide procedure.
Procedure ExecuteAtSideAfterCertificateSearch(Result, Context) Export
	
	If TypeOf(Result) <> Type("CryptoCertificate") AND Result <> Null Then
		ExecuteNotifyProcessing(Context.Notification, New Structure("Error", Result));
		Return;
	EndIf;
	Context.Insert("CryptoCertificate", Result);
	
	If Context.Operation = "Signing" Then
		If Not InteractiveCryptographyModeUsed(Context.CryptoManager) Then
			Context.CryptoManager.PrivateKeyAccessPassword = Context.PasswordValue;
		EndIf;
		Context.Delete("PasswordValue");
		Context.CryptoCertificate.BeginUnloading(New NotifyDescription(
			"ExecuteAtSideAfterCertificateExport", ThisObject, Context));
		
	ElsIf Context.Operation = "Encryption" Then
		CertificatesProperties = Context.DataDetails.EncryptionCertificates;
		If TypeOf(CertificatesProperties) = Type("String") Then
			CertificatesProperties = GetFromTempStorage(CertificatesProperties);
		EndIf;
		Context.Insert("IndexOf", -1);
		Context.Insert("CertificatesProperties", CertificatesProperties);
		Context.Insert("EncryptionCertificates", New Array);
		ExecuteAtSidePrepareCertificatesLoopStart(Context);
		Return;
	Else
		If Not InteractiveCryptographyModeUsed(Context.CryptoManager) Then
			Context.CryptoManager.PrivateKeyAccessPassword = Context.PasswordValue;
		EndIf;
		Context.Delete("PasswordValue");
		ExecuteAtSideLoopRun(Context);
	EndIf;
	
EndProcedure

// Continues the ExecuteAtSide procedure.
Procedure ExecuteAtSidePrepareCertificatesLoopStart(Context)
	
	If Context.CertificatesProperties.Count() <= Context.IndexOf + 1 Then
		ExecuteAtSideLoopRun(Context);
		Return;
	EndIf;
	Context.IndexOf = Context.IndexOf + 1;
	
	CryptoCertificate = New CryptoCertificate;
	CryptoCertificate.BeginInitialization(New NotifyDescription(
			"ExecuteAtSidePrepareCertificatesAfterInitializeCertificate", ThisObject, Context),
		Context.CertificatesProperties[Context.IndexOf].Certificate);
	
EndProcedure

// Continues the ExecuteAtSide procedure.
Procedure ExecuteAtSidePrepareCertificatesAfterInitializeCertificate(CryptoCertificate, Context) Export
	
	Context.EncryptionCertificates.Add(CryptoCertificate);
	
	ExecuteAtSidePrepareCertificatesLoopStart(Context);
	
EndProcedure

// Continues the ExecuteAtSide procedure.
Procedure ExecuteAtSideAfterCertificateExport(ExportedData, Context) Export
	
	Context.Insert("CertificateProperties", DigitalSignatureClient.CertificateProperties(
		Context.CryptoCertificate));
	Context.CertificateProperties.Insert("BinaryData", ExportedData);
	
	ExecuteAtSideLoopRun(Context);
	
EndProcedure

// Continues the ExecuteAtSide procedure.
Procedure ExecuteAtSideLoopRun(Context)
	
	Context.Insert("OperationStarted", False);
	
	If Context.DataDetails.Property("Data") Then
		DataItems = New Array;
		DataItems.Add(Context.DataDetails);
	Else
		DataItems = Context.DataDetails.DataSet;
	EndIf;
	
	Context.Insert("DataItems", DataItems);
	Context.Insert("IndexOf", -1);
	
	ExecuteAtSideLoopStart(Context);
	
EndProcedure

// Continues the ExecuteAtSide procedure.
Procedure ExecuteAtSideLoopStart(Context)
	
	If Context.DataItems.Count() <= Context.IndexOf + 1 Then
		ExecuteAtSideAfterLoop(Undefined, Context);
		Return;
	EndIf;
	Context.IndexOf = Context.IndexOf + 1;
	Context.Insert("DataItem", Context.DataItems[Context.IndexOf]);
	
	If Not Context.DataDetails.Property("Data") Then
		Context.DataDetails.Insert("CurrentDataSetItem", Context.DataItem);
	EndIf;
	
	If Context.Operation = "Signing"
	   AND Context.DataItem.Property("SignatureProperties")
	 Or Context.Operation = "Encryption"
	   AND Context.DataItem.Property("EncryptedData")
	 Or Context.Operation = "Details"
	   AND Context.DataItem.Property("DecryptedData") Then
		
		ExecuteAtSideLoopStart(Context);
		Return;
	EndIf;
	
	GetDataFromDataDetails(New NotifyDescription(
			"ExecuteAtSideCycleAfterGetData", ThisObject, Context),
		Context.Form, Context.DataDetails, Context.DataItem.Data, Context.OnClientSide);
	
EndProcedure


// Continues the ExecuteAtSide procedure.
Procedure ExecuteAtSideLoopAfterOperationAtClientXMLDSig(SOAPEnvelope, Context) Export
	
	Context.OperationStarted = True;
	
	SignatureProperties = DigitalSignatureInternalClientServer.SignatureProperties(SOAPEnvelope,
		Context.CertificateProperties,
		Context.Form.Comment,
		UsersClient.AuthorizedUser());
	
	If Context.CertificateValid <> Undefined Then
		SignatureProperties.SignatureDate = CommonClient.SessionDate();
		SignatureProperties.SignatureValidationDate = SignatureProperties.SignatureDate;
		SignatureProperties.SignatureCorrect = Context.CertificateValid;
	EndIf;
	
	ExecuteAtSideAfterSigning(SignatureProperties, Context);
	
EndProcedure

// Continues the ExecuteAtSide procedure.
Procedure ExecuteAtSideCycleAfterErrorAtClientXMLDSig(ErrorText, Context) Export
	
	ErrorAtClient = New Structure("ErrorDescription", ErrorText);
	ErrorAtClient.Insert("Instruction", True);
	
	ExecuteAtSideAfterLoop(ErrorAtClient, Context);
	
EndProcedure

// Continues the ExecuteAtSide procedure.
Procedure ExecuteAtSideCycleAfterGetData(Result, Context) Export
	
	IsXMLDSig = (TypeOf(Result) = Type("Structure") AND Result.Property("XMLDSigParameters"));
	
	If TypeOf(Result) = Type("Structure")
		AND Not IsXMLDSig Then
		Error = New Structure("ErrorDescription",
			DigitalSignatureInternalClientServer.DataGettingErrorTitle(Context.Operation)
			+ Chars.LF + Result.ErrorDescription);
		ExecuteAtSideAfterLoop(Error, Context);
		Return;
	EndIf;
	Data = Result;
	
	If Context.OnClientSide Then
		CryptoManager = Context.CryptoManager;
		
		If IsXMLDSig Then
			If Context.Operation <> "Signing" Then
				Error = New Structure("ErrorDescription",
					DigitalSignatureInternalClientServer.DataGettingErrorTitle(Context.Operation)
					+ Chars.LF + NStr("ru = 'Внешняя компонента XMLDSig может использоваться только для подписания.'; en = 'External component XMLDSig can be used only for signing.'; pl = 'External component XMLDSig can be used only for signing.';de = 'External component XMLDSig can be used only for signing.';ro = 'External component XMLDSig can be used only for signing.';tr = 'External component XMLDSig can be used only for signing.'; es_ES = 'External component XMLDSig can be used only for signing.'"));
				ExecuteAtSideAfterLoop(Error, Context);
				Return;
			EndIf;
			
			NotificationSuccess = New NotifyDescription(
				"ExecuteAtSideLoopAfterOperationAtClientXMLDSig", ThisObject, Context);
			
			NotificationError = New NotifyDescription(
				"ExecuteAtSideCycleAfterErrorAtClientXMLDSig", ThisObject, Context);
			
			Notifications = New Structure;
			Notifications.Insert("Success", NotificationSuccess);
			Notifications.Insert("Error", NotificationError);
			
			StartSigning(
				Notifications,
				Result.SOAPEnvelope,
				Result.XMLDSigParameters,
				Context.CryptoCertificate,
				Context.CryptoManager);
		Else
			Notification = New NotifyDescription(
				"ExecuteAtSideCycleAfterOPerationAtClient", ThisObject, Context,
				"ExecuteOnSideLoopAfterOperationErrorAtClient", ThisObject);
			If Context.Operation = "Signing" Then
				If CryptoManager = "CryptographyService" Then
					CertificateForSignature = GetFromTempStorage(Context.DataDetails.SelectedCertificate.Data);
					ModuleCryptoServiceClient = CommonClient.CommonModule("CryptographyServiceClient");
					ModuleCryptoServiceClient.Sign(Notification, Data, CertificateForSignature);
				Else
					CryptoManager.BeginSigning(Notification, Data, Context.CryptoCertificate);
				EndIf;
				
			ElsIf Context.Operation = "Encryption" Then
				If CryptoManager = "CryptographyService" Then
					ModuleCryptoServiceClient = CommonClient.CommonModule("CryptographyServiceClient");
					ModuleCryptoServiceClient.Encrypt(Notification, Data, Context.EncryptionCertificates);
				Else
					CryptoManager.BeginEncrypting(Notification, Data, Context.EncryptionCertificates);
				EndIf;
			Else
				If CryptoManager = "CryptographyService" Then
					ModuleCryptoServiceClient = CommonClient.CommonModule("CryptographyServiceClient");
					ModuleCryptoServiceClient.Decrypt(Notification, Data);
				Else
					CryptoManager.BeginDecrypting(Notification, Data);
				EndIf;
			EndIf;
		EndIf;
		
		Return;
	EndIf;
	
	DataItemForSErver = New Structure;
	DataItemForSErver.Insert("Data", Data);
	
	ParametersForServer = New Structure;
	ParametersForServer.Insert("Operation", Context.Operation);
	ParametersForServer.Insert("FormID",  Context.FormID);
	ParametersForServer.Insert("CertificateValid",     Context.CertificateValid);
	ParametersForServer.Insert("CertificateApplication", Context.Form.CertificateApplication);
	ParametersForServer.Insert("CertificateThumbprint", Context.Form.CertificateThumbprint);
	ParametersForServer.Insert("DataItemForSErver", DataItemForSErver);
	
	ErrorAtServer = New Structure;
	ResultAddress = Undefined;
	
	If Context.Operation = "Signing" Then
		ParametersForServer.Insert("Comment",    Context.Form.Comment);
		ParametersForServer.Insert("PasswordValue", Context.PasswordValue);
		
		If Context.DataItem.Property("Object")
		   AND Not TypeOf(Context.DataItem.Object) = Type("NotifyDescription") Then
			
			DataItemForSErver.Insert("Object", Context.DataItem.Object);
			
			If Context.DataItem.Property("ObjectVersion") Then
				DataItemForSErver.Property("ObjectVersion", Context.DataItem.ObjectVersion);
			EndIf;
		EndIf;
		
	ElsIf Context.Operation = "Encryption" Then
		ParametersForServer.Insert("CertificatesAddress", Context.DataDetails.EncryptionCertificates);
	Else // Decryption.
		ParametersForServer.Insert("PasswordValue", Context.PasswordValue);
	EndIf;
	
	Success = DigitalSignatureServerServiceCall.ExecuteAtServerSide(ParametersForServer,
		ResultAddress, Context.OperationStarted, ErrorAtServer);
	
	If Not Success Then
		ExecuteAtSideAfterLoop(ErrorAtServer, Context);
		
	ElsIf Context.Operation = "Signing" Then
		ExecuteAtSideAfterSigning(ResultAddress, Context);
		
	ElsIf Context.Operation = "Encryption" Then
		ExecuteAtSideLoopAfterEncryption(ResultAddress, Context);
	Else // Decryption.
		ExecuteAtSideAfterDecrypt(ResultAddress, Context);
	EndIf;
	
EndProcedure

// Continues the ExecuteAtSide procedure.
Procedure ExecuteOnSideLoopAfterOperationErrorAtClient(ErrorInformation, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	ErrorAtClient = New Structure("ErrorDescription", BriefErrorDescription(ErrorInformation));
	ErrorAtClient.Insert("Instruction", True);
	
	ExecuteAtSideAfterLoop(ErrorAtClient, Context);
	
EndProcedure

// Continues the ExecuteAtSide procedure.
Procedure ExecuteAtSideCycleAfterOPerationAtClient(BinaryData, Context) Export
	
	If Context.Property("CryptoManager") AND Context.CryptoManager = "CryptographyService" Then
		
		If Not BinaryData.Completed Then
			ErrorAtClient = New Structure("ErrorDescription", BinaryData.ErrorInfo.Details);
			ExecuteAtSideAfterLoop(ErrorAtClient, Context);
			Return;
		EndIf;
		
		If Context.Operation = "Signing" Then
			BinaryData = BinaryData.Signature;
		ElsIf Context.Operation = "Encryption" Then
			BinaryData = BinaryData.EncryptedData;
		Else
			BinaryData = BinaryData.DecryptedData;
		EndIf;
		
	EndIf;
	
	ErrorDescription = "";
	If Context.Operation = "Signing"
	   AND DigitalSignatureInternalClientServer.BlankSignatureData(BinaryData, ErrorDescription)
	 Or Context.Operation = "Encryption"
	   AND DigitalSignatureInternalClientServer.BlankEncryptedData(BinaryData, ErrorDescription) Then

		ErrorAtClient = New Structure("ErrorDescription", ErrorDescription);
		ExecuteAtSideAfterLoop(ErrorAtClient, Context);
		Return;
	EndIf;
	
	Context.OperationStarted = True;
	
	If Context.Operation = "Signing" Then
		SignatureProperties = DigitalSignatureInternalClientServer.SignatureProperties(BinaryData,
			Context.CertificateProperties,
			Context.Form.Comment,
			UsersClient.AuthorizedUser());
		
		If Context.CertificateValid <> Undefined Then
			SignatureProperties.SignatureDate = CommonClient.SessionDate();
			SignatureProperties.SignatureValidationDate = SignatureProperties.SignatureDate;
			SignatureProperties.SignatureCorrect = Context.CertificateValid;
		EndIf;
		ExecuteAtSideAfterSigning(SignatureProperties, Context);
		
	ElsIf Context.Operation = "Encryption" Then
		ExecuteAtSideLoopAfterEncryption(BinaryData, Context);
	Else
		ExecuteAtSideAfterDecrypt(BinaryData, Context);
	EndIf;
	
EndProcedure

// Continues the ExecuteAtSide procedure.
Procedure ExecuteAtSideAfterSigning(SignatureProperties, Context)
	
	DataItem = Context.DataItem;
	DataItem.Insert("SignatureProperties", SignatureProperties);
	
	If Not DataItem.Property("Object") Then
		DigitalSignatureServerServiceCall.RegisterDataSigningInLog(
			CurrentDataItemProperties(Context, SignatureProperties));
		ExecuteAtSideLoopStart(Context);
		Return;
	EndIf;
	
	If TypeOf(DataItem.Object) <> Type("NotifyDescription") Then
		If Context.OnClientSide Then
			ObjectVersion = Undefined;
			DataItem.Property("ObjectVersion", ObjectVersion);
			ErrorPresentation = DigitalSignatureServerServiceCall.AddSignature(
				DataItem.Object, SignatureProperties, Context.FormID, ObjectVersion);
			If ValueIsFilled(ErrorPresentation) Then
				DataItem.Delete("SignatureProperties");
				ErrorAtClient = New Structure("ErrorDescription", ErrorPresentation);
				ExecuteAtSideAfterLoop(ErrorAtClient, Context);
				Return;
			EndIf;
		EndIf;
		NotifyChanged(DataItem.Object);
		ExecuteAtSideLoopStart(Context);
		Return;
	EndIf;
	
	DigitalSignatureServerServiceCall.RegisterDataSigningInLog(
		CurrentDataItemProperties(Context, SignatureProperties));
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("DataDetails", Context.DataDetails);
	ExecutionParameters.Insert("Notification", New NotifyDescription(
		"ExecuteAtSideAfterRecordSignature", ThisObject, Context));
	
	Try
		ExecuteNotifyProcessing(DataItem.Object, ExecutionParameters);
	Except
		ErrorInformation = ErrorInfo();
		ExecuteAtSideAfterRecordSignature(New Structure("ErrorDescription",
			BriefErrorDescription(ErrorInformation)), Context);
	EndTry;
	
EndProcedure

// Continues the ExecuteAtSide procedure.
Procedure ExecuteAtSideAfterRecordSignature(Result, Context) Export
	
	If Result.Property("ErrorDescription") Then
		Context.DataItem.Delete("SignatureProperties");
		Error = New Structure("ErrorDescription",
			NStr("ru = 'При записи подписи возникла ошибка:'; en = 'An error occurred when writing the signature:'; pl = 'An error occurred when writing the signature:';de = 'An error occurred when writing the signature:';ro = 'An error occurred when writing the signature:';tr = 'An error occurred when writing the signature:'; es_ES = 'An error occurred when writing the signature:'") + Chars.LF + Result.ErrorDescription);
		ExecuteAtSideAfterLoop(Error, Context);
		Return;
	EndIf;
	
	ExecuteAtSideLoopStart(Context);
	
EndProcedure

// Continues the ExecuteAtSide procedure.
Procedure ExecuteAtSideLoopAfterEncryption(EncryptedData, Context)
	
	DataItem = Context.DataItem;
	DataItem.Insert("EncryptedData", EncryptedData);
	
	If Not DataItem.Property("ResultPlacement")
	 Or TypeOf(DataItem.ResultPlacement) <> Type("NotifyDescription") Then
		
		ExecuteAtSideLoopStart(Context);
		Return;
	EndIf;
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("DataDetails", Context.DataDetails);
	ExecutionParameters.Insert("Notification", New NotifyDescription(
		"ExecuteAtSideLoopAfterWriteEncryptedData", ThisObject, Context));
	
	Try
		ExecuteNotifyProcessing(DataItem.ResultPlacement, ExecutionParameters);
	Except
		ErrorInformation = ErrorInfo();
		ExecuteAtSideLoopAfterWriteEncryptedData(New Structure("ErrorDescription",
			BriefErrorDescription(ErrorInformation)), Context);
	EndTry;
	
EndProcedure

// Continues the ExecuteAtSide procedure.
Procedure ExecuteAtSideLoopAfterWriteEncryptedData(Result, Context) Export
	
	If Result.Property("ErrorDescription") Then
		Context.DataItem.Delete("EncryptedData");
		Error = New Structure("ErrorDescription",
			NStr("ru = 'При записи зашифрованных данных возникла ошибка:'; en = 'An error occurred when writing encrypted data:'; pl = 'An error occurred when writing encrypted data:';de = 'An error occurred when writing encrypted data:';ro = 'An error occurred when writing encrypted data:';tr = 'An error occurred when writing encrypted data:'; es_ES = 'An error occurred when writing encrypted data:'")
			+ Chars.LF + Result.ErrorDescription);
		ExecuteAtSideAfterLoop(Error, Context);
		Return;
	EndIf;
	
	ExecuteAtSideLoopStart(Context);
	
EndProcedure

// Continues the ExecuteAtSide procedure.
Procedure ExecuteAtSideAfterDecrypt(DecryptedData, Context)
	
	DataItem = Context.DataItem;
	DataItem.Insert("DecryptedData", DecryptedData);
	
	If Not DataItem.Property("ResultPlacement")
	 Or TypeOf(DataItem.ResultPlacement) <> Type("NotifyDescription") Then
	
		ExecuteAtSideLoopStart(Context);
		Return;
	EndIf;
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("DataDetails", Context.DataDetails);
	ExecutionParameters.Insert("Notification", New NotifyDescription(
		"ExecuteAtSideLoopAfterWriteDecryptedData", ThisObject, Context));
	
	Try
		ExecuteNotifyProcessing(DataItem.ResultPlacement, ExecutionParameters);
	Except
		ErrorInformation = ErrorInfo();
		ExecuteAtSideLoopAfterWriteEncryptedData(New Structure("ErrorDescription",
			BriefErrorDescription(ErrorInformation)), Context);
	EndTry;
	
EndProcedure

// Continues the ExecuteAtSide procedure.
Procedure ExecuteAtSideLoopAfterWriteDecryptedData(Result, Context) Export
	
	If Result.Property("ErrorDescription") Then
		Context.DataItem.Delete("DecryptedData");
		Error = New Structure("ErrorDescription",
			NStr("ru = 'При записи расшифрованных данных возникла ошибка:'; en = 'An error occurred when writing decrypted data:'; pl = 'An error occurred when writing decrypted data:';de = 'An error occurred when writing decrypted data:';ro = 'An error occurred when writing decrypted data:';tr = 'An error occurred when writing decrypted data:'; es_ES = 'An error occurred when writing decrypted data:'")
			+ Chars.LF + Result.ErrorDescription);
		ExecuteAtSideAfterLoop(Error, Context);
		Return;
	EndIf;
	
	ExecuteAtSideLoopStart(Context);
	
EndProcedure

// Continues the ExecuteAtSide procedure.
Procedure ExecuteAtSideAfterLoop(Error, Context)
	
	Result = New Structure;
	If Error <> Undefined Then
		Result.Insert("Error", Error);
	EndIf;
	
	If Context.OperationStarted Then
		Result.Insert("OperationStarted");
		
		If Not Result.Property("Error") AND Context.IndexOf > 0 Then
			Result.Insert("HasProcessedDataItems");
		EndIf;
	EndIf;
	
	ExecuteNotifyProcessing(Context.Notification, Result);
	
EndProcedure


// For internal use only.
Function CurrentDataItemProperties(ExecutionParameters, SignatureProperties = Undefined) Export
	
	If ExecutionParameters.DataDetails.Property("Data")
	 Or Not ExecutionParameters.DataDetails.Property("CurrentDataSetItem") Then
		
		DataItemPresentation = ExecutionParameters.CurrentPresentationsList[0].Value;
	Else
		DataItemPresentation = ExecutionParameters.CurrentPresentationsList[
			ExecutionParameters.DataDetails.DataSet.Find(
				ExecutionParameters.DataDetails.CurrentDataSetItem)].Value;
	EndIf;
	
	If TypeOf(DataItemPresentation) = Type("NotifyDescription") Then
		DataItemPresentation = ExecutionParameters.FullDataPresentation;
	EndIf;
	
	If SignatureProperties = Undefined Then
		SignatureProperties = New Structure;
		SignatureProperties.Insert("Certificate",  ExecutionParameters.CertificateAddress);
		SignatureProperties.Insert("SignatureDate", '00010101');
	EndIf;
	
	DataItemProperties = New Structure;
	
	DataItemProperties.Insert("SignatureProperties",     SignatureProperties);
	DataItemProperties.Insert("DataPresentation", DataItemPresentation);
	
	Return DataItemProperties;
	
EndFunction

// For internal use only.
Procedure GetDataFromDataDetails(Notification, Form, DataDetails, DataSource, ForClientSide) Export
	
	Context = New Structure;
	Context.Insert("Form", Form);
	Context.Insert("Notification", Notification);
	Context.Insert("ForClientSide", ForClientSide);
	
	If TypeOf(DataSource) = Type("NotifyDescription") Then
		ExecutionParameters = New Structure;
		ExecutionParameters.Insert("DataDetails", DataDetails);
		ExecutionParameters.Insert("Notification",  New NotifyDescription(
			"GetDataFromDataDetailsFollowUp", ThisObject, Context));
		
		Try
			ExecuteNotifyProcessing(DataSource, ExecutionParameters);
		Except
			ErrorInformation = ErrorInfo();
			Result = New Structure("ErrorDescription", BriefErrorDescription(ErrorInformation));
			GetDataFromDataDetailsFollowUp(Result, Context);
		EndTry;
	Else
		GetDataFromDataDetailsFollowUp(New Structure("Data", DataSource), Context);
	EndIf;
	
EndProcedure

// Continue the GetDataFromDataDetails procedure.
Procedure GetDataFromDataDetailsFollowUp(Result, Context) Export
	
	IsXMLDSig = (TypeOf(Result) = Type("Structure")
	            AND Result.Property("Data")
	            AND TypeOf(Result.Data) = Type("Structure")
	            AND Result.Data.Property("XMLDSigParameters"));
	
	If TypeOf(Result) <> Type("Structure")
	 Or Not Result.Property("Data")
	 Or TypeOf(Result.Data) <> Type("BinaryData")
	   AND TypeOf(Result.Data) <> Type("String")
	   AND (Not IsXMLDSig) Then
		
		If TypeOf(Result) <> Type("Structure") Or Not Result.Property("ErrorDescription") Then
			Error = New Structure("ErrorDescription", NStr("ru = 'Некорректный тип данных.'; en = 'Incorrect data type.'; pl = 'Incorrect data type.';de = 'Incorrect data type.';ro = 'Incorrect data type.';tr = 'Incorrect data type.'; es_ES = 'Incorrect data type.'"));
		Else
			Error = New Structure("ErrorDescription", Result.ErrorDescription);
		EndIf;
		ExecuteNotifyProcessing(Context.Notification, Error);
		Return;
	EndIf;
	
	Data = Result.Data;
	
	If Context.ForClientSide Then
		// The client side requires binary data or file path.
		
		If TypeOf(Data) = Type("BinaryData")
			Or IsXMLDSig Then
			ExecuteNotifyProcessing(Context.Notification, Data);
			
		ElsIf IsTempStorageURL(Data) Then
			Try
				CurrentResult = GetFromTempStorage(Data);
			Except
				ErrorInformation = ErrorInfo();
				CurrentResult = New Structure("ErrorDescription",
					BriefErrorDescription(ErrorInformation));
			EndTry;
			ExecuteNotifyProcessing(Context.Notification, CurrentResult);
			
		Else // A file path
			ExecuteNotifyProcessing(Context.Notification, Data);
		EndIf;
	Else
		// The server side requires a binary data address in the temporary storage.
		
		If TypeOf(Data) = Type("BinaryData")
			Or IsXMLDSig Then
			ExecuteNotifyProcessing(Context.Notification,
				PutToTempStorage(Data, Context.Form.UUID));
		
		ElsIf IsTempStorageURL(Data) Then
			ExecuteNotifyProcessing(Context.Notification, Data);
			
		Else // A file path
			Try
				ImportParameters = FileSystemClient.FileImportParameters();
				ImportParameters.FormID = Context.Form.UUID;
				ImportParameters.Interactively = False;
				FileSystemClient.ImportFile(New NotifyDescription(
					"GetDataFromDataDetailsCompletion", ThisObject, Context,
					"GetDataFromDataDescriptionCompletionOnError", ThisObject),
					ImportParameters, Data); 
			Except
				ErrorInformation = ErrorInfo();
				CurrentResult = New Structure("ErrorDescription",
					BriefErrorDescription(ErrorInformation));
				ExecuteNotifyProcessing(Context.Notification, CurrentResult);
			EndTry;
		EndIf;
	EndIf;
	
EndProcedure

// Continue the GetDataFromDataDetails procedure.
Procedure GetDataFromDataDescriptionCompletionOnError(ErrorInformation, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	Result = New Structure("ErrorDescription", BriefErrorDescription(ErrorInformation));
	ExecuteNotifyProcessing(Context.Notification, Result);
	
EndProcedure

// Continue the GetDataFromDataDetails procedure.
Procedure GetDataFromDataDetailsCompletion(FilesThatWerePut, Context) Export
	
	If FilesThatWerePut = Undefined Or FilesThatWerePut.Count() = 0 Then
		Result = New Structure("ErrorDescription",
			NStr("ru = 'Передача данных отменена пользователем.'; en = 'User canceled data transfer.'; pl = 'User canceled data transfer.';de = 'User canceled data transfer.';ro = 'User canceled data transfer.';tr = 'User canceled data transfer.'; es_ES = 'User canceled data transfer.'"));
	Else
		Result = FilesThatWerePut[0].Location;
	EndIf;
	
	ExecuteNotifyProcessing(Context.Notification, Result);
	
EndProcedure

// For internal use only.
Procedure ExtendStoringOperationContext(DataDetails) Export
	
	PassParametersForm().ExtendStoringOperationContext(DataDetails.OperationContext);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// XMLDSig operations

// Starts signing an XML message.
//
// Parameters:
//  NotificationsOnComplete - NotifyDescription - a procedure that will be called after signing the message.
//  SOAPEnvelope - String - a template of the message being signed.
//  CryptoCertificate - CryptoCertificate.
//  CryptoManager - CryptoManager.
//
Procedure StartSigning(NotificationsOnComplete, SOAPEnvelope, SigningAlgorithmData, CryptoCertificate, CryptoManager)
	
	Context = New Structure;
	Context.Insert("Mode",                   "SigningMode");
	Context.Insert("NotificationsOnComplete", NotificationsOnComplete);
	Context.Insert("SetComponent", True);
	
	Context.Insert("SOAPEnvelope", SOAPEnvelope);
	
	Context.Insert("SigningAlgorithmData",    SigningAlgorithmData);
	Context.Insert("CryptoCertificate",       CryptoCertificate);
	Context.Insert("Base64CryptoCertificate", Undefined);
	Context.Insert("CryptoManager",         CryptoManager);
	
	Context.Insert("CryptoProviderType", Undefined);
	Context.Insert("CryptoProviderName", Undefined);
	Context.Insert("CryptoProviderPath", Undefined);
	
	CryptoCertificate.BeginUnloading(
		New NotifyDescription("StartSigning_AfterExportCryptoCertificate", ThisObject, Context));
	
EndProcedure

// Starts signing an XML message.
//
// Parameters:
//  NotificationsOnComplete - NotifyDescription - a procedure that will be called after signing the message.
//  SOAPEnvelope - String - a template of the message being signed.
//  SigningAlgorithmData - a structure with the following properties:
//  CryptoManager - CryptoManager.
//
Procedure BeginVerifyingSignature(NotificationsOnComplete, SOAPEnvelope, SigningAlgorithmData, CryptoManager)
	
	Base64CryptoCertificate = DigitalSignatureInternalClientServer.FindInXML(SOAPEnvelope, "wsse:BinarySecurityToken");
	BinaryData = Base64Value(Base64CryptoCertificate);
	
	Context = New Structure;
	Context.Insert("Mode",                   "CheckMode");
	Context.Insert("NotificationsOnComplete", NotificationsOnComplete);
	Context.Insert("SetComponent", True);
	
	Context.Insert("SOAPEnvelope", SOAPEnvelope);
	
	Context.Insert("SigningAlgorithmData", SigningAlgorithmData);
	Context.Insert("CryptoCertificate",    New CryptoCertificate);
	Context.Insert("Base64CryptoCertificate", Base64CryptoCertificate);
	Context.Insert("CryptoManager",      CryptoManager);
	
	Context.Insert("CryptoProviderType",  Undefined);
	Context.Insert("CryptoProviderName",  Undefined);
	Context.Insert("CryptoProviderPath", Undefined);
	
	Context.CryptoCertificate.BeginInitialization(New NotifyDescription(
			"StartSignatureCheckAfterInitializeCertificate", ThisObject, Context),
		BinaryData);
	
EndProcedure

Procedure StartSignatureCheckAfterInitializeCertificate(CryptoCertificate, Context) Export
	
	Context.CryptoCertificate = CryptoCertificate;
	
	AttachmentParameters = CommonClient.AddInAttachmentParameters();
	AttachmentParameters.NoteText = NStr("ru = 'Для подписания XML необходима установка компоненты XMLDSig'; en = 'To sign XML, install the XMLDSig component'; pl = 'To sign XML, install the XMLDSig component';de = 'To sign XML, install the XMLDSig component';ro = 'To sign XML, install the XMLDSig component';tr = 'To sign XML, install the XMLDSig component'; es_ES = 'To sign XML, install the XMLDSig component'");
	
	CommonClient.AttachAddInFromTemplate(
		New NotifyDescription("AfterAttachComponent", ThisObject, Context),
		"XMLDSignAddIn",
		"Catalog.DigitalSignatureAndEncryptionKeysCertificates.Template.XMLDSIGComponent",
		AttachmentParameters);
	
EndProcedure

Procedure AfterAttachComponent(Result, Context) Export
	
	If Result.Attached Then
		Context.Insert("ComponentObject", Result.AttachableModule);
		Context.CryptoManager.BeginGettingCryptoModuleInformation(
			New NotifyDescription("AfterGetCryptoModuleInformation", ThisObject, Context));
	Else
		
		If IsBlankString(Result.ErrorDescription) Then 
			
			// A user canceled the installation.
			
			CompleteOperationWithError(
				Context,
				NStr("ru = 'Операция невозможна. Требуется установка компоненты для HTTP-запросов.'; en = 'This operation is not possible. Component for making HTTP requests is required.'; pl = 'This operation is not possible. Component for making HTTP requests is required.';de = 'This operation is not possible. Component for making HTTP requests is required.';ro = 'This operation is not possible. Component for making HTTP requests is required.';tr = 'This operation is not possible. Component for making HTTP requests is required.'; es_ES = 'This operation is not possible. Component for making HTTP requests is required.'"));
				
		Else 
			
			// Installation failed. The error description is in Result.ErrorDescription.
			
			CompleteOperationWithError(
				Context,
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Операция невозможна. %1'; en = 'Operation is not allowed. %1'; pl = 'Operation is not allowed. %1';de = 'Operation is not allowed. %1';ro = 'Operation is not allowed. %1';tr = 'Operation is not allowed. %1'; es_ES = 'Operation is not allowed. %1'"), Result.ErrorDescription));
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure AfterGetCryptoModuleInformation(CryptoModuleInformation, Context) Export
	
	CryptoProviderName = CryptoModuleInformation.Name;
	ApplicationDetails = DigitalSignatureInternalClientServer.ApplicationDetailsByCryptoProviderName(
		CryptoProviderName, DigitalSignatureClient.CommonSettings().ApplicationsDetailsCollection);
	
	If ApplicationDetails = Undefined Then
		CompleteOperationWithError(Context,
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось определить тип криптопровайдера %1'; en = 'Cannot define a type of cryptographic service provider %1'; pl = 'Cannot define a type of cryptographic service provider %1';de = 'Cannot define a type of cryptographic service provider %1';ro = 'Cannot define a type of cryptographic service provider %1';tr = 'Cannot define a type of cryptographic service provider %1'; es_ES = 'Cannot define a type of cryptographic service provider %1'"),
				CryptoModuleInformation.Name));
		Return;
	EndIf;
	
	Context.CryptoProviderType = ApplicationDetails.ApplicationType;
	Context.CryptoProviderName = CryptoProviderName;
	
	If CommonClient.IsWindowsClient() Then
		ApplicationPath = "";
	Else
		PersonalSettings = DigitalSignatureClient.PersonalSettings();
		ApplicationPath = PersonalSettings.PathsToDigitalSignatureAndEncryptionApplications.Get(
			ApplicationDetails.Ref);
	EndIf;
	Context.CryptoProviderPath = ApplicationPath;
	
	Context.ComponentObject.StartInstallationPathToCryptoServiceProvider(
		New NotifyDescription("AfterSetComponentCryptoproviderPath", ThisObject, Context),
		Context.CryptoProviderPath);
		
EndProcedure

Procedure AfterSetComponentCryptoproviderPath(Context) Export
	
	If CommonClient.IsWindowsClient() Then
		Context.ComponentObject.StartInstallationDisallowUserInterface(
			New NotifyDescription("AfterSetPropertyDisableUserInterface", ThisObject, Context),
			False);
	Else
		AfterSetPropertyDisableUserInterface(Context);
	EndIf;
	
EndProcedure

Procedure AfterSetPropertyDisableUserInterface(Context) Export
	
	If Context.Mode = "CheckMode" Then
		StartSignatureCheckSOAPMessage(Context);
		
	ElsIf Context.Mode = "SigningMode" Then
		StartSigningSOAPMessage(Context);
	Else
		CompleteOperationWithError(
			Context,
			NStr("ru = 'Не установлен режим работы компоненты XMLDSig.'; en = 'The XMLDSig component mode is not set.'; pl = 'The XMLDSig component mode is not set.';de = 'The XMLDSig component mode is not set.';ro = 'The XMLDSig component mode is not set.';tr = 'The XMLDSig component mode is not set.'; es_ES = 'The XMLDSig component mode is not set.'"));
	EndIf;
	
EndProcedure

Procedure StartSigning_AfterExportCryptoCertificate(CertificateBinaryData, Context) Export
	
	Base64CryptoCertificate = FormatBase64Row(Base64String(CertificateBinaryData));
	
	Context.SOAPEnvelope = StrReplace(
		Context.SOAPEnvelope,
		"%BinarySecurityToken%",
		Base64CryptoCertificate);
	
	Context.Base64CryptoCertificate = Base64CryptoCertificate;
	
	AttachmentParameters = CommonClient.AddInAttachmentParameters();
	AttachmentParameters.NoteText = NStr("ru = 'Для подписания XML необходима установка компоненты XMLDSig'; en = 'To sign XML, install the XMLDSig component'; pl = 'To sign XML, install the XMLDSig component';de = 'To sign XML, install the XMLDSig component';ro = 'To sign XML, install the XMLDSig component';tr = 'To sign XML, install the XMLDSig component'; es_ES = 'To sign XML, install the XMLDSig component'");
	
	CommonClient.AttachAddInFromTemplate(
		New NotifyDescription("AfterAttachComponent", ThisObject, Context),
		"XMLDSignAddIn",
		"Catalog.DigitalSignatureAndEncryptionKeysCertificates.Template.XMLDSIGComponent",
		AttachmentParameters);
	
EndProcedure

Procedure StartSigningSOAPMessage(Context)
	
	Try
		NotifyDescription = New NotifyDescription(
			"Signing_AfterExecuteGetSignOIDFromCert", ThisObject, Context,
			"Signing_AfterExecureGetSignOIDFromCert_Error", ThisObject);
		
		Context.ComponentObject.StartCallGetSignOIDFromCert(
			NotifyDescription,
			Context.Base64CryptoCertificate);
	Except
		CompleteOperationWithError(
			Context,
			NStr("ru = 'Ошибка вызова метода GetSignOIDFromCert компоненты XMLDSig.'; en = 'An error occurred when calling method GetSignOIDFromCert of component XMLDSig.'; pl = 'An error occurred when calling method GetSignOIDFromCert of component XMLDSig.';de = 'An error occurred when calling method GetSignOIDFromCert of component XMLDSig.';ro = 'An error occurred when calling method GetSignOIDFromCert of component XMLDSig.';tr = 'An error occurred when calling method GetSignOIDFromCert of component XMLDSig.'; es_ES = 'An error occurred when calling method GetSignOIDFromCert of component XMLDSig.'") + Chars.LF + DetailErrorDescription(ErrorInfo()));
	EndTry;
	
EndProcedure

Procedure Signing_AfterExecureGetSignOIDFromCert_Error(ErrorInformation, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	CompleteOperationWithError(
		Context,
		NStr("ru = 'Ошибка вызова метода GetSignOIDFromCert компоненты XMLDSig.'; en = 'An error occurred when calling method GetSignOIDFromCert of component XMLDSig.'; pl = 'An error occurred when calling method GetSignOIDFromCert of component XMLDSig.';de = 'An error occurred when calling method GetSignOIDFromCert of component XMLDSig.';ro = 'An error occurred when calling method GetSignOIDFromCert of component XMLDSig.';tr = 'An error occurred when calling method GetSignOIDFromCert of component XMLDSig.'; es_ES = 'An error occurred when calling method GetSignOIDFromCert of component XMLDSig.'") + Chars.LF + DetailErrorDescription(ErrorInformation));
	
EndProcedure

Procedure Signing_AfterExecuteGetSignOIDFromCert(SignatureAlgorithmOID, Parameters, Context) Export
	
	If SignatureAlgorithmOID = Undefined Then
		StartGetErrorText(NStr("ru = 'При выполнении метода GetSignOIDFromCert произошла ошибка:'; en = 'An error occurred while executing GetSignOIDFromCert method:'; pl = 'An error occurred while executing GetSignOIDFromCert method:';de = 'An error occurred while executing GetSignOIDFromCert method:';ro = 'An error occurred while executing GetSignOIDFromCert method:';tr = 'An error occurred while executing GetSignOIDFromCert method:'; es_ES = 'An error occurred while executing GetSignOIDFromCert method:'"), Context);
		Return;
	EndIf;
	
	SignAlgorithmsOID     = StrSplit(Context.SigningAlgorithmData.SignatureAlgorithmOID, Chars.LF);
	HashAlgorithmsOID = StrSplit(Context.SigningAlgorithmData.HashingAlgorithmOID, Chars.LF);
	SignAlgorithms         = StrSplit(Context.SigningAlgorithmData.SignAlgorithm,         Chars.LF);
	HashAlgorithms     = StrSplit(Context.SigningAlgorithmData.HashAlgorithm,     Chars.LF);
	
	Context.SigningAlgorithmData.Insert("SelectedSignatureAlgorithmOID",     Undefined);
	Context.SigningAlgorithmData.Insert("SelectedHashAlgorithmOID", Undefined);
	Context.SigningAlgorithmData.Insert("SelectedSignatureAlgorithm",          Undefined);
	Context.SigningAlgorithmData.Insert("SelectedHashAlgorithm",      Undefined);
	For Index = 0 To SignAlgorithmsOID.Count() - 1 Do
		
		If SignatureAlgorithmOID = SignAlgorithmsOID[Index] Then
			
			Context.SigningAlgorithmData.SelectedSignatureAlgorithmOID     = SignAlgorithmsOID[Index];
			Context.SigningAlgorithmData.SelectedHashAlgorithmOID = HashAlgorithmsOID[Index];
			Context.SigningAlgorithmData.SelectedSignatureAlgorithm          = SignAlgorithms[Index];
			Context.SigningAlgorithmData.SelectedHashAlgorithm      = HashAlgorithms[Index];
			
			Break;
			
		EndIf;
		
	EndDo;
	
	If Not ValueIsFilled(Context.SigningAlgorithmData.SelectedSignatureAlgorithmOID) Then
		
		CompleteOperationWithError(
			Context,
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Алгоритм подписи сертификата криптографии отличается от алгоритма %1.'; en = 'Certificate signature algorithm of cryptography differs from algorithm %1.'; pl = 'Certificate signature algorithm of cryptography differs from algorithm %1.';de = 'Certificate signature algorithm of cryptography differs from algorithm %1.';ro = 'Certificate signature algorithm of cryptography differs from algorithm %1.';tr = 'Certificate signature algorithm of cryptography differs from algorithm %1.'; es_ES = 'Certificate signature algorithm of cryptography differs from algorithm %1.'"),
				Context.SigningAlgorithmData.SIgnatureAlgorithmName));
		
	Else
		
		Context.SOAPEnvelope = StrReplace(Context.SOAPEnvelope, "%SignatureMethod%", Context.SigningAlgorithmData.SelectedSignatureAlgorithm);
		Context.SOAPEnvelope = StrReplace(Context.SOAPEnvelope, "%DigestMethod%",    Context.SigningAlgorithmData.SelectedHashAlgorithm);
		
		Try
			
			NotifyDescription = New NotifyDescription(
				"Signing_AfterExecuteC14N_TagToSign", ThisObject, Context,
				"Signing_AfterExecureC14N_TagToSign_Error", ThisObject);
			
			Context.ComponentObject.StartCallC14N(
				NotifyDescription,
				Context.SOAPEnvelope,
				Context.SigningAlgorithmData.XPathTagToSign);
			
		Except
			
			CompleteOperationWithError(
				Context,
				NStr("ru = 'Ошибка вызова метода C14N компоненты XMLDSig.'; en = 'An error occurred when calling method C14N of component XMLDSig.'; pl = 'An error occurred when calling method C14N of component XMLDSig.';de = 'An error occurred when calling method C14N of component XMLDSig.';ro = 'An error occurred when calling method C14N of component XMLDSig.';tr = 'An error occurred when calling method C14N of component XMLDSig.'; es_ES = 'An error occurred when calling method C14N of component XMLDSig.'") + Chars.LF + DetailErrorDescription(ErrorInfo()));
			
		EndTry;
		
	EndIf;
	
EndProcedure

Procedure Signing_AfterExecureC14N_TagToSign_Error(ErrorInformation, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	CompleteOperationWithError(
		Context,
		NStr("ru = 'Ошибка вызова метода C14N компоненты XMLDSig.'; en = 'An error occurred when calling method C14N of component XMLDSig.'; pl = 'An error occurred when calling method C14N of component XMLDSig.';de = 'An error occurred when calling method C14N of component XMLDSig.';ro = 'An error occurred when calling method C14N of component XMLDSig.';tr = 'An error occurred when calling method C14N of component XMLDSig.'; es_ES = 'An error occurred when calling method C14N of component XMLDSig.'") + Chars.LF + DetailErrorDescription(ErrorInformation));
	
EndProcedure

Procedure Signing_AfterExecuteC14N_TagToSign(CanonicalizedXMLText, Parameters, Context) Export
	
	If CanonicalizedXMLText = Undefined Then
		StartGetErrorText(NStr("ru = 'При выполнении метода C14N произошла ошибка:'; en = 'An error occurred while executing C14N method:'; pl = 'An error occurred while executing C14N method:';de = 'An error occurred while executing C14N method:';ro = 'An error occurred while executing C14N method:';tr = 'An error occurred while executing C14N method:'; es_ES = 'An error occurred while executing C14N method:'"), Context);
		Return;
	EndIf;
	
	Try
		
		NotifyDescription = New NotifyDescription(
			"Signing_AfterExecuteHash_TagToSign", ThisObject, Context,
			"Signing_AfterExecureHash_TagToSign_Error", ThisObject);
		
		Context.ComponentObject.StartCallHash(
			NotifyDescription,
			CanonicalizedXMLText,
			Context.SigningAlgorithmData.SelectedHashAlgorithmOID,
			Context.CryptoProviderType);
		
	Except
		
		CompleteOperationWithError(
			Context,
			NStr("ru = 'Ошибка вызова метода Hash компоненты XMLDSig.'; en = 'An error occurred when calling method Hash of component XMLDSig.'; pl = 'An error occurred when calling method Hash of component XMLDSig.';de = 'An error occurred when calling method Hash of component XMLDSig.';ro = 'An error occurred when calling method Hash of component XMLDSig.';tr = 'An error occurred when calling method Hash of component XMLDSig.'; es_ES = 'An error occurred when calling method Hash of component XMLDSig.'") + Chars.LF + DetailErrorDescription(ErrorInfo()));
		
	EndTry;
	
EndProcedure

Procedure Signing_AfterExecureHash_TagToSign_Error(ErrorInformation, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	CompleteOperationWithError(
		Context,
		NStr("ru = 'Ошибка вызова метода Hash компоненты XMLDSig.'; en = 'An error occurred when calling method Hash of component XMLDSig.'; pl = 'An error occurred when calling method Hash of component XMLDSig.';de = 'An error occurred when calling method Hash of component XMLDSig.';ro = 'An error occurred when calling method Hash of component XMLDSig.';tr = 'An error occurred when calling method Hash of component XMLDSig.'; es_ES = 'An error occurred when calling method Hash of component XMLDSig.'") + Chars.LF + DetailErrorDescription(ErrorInformation));
	
EndProcedure

Procedure Signing_AfterExecuteHash_TagToSign(DigestValue, Parameters, Context) Export
	
	If DigestValue = Undefined Then
		StartGetErrorText(NStr("ru = 'При выполнении метода Hash произошла ошибка:'; en = 'An error occurred while executing Hash method:'; pl = 'An error occurred while executing Hash method:';de = 'An error occurred while executing Hash method:';ro = 'An error occurred while executing Hash method:';tr = 'An error occurred while executing Hash method:'; es_ES = 'An error occurred while executing Hash method:'"), Context);
		Return;
	EndIf;
	
	Context.SOAPEnvelope = StrReplace(Context.SOAPEnvelope, "%DigestValue%", DigestValue);
	
	Try
		
		NotifyDescription = New NotifyDescription(
			"Signing_AfterExecuteC14N_SignedInfo", ThisObject, Context,
			"Signing_AfterExecureC14N_SignedInfo_Error", ThisObject);
		
		Context.ComponentObject.StartCallC14N(
			NotifyDescription,
			Context.SOAPEnvelope,
			Context.SigningAlgorithmData.XPathSignedInfo);
		
	Except
		
		CompleteOperationWithError(
			Context,
			NStr("ru = 'Ошибка вызова метода C14N компоненты XMLDSig.'; en = 'An error occurred when calling method C14N of component XMLDSig.'; pl = 'An error occurred when calling method C14N of component XMLDSig.';de = 'An error occurred when calling method C14N of component XMLDSig.';ro = 'An error occurred when calling method C14N of component XMLDSig.';tr = 'An error occurred when calling method C14N of component XMLDSig.'; es_ES = 'An error occurred when calling method C14N of component XMLDSig.'") + Chars.LF + DetailErrorDescription(ErrorInfo()));
		
	EndTry;
	
EndProcedure

Procedure Signing_AfterExecureC14N_SignedInfo_Error(ErrorInformation, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	CompleteOperationWithError(
		Context,
		NStr("ru = 'Ошибка вызова метода C14N компоненты XMLDSig.'; en = 'An error occurred when calling method C14N of component XMLDSig.'; pl = 'An error occurred when calling method C14N of component XMLDSig.';de = 'An error occurred when calling method C14N of component XMLDSig.';ro = 'An error occurred when calling method C14N of component XMLDSig.';tr = 'An error occurred when calling method C14N of component XMLDSig.'; es_ES = 'An error occurred when calling method C14N of component XMLDSig.'") + Chars.LF + DetailErrorDescription(ErrorInformation));
	
EndProcedure

Procedure Signing_AfterExecuteC14N_SignedInfo(CanonicalizedXMLTextSignedInfo, Parameters, Context) Export
	
	If CanonicalizedXMLTextSignedInfo = Undefined Then
		StartGetErrorText(NStr("ru = 'При выполнении метода C14N произошла ошибка:'; en = 'An error occurred while executing C14N method:'; pl = 'An error occurred while executing C14N method:';de = 'An error occurred while executing C14N method:';ro = 'An error occurred while executing C14N method:';tr = 'An error occurred while executing C14N method:'; es_ES = 'An error occurred while executing C14N method:'"), Context);
		Return;
	EndIf;
	
	Try
		
		Context.ComponentObject.StartCallSign(
			New NotifyDescription("Signing_AfterExecuteSign", ThisObject, Context),
			CanonicalizedXMLTextSignedInfo,
			Context.Base64CryptoCertificate,
			Context.CryptoManager.PrivateKeyAccessPassword);
		
	Except
		
		CompleteOperationWithError(
			Context,
			NStr("ru = 'Ошибка вызова метода Sign компоненты XMLDSig.'; en = 'An error occurred when calling method Sign of component XMLDSig.'; pl = 'An error occurred when calling method Sign of component XMLDSig.';de = 'An error occurred when calling method Sign of component XMLDSig.';ro = 'An error occurred when calling method Sign of component XMLDSig.';tr = 'An error occurred when calling method Sign of component XMLDSig.'; es_ES = 'An error occurred when calling method Sign of component XMLDSig.'") + Chars.LF + DetailErrorDescription(ErrorInfo()));
		
	EndTry;
	
EndProcedure

Procedure Signing_AfterExecuteSign(SignatureValue, Parameters, Context) Export
	
	If SignatureValue = Undefined Then
		StartGetErrorText(NStr("ru = 'При выполнении метода Sign произошла ошибка:'; en = 'An error occurred while executing Sign method:'; pl = 'An error occurred while executing Sign method:';de = 'An error occurred while executing Sign method:';ro = 'An error occurred while executing Sign method:';tr = 'An error occurred while executing Sign method:'; es_ES = 'An error occurred while executing Sign method:'"), Context);
		Return;
	EndIf;
	
	SOAPEnvelope = StrReplace(Context.SOAPEnvelope, "%SignatureValue%", SignatureValue);
	ExecuteNotifyProcessing(Context.NotificationsOnComplete.Success, SOAPEnvelope);
	
EndProcedure

Procedure StartSignatureCheckSOAPMessage(Context)
	
	Try
		NotifyDescription = New NotifyDescription(
			"Check_AfterExecuteGetSignOIDFromCert", ThisObject, Context,
			"Check_AfterExecureGetSignOIDFromCert_Error", ThisObject);
		
		Context.ComponentObject.StartCallGetSignOIDFromCert(
			NotifyDescription,
			Context.Base64CryptoCertificate);
	Except
		CompleteOperationWithError(Context,
			NStr("ru = 'Ошибка вызова метода GetSignOIDFromCert компоненты XMLDSig.'; en = 'An error occurred when calling method GetSignOIDFromCert of component XMLDSig.'; pl = 'An error occurred when calling method GetSignOIDFromCert of component XMLDSig.';de = 'An error occurred when calling method GetSignOIDFromCert of component XMLDSig.';ro = 'An error occurred when calling method GetSignOIDFromCert of component XMLDSig.';tr = 'An error occurred when calling method GetSignOIDFromCert of component XMLDSig.'; es_ES = 'An error occurred when calling method GetSignOIDFromCert of component XMLDSig.'") + Chars.LF + DetailErrorDescription(ErrorInfo()));
	EndTry;
	
EndProcedure

Procedure Check_AfterExecureGetSignOIDFromCert_Error(ErrorInformation, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	CompleteOperationWithError(
		Context,
		NStr("ru = 'Ошибка вызова метода GetSignOIDFromCert компоненты XMLDSig.'; en = 'An error occurred when calling method GetSignOIDFromCert of component XMLDSig.'; pl = 'An error occurred when calling method GetSignOIDFromCert of component XMLDSig.';de = 'An error occurred when calling method GetSignOIDFromCert of component XMLDSig.';ro = 'An error occurred when calling method GetSignOIDFromCert of component XMLDSig.';tr = 'An error occurred when calling method GetSignOIDFromCert of component XMLDSig.'; es_ES = 'An error occurred when calling method GetSignOIDFromCert of component XMLDSig.'") + Chars.LF + DetailErrorDescription(ErrorInformation));
	
EndProcedure

Procedure Check_AfterExecuteGetSignOIDFromCert(SignatureAlgorithmOID, Parameters, Context) Export
	
	If SignatureAlgorithmOID = Undefined Then
		StartGetErrorText(NStr("ru = 'При выполнении метода GetSignOIDFromCert произошла ошибка:'; en = 'An error occurred while executing GetSignOIDFromCert method:'; pl = 'An error occurred while executing GetSignOIDFromCert method:';de = 'An error occurred while executing GetSignOIDFromCert method:';ro = 'An error occurred while executing GetSignOIDFromCert method:';tr = 'An error occurred while executing GetSignOIDFromCert method:'; es_ES = 'An error occurred while executing GetSignOIDFromCert method:'"), Context);
		Return;
	EndIf;
	
	SignAlgorithmsOID     = StrSplit(Context.SigningAlgorithmData.SignatureAlgorithmOID, Chars.LF);
	HashAlgorithmsOID = StrSplit(Context.SigningAlgorithmData.HashingAlgorithmOID, Chars.LF);
	
	Context.SigningAlgorithmData.Insert("SelectedSignatureAlgorithmOID",     Undefined);
	Context.SigningAlgorithmData.Insert("SelectedHashAlgorithmOID", Undefined);
	For Index = 0 To SignAlgorithmsOID.Count() - 1 Do
		If SignatureAlgorithmOID = SignAlgorithmsOID[Index] Then
			Context.SigningAlgorithmData.SelectedSignatureAlgorithmOID     = SignAlgorithmsOID[Index];
			Context.SigningAlgorithmData.SelectedHashAlgorithmOID = HashAlgorithmsOID[Index];
		EndIf;
	EndDo;
	
	If Not ValueIsFilled(Context.SigningAlgorithmData.SelectedSignatureAlgorithmOID) Then
		CompleteOperationWithError(
			Context,
			NStr("ru = 'Ошибка вызова метода Hash компоненты XMLDSig.'; en = 'An error occurred when calling method Hash of component XMLDSig.'; pl = 'An error occurred when calling method Hash of component XMLDSig.';de = 'An error occurred when calling method Hash of component XMLDSig.';ro = 'An error occurred when calling method Hash of component XMLDSig.';tr = 'An error occurred when calling method Hash of component XMLDSig.'; es_ES = 'An error occurred when calling method Hash of component XMLDSig.'") + Chars.LF + DetailErrorDescription(ErrorInfo()));
	Else
		
		Try
			
			NotifyDescription = New NotifyDescription(
				"Check_AfterExecuteC14N_SignedInfo", ThisObject, Context,
				"Check_AfterExecureC14N_SignedInfo_Error", ThisObject);
			
			Context.ComponentObject.StartCallC14N(
				NotifyDescription,
				Context.SOAPEnvelope,
				Context.SigningAlgorithmData.XPathSignedInfo);
			
		Except
			
			CompleteOperationWithError(
				Context,
				NStr("ru = 'Ошибка вызова метода C14N компоненты XMLDSig.'; en = 'An error occurred when calling method C14N of component XMLDSig.'; pl = 'An error occurred when calling method C14N of component XMLDSig.';de = 'An error occurred when calling method C14N of component XMLDSig.';ro = 'An error occurred when calling method C14N of component XMLDSig.';tr = 'An error occurred when calling method C14N of component XMLDSig.'; es_ES = 'An error occurred when calling method C14N of component XMLDSig.'") + Chars.LF + DetailErrorDescription(ErrorInfo()));
			
		EndTry;
		
	EndIf;
	
EndProcedure

Procedure Check_AfterExecureC14N_SignedInfo_Error(ErrorInformation, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	CompleteOperationWithError(
		Context,
		NStr("ru = 'Ошибка вызова метода C14N компоненты XMLDSig.'; en = 'An error occurred when calling method C14N of component XMLDSig.'; pl = 'An error occurred when calling method C14N of component XMLDSig.';de = 'An error occurred when calling method C14N of component XMLDSig.';ro = 'An error occurred when calling method C14N of component XMLDSig.';tr = 'An error occurred when calling method C14N of component XMLDSig.'; es_ES = 'An error occurred when calling method C14N of component XMLDSig.'") + Chars.LF + DetailErrorDescription(ErrorInformation));
	
EndProcedure

Procedure Check_AfterExecuteC14N_SignedInfo(CanonicalizedXMLTextSignedInfo, Parameters, Context) Export
	
	If CanonicalizedXMLTextSignedInfo = Undefined Then
		StartGetErrorText(NStr("ru = 'При выполнении метода C14N произошла ошибка:'; en = 'An error occurred while executing C14N method:'; pl = 'An error occurred while executing C14N method:';de = 'An error occurred while executing C14N method:';ro = 'An error occurred while executing C14N method:';tr = 'An error occurred while executing C14N method:'; es_ES = 'An error occurred while executing C14N method:'"), Context);
		Return;
	EndIf;
	
	SignatureValue               = DigitalSignatureInternalClientServer.FindInXML(Context.SOAPEnvelope, "SignatureValue");
	Base64CryptoCertificate = DigitalSignatureInternalClientServer.FindInXML(Context.SOAPEnvelope, "wsse:BinarySecurityToken");
	
	Try
		
		NotifyDescription = New NotifyDescription(
			"Check_AfterExecuteVerifySign", ThisObject, Context,
			"Check_AfterExecureVerifySign_Error", ThisObject);
		
		Context.ComponentObject.StartCallVerifySign(
			NotifyDescription,
			CanonicalizedXMLTextSignedInfo,
			SignatureValue,
			Base64CryptoCertificate,
			Context.CryptoProviderType);
		
	Except
		
		CompleteOperationWithError(
			Context,
			NStr("ru = 'Ошибка вызова метода VerifySign компоненты XMLDSig.'; en = 'An error occurred when calling method VerifySign of component XMLDSig.'; pl = 'An error occurred when calling method VerifySign of component XMLDSig.';de = 'An error occurred when calling method VerifySign of component XMLDSig.';ro = 'An error occurred when calling method VerifySign of component XMLDSig.';tr = 'An error occurred when calling method VerifySign of component XMLDSig.'; es_ES = 'An error occurred when calling method VerifySign of component XMLDSig.'") + Chars.LF + DetailErrorDescription(ErrorInfo()));
		
	EndTry;
	
EndProcedure

Procedure Check_AfterExecureVerifySign_Error(ErrorInformation, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	CompleteOperationWithError(
		Context,
		NStr("ru = 'Ошибка вызова метода VerifySign компоненты XMLDSig.'; en = 'An error occurred when calling method VerifySign of component XMLDSig.'; pl = 'An error occurred when calling method VerifySign of component XMLDSig.';de = 'An error occurred when calling method VerifySign of component XMLDSig.';ro = 'An error occurred when calling method VerifySign of component XMLDSig.';tr = 'An error occurred when calling method VerifySign of component XMLDSig.'; es_ES = 'An error occurred when calling method VerifySign of component XMLDSig.'") + Chars.LF + DetailErrorDescription(ErrorInformation));
	
EndProcedure

Procedure Check_AfterExecuteVerifySign(SignatureCorrect, Parameters, Context) Export
	
	If SignatureCorrect = Undefined Then
		StartGetErrorText(NStr("ru = 'При выполнении метода VerifySign произошла ошибка:'; en = 'An error occurred while executing VerifySign method:'; pl = 'An error occurred while executing VerifySign method:';de = 'An error occurred while executing VerifySign method:';ro = 'An error occurred while executing VerifySign method:';tr = 'An error occurred while executing VerifySign method:'; es_ES = 'An error occurred while executing VerifySign method:'"), Context);
		Return;
	EndIf;
	
	If Not SignatureCorrect Then
		
		CompleteOperationWithError(
			Context,
			NStr("ru = 'Подпись не верна (SignatureValue некорректно.'; en = 'Signature is invalid (SignatureValue incorrect.'; pl = 'Signature is invalid (SignatureValue incorrect.';de = 'Signature is invalid (SignatureValue incorrect.';ro = 'Signature is invalid (SignatureValue incorrect.';tr = 'Signature is invalid (SignatureValue incorrect.'; es_ES = 'Signature is invalid (SignatureValue incorrect.'"));
		
	Else
		
		Try
			
			NotifyDescription = New NotifyDescription(
				"Check_AfterExecuteC14N_TagToSign", ThisObject, Context,
				"Check_AfterExecureC14N_TagToSign_Error", ThisObject);
			
			Context.ComponentObject.StartCallC14N(
				NotifyDescription,
				Context.SOAPEnvelope,
				Context.SigningAlgorithmData.XPathTagToSign);
			
		Except
			
			CompleteOperationWithError(
				Context,
				NStr("ru = 'Ошибка вызова метода C14N компоненты XMLDSig.'; en = 'An error occurred when calling method C14N of component XMLDSig.'; pl = 'An error occurred when calling method C14N of component XMLDSig.';de = 'An error occurred when calling method C14N of component XMLDSig.';ro = 'An error occurred when calling method C14N of component XMLDSig.';tr = 'An error occurred when calling method C14N of component XMLDSig.'; es_ES = 'An error occurred when calling method C14N of component XMLDSig.'") + Chars.LF + DetailErrorDescription(ErrorInfo()));
			
		EndTry;
		
	EndIf;
	
EndProcedure

Procedure Check_AfterExecureC14N_TagToSign_Error(ErrorInformation, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	CompleteOperationWithError(
		Context,
		NStr("ru = 'Ошибка вызова метода C14N компоненты XMLDSig.'; en = 'An error occurred when calling method C14N of component XMLDSig.'; pl = 'An error occurred when calling method C14N of component XMLDSig.';de = 'An error occurred when calling method C14N of component XMLDSig.';ro = 'An error occurred when calling method C14N of component XMLDSig.';tr = 'An error occurred when calling method C14N of component XMLDSig.'; es_ES = 'An error occurred when calling method C14N of component XMLDSig.'") + Chars.LF + DetailErrorDescription(ErrorInformation));
	
EndProcedure

Procedure Check_AfterExecuteC14N_TagToSign(CanonicalizedXMLTextTagToSign, Parameters, Context) Export
	
	If CanonicalizedXMLTextTagToSign = Undefined Then
		StartGetErrorText(NStr("ru = 'При выполнении метода C14N произошла ошибка:'; en = 'An error occurred while executing C14N method:'; pl = 'An error occurred while executing C14N method:';de = 'An error occurred while executing C14N method:';ro = 'An error occurred while executing C14N method:';tr = 'An error occurred while executing C14N method:'; es_ES = 'An error occurred while executing C14N method:'"), Context);
		Return;
	EndIf;
	
	Try
		
		NotifyDescription = New NotifyDescription(
			"Check_AfterExecuteHash_TagToSign", ThisObject, Context,
			"Check_AfterExecureHash_TagToSign_Error", ThisObject);
		
		Context.ComponentObject.StartCallHash(
			NotifyDescription,
			CanonicalizedXMLTextTagToSign,
			Context.SigningAlgorithmData.SelectedHashAlgorithmOID,
			Context.CryptoProviderType);
		
	Except
		
		CompleteOperationWithError(
			Context,
			NStr("ru = 'Ошибка вызова метода Hash компоненты XMLDSig.'; en = 'An error occurred when calling method Hash of component XMLDSig.'; pl = 'An error occurred when calling method Hash of component XMLDSig.';de = 'An error occurred when calling method Hash of component XMLDSig.';ro = 'An error occurred when calling method Hash of component XMLDSig.';tr = 'An error occurred when calling method Hash of component XMLDSig.'; es_ES = 'An error occurred when calling method Hash of component XMLDSig.'") + Chars.LF + DetailErrorDescription(ErrorInfo()));
		
	EndTry;
	
EndProcedure

Procedure Check_AfterExecureHash_TagToSign_Error(ErrorInformation, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	CompleteOperationWithError(
		Context,
		NStr("ru = 'Ошибка вызова метода Hash компоненты XMLDSig.'; en = 'An error occurred when calling method Hash of component XMLDSig.'; pl = 'An error occurred when calling method Hash of component XMLDSig.';de = 'An error occurred when calling method Hash of component XMLDSig.';ro = 'An error occurred when calling method Hash of component XMLDSig.';tr = 'An error occurred when calling method Hash of component XMLDSig.'; es_ES = 'An error occurred when calling method Hash of component XMLDSig.'") + Chars.LF + DetailErrorDescription(ErrorInformation));
	
EndProcedure

Procedure Check_AfterExecuteHash_TagToSign(HashValue, Parameters, Context) Export
	
	If HashValue = Undefined Then
		StartGetErrorText(NStr("ru = 'При выполнении метода Hash произошла ошибка:'; en = 'An error occurred while executing Hash method:'; pl = 'An error occurred while executing Hash method:';de = 'An error occurred while executing Hash method:';ro = 'An error occurred while executing Hash method:';tr = 'An error occurred while executing Hash method:'; es_ES = 'An error occurred while executing Hash method:'"), Context);
		Return;
	EndIf;
	
	DigestValue = DigitalSignatureInternalClientServer.FindInXML(Context.SOAPEnvelope, "DigestValue");
	
	SignatureCorrect = (DigestValue = HashValue);
	
	If Not SignatureCorrect Then
		
		CompleteOperationWithError(
			Context,
			NStr("ru = 'Подпись не верна (SignatureValue корректно, отличается DigestValue).'; en = 'Signature is invalid (SignatureValue correct, DigestValue different).'; pl = 'Signature is invalid (SignatureValue correct, DigestValue different).';de = 'Signature is invalid (SignatureValue correct, DigestValue different).';ro = 'Signature is invalid (SignatureValue correct, DigestValue different).';tr = 'Signature is invalid (SignatureValue correct, DigestValue different).'; es_ES = 'Signature is invalid (SignatureValue correct, DigestValue different).'"));
		
	Else
		
		BinaryData = Base64Value(Context.Base64CryptoCertificate);
		
		DigitalSignatureClient.SigningDate(
			New NotifyDescription("Check_AfterExecuteHash_TagToSignAfterGetSigningDate", ThisObject, Context), BinaryData);
		
	EndIf;
	
EndProcedure

Procedure Check_AfterExecuteHash_TagToSignAfterGetSigningDate(SigningDate, Context) Export
	
	If Not ValueIsFilled(SigningDate) Then
		SigningDate = Undefined;
	EndIf;
	
	ReturnValue = New Structure;
	ReturnValue.Insert("Certificate", Context.CryptoCertificate);
	ReturnValue.Insert("SigningDate", SigningDate);
	
	ExecuteNotifyProcessing(Context.NotificationsOnComplete.Success, ReturnValue);
	
EndProcedure


Procedure StartGetErrorText(StartErrorTextDetails, Context)
	
	Try
		
		Context.Insert("StartErrorTextDetails", StartErrorTextDetails);
		
		NotifyDescription = New NotifyDescription(
			"AfterExecuteGetLastError", ThisObject, Context,
			"AfterExecuteGetLastError_Error", ThisObject);
		
		Context.ComponentObject.StartCallGetLastError(NotifyDescription);
		
	Except
		
		CompleteOperationWithError(
			Context,
			NStr("ru = 'Ошибка вызова метода GetLastError компоненты XMLDSig.'; en = 'An error occurred when calling method GetLastError of component XMLDSig.'; pl = 'An error occurred when calling method GetLastError of component XMLDSig.';de = 'An error occurred when calling method GetLastError of component XMLDSig.';ro = 'An error occurred when calling method GetLastError of component XMLDSig.';tr = 'An error occurred when calling method GetLastError of component XMLDSig.'; es_ES = 'An error occurred when calling method GetLastError of component XMLDSig.'") + Chars.LF + DetailErrorDescription(ErrorInfo()));
		
	EndTry;
	
EndProcedure

Procedure AfterExecuteGetLastError_Error(ErrorInformation, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	CompleteOperationWithError(
		Context,
		NStr("ru = 'Ошибка вызова метода GetLastError компоненты XMLDSig.'; en = 'An error occurred when calling method GetLastError of component XMLDSig.'; pl = 'An error occurred when calling method GetLastError of component XMLDSig.';de = 'An error occurred when calling method GetLastError of component XMLDSig.';ro = 'An error occurred when calling method GetLastError of component XMLDSig.';tr = 'An error occurred when calling method GetLastError of component XMLDSig.'; es_ES = 'An error occurred when calling method GetLastError of component XMLDSig.'") + Chars.LF + DetailErrorDescription(ErrorInformation));
	
EndProcedure

Procedure AfterExecuteGetLastError(ErrorText, Parameters, Context) Export
	
	CompleteOperationWithError(
		Context,
		Context.StartErrorTextDetails + Chars.LF + ErrorText);
	
EndProcedure

// Formats row in the base64 format, deleting newline and carriage return characters.
//
// Parameters:
//  Base64Row - String - a row to be transformed.
// 
// Returns:
//   String - a string, from which a new line character and a carriage return character are deleted.
//
Function FormatBase64Row(Base64Row)
	
	Value = StrReplace(Base64Row, Chars.CR, "");
	Value = StrReplace(Value, Chars.LF, "");
	
	Return Value;
	
EndFunction

Procedure CompleteOperationWithError(Context, ErrorText)
	
	ExecuteNotifyProcessing(Context.NotificationsOnComplete.Error, ErrorText);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Auxiliary procedures and functions.

// For the SetCertificatePassword, OpenNewForm, ChooseCertificateToSignOrDecrypt, and
// CheckCatalogCertificate procedures.
//
Function PassParametersForm()
	
	ParameterName = "StandardSubsystems.DigitalSignatureAndEncryptionParameters";
	If ApplicationParameters[ParameterName] = Undefined Then
		ApplicationParameters.Insert(ParameterName, New Map);
	EndIf;
	
	Form = ApplicationParameters["StandardSubsystems.DigitalSignatureAndEncryptionParameters"].Get("PassParametersForm");
	
	If Form = Undefined Then
		Form = OpenForm("Catalog.DigitalSignatureAndEncryptionKeysCertificates.Form.PassingParameters");
		ApplicationParameters["StandardSubsystems.DigitalSignatureAndEncryptionParameters"].Insert("PassParametersForm", Form);
	EndIf;
	
	Return Form;
	
EndFunction

// For the ProcessPasswordInForm procedure.
Procedure ProcessPassword(InternalData, AttributePassword, PasswordProperties,
			RememberPasswordAttribute, AdditionalParameters, NewPassword = Null)
	
	Certificate = AdditionalParameters.Certificate;
	
	PasswordStorage = InternalData.Get("PasswordStorage");
	If PasswordStorage = Undefined Then
		PasswordStorage = New Map;
		InternalData.Insert("PasswordStorage", PasswordStorage);
	EndIf;
	
	SpecifiedPasswords = InternalData.Get("SpecifiedPasswords");
	If SpecifiedPasswords = Undefined Then
		SpecifiedPasswords = New Map;
		InternalData.Insert("SpecifiedPasswords", SpecifiedPasswords);
		InternalData.Insert("SpecifiedPasswordsExplanations", New Map);
	EndIf;
	
	SpecifiedPassword = SpecifiedPasswords.Get(Certificate);
	AdditionalParameters.Insert("PasswordSetProgrammatically", SpecifiedPassword <> Undefined);
	If SpecifiedPassword <> Undefined Then
		AdditionalParameters.Insert("PasswordNote",
			InternalData.Get("SpecifiedPasswordsExplanations").Get(Certificate));
	EndIf;
	
	If AdditionalParameters.StrongPrivateKeyProtection Then
		PasswordProperties.Value = "";
		PasswordProperties.PasswordVerified = False;
		AttributePassword = "";
		Value = PasswordStorage.Get(Certificate);
		If Value <> Undefined Then
			PasswordStorage.Delete(Certificate);
			Value = Undefined;
		EndIf;
		AdditionalParameters.Insert("PasswordInMemory", False);
		
		Return;
	EndIf;
	
	Password = PasswordStorage.Get(Certificate);
	AdditionalParameters.Insert("PasswordInMemory", Password <> Undefined);
	
	If AdditionalParameters.OnSetPasswordFromAnotherOperation Then
		AttributePassword = ?(PasswordProperties.Value <> "", "****************", "");
		Return;
	EndIf;
	
	If AdditionalParameters.OnChangeAttributePassword Then
		If AttributePassword = "****************" Then
			Return;
		EndIf;
		PasswordProperties.Value = AttributePassword;
		PasswordProperties.PasswordVerified = False;
		AttributePassword = ?(PasswordProperties.Value <> "", "****************", "");
		
		Return;
	EndIf;
	
	If AdditionalParameters.OnChangeAttributeRememberPassword Then
		If Not RememberPasswordAttribute Then
			Value = PasswordStorage.Get(Certificate);
			If Value <> Undefined Then
				PasswordStorage.Delete(Certificate);
				Value = Undefined;
			EndIf;
			AdditionalParameters.Insert("PasswordInMemory", False);
			
		ElsIf PasswordProperties.PasswordVerified Then
			PasswordStorage.Insert(Certificate, PasswordProperties.Value);
			AdditionalParameters.Insert("PasswordInMemory", True);
		EndIf;
		
		Return;
	EndIf;
	
	If AdditionalParameters.OnOperationSuccess Then
		If RememberPasswordAttribute
		   AND NOT AdditionalParameters.PasswordSetProgrammatically Then
			
			PasswordStorage.Insert(Certificate, PasswordProperties.Value);
			AdditionalParameters.Insert("PasswordInMemory", True);
			PasswordProperties.PasswordVerified = True;
		EndIf;
		
		Return;
	EndIf;
	
	If AdditionalParameters.PasswordSetProgrammatically Then
		If NewPassword <> Null Then
			PasswordProperties.Value = String(NewPassword);
		Else
			PasswordProperties.Value = String(SpecifiedPassword);
		EndIf;
		PasswordProperties.PasswordVerified = False;
		AttributePassword = ?(PasswordProperties.Value <> "", "****************", "");
		
		Return;
	EndIf;
	
	If NewPassword <> Null Then
		// Setting a new password to a new certificate.
		If NewPassword <> Undefined Then
			PasswordProperties.Value = String(NewPassword);
			PasswordProperties.PasswordVerified = True;
			NewPassword = "";
			If PasswordStorage.Get(Certificate) <> Undefined Or RememberPasswordAttribute Then
				PasswordStorage.Insert(Certificate, PasswordProperties.Value);
				AdditionalParameters.Insert("PasswordInMemory", True);
			EndIf;
		ElsIf PasswordStorage.Get(Certificate) <> Undefined Then
			// Deleting the saved password from the storage.
			RememberPasswordAttribute = False;
			PasswordStorage.Delete(Certificate);
			AdditionalParameters.Insert("PasswordInMemory", False);
		EndIf;
		AttributePassword = ?(PasswordProperties.Value <> "", "****************", "");
		
		Return;
	EndIf;
	
	If AdditionalParameters.OnChangeCertificateProperties Then
		Return;
	EndIf;
	
	// Getting a password from the storage.
	Value = PasswordStorage.Get(Certificate);
	AdditionalParameters.Insert("PasswordInMemory", Value <> Undefined);
	RememberPasswordAttribute = AdditionalParameters.PasswordInMemory;
	PasswordProperties.Value = String(Value);
	PasswordProperties.PasswordVerified = AdditionalParameters.PasswordInMemory;
	Value = Undefined;
	AttributePassword = ?(PasswordProperties.Value <> "", "****************", "");
	
EndProcedure

// For the SetDataPresentation procedure.
Procedure FillPresentationsList(PresentationsList, DataItem)
	
	ListItem = New Structure("Value, Presentation", Undefined, "");
	PresentationsList.Add(ListItem);
	
	If DataItem.Property("Presentation")
	   AND TypeOf(DataItem.Presentation) = Type("Structure") Then
		
		FillPropertyValues(ListItem, DataItem.Presentation);
		Return;
	EndIf;
	
	If DataItem.Property("Presentation")
	   AND TypeOf(DataItem.Presentation) <> Type("String") Then
	
		ListItem.Value = DataItem.Presentation;
		
	ElsIf DataItem.Property("Object")
	        AND TypeOf(DataItem.Object) <> Type("NotifyDescription") Then
		
		ListItem.Value = DataItem.Object;
	EndIf;
	
	If DataItem.Property("Presentation") Then
		ListItem.Presentation = DataItem.Presentation;
	EndIf;
	
EndProcedure

// This method is required by the SaveCertificateFollowUp and SaveApplicationForCertificateAfterInstallExtension procedures.

// Prepares a string to use as a file name.
Function PrepareStringForFileName(Row, SpaceReplacement = Undefined)
	
	CharsReplacement = New Map;
	CharsReplacement.Insert("\", " ");
	CharsReplacement.Insert("/", " ");
	CharsReplacement.Insert("*", " ");
	CharsReplacement.Insert("<", " ");
	CharsReplacement.Insert(">", " ");
	CharsReplacement.Insert("|", " ");
	CharsReplacement.Insert(":", "");
	CharsReplacement.Insert("""", "");
	CharsReplacement.Insert("?", "");
	CharsReplacement.Insert(Chars.CR, "");
	CharsReplacement.Insert(Chars.LF, " ");
	CharsReplacement.Insert(Chars.Tab, " ");
	CharsReplacement.Insert(Chars.NBSp, " ");
	// replacing quote characters
	CharsReplacement.Insert(Char(171), "");
	CharsReplacement.Insert(Char(187), "");
	CharsReplacement.Insert(Char(8195), "");
	CharsReplacement.Insert(Char(8194), "");
	CharsReplacement.Insert(Char(8216), "");
	CharsReplacement.Insert(Char(8218), "");
	CharsReplacement.Insert(Char(8217), "");
	CharsReplacement.Insert(Char(8220), "");
	CharsReplacement.Insert(Char(8222), "");
	CharsReplacement.Insert(Char(8221), "");
	
	PreparedString = "";
	
	CharsCount = StrLen(Row);
	
	For CharNumber = 1 To CharsCount Do
		Char = Mid(Row, CharNumber, 1);
		If CharsReplacement[Char] <> Undefined Then
			Char = CharsReplacement[Char];
		EndIf;
		PreparedString = PreparedString + Char;
	EndDo;
	
	If SpaceReplacement <> Undefined Then
		PreparedString = StrReplace(SpaceReplacement, " ", SpaceReplacement);
	EndIf;
	
	Return TrimAll(PreparedString);
	
EndFunction

// Continues the CheckSignature procedure.
Procedure CheckSignatureSaaS(Context)
	
	If Not DigitalSignatureClient.VerifyDigitalSignaturesOnTheServer() Then
		
		If TypeOf(Context.RawData) = Type("String")
			AND IsTempStorageURL(Context.RawData) Then
			Context.RawData = GetFromTempStorage(Context.RawData);
		EndIf;
		
		Context.Insert("CheckCertificateAtClient");
		
		CheckSignatureAtClientSaaS(Context);
		Return;
	EndIf;
	
EndProcedure

// Continues the CheckSignature procedure.
Procedure CheckSignatureAtClientSaaS(Context)
	
	Signature = Context.Signature;
	
	If TypeOf(Signature) = Type("String") AND IsTempStorageURL(Signature) Then
		Signature = GetFromTempStorage(Signature);
	EndIf;
	
	Context.Insert("SignatureData", Signature);
	Context.Insert("CryptoManager", "CryptographyService");
	
	ModuleCryptoServiceClient = CommonClient.CommonModule("CryptographyServiceClient");
	ModuleCryptoServiceClient.VerifySignature(New NotifyDescription(
		"CheckSignatureAtClientAfterSignatureCheck", ThisObject, Context,
		"CheckSignatureAtClientAfterSignatureCheckError", ThisObject),
		Context.SignatureData,
		Context.RawData);
		
EndProcedure

// Continues the CheckCertificate procedure.
Procedure CheckCertificateSaaS(Result, Context)
	
	ExecuteNotifyProcessing(Context.Notification, True);
	
EndProcedure

// Continues the ExecuteAtSide procedure.
Procedure ExecuteAtSIdeSaaS(Result, Context)
	
	Context.Insert("CryptoCertificate", Result);
	
	If Context.Operation = "Signing" Then
		SignatureCertificate = Context.DataDetails.SelectedCertificate;
		SignatureCertificate.Thumbprint = Base64Value(SignatureCertificate.Thumbprint);
		ModuleCertificateStoreClient = CommonClient.CommonModule("CertificatesStorageClient");
		ModuleCertificateStoreClient.FindCertificate(New NotifyDescription(
				"ExecuteAtSideAfterExportCertificateInSaaSMode", ThisObject, Context), SignatureCertificate);
		
	ElsIf Context.Operation = "Encryption" Then
		CertificatesProperties = Context.DataDetails.EncryptionCertificates;
		If TypeOf(CertificatesProperties) = Type("String") Then
			CertificatesProperties = GetFromTempStorage(CertificatesProperties);
		EndIf;
		Context.Insert("IndexOf", -1);
		Context.Insert("CertificatesProperties", CertificatesProperties);
		Context.Insert("EncryptionCertificates", New Array);
		ExecuteAtSidePrepareCertificatesSaaSLoopStart(Context);
		Return;
	Else
		ExecuteAtSideLoopRun(Context);
	EndIf;
	
EndProcedure

// Continues the ExecuteAtSide procedure.
Procedure ExecuteAtSidePrepareCertificatesSaaSLoopStart(Context)
	
	If Context.CertificatesProperties.Count() <= Context.IndexOf + 1 Then
		ExecuteAtSideLoopRun(Context);
		Return;
	EndIf;
	Context.IndexOf = Context.IndexOf + 1;
	
	ExecuteAtSidePrepareCertificatesAfterInitializeCertificateSaaS(
		Context.CertificatesProperties[Context.IndexOf].Certificate, Context);
	
EndProcedure

// Continues the ExecuteAtSide procedure.
Procedure ExecuteAtSidePrepareCertificatesAfterInitializeCertificateSaaS(CryptoCertificate, Context)
	
	Context.EncryptionCertificates.Add(CryptoCertificate);
	
	ExecuteAtSidePrepareCertificatesSaaSLoopStart(Context);
	
EndProcedure

// Continues the ExecuteAtSide procedure.
Procedure ExecuteAtSideAfterExportCertificateInSaaSMode(ExportedData, Context) Export
	
	Context.Insert("CertificateProperties", DigitalSignatureClient.CertificateProperties(
		ExportedData.Certificate));
	Context.CertificateProperties.Insert("BinaryData", ExportedData.Certificate.Certificate);
	
	ExecuteAtSideLoopRun(Context);
	
EndProcedure

Function UseDigitalSignatureSaaS() Export
	
	If CommonClient.SubsystemExists("SaaSTechnology.SaaS.DigitalSignatureSaaS") Then
		ModuleDigitalSignatureSaaSClientServer = CommonClient.CommonModule("DigitalSignatureSaaSClientServer");
		Return ModuleDigitalSignatureSaaSClientServer.UsageAllowed();
	EndIf;
	
	Return False;
	
EndFunction

Function InteractiveCryptoModeUsageUse()
	
	Return Eval("CryptographyInteractiveModeUsage.Use");
	
EndFunction

#EndRegion
