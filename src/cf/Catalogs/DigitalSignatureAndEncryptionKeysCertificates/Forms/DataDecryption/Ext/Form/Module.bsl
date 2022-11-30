///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var InternalData, PasswordProperties, DataDetails, ObjectForm, ProcessingAfterWarning, CurrentPresentationsList;

#EndRegion

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	DigitalSignatureInternal.SetPasswordEntryNote(ThisObject, ,
		Items.AdvancedPasswordNote.Name);
	
	DigitalSignatureInternal.SetSigningEncryptionDecryptionForm(ThisObject, , True);
	
	AllowRememberPassword = Parameters.AllowRememberPassword;
	IsAuthentication = Parameters.IsAuthentication;
	
	If IsAuthentication Then
		Items.FormDecrypt.Title = NStr("ru = 'ОК'; en = 'OK'; pl = 'OK';de = 'OK';ro = 'OK';tr = 'OK'; es_ES = 'OK'");
		Items.AdvancedPasswordNote.Title = NStr("ru = 'Нажмите ОК, чтобы перейти к вводу пароля.'; en = 'Click OK to enter the password.'; pl = 'Click OK to enter the password.';de = 'Click OK to enter the password.';ro = 'Click OK to enter the password.';tr = 'Click OK to enter the password.'; es_ES = 'Click OK to enter the password.'");
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
	
	DigitalSignatureInternalClient.ProcessPasswordInForm(ThisObject, InternalData, PasswordProperties);
	
EndProcedure

&AtClient
Procedure CertificateStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	If CertificatesFilter.Count() > 0 Then
		DigitalSignatureInternalClient.StartChooseCertificateAtSetFilter(ThisObject);
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("SelectedCertificate", Certificate);
	FormParameters.Insert("ToEncryptAndDecrypt", True);
	FormParameters.Insert("ReturnPassword", True);
	
	DigitalSignatureInternalClient.SelectSigningOrDecryptionCertificate(FormParameters, Item);
	
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
	
	If ValueSelected = True Then
		Certificate = InternalData["SelectedCertificate"];
		InternalData.Delete("SelectedCertificate");
		
	ElsIf ValueSelected = False Then
		Certificate = Undefined;
		
	ElsIf TypeOf(ValueSelected) = Type("String") Then
		FormParameters = New Structure;
		FormParameters.Insert("SelectedCertificateThumbprint", ValueSelected);
		FormParameters.Insert("ToEncryptAndDecrypt", True);
		FormParameters.Insert("ReturnPassword", True);
		
		DigitalSignatureInternalClient.SelectSigningOrDecryptionCertificate(FormParameters, Item);
		Return;
	Else
		Certificate = ValueSelected;
	EndIf;
	
	DigitalSignatureInternalClient.GetCertificatesThumbprintsAtClient(
		New NotifyDescription("CertificateChoiceProcessingCompletion", ThisObject, ValueSelected));
	
EndProcedure

// Continues the CertificateChoiceProcessing procedure.
&AtClient
Procedure CertificateChoiceProcessingCompletion(CertificatesThumbprintsAtClient, SelectedValue) Export
	
	CertificateOnChangeAtServer(CertificatesThumbprintsAtClient);
	
	If SelectedValue = True
	   AND InternalData["SelectedCertificatePassword"] <> Undefined Then
		
		DigitalSignatureInternalClient.ProcessPasswordInForm(ThisObject,
			InternalData, PasswordProperties,, InternalData["SelectedCertificatePassword"]);
		InternalData.Delete("SelectedCertificatePassword");
		Items.RememberPassword.ReadOnly = False;
	Else
		DigitalSignatureInternalClient.ProcessPasswordInForm(ThisObject, InternalData, PasswordProperties);
	EndIf;
	
EndProcedure

&AtClient
Procedure CertificateAutoComplete(Item, Text, ChoiceData, Parameters, Waiting, StandardProcessing)
	
	DigitalSignatureInternalClient.CertificatePickupFromSelectionList(ThisObject, Text, ChoiceData, StandardProcessing);
	
EndProcedure

&AtClient
Procedure CertificateTextEditEnd(Item, Text, ChoiceData, Parameters, StandardProcessing)
	
	DigitalSignatureInternalClient.CertificatePickupFromSelectionList(ThisObject, Text, ChoiceData, StandardProcessing);
	
EndProcedure

