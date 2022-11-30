///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var ClientParameters Export;

&AtClient
Var DataDetails, ObjectForm, CurrentPresentationsList;

&AtClient
Var DataRepresentationRefreshed;

#EndRegion

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If ValueIsFilled(Parameters.DataTitle) Then
		Items.DataPresentation.Title = Parameters.DataTitle;
	Else
		Items.DataPresentation.TitleLocation = FormItemTitleLocation.None;
	EndIf;
	
	DataPresentation = Parameters.DataPresentation;
	Items.DataPresentation.Hyperlink = Parameters.DataPresentationCanOpen;
	
	If Not ValueIsFilled(DataPresentation) Then
		Items.DataPresentation.Visible = False;
	EndIf;
	
	If Not Parameters.ShowComment Then
		Items.Signatures.Header = False;
		Items.SignaturesComment.Visible = False;
	EndIf;
	
	CryptographyManagerOnServerErrorDescription = New Structure;
	
	If DigitalSignature.VerifyDigitalSignaturesOnTheServer()
	 Or DigitalSignature.GenerateDigitalSignaturesAtServer() Then
		
		DigitalSignatureInternal.CryptoManager("",
			False, CryptographyManagerOnServerErrorDescription);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If ClientParameters = Undefined Then
		Cancel = True;
	Else
		DataDetails             = ClientParameters.DataDetails;
		ObjectForm               = ClientParameters.Form;
		CurrentPresentationsList = ClientParameters.CurrentPresentationsList;
		AttachIdleHandler("AfterOpen", 0.1, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DataPresentationClick(Item, StandardProcessing)
	
	DigitalSignatureInternalClient.DataPresentationClick(ThisObject,
		Item, StandardProcessing, CurrentPresentationsList);
	
EndProcedure

#EndRegion

#Region SignaturesFormTableItemsEventHandlers

&AtClient
Procedure SIgnaturesBeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)
	
	Cancel = True;
	
	If DataRepresentationRefreshed = True Then
		SelectFile(True);
	EndIf;
	
EndProcedure

&AtClient
Procedure SignaturesFilePathStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	SelectFile();
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure OK(Command)
	
	If Signatures.Count() = 0 Then
		ShowMessageBox(, NStr("ru = 'Не выбрано ни одного файла подписи'; en = 'No signature file is selected'; pl = 'No signature file is selected';de = 'No signature file is selected';ro = 'No signature file is selected';tr = 'No signature file is selected'; es_ES = 'No signature file is selected'"));
		Return;
	EndIf;
	
	If Not DataDetails.Property("Object") Then
		DataDetails.Insert("Signatures", SignaturesArray());
		Close(True);
		Return;
	EndIf;
	
	If TypeOf(DataDetails.Object) <> Type("NotifyDescription") Then
		ObjectVersion = Undefined;
		DataDetails.Property("ObjectVersion", ObjectVersion);
		SignaturesArray = Undefined;
		Try
			AddSignature(DataDetails.Object, ObjectVersion, SignaturesArray);
		Except
			ErrorInformation = ErrorInfo();
			OKCompletion(New Structure("ErrorDescription", BriefErrorDescription(ErrorInformation)));
			Return;
		EndTry;
		DataDetails.Insert("Signatures", SignaturesArray);
		NotifyChanged(DataDetails.Object);
	Else
		DataDetails.Insert("Signatures", SignaturesArray());
		
		ExecutionParameters = New Structure;
		ExecutionParameters.Insert("DataDetails", DataDetails);
		ExecutionParameters.Insert("Notification", New NotifyDescription("OKCompletion", ThisObject));
		
		Try
			ExecuteNotifyProcessing(DataDetails.Object, ExecutionParameters);
			Return;
		Except
			ErrorInformation = ErrorInfo();
			OKCompletion(New Structure("ErrorDescription", BriefErrorDescription(ErrorInformation)));
			Return;
		EndTry;
	EndIf;
	
	OKCompletion(New Structure);
	
EndProcedure

