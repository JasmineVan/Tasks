///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var InternalData, DataDetails, ObjectForm, ProcessingAfterWarning, CurrentPresentationsList;

#EndRegion

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If ValueIsFilled(Parameters.CertificatesSet) Then
		SpecifiedImmutableCertificateSet = True;
		FillEncryptionCertificatesFromSet(Parameters.CertificatesSet);
		If CertificatesSet.Count() = 0 AND Parameters.EditSet Then
			// If all set certificates are referenced and it is allowed to change the set, the user interaction 
			// is normal as if this user added them.
			SpecifiedImmutableCertificateSet = False;
		EndIf;
	EndIf;
	
	DigitalSignatureInternal.SetSigningEncryptionDecryptionForm(ThisObject, True);
	
	If SpecifiedImmutableCertificateSet Then
		Items.Certificate.Visible = False;
		Items.EncryptionCertificatesGroup.Title = Items.SpecifiedCertificatesSetGroup.Title;
		Items.EncryptionCertificates.ReadOnly = True;
		Items.EncryptionCertificatesSelect.Enabled = False;
		FillEncryptionApplicationAtServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If InternalData = Undefined Then
		Cancel = True;
	EndIf;
	
	If ValueIsFilled(DefaultFieldNameToActivate) Then
		CurrentItem = Items[DefaultFieldNameToActivate];
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	ClearFormVariables();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If Upper(EventName) = Upper("Write_DigitalSignatureAndEncryptionSoftware")
	 Or Upper(EventName) = Upper("Write_PathToDigitalSignatureAndEncryptionSoftwareAtServer")
	 Or Upper(EventName) = Upper("Write_DigitalSignatureAndEncryptionKeyCertificates") Then
		
		If SpecifiedImmutableCertificateSet Then
			AttachIdleHandler("RefillEncryptionApplication", 0.1, True);
			Return;
		EndIf;
	EndIf;
	
	If Upper(EventName) = Upper("Write_DigitalSignatureAndEncryptionKeyCertificates") Then
		AttachIdleHandler("OnChangeCertificatesList", 0.1, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DataPresentationClick(Item, StandardProcessing)
	
	DigitalSignatureInternalClient.DataPresentationClick(ThisObject,
		Item, StandardProcessing, CurrentPresentationsList);
	
EndProcedure

&AtClient
Procedure CertificateOnChange(Item)
	
	DigitalSignatureInternalClient.GetCertificatesThumbprintsAtClient(
		New NotifyDescription("CertificateOnChangeCompletion", ThisObject));
	
EndProcedure

// Continues the CertificateOnChange procedure.
&AtClient
Procedure CertificateOnChangeCompletion(CertificatesThumbprintsAtClient, Context) Export
	
	CertificateOnChangeAtServer(CertificatesThumbprintsAtClient);
	
EndProcedure

&AtClient
Procedure CertificateStartChoice(Item, ChoiceData, StandardProcessing)
	
	DigitalSignatureClient.CertificateStartChoiceWithConfirmation(Item,
		Certificate, StandardProcessing, True);
	
EndProcedure

&AtClient
Procedure CertificateOpen(Item, StandardProcessing)
	
	StandardProcessing = False;
	If ValueIsFilled(Certificate) Then
		DigitalSignatureClient.OpenCertificate(Certificate);
	EndIf;
	
EndProcedure

&AtClient
Procedure CertificateChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	Certificate = ValueSelected;
	
	DigitalSignatureInternalClient.GetCertificatesThumbprintsAtClient(
		New NotifyDescription("CertificateChoiceProcessingCompletion", ThisObject));
	
EndProcedure

// Continues the CertificateChoiceProcessing procedure.
&AtClient
Procedure CertificateChoiceProcessingCompletion(CertificatesThumbprintsAtClient, Context) Export
	
	CertificateOnChangeAtServer(CertificatesThumbprintsAtClient);
	
EndProcedure

&AtClient
Procedure CertificateAutoComplete(Item, Text, ChoiceData, Parameters, Waiting, StandardProcessing)
	
	DigitalSignatureInternalClient.CertificatePickupFromSelectionList(ThisObject, Text, ChoiceData, StandardProcessing);
	
EndProcedure

&AtClient
Procedure CertificateTextEditEnd(Item, Text, ChoiceData, Parameters, StandardProcessing)
	
	DigitalSignatureInternalClient.CertificatePickupFromSelectionList(ThisObject, Text, ChoiceData, StandardProcessing);
	
EndProcedure

#EndRegion

#Region EncryptionCertificatesFormTableItemsEventHandlers

&AtClient
Procedure EncryptionCertificatesChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If TypeOf(ValueSelected) <> Type("Array") Then
		Return;
	EndIf;
	
	For each Value In ValueSelected Do
		Filter = New Structure("Certificate", Value);
		Rows = EncryptionCertificates.FindRows(Filter);
		If Rows.Count() > 0 Then
			Continue;
		EndIf;
		EncryptionCertificates.Add().Certificate = Value;
	EndDo;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Select(Command)
	
	OpenForm("Catalog.DigitalSignatureAndEncryptionKeysCertificates.Form.SelectEncryptionCertificates",
		, Items.EncryptionCertificates);
	
EndProcedure

&AtClient
Procedure OpenCertificate(Command)
	
	If Items.EncryptionOptions.CurrentPage = Items.SelectFromCatalog Then
		CurrentData = Items.EncryptionCertificates.CurrentData;
	Else
		CurrentData = Items.CertificatesSet.CurrentData;
	EndIf;
	
	If CurrentData = Undefined Then 
		Return;
	EndIf;
	
	If Items.EncryptionOptions.CurrentPage = Items.SelectFromCatalog Then
		DigitalSignatureClient.OpenCertificate(CurrentData.Certificate);
	Else
		DigitalSignatureClient.OpenCertificate(CurrentData.DataAddress);
	EndIf;
	
EndProcedure

&AtClient
Procedure Encrypt(Command)
	
	If Not Items.FormEncrypt.Enabled Then
		Return;
	EndIf;
	
	If Not SpecifiedImmutableCertificateSet
	   AND Not CheckFilling() Then
		
		Return;
	EndIf;
	
	Items.FormEncrypt.Enabled = False;
	
	EncryptData(New NotifyDescription("EncryptCompletion", ThisObject));
	
EndProcedure

// Continues the Encrypt procedure.
&AtClient
Procedure EncryptCompletion(Result, Context) Export
	
	Items.FormEncrypt.Enabled = True;
	
	If Result = True Then
		Close(True);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillEncryptionCertificatesFromSet(CertificatesSetDetails)
	
	If Common.IsReference(TypeOf(CertificatesSetDetails)) Then
		Query = New Query;
		Query.SetParameter("Ref", CertificatesSetDetails);
		Query.Text =
		"SELECT
		|	EncryptionCertificates.Certificate AS Certificate
		|FROM
		|	InformationRegister.EncryptionCertificates AS EncryptionCertificates
		|WHERE
		|	EncryptionCertificates.EncryptedObject = &Ref";
		CertificatesArray = New Array;
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			CertificatesArray.Add(Selection.Certificate.Get());
		EndDo;
	Else
		If TypeOf(CertificatesSetDetails) = Type("String") Then
			CertificatesArray = GetFromTempStorage(CertificatesSetDetails);
		Else
			CertificatesArray = CertificatesSetDetails;
		EndIf;
		AddedCertificates = New Map;
		For Each CurrentCertificate In CertificatesArray Do
			If TypeOf(CurrentCertificate) = Type("CatalogRef.DigitalSignatureAndEncryptionKeysCertificates") Then
				If AddedCertificates.Get(CurrentCertificate) = Undefined Then
					AddedCertificates.Insert(CurrentCertificate, True);
					EncryptionCertificates.Add().Certificate = CurrentCertificate;
				EndIf;
			Else
				EncryptionCertificates.Clear();
				Break;
			EndIf;
		EndDo;
		If EncryptionCertificates.Count() > 0
		 Or CertificatesArray.Count() = 0 Then
			Return;
		EndIf;
	EndIf;
	
	CertificatesTable = New ValueTable;
	CertificatesTable.Columns.Add("Ref");
	CertificatesTable.Columns.Add("Thumbprint");
	CertificatesTable.Columns.Add("Presentation");
	CertificatesTable.Columns.Add("IssuedTo");
	CertificatesTable.Columns.Add("Data");
	
	References = New Array;
	Thumbprints = New Array;
	For Each CertificateDetails In CertificatesArray Do
		NewRow = CertificatesTable.Add();
		If TypeOf(CertificateDetails) = Type("BinaryData") Then
			CryptoCertificate = New CryptoCertificate(CertificateDetails);
			CertificateProperties = DigitalSignature.CertificateProperties(CryptoCertificate);
			NewRow.Presentation = CertificateProperties.Presentation;
			NewRow.IssuedTo     = CertificateProperties.IssuedTo;
			NewRow.Thumbprint     = CertificateProperties.Thumbprint;
			NewRow.Data        = CertificateDetails;
			Thumbprints.Add(CertificateProperties.Thumbprint);
		Else
			NewRow.Ref = CertificateDetails;
			References.Add(CertificateDetails);
		EndIf;
	EndDo;
	CertificatesTable.Indexes.Add("Ref");
	CertificatesTable.Indexes.Add("Thumbprint");
	
	Query = New Query;
	Query.SetParameter("References", References);
	Query.SetParameter("Thumbprints", Thumbprints);
	Query.Text =
	"SELECT
	|	Certificates.Ref AS Ref,
	|	Certificates.Thumbprint AS Thumbprint,
	|	Certificates.Description AS Presentation,
	|	Certificates.CertificateData AS CertificateData
	|FROM
	|	Catalog.DigitalSignatureAndEncryptionKeysCertificates AS Certificates
	|WHERE
	|	(Certificates.Ref IN (&References)
	|			OR Certificates.Thumbprint IN (&Thumbprints))";
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Rows = CertificatesTable.FindRows(New Structure("Ref", Selection.Ref));
		For Each Row In Rows Do
			CertificateData = Selection.CertificateData.Get();
			If TypeOf(CertificateData) <> Type("BinaryData") Then
				Raise StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Данные сертификата ""%1"" не найдены в справочнике'; en = 'The ""%1"" certificate data is not found in catalog'; pl = 'The ""%1"" certificate data is not found in catalog';de = 'The ""%1"" certificate data is not found in catalog';ro = 'The ""%1"" certificate data is not found in catalog';tr = 'The ""%1"" certificate data is not found in catalog'; es_ES = 'The ""%1"" certificate data is not found in catalog'"), Selection.Presentation);
			EndIf;
			Try
				CryptoCertificate = New CryptoCertificate(CertificateData);
			Except
				ErrorInformation = ErrorInfo();
				Raise StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Данные сертификата ""%1"" в справочнике не корректны по причине:
					           |%2'; 
					           |en = 'The ""%1"" certificate data in catalog is incorrect due to: 
					           |%2'; 
					           |pl = 'The ""%1"" certificate data in catalog is incorrect due to: 
					           |%2';
					           |de = 'The ""%1"" certificate data in catalog is incorrect due to: 
					           |%2';
					           |ro = 'The ""%1"" certificate data in catalog is incorrect due to: 
					           |%2';
					           |tr = 'The ""%1"" certificate data in catalog is incorrect due to: 
					           |%2'; 
					           |es_ES = 'The ""%1"" certificate data in catalog is incorrect due to: 
					           |%2'"),
					Selection.Presentation,
					BriefErrorDescription(ErrorInformation));
			EndTry;
			CertificateProperties = DigitalSignature.CertificateProperties(CryptoCertificate);
			Row.Thumbprint     = Selection.Thumbprint;
			Row.Presentation = Selection.Presentation;
			Row.IssuedTo     = CertificateProperties.IssuedTo;
			Row.Data        = CertificateData;
		EndDo;
		Rows = CertificatesTable.FindRows(New Structure("Thumbprint", Selection.Thumbprint));
		For Each Row In Rows Do
			Row.Ref        = Selection.Ref;
			Row.Presentation = Selection.Presentation;
		EndDo;
	EndDo;
	
	// Deleting duplicates.
	AllThumbprints = New Map;
	Index = CertificatesTable.Count() - 1;
	While Index >= 0 Do
		Row = CertificatesTable[Index];
		If AllThumbprints.Get(Row.Thumbprint) = Undefined Then
			AllThumbprints.Insert(Row.Thumbprint, True);
		Else
			CertificatesTable.Delete(Index);
		EndIf;
		Index = Index - 1;
	EndDo;
	
	Filter = New Structure("Ref", Undefined);
	AllCertificatesInCatalog = CertificatesTable.FindRows(Filter).Count() = 0;
	
	If AllCertificatesInCatalog Then
		For Each Row In CertificatesTable Do
			EncryptionCertificates.Add().Certificate = Row.Ref;
		EndDo;
	Else
		CertificatesProperties = New Array;
		For Each Row In CertificatesTable Do
			NewRow = CertificatesSet.Add();
			FillPropertyValues(NewRow, Row);
			NewRow.DataAddress = PutToTempStorage(Row.Data, UUID);
			Properties = New Structure;
			Properties.Insert("Thumbprint",     Row.Thumbprint);
			Properties.Insert("Presentation", Row.IssuedTo);
			Properties.Insert("Certificate",    Row.Data);
			CertificatesProperties.Add(Properties);
		EndDo;
		
		CertificatesPropertiesAddress = PutToTempStorage(CertificatesProperties, UUID);
		Items.EncryptionOptions.CurrentPage = Items.SpecifiedCertificatesSet;
	EndIf;
	