&AtClient
Procedure PasswordOnChange(Item)
	
	DigitalSignatureInternalClient.ProcessPasswordInForm(ThisObject,
		InternalData, PasswordProperties, New Structure("OnChangeAttributePassword", True));
	
	If Not AllowRememberPassword
	   AND Not RememberPassword
	   AND Not PasswordProperties.PasswordVerified Then
		
		Items.RememberPassword.ReadOnly = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure RememberPasswordOnChange(Item)
	
	DigitalSignatureInternalClient.ProcessPasswordInForm(ThisObject,
		InternalData, PasswordProperties, New Structure("OnChangeAttributeRememberPassword", True));
	
	If Not AllowRememberPassword
	   AND Not RememberPassword
	   AND Not PasswordProperties.PasswordVerified Then
		
		Items.RememberPassword.ReadOnly = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure SpecifiedPasswordNoteClick(Item)
	
	DigitalSignatureInternalClient.SpecifiedPasswordNoteClick(ThisObject, Item, PasswordProperties);
	
EndProcedure

&AtClient
Procedure SpecifiedPasswordNoteExtendedTooltipURLProcessing(Item, URL, StandardProcessing)
	
	DigitalSignatureInternalClient.SpecifiedPasswordNoteURLProcessing(
		ThisObject, Item, URL, StandardProcessing, PasswordProperties);
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Decrypt(Command)
	
	If Not Items.FormDecrypt.Enabled Then
		Return;
	EndIf;
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	Items.FormDecrypt.Enabled = False;
	
	DecryptData(New NotifyDescription("DecryptCompletion", ThisObject));
	
EndProcedure

// Continues the Decrypt procedure.
&AtClient
Procedure DecryptCompletion(Result, Context) Export
	
	Items.FormDecrypt.Enabled = True;
	
	If Result = True Then
		Close(True);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ContinueOpening(Notification, CommonInternalData, ClientParameters) Export
	
	If ClientParameters = InternalData Then
		ClientParameters = New Structure("Certificate, PasswordProperties", Certificate, PasswordProperties);
		Return;
	EndIf;
	
	If ClientParameters.Property("SpecifiedContextOfOtherOperation") Then
		CertificateProperties = CommonInternalData;
		ClientParameters.DataDetails.OperationContext.ContinueOpening(Undefined, Undefined, CertificateProperties);
		If CertificateProperties.Certificate = Certificate Then
			PasswordProperties = CertificateProperties.PasswordProperties;
		EndIf;
	EndIf;
	
	DataDetails             = ClientParameters.DataDetails;
	ObjectForm               = ClientParameters.Form;
	CurrentPresentationsList = ClientParameters.CurrentPresentationsList;
	
	InternalData = CommonInternalData;
	Context = New Structure("Notification", Notification);
	Notification = New NotifyDescription("ContinueOpening", ThisObject);
	
	DigitalSignatureInternalClient.ContinueOpeningStart(New NotifyDescription(
		"ContinueOpeningAfterStart", ThisObject, Context), ThisObject, ClientParameters,, True);
	
EndProcedure

// Continues the ContinueOpening procedure.
&AtClient
Procedure ContinueOpeningAfterStart(Result, Context) Export
	
	If Result <> True Then
		ContinueOpeningCompletion(Context);
		Return;
	EndIf;
	
	AdditionalParameters = New Structure;
	If PasswordProperties <> Undefined Then
		AdditionalParameters.Insert("OnSetPasswordFromAnotherOperation", True);
	EndIf;
	DigitalSignatureInternalClient.ProcessPasswordInForm(ThisObject,
		InternalData, PasswordProperties, AdditionalParameters);
	
	If Not AllowRememberPassword
	   AND Not RememberPassword
	   AND Not PasswordProperties.PasswordVerified Then
		
		Items.RememberPassword.ReadOnly = True;
	EndIf;
	
	If NoConfirmation
	   AND (    AdditionalParameters.PasswordSpecified
	      Or AdditionalParameters.StrongPrivateKeyProtection) Then
	
		ProcessingAfterWarning = Undefined;
		DecryptData(New NotifyDescription("ContinueOpeningAfterDataDecryption", ThisObject, Context));
		Return;
	EndIf;
	
	Open();
	
	ContinueOpeningCompletion(Context);
	
EndProcedure

// Continues the ContinueOpening procedure.
&AtClient
Procedure ContinueOpeningAfterDataDecryption(Result, Context) Export
	
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
Procedure ExecuteDecryption(ClientParameters, CompletionProcessing) Export
// CAC:78-on: to securely pass data between forms on the client without sending them to the server.
	
	DigitalSignatureInternalClient.RefreshFormBeforeSecondUse(ThisObject, ClientParameters);
	
	DataDetails             = ClientParameters.DataDetails;
	ObjectForm               = ClientParameters.Form;
	CurrentPresentationsList = ClientParameters.CurrentPresentationsList;
	
	ProcessingAfterWarning = CompletionProcessing;
	
	Context = New Structure("CompletionProcessing", CompletionProcessing);
	DecryptData(New NotifyDescription("ExecuteEncryptionCompletion", ThisObject, Context));
	
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
	
	DigitalSignatureInternalClient.ProcessPasswordInForm(ThisObject,
		InternalData, PasswordProperties, New Structure("OnChangeCertificateProperties", True));
	