// Continues the OK procedure.
&AtClient
Procedure OKCompletion(Result, Context = Undefined) Export
	
	If Result.Property("ErrorDescription") Then
		DataDetails.Delete("Signatures");
		
		Error = New Structure("ErrorDescription",
			NStr("ru = 'При записи подписи возникла ошибка:'; en = 'An error occurred when writing the signature:'; pl = 'An error occurred when writing the signature:';de = 'An error occurred when writing the signature:';ro = 'An error occurred when writing the signature:';tr = 'An error occurred when writing the signature:'; es_ES = 'An error occurred when writing the signature:'") + Chars.LF + Result.ErrorDescription);
			
		DigitalSignatureInternalClient.ShowApplicationCallError(
			NStr("ru = 'Не удалось добавить электронную подпись из файла'; en = 'Cannot add a digital signature from the file'; pl = 'Cannot add a digital signature from the file';de = 'Cannot add a digital signature from the file';ro = 'Cannot add a digital signature from the file';tr = 'Cannot add a digital signature from the file'; es_ES = 'Cannot add a digital signature from the file'"), "", Error, New Structure);
		Return;
	EndIf;
	
	If ValueIsFilled(DataPresentation) Then
		DigitalSignatureClient.ObjectSigningInfo(
			DigitalSignatureInternalClient.FullDataPresentation(ThisObject),, True);
	EndIf;
	
	Close(True);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure AfterOpen()
	
	DataRepresentationRefreshed = True;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SignaturesPathToFile.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Signatures.PathToFile");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
EndProcedure

&AtClient
Procedure SelectFile(AddNewRow = False)
	
	Context = New Structure;
	Context.Insert("AddNewRow", AddNewRow);
	
	Notification = New NotifyDescription("SelectFileAfterPutFiles", ThisObject, Context);
	
	ImportParameters = FileSystemClient.FileImportParameters();
	ImportParameters.FormID = UUID;
	ImportParameters.Dialog.Title = NStr("ru = 'Выберите файл электронной подписи'; en = 'Select a digital signature file'; pl = 'Select a digital signature file';de = 'Select a digital signature file';ro = 'Select a digital signature file';tr = 'Select a digital signature file'; es_ES = 'Select a digital signature file'");
	ImportParameters.Dialog.Filter = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Файлы подписи (*.%1)|*.%1|Все файлы(*.*)|*.*'; en = 'Signature files (*.%1)|*.%1|All files(*.*)|*.*'; pl = 'Signature files (*.%1)|*.%1|All files(*.*)|*.*';de = 'Signature files (*.%1)|*.%1|All files(*.*)|*.*';ro = 'Signature files (*.%1)|*.%1|All files(*.*)|*.*';tr = 'Signature files (*.%1)|*.%1|All files(*.*)|*.*'; es_ES = 'Signature files (*.%1)|*.%1|All files(*.*)|*.*'"),
		DigitalSignatureClient.PersonalSettings().SignatureFilesExtension);
	
	If Not AddNewRow Then
		ImportParameters.Dialog.FullFileName = Items.Signatures.CurrentData.PathToFile;
	EndIf;
	
	FileSystemClient.ImportFile(Notification, ImportParameters);
	
EndProcedure

// Continues the SelectFile procedure.
&AtClient
Procedure SelectFileAfterPutFiles(FileThatWasPut, Context) Export
	
	If FileThatWasPut = Undefined Then
		Return;
	EndIf;
	
	Context.Insert("Address",               FileThatWasPut.Location);
	Context.Insert("FileName",            FileThatWasPut.Name);
	Context.Insert("ErrorAtServer",     New Structure);
	Context.Insert("SignatureData",       Undefined);
	Context.Insert("SignatureDate",         Undefined);
	Context.Insert("SignaturePropertiesAddress", Undefined);
	
	Success = AddRowAtServer(Context.Address, Context.FileName, Context.AddNewRow,
		Context.ErrorAtServer, Context.SignatureData, Context.SignatureDate, Context.SignaturePropertiesAddress);
	
	If Success Then
		SelectFileAfterAddRow(Context);
		Return;
	EndIf;
	
	DigitalSignatureInternalClient.CreateCryptoManager(New NotifyDescription(
			"ChooseFileAfterCreateCryptoManager", ThisObject, Context),
		"", Undefined);
	
EndProcedure

// Continues the SelectFile procedure.
&AtClient
Procedure ChooseFileAfterCreateCryptoManager(CryptoManager, Context) Export
	
	If TypeOf(CryptoManager) <> Type("CryptoManager") Then
		ShowError(CryptoManager, Context.ErrorAtServer);
		Return;
	EndIf;
	
	CryptoManager.BeginGettingCertificatesFromSignature(New NotifyDescription(
		"ChooseFilesAfterGetCertificatesFromSignature", ThisObject, Context,
		"SelectFileAfterGetCertificateFromSignatureError", ThisObject), Context.SignatureData);
	
EndProcedure