EndProcedure

&AtClient
Procedure RefillEncryptionApplication()
	
	FillEncryptionApplicationAtServer();
	FillEncryptionApplication();
	
EndProcedure

&AtServer
Procedure FillEncryptionApplicationAtServer()
	
	CertificateApplication = Undefined;
	FirstApplicationAtServer = Undefined;
	
	If CertificatesSet.Count() > 0 Then
		CertificateAddress = CertificatesSet[0].DataAddress;
	Else
		Try
			AttributesValues = Common.ObjectAttributesValues(
				EncryptionCertificates[0].Certificate, "Application, CertificateData");
			
			If ValueIsFilled(AttributesValues.Application) Then
				CertificateApplication = AttributesValues.Application;
				Return;
			EndIf;
			
			CertificateBinaryData = AttributesValues.CertificateData.Get();
			CryptoCertificate = New CryptoCertificate(CertificateBinaryData);
		Except
			ErrorInformation = ErrorInfo();
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
				EncryptionCertificates[0].Certificate,
				BriefErrorDescription(ErrorInformation));
		EndTry;
		CertificateAddress = PutToTempStorage(CertificateBinaryData, UUID);
	EndIf;
	
	If Not DigitalSignature.GenerateDigitalSignaturesAtServer() Then
		Return;
	EndIf;
	
	CryptoCertificate = New CryptoCertificate(GetFromTempStorage(CertificateAddress));
	TestData = TestBinaryData();
	ApplicationsDetailsCollection = DigitalSignature.CommonSettings().ApplicationsDetailsCollection;
	
	For Each ApplicationDetails In ApplicationsDetailsCollection Do
		CryptoManager = DigitalSignatureInternal.CryptoManager("",
			False, "", ApplicationDetails.Ref);
		
		If CryptoManager = Undefined Then
			Continue;
		EndIf;
		If Not ValueIsFilled(FirstApplicationAtServer) Then
			FirstApplicationAtServer = ApplicationDetails.Ref;
		EndIf;
		Try
			EncryptedTestData = CryptoManager.Encrypt(TestData, CryptoCertificate);
		Except
			ErrorInformation = ErrorInfo();
		EndTry;
		If ErrorInformation = Undefined AND ValueIsFilled(EncryptedTestData) Then
			CertificateApplication = ApplicationDetails.Ref;
			Break;
		EndIf;
	EndDo;
	