EndProcedure

&AtServer
Procedure CertificateOnChangeAtServer(CertificatesThumbprintsAtClient, CheckRef = False)
	
	If CheckRef
	   AND ValueIsFilled(Certificate)
	   AND Common.ObjectAttributeValue(Certificate, "Ref") <> Certificate Then
		
		Certificate = Undefined;
	EndIf;
	
	DigitalSignatureInternal.CertificateOnChangeAtServer(ThisObject, CertificatesThumbprintsAtClient,, True);
	
EndProcedure

&AtClient
Procedure DecryptData(Notification)
	
	Context = New Structure;
	Context.Insert("Notification", Notification);
	Context.Insert("ErrorAtClient", New Structure);
	Context.Insert("ErrorAtServer", New Structure);
	
	If Not ValueIsFilled(CertificateApplication) Then
		Context.ErrorAtClient.Insert("ErrorDescription",
			NStr("ru = 'У выбранного сертификата не указана программа для закрытого ключа.
			           |Выберите сертификат повторно из полного списка или
			           |откройте сертификат и укажите программу вручную.'; 
			           |en = 'Application for the private key of the selected certificate is not specified.
			           |Select the certificate from the full list again 
			           |or open the certificate and specify the application manually.'; 
			           |pl = 'Application for the private key of the selected certificate is not specified.
			           |Select the certificate from the full list again 
			           |or open the certificate and specify the application manually.';
			           |de = 'Application for the private key of the selected certificate is not specified.
			           |Select the certificate from the full list again 
			           |or open the certificate and specify the application manually.';
			           |ro = 'Application for the private key of the selected certificate is not specified.
			           |Select the certificate from the full list again 
			           |or open the certificate and specify the application manually.';
			           |tr = 'Application for the private key of the selected certificate is not specified.
			           |Select the certificate from the full list again 
			           |or open the certificate and specify the application manually.'; 
			           |es_ES = 'Application for the private key of the selected certificate is not specified.
			           |Select the certificate from the full list again 
			           |or open the certificate and specify the application manually.'"));
		ShowError(Context.ErrorAtClient, Context.ErrorAtServer);
		ExecuteNotifyProcessing(Context.Notification, False);
		Return;
	EndIf;
	
	SelectedCertificate = New Structure;
	SelectedCertificate.Insert("Ref",    Certificate);
	SelectedCertificate.Insert("Thumbprint", CertificateThumbprint);
	SelectedCertificate.Insert("Data",    CertificateAddress);
	DataDetails.Insert("SelectedCertificate", SelectedCertificate);
	
	If DataDetails.Property("BeforeExecute")
	   AND TypeOf(DataDetails.BeforeExecute) = Type("NotifyDescription") Then
		
		ExecutionParameters = New Structure;
		ExecutionParameters.Insert("DataDetails", DataDetails);
		ExecutionParameters.Insert("Notification", New NotifyDescription(
			"DecryptDataAfterProcessingBeforeExecute", ThisObject, Context));
		
		ExecuteNotifyProcessing(DataDetails.BeforeExecute, ExecutionParameters);
	Else
		DecryptDataAfterProcessingBeforeExecute(New Structure, Context);
	EndIf;
	
EndProcedure

// Continues the DecryptData procedure.
&AtClient
Procedure DecryptDataAfterProcessingBeforeExecute(Result, Context) Export
	
	If Result.Property("ErrorDescription") Then
		ShowError(New Structure("ErrorDescription", Result.ErrorDescription), New Structure);
		Return;
	EndIf;
	
	Context.Insert("FormID", UUID);
	If TypeOf(ObjectForm) = Type("ManagedForm") Then
		Context.FormID = ObjectForm.UUID;
	ElsIf TypeOf(ObjectForm) = Type("UUID") Then
		Context.FormID = ObjectForm;
	EndIf;
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("DataDetails",     DataDetails);
	ExecutionParameters.Insert("Form",              ThisObject);
	ExecutionParameters.Insert("FormID", Context.FormID);
	ExecutionParameters.Insert("PasswordValue",     PasswordProperties.Value);
	Context.Insert("ExecutionParameters", ExecutionParameters);
	
	If DigitalSignatureClient.GenerateDigitalSignaturesAtServer() Then
		If ValueIsFilled(CertificateAtServerErrorDescription) Then
			Result = New Structure("Error", CertificateAtServerErrorDescription);
			CertificateAtServerErrorDescription = New Structure;
			DecryptDataAfterExecuteAtServerSide(Result, Context);
		Else
			// An attempt to encrypt on the server.
			DigitalSignatureInternalClient.ExecuteAtSide(New NotifyDescription(
					"DecryptDataAfterExecuteAtServerSide", ThisObject, Context),
				"Details", "AtServerSide", Context.ExecutionParameters);
		EndIf;
	Else
		DecryptDataAfterExecuteAtServerSide(Undefined, Context);
	EndIf;
	
	
EndProcedure

// Continues the DecryptData procedure.
&AtClient
Procedure DecryptDataAfterExecuteAtServerSide(Result, Context) Export
	
	If Result <> Undefined Then
		DecryptDataAfterExecute(Result);
	EndIf;
	
	If Result <> Undefined AND Not Result.Property("Error") Then
		DecryptDataAfterExecuteAtClientSide(New Structure, Context);
	Else
		If Result <> Undefined Then
			Context.ErrorAtServer = Result.Error;
		EndIf;
		
		// An attempt to sign on the client.
		DigitalSignatureInternalClient.ExecuteAtSide(New NotifyDescription(
				"DecryptDataAfterExecuteAtClientSide", ThisObject, Context),
			"Details", "OnClientSide", Context.ExecutionParameters);
	EndIf;
	
EndProcedure

// Continues the DecryptData procedure.
&AtClient
Procedure DecryptDataAfterExecuteAtClientSide(Result, Context) Export
	
	DecryptDataAfterExecute(Result);
	
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
	
	If Not IsAuthentication
	   AND ValueIsFilled(DataPresentation)
	   AND (Not DataDetails.Property("NotifyOnCompletion")
	      Or DataDetails.NotifyOnCompletion <> False) Then
		
		DigitalSignatureClient.InformOfObjectDecryption(
			DigitalSignatureInternalClient.FullDataPresentation(ThisObject),
			CurrentPresentationsList.Count() > 1);
	EndIf;
	
	If DataDetails.Property("OperationContext") Then
		DataDetails.OperationContext = ThisObject;
	EndIf;
	
	ExecuteNotifyProcessing(Context.Notification, True);
	
EndProcedure

// Continues the DecryptData procedure.
&AtClient
Procedure DecryptDataAfterExecute(Result)
	
	If Result.Property("OperationStarted") Then
		DigitalSignatureInternalClient.ProcessPasswordInForm(ThisObject, InternalData,
			PasswordProperties, New Structure("OnOperationSuccess", True));
	EndIf;
	
EndProcedure

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
	
	Error = New Structure;
	WriteEncryptionCertificatesAtServer(ObjectsDetails, FormID, Error);
	
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
Procedure WriteEncryptionCertificatesAtServer(ObjectsDetails, FormID, Error)
	
	EncryptionCertificates = New Array;
	
	BeginTransaction();
	Try
		For each ObjectDetails In ObjectsDetails Do
			DigitalSignature.WriteEncryptionCertificates(ObjectDetails.Ref,
				EncryptionCertificates, FormID, ObjectDetails.Version);
		EndDo;
		CommitTransaction();
	Except
		RollbackTransaction();
		ErrorInformation = ErrorInfo();
		Error.Insert("ErrorDescription", NStr("ru = 'При очистке сертификатов шифрования возникла ошибка:'; en = 'An error occurred during the encryption certificate cleanup:'; pl = 'An error occurred during the encryption certificate cleanup:';de = 'An error occurred during the encryption certificate cleanup:';ro = 'An error occurred during the encryption certificate cleanup:';tr = 'An error occurred during the encryption certificate cleanup:'; es_ES = 'An error occurred during the encryption certificate cleanup:'")
			+ Chars.LF + BriefErrorDescription(ErrorInformation));
	EndTry;
	
EndProcedure


&AtClient
Procedure ShowError(ErrorAtClient, ErrorAtServer)
	
	If Not IsOpen() AND ProcessingAfterWarning = Undefined Then
		Open();
	EndIf;
	
	DigitalSignatureInternalClient.ShowApplicationCallError(
		NStr("ru = 'Не удалось расшифровать данные'; en = 'Cannot decrypt data'; pl = 'Cannot decrypt data';de = 'Cannot decrypt data';ro = 'Cannot decrypt data';tr = 'Cannot decrypt data'; es_ES = 'Cannot decrypt data'"), "",
		ErrorAtClient, ErrorAtServer, , ProcessingAfterWarning);
	
EndProcedure

#EndRegion