// Continues the SelectFile procedure.
&AtClient
Procedure SelectFileAfterGetCertificateFromSignatureError(ErrorInformation, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	ErrorAtClient = New Structure("ErrorDescription", StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'При получении сертификатов из файла подписи произошла ошибка:
		           |%1'; 
		           |en = 'An error occurred when receiving certificates from signature file:
		           |%1'; 
		           |pl = 'An error occurred when receiving certificates from signature file:
		           |%1';
		           |de = 'An error occurred when receiving certificates from signature file:
		           |%1';
		           |ro = 'An error occurred when receiving certificates from signature file:
		           |%1';
		           |tr = 'An error occurred when receiving certificates from signature file:
		           |%1'; 
		           |es_ES = 'An error occurred when receiving certificates from signature file:
		           |%1'"),
		BriefErrorDescription(ErrorInformation)));
	
	ShowError(ErrorAtClient, Context.ErrorAtServer);
	
EndProcedure

// Continues the SelectFile procedure.
&AtClient
Procedure ChooseFilesAfterGetCertificatesFromSignature(Certificates, Context) Export
	
	If Certificates.Count() = 0 Then
		ErrorAtClient = New Structure("ErrorDescription",
			NStr("ru = 'В файле подписи нет ни одного сертификата.'; en = 'Signature file does not include any certificates.'; pl = 'Signature file does not include any certificates.';de = 'Signature file does not include any certificates.';ro = 'Signature file does not include any certificates.';tr = 'Signature file does not include any certificates.'; es_ES = 'Signature file does not include any certificates.'"));
		
		ShowError(ErrorAtClient, Context.ErrorAtServer);
		Return;
	EndIf;
	
	Context.Insert("Certificate", Certificates[0]);
	
	Context.Certificate.BeginUnloading(New NotifyDescription(
		"ChooseFileAfterCertificateExport", ThisObject, Context));
	
EndProcedure

// Continues the SelectFile procedure.
&AtClient
Procedure ChooseFileAfterCertificateExport(CertificateData, Context) Export
	
	CertificateProperties = DigitalSignatureClient.CertificateProperties(Context.Certificate);
	CertificateProperties.Insert("BinaryData", CertificateData);
	
	SignatureProperties = DigitalSignatureInternalClientServer.SignatureProperties(Context.SignatureData,
		CertificateProperties, "", UsersClient.AuthorizedUser(), Context.FileName);
	
	AddRow(ThisObject, Context.AddNewRow, SignatureProperties,
		Context.FileName, Context.SignaturePropertiesAddress);
	
	SelectFileAfterAddRow(Context);
	
EndProcedure

// Continues the SelectFile procedure.
&AtClient
Procedure SelectFileAfterAddRow(Context)
	
	If Not DataDetails.Property("Data") Then
		Return; // If data is not specified, the signature cannot be checked.
	EndIf;
	
	DigitalSignatureInternalClient.GetDataFromDataDetails(New NotifyDescription(
			"ChooseFileAfterGetData", ThisObject, Context),
		ThisObject, DataDetails, DataDetails.Data, True);
	
EndProcedure

// Continues the SelectFile procedure.
&AtClient
Procedure ChooseFileAfterGetData(Result, Context) Export
	
	If TypeOf(Result) = Type("Structure") Then
		Return; // Cannot get data. Signature check is impossible.
	EndIf;
	
	DigitalSignatureInternalClient.VerifySignature(New NotifyDescription(
			"ChooseFileAfterSignatureCheck", ThisObject, Context),
		Result, Context.SignatureData, , Context.SignatureDate, False);
	
EndProcedure

// Continues the SelectFile procedure.
&AtClient
Procedure ChooseFileAfterSignatureCheck(Result, Context) Export
	
	If Result = Undefined Then
		Return; // Cannot check the signature.
	EndIf;
	
	UpdateSignatureCheckResult(Context.SignaturePropertiesAddress, Result = True);
	
EndProcedure

&AtServer
Procedure UpdateSignatureCheckResult(SignaturePropertiesAddress, SignatureCorrect)
	
	CurrentSessionDate = CurrentSessionDate();
	SignatureProperties = GetFromTempStorage(SignaturePropertiesAddress);
	
	If Not ValueIsFilled(SignatureProperties.SignatureDate) Then
		SignatureProperties.SignatureDate = CurrentSessionDate;
	EndIf;
	
	SignatureProperties.SignatureValidationDate = CurrentSessionDate;
	SignatureProperties.SignatureCorrect = SignatureCorrect;
	
	PutToTempStorage(SignatureProperties, SignaturePropertiesAddress);
	
EndProcedure