EndProcedure

&AtServerNoContext
Function TestBinaryData()
	
	Return PictureLib.KeyCertificate.GetBinaryData();
	
EndFunction

&AtClient
Procedure FillEncryptionApplication(Notification = Undefined)
	
	Context = New Structure;
	Context.Insert("Notification", Notification);
	Context.Insert("FirstApplicationAtClient", Undefined);
	
	If ValueIsFilled(CertificateApplication) Then
		FillEncryptionApplicationAfterLoop(Context);
		Return;
	EndIf;
	
	ApplicationsDetailsCollection = DigitalSignatureClient.CommonSettings().ApplicationsDetailsCollection;
	
	If ApplicationsDetailsCollection = Undefined Or ApplicationsDetailsCollection.Count() = 0 Then
		FillEncryptionApplicationAfterLoop(Context);
		Return;
	EndIf;
	
	Context.Insert("ApplicationsDetailsCollection",  ApplicationsDetailsCollection);
	
	CryptoCertificate = New CryptoCertificate;
	CryptoCertificate.BeginInitialization(New NotifyDescription(
			"FillEncryptionApplicationAfterInitializeCertificate", ThisObject, Context),
		GetFromTempStorage(CertificateAddress));
	
EndProcedure

// Continues the FillEncryptionApplication procedure.
&AtClient
Procedure FillEncryptionApplicationAfterInitializeCertificate(CryptoCertificate, Context) Export
	
	Context.Insert("EncryptionCertificate", CryptoCertificate);
	Context.Insert("TestData", TestBinaryData());
	
	Context.Insert("IndexOf", -1);
	FillEncryptionApplicationLoopStart(Context);
	
EndProcedure

// Continues the FillEncryptionApplication procedure.
&AtClient
Procedure FillEncryptionApplicationLoopStart(Context)
	
	If Context.ApplicationsDetailsCollection.Count() <= Context.IndexOf + 1 Then
		FillEncryptionApplicationAfterLoop(Context);
		Return;
	EndIf;
	Context.IndexOf = Context.IndexOf + 1;
	Context.Insert("ApplicationDetails", Context.ApplicationsDetailsCollection[Context.IndexOf]);
	
	DigitalSignatureInternalClient.CreateCryptoManager(New NotifyDescription(
			"FillEncryptionApplicationAfterCreateCryptoManager", ThisObject, Context),
		"Encryption", False, Context.ApplicationDetails.Ref);
	
EndProcedure

// Continues the FillEncryptionApplication procedure.
&AtClient
Procedure FillEncryptionApplicationAfterCreateCryptoManager(CryptoManager, Context) Export
	
	If TypeOf(CryptoManager) <> Type("CryptoManager") Then
		FillEncryptionApplicationLoopStart(Context);
		Return;
	EndIf;
	
	If Not ValueIsFilled(Context.FirstApplicationAtClient) Then
		Context.FirstApplicationAtClient = Context.ApplicationDetails.Ref;
	EndIf;
	
	CryptoManager.BeginEncrypting(New NotifyDescription(
			"FillEncryptionApplicationAfterEncryption", ThisObject, Context,
			"FillEncryptionProgramAfterEncryptionError", ThisObject),
		Context.TestData, Context.EncryptionCertificate);
	