&AtServer
Function AddRowAtServer(Address, FileName, AddNewRow, ErrorAtServer,
			SignatureData, SignatureDate, SignaturePropertiesAddress)
	
	SignatureData = GetFromTempStorage(Address);
	SignatureDate = DigitalSignature.SigningDate(SignatureData);
	
	If Not DigitalSignature.VerifyDigitalSignaturesOnTheServer()
	   AND Not DigitalSignature.GenerateDigitalSignaturesAtServer() Then
		
		Return False;
	EndIf;
	
	CryptoManager = DigitalSignatureInternal.CryptoManager("", False, ErrorAtServer);
	If CryptoManager = Undefined Then
		Return False;
	EndIf;
	
	Try
		Certificates = CryptoManager.GetCertificatesFromSignature(SignatureData);
	Except
		ErrorInformation = ErrorInfo();
		ErrorAtServer.Insert("ErrorDescription", StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'При получении сертификатов из файла подписи произошла ошибка:
			           |%1'; 
			           |en = 'An error occurred when receiving certificates from signature file:
			           |%1'; 
			           |pl = 'An error occurred when receiving certificates from signature file:
			           |%1';
			           |de = 'An error occurred when receiving certificates from signature file:
			           |%1';
			           |ro = 'An error occurred when receiving certificates from signature file:
			           |%1';
			           |tr = 'An error occurred when receiving certificates from signature file:
			           |%1'; 
			           |es_ES = 'An error occurred when receiving certificates from signature file:
			           |%1'"),
			BriefErrorDescription(ErrorInformation)));
		Return False;
	EndTry;
	
	If Certificates.Count() = 0 Then
		ErrorAtServer.Insert("ErrorDescription", NStr("ru = 'В файле подписи нет ни одного сертификата.'; en = 'Signature file does not include any certificates.'; pl = 'Signature file does not include any certificates.';de = 'Signature file does not include any certificates.';ro = 'Signature file does not include any certificates.';tr = 'Signature file does not include any certificates.'; es_ES = 'Signature file does not include any certificates.'"));
		Return False;
	EndIf;
	
	CertificateProperties = DigitalSignature.CertificateProperties(Certificates[0]);
	CertificateProperties.Insert("BinaryData", Certificates[0].Unload());
	
	SignatureProperties = DigitalSignatureInternalClientServer.SignatureProperties(SignatureData,
		CertificateProperties, "", Users.AuthorizedUser(), FileName);
	
	AddRow(ThisObject, AddNewRow, SignatureProperties, FileName, SignaturePropertiesAddress);
	
	Return True;
	
EndFunction

&AtClientAtServerNoContext
Procedure AddRow(Form, AddNewRow, SignatureProperties, FileName, SignaturePropertiesAddress)
	
	SignaturePropertiesAddress = PutToTempStorage(SignatureProperties, Form.UUID);
	
	If AddNewRow Then
		CurrentData = Form.Signatures.Add();
	Else
		CurrentData = Form.Signatures.FindByID(Form.Items.Signatures.CurrentRow);
	EndIf;
	
	CurrentData.PathToFile = FileName;
	CurrentData.SignaturePropertiesAddress = SignaturePropertiesAddress;
	
EndProcedure

&AtServer
Function SignaturesArray()
	
	SignaturesArray = New Array;
	
	For each Row In Signatures Do
		
		SignatureProperties = GetFromTempStorage(Row.SignaturePropertiesAddress);
		SignatureProperties.Insert("Comment", Row.Comment);
		
		SignaturesArray.Add(PutToTempStorage(SignatureProperties, UUID));
	EndDo;
	
	Return SignaturesArray;
	
EndFunction

&AtServer
Procedure AddSignature(ObjectRef, ObjectVersion, SignaturesArray)
	
	SignaturesArray = SignaturesArray();
	
	DigitalSignature.AddSignature(ObjectRef,
		SignaturesArray, UUID, ObjectVersion);
	
EndProcedure

&AtClient
Procedure ShowError(ErrorAtClient, ErrorAtServer)
	
	DigitalSignatureInternalClient.ShowApplicationCallError(
		NStr("ru = 'Не удалось получить подпись из файла'; en = 'Cannot receive a signature from the file'; pl = 'Cannot receive a signature from the file';de = 'Cannot receive a signature from the file';ro = 'Cannot receive a signature from the file';tr = 'Cannot receive a signature from the file'; es_ES = 'Cannot receive a signature from the file'"), "", ErrorAtClient, ErrorAtServer);
	
EndProcedure

#EndRegion