EndProcedure

// Continues the FillEncryptionApplication procedure.
&AtClient
Procedure FillEncryptionProgramAfterEncryptionError(ErrorInformation, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	FillEncryptionApplicationLoopStart(Context);
	
EndProcedure

// Continues the FillEncryptionApplication procedure.
&AtClient
Procedure FillEncryptionApplicationAfterEncryption(EncryptedData, Context) Export
	
	If Not ValueIsFilled(EncryptedData) Then
		FillEncryptionApplicationLoopStart(Context);
		Return;
	EndIf;
	
	CertificateApplication = Context.ApplicationDetails.Ref;
	FillEncryptionApplicationAfterLoop(Context);
	
EndProcedure

// Continues the CreateCryptoManager procedure.
&AtClient
Procedure FillEncryptionApplicationAfterLoop(Context)
	
	If Not ValueIsFilled(CertificateApplication) Then
		
		If ValueIsFilled(Context.FirstApplicationAtClient) Then
			CertificateApplication = Context.FirstApplicationAtClient;
			
		ElsIf ValueIsFilled(FirstApplicationAtServer) Then
			CertificateApplication = FirstApplicationAtServer;
		EndIf;
	EndIf;
	
	If Context.Notification <> Undefined Then
		ExecuteNotifyProcessing(Context.Notification);
	EndIf;
	
EndProcedure

&AtClient
Procedure ContinueOpening(Notification, CommonInternalData, ClientParameters) Export
	
	DataDetails             = ClientParameters.DataDetails;
	ObjectForm               = ClientParameters.Form;
	CurrentPresentationsList = ClientParameters.CurrentPresentationsList;
	
	InternalData = CommonInternalData;
	Context = New Structure("Notification", Notification);
	Notification = New NotifyDescription("ContinueOpening", ThisObject);
	
	DigitalSignatureInternalClient.ContinueOpeningStart(New NotifyDescription(
		"ContinueOpeningAfterStart", ThisObject, Context), ThisObject, ClientParameters, True);
	
EndProcedure

// Continues the ContinueOpening procedure.
&AtClient
Procedure ContinueOpeningAfterStart(Result, Context) Export
	
	If Result <> True Then
		ContinueOpeningCompletion(Context);
		Return;
	EndIf;
	
	If SpecifiedImmutableCertificateSet Then
		FillEncryptionApplication(New NotifyDescription(
			"ContinueOpeningAfterFillApplication", ThisObject, Context));
	Else
		ContinueOpeningAfterFillApplication(Undefined, Context);
	EndIf;
	
EndProcedure

// Continues the ContinueOpening procedure.
&AtClient
Procedure ContinueOpeningAfterFillApplication(Result, Context) Export
	
	If NoConfirmation Then
		ProcessingAfterWarning = Undefined;
		EncryptData(New NotifyDescription("ContinueOpeningAfterDataEncryption", ThisObject, Context));
		Return;
	EndIf;
	
	Open();
	
	ContinueOpeningCompletion(Context);
	
EndProcedure

// Continues the ContinueOpening procedure.
&AtClient
Procedure ContinueOpeningAfterDataEncryption(Result, Context) Export
	
	ContinueOpeningCompletion(Context, Result = True);
	
EndProcedure

// Continues the ContinueOpening procedure.
&AtClient
Procedure ContinueOpeningCompletion(Context, Result = Undefined)
	
	If Not IsOpen() Then
		ClearFormVariables();
	EndIf;
	
	ExecuteNotifyProcessing(Context.Notification, Result);
	
EndProcedure

&AtClient
Procedure ClearFormVariables()
	
	DataDetails             = Undefined;
	ObjectForm               = Undefined;
	CurrentPresentationsList = Undefined;
	
EndProcedure

// CAC:78-off: to securely pass data between forms on the client without sending them to the server.
&AtClient
Procedure ExecuteEncryption(ClientParameters, CompletionProcessing) Export
// CAC:78-on: to securely pass data between forms on the client without sending them to the server.
	
	DigitalSignatureInternalClient.RefreshFormBeforeSecondUse(ThisObject, ClientParameters);
	
	DataDetails             = ClientParameters.DataDetails;
	ObjectForm               = ClientParameters.Form;
	CurrentPresentationsList = ClientParameters.CurrentPresentationsList;
	
	ProcessingAfterWarning = CompletionProcessing;
	
	Context = New Structure("CompletionProcessing", CompletionProcessing);
	EncryptData(New NotifyDescription("ExecuteEncryptionCompletion", ThisObject, Context));
	
EndProcedure

// Continues the ExecuteEncryption procedure.
&AtClient
Procedure ExecuteEncryptionCompletion(Result, Context) Export
	
	If Result = True Then
		ExecuteNotifyProcessing(Context.CompletionProcessing, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnChangeCertificatesList()
	
	DigitalSignatureInternalClient.GetCertificatesThumbprintsAtClient(
		New NotifyDescription("OnChangeCertificateListCompletion", ThisObject));
	
EndProcedure

// Continues the OnChangeCertificatesList procedure.
&AtClient
Procedure OnChangeCertificateListCompletion(CertificatesThumbprintsAtClient, Context) Export
	
	CertificateOnChangeAtServer(CertificatesThumbprintsAtClient, True);
	
EndProcedure

&AtServer
Procedure CertificateOnChangeAtServer(CertificatesThumbprintsAtClient, CheckRef = False)
	
	If CheckRef
	   AND ValueIsFilled(Certificate)
	   AND Common.ObjectAttributeValue(Certificate, "Ref") <> Certificate Then
		
		Certificate = Undefined;
	EndIf;
	
	DigitalSignatureInternal.CertificateOnChangeAtServer(ThisObject, CertificatesThumbprintsAtClient, True);
	
EndProcedure

&AtClient
Procedure EncryptData(Notification)
	
	Context = New Structure;
	Context.Insert("Notification", Notification);
	Context.Insert("ErrorAtClient", New Structure);
	Context.Insert("ErrorAtServer", New Structure);
	
	If ValueIsFilled(Certificate) Then
		If CertificateExpiresOn < CommonClient.SessionDate() Then
			Context.ErrorAtClient.Insert("ErrorDescription",
				NStr("ru = 'У выбранного личного сертификата истек срок действия.
				           |Выберите другой сертификат.'; 
				           |en = 'The selected personal certificate has expired.
				           |Select another certificate.'; 
				           |pl = 'The selected personal certificate has expired.
				           |Select another certificate.';
				           |de = 'The selected personal certificate has expired.
				           |Select another certificate.';
				           |ro = 'The selected personal certificate has expired.
				           |Select another certificate.';
				           |tr = 'The selected personal certificate has expired.
				           |Select another certificate.'; 
				           |es_ES = 'The selected personal certificate has expired.
				           |Select another certificate.'"));
			ShowError(Context.ErrorAtClient, Context.ErrorAtServer);
			ExecuteNotifyProcessing(Context.Notification, False);
			Return;
		EndIf;
		
		If Not ValueIsFilled(CertificateApplication) Then
			Context.ErrorAtClient.Insert("ErrorDescription",
				NStr("ru = 'У выбранного личного сертификата не указана программа для закрытого ключа.
				           |Выберите другой сертификат.'; 
				           |en = 'An application for the private key of the selected personal certificate is not specified.
				           |Select another certificate.'; 
				           |pl = 'An application for the private key of the selected personal certificate is not specified.
				           |Select another certificate.';
				           |de = 'An application for the private key of the selected personal certificate is not specified.
				           |Select another certificate.';
				           |ro = 'An application for the private key of the selected personal certificate is not specified.
				           |Select another certificate.';
				           |tr = 'An application for the private key of the selected personal certificate is not specified.
				           |Select another certificate.'; 
				           |es_ES = 'An application for the private key of the selected personal certificate is not specified.
				           |Select another certificate.'"));
			ShowError(Context.ErrorAtClient, Context.ErrorAtServer);
			ExecuteNotifyProcessing(Context.Notification, False);
			Return;
		EndIf;
	EndIf;
	
	Context.Insert("FormID", UUID);
	If TypeOf(ObjectForm) = Type("ManagedForm") Then
		Context.FormID = ObjectForm.UUID;
	ElsIf TypeOf(ObjectForm) = Type("UUID") Then
		Context.FormID = ObjectForm;
	EndIf;
	
	If CertificatesSet.Count() = 0 Then
		References = New Array;
		ExcludePersonalCertificate = False;
		If Items.Certificate.Visible AND ValueIsFilled(Certificate) Then
			References.Add(Certificate);
			ExcludePersonalCertificate = True;
		EndIf;
		For each Row In EncryptionCertificates Do
			If Not ExcludePersonalCertificate Or Row.Certificate <> Certificate Then
				References.Add(Row.Certificate);
			EndIf;
		EndDo;
		DataDetails.Insert("EncryptionCertificates",
			CertificatesProperties(References, Context.FormID));
	Else
		DataDetails.Insert("EncryptionCertificates", CertificatesPropertiesAddress);
	EndIf;
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("DataDetails",     DataDetails);
	ExecutionParameters.Insert("Form",              ThisObject);
	ExecutionParameters.Insert("FormID", Context.FormID);
	Context.Insert("ExecutionParameters", ExecutionParameters);
	
	If DigitalSignatureClient.GenerateDigitalSignaturesAtServer() Then
		If ValueIsFilled(CertificateAtServerErrorDescription) Then
			Result = New Structure("Error", CertificateAtServerErrorDescription);
			CertificateAtServerErrorDescription = New Structure;
			EncryptDataAfterExecuteAtServerSide(Result, Context);
		Else
			// An attempt to encrypt on the server.
			DigitalSignatureInternalClient.ExecuteAtSide(New NotifyDescription(
					"EncryptDataAfterExecuteAtServerSide", ThisObject, Context),
				"Encryption", "AtServerSide", Context.ExecutionParameters);
		EndIf;
	Else
		EncryptDataAfterExecuteAtServerSide(Undefined, Context);
	EndIf;
	
EndProcedure

// Continues the EncryptData procedure.
&AtClient
Procedure EncryptDataAfterExecuteAtServerSide(Result, Context) Export
	
	If Result <> Undefined Then
		EncryptDataAfterExecute(Result);
	EndIf;
	
	If Result <> Undefined AND Not Result.Property("Error") Then
		EncryptDataAfterExecuteAtClientSide(New Structure, Context);
	Else
		If Result <> Undefined Then
			Context.ErrorAtServer = Result.Error;
		EndIf;
		
		// An attempt to sign on the client.
		DigitalSignatureInternalClient.ExecuteAtSide(New NotifyDescription(
				"EncryptDataAfterExecuteAtClientSide", ThisObject, Context),
			"Encryption", "OnClientSide", Context.ExecutionParameters);
	EndIf;
	
EndProcedure

// Continues the EncryptData procedure.
&AtClient
Procedure EncryptDataAfterExecuteAtClientSide(Result, Context) Export
	
	EncryptDataAfterExecute(Result);
	
	If Result.Property("Error") Then
		Context.ErrorAtClient = Result.Error;
		ShowError(Context.ErrorAtClient, Context.ErrorAtServer);
		ExecuteNotifyProcessing(Context.Notification, False);
		Return;
	EndIf;
	
	If Not WriteEncryptionCertificates(Context.FormID, Context.ErrorAtClient) Then
		ShowError(Context.ErrorAtClient, Context.ErrorAtServer);
		ExecuteNotifyProcessing(Context.Notification, False);
		Return;
	EndIf;
	
	If ValueIsFilled(DataPresentation)
	   AND (Not DataDetails.Property("NotifyOnCompletion")
	      Or DataDetails.NotifyOnCompletion <> False) Then
		
		DigitalSignatureClient.InformOfObjectEncryption(
			DigitalSignatureInternalClient.FullDataPresentation(ThisObject),
			CurrentPresentationsList.Count() > 1);
	EndIf;
	
	If DataDetails.Property("OperationContext") Then
		DataDetails.OperationContext = ThisObject;
	EndIf;
	
	If NotifyOfCertificateAboutToExpire Then
		FormParameters = New Structure("Certificate", Certificate);
		OpenForm("Catalog.DigitalSignatureAndEncryptionKeysCertificates.Form.CertificateAboutToExpireNotification",
			FormParameters);
	EndIf;
	
	ExecuteNotifyProcessing(Context.Notification, True);
	
EndProcedure

// Continues the EncryptData procedure.
&AtClient
Procedure EncryptDataAfterExecute(Result)
	
	If Result.Property("HasProcessedDataItems") Then
		// You cannot change certificates once encryption starts, otherwise, the data set will be processed 
		// differently.
		Items.Certificate.ReadOnly = True;
		Items.EncryptionCertificates.ReadOnly = True;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function CertificatesProperties(Val References, Val FormID)
	
	Query = New Query;
	Query.SetParameter("References", References);
	Query.Text =
	"SELECT
	|	Certificates.Ref AS Ref,
	|	Certificates.Description AS Description,
	|	Certificates.Application,
	|	Certificates.CertificateData
	|FROM
	|	Catalog.DigitalSignatureAndEncryptionKeysCertificates AS Certificates
	|WHERE
	|	Certificates.Ref IN(&References)";
	
	Selection = Query.Execute().Select();
	CertificatesProperties = New Array;
	
	While Selection.Next() Do
		
		CertificateData = Selection.CertificateData.Get();
		If TypeOf(CertificateData) <> Type("BinaryData") Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Данные сертификата ""%1"" не найдены в справочнике'; en = 'The ""%1"" certificate data is not found in catalog'; pl = 'The ""%1"" certificate data is not found in catalog';de = 'The ""%1"" certificate data is not found in catalog';ro = 'The ""%1"" certificate data is not found in catalog';tr = 'The ""%1"" certificate data is not found in catalog'; es_ES = 'The ""%1"" certificate data is not found in catalog'"),
				Selection.Description);
		EndIf;
		
		Try
			CryptoCertificate = New CryptoCertificate(CertificateData);
		Except
			ErrorInformation = ErrorInfo();
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Данные сертификата ""%1"" в справочнике не корректны по причине:
				           |%2'; 
				           |en = 'The ""%1"" certificate data in catalog is incorrect due to: 
				           |%2'; 
				           |pl = 'The ""%1"" certificate data in catalog is incorrect due to: 
				           |%2';
				           |de = 'The ""%1"" certificate data in catalog is incorrect due to: 
				           |%2';
				           |ro = 'The ""%1"" certificate data in catalog is incorrect due to: 
				           |%2';
				           |tr = 'The ""%1"" certificate data in catalog is incorrect due to: 
				           |%2'; 
				           |es_ES = 'The ""%1"" certificate data in catalog is incorrect due to: 
				           |%2'"),
				Selection.Description,
				BriefErrorDescription(ErrorInformation));
		EndTry;
		CertificateProperties = DigitalSignature.CertificateProperties(CryptoCertificate);
		
		Properties = New Structure;
		Properties.Insert("Thumbprint",     CertificateProperties.Thumbprint);
		Properties.Insert("Presentation", CertificateProperties.IssuedTo);
		Properties.Insert("Certificate",    CertificateData);
		
		CertificatesProperties.Add(Properties);
	EndDo;
	
	Return PutToTempStorage(CertificatesProperties, FormID);
	
EndFunction


&AtClient
Function WriteEncryptionCertificates(FormID, Error)
	
	ObjectsDetails = New Array;
	If DataDetails.Property("Data") Then
		AddObjectDetails(ObjectsDetails, DataDetails);
	Else
		For Each DataItem In DataDetails.DataSet Do
			AddObjectDetails(ObjectsDetails, DataItem);
		EndDo;
	EndIf;
	
	CertificatesAddress = DataDetails.EncryptionCertificates;
	
	Error = New Structure;
	WriteEncryptionCertificatesAtServer(ObjectsDetails, CertificatesAddress, FormID, Error);
	
	Return Not ValueIsFilled(Error);
	
EndFunction

&AtClient
Procedure AddObjectDetails(ObjectsDetails, DataItem)
	
	If Not DataItem.Property("Object") Then
		Return;
	EndIf;
	
	ObjectVersion = Undefined;
	DataItem.Property("ObjectVersion", ObjectVersion);
	
	ObjectDetails = New Structure;
	ObjectDetails.Insert("Ref", DataItem.Object);
	ObjectDetails.Insert("Version", ObjectVersion);
	
	ObjectsDetails.Add(ObjectDetails);
	
EndProcedure

&AtServerNoContext
Procedure WriteEncryptionCertificatesAtServer(ObjectsDetails, CertificatesAddress, FormID, Error)
	
	CertificatesProperties = GetFromTempStorage(CertificatesAddress);
	
	BeginTransaction();
	Try
		For each ObjectDetails In ObjectsDetails Do
			DigitalSignature.WriteEncryptionCertificates(ObjectDetails.Ref,
				CertificatesProperties, FormID, ObjectDetails.Version);
		EndDo;
		CommitTransaction();
	Except
		RollbackTransaction();
		ErrorInformation = ErrorInfo();
		Error.Insert("ErrorDescription", NStr("ru = 'При записи сертификатов шифрования возникла ошибка:'; en = 'An error occurred when writing encryption certificates:'; pl = 'An error occurred when writing encryption certificates:';de = 'An error occurred when writing encryption certificates:';ro = 'An error occurred when writing encryption certificates:';tr = 'An error occurred when writing encryption certificates:'; es_ES = 'An error occurred when writing encryption certificates:'")
			+ Chars.LF + BriefErrorDescription(ErrorInformation));
	EndTry;
	
EndProcedure


&AtClient
Procedure ShowError(ErrorAtClient, ErrorAtServer)
	
	If Not IsOpen() AND ProcessingAfterWarning = Undefined Then
		Open();
	EndIf;
	
	DigitalSignatureInternalClient.ShowApplicationCallError(
		NStr("ru = 'Не удалось зашифровать данные'; en = 'Cannot encrypt data'; pl = 'Cannot encrypt data';de = 'Cannot encrypt data';ro = 'Cannot encrypt data';tr = 'Cannot encrypt data'; es_ES = 'Cannot encrypt data'"), "",
		ErrorAtClient, ErrorAtServer, , ProcessingAfterWarning);
	
EndProcedure

#EndRegion
