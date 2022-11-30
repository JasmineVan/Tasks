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
	
	DigitalSignatureInternal.SetSigningEncryptionDecryptionForm(ThisObject);
	
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
	
	If TypeOf(CertificatesFilter) = Type("ValueList") AND CertificatesFilter.Count() > 0 Then
		DigitalSignatureInternalClient.StartChooseCertificateAtSetFilter(ThisObject);
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("SelectedCertificate", Certificate);
	FormParameters.Insert("ToEncryptAndDecrypt", False);
	FormParameters.Insert("ReturnPassword", True);
	If TypeOf(CertificatesFilter) <> Type("ValueList") Then
		FormParameters.Insert("FilterByCompany", CertificatesFilter);
	EndIf;
	
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
	
EndProcedure

&AtClient
Procedure RememberPasswordOnChange(Item)
	
	DigitalSignatureInternalClient.ProcessPasswordInForm(ThisObject,
		InternalData, PasswordProperties, New Structure("OnChangeAttributeRememberPassword", True));
	
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
Procedure Sign(Command)
	
	If Not Items.Sign.Enabled Then
		Return;
	EndIf;
	
	DataDetails.Insert("UserClickedSignButton", True);
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	Items.Sign.Enabled = False;
	
	SignData(New NotifyDescription("SignCompletion", ThisObject));
	
EndProcedure

// Continues the Sign procedure.
&AtClient
Procedure SignCompletion(Result, Context) Export
	
	Items.Sign.Enabled = True;
	
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
		"ContinueOpeningAfterStart", ThisObject, Context), ThisObject, ClientParameters);
	
EndProcedure

// Continues the ContinueOpen procedure.
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
	
	If NoConfirmation
	   AND (    AdditionalParameters.PasswordSpecified
	      Or AdditionalParameters.StrongPrivateKeyProtection) Then
		
		ProcessingAfterWarning = Undefined;
		SignData(New NotifyDescription("ContinueOpeningAfterSignData", ThisObject, Context));
		Return;
	EndIf;
	
	Open();
	
	ContinueOpeningCompletion(Context);
	
EndProcedure

// Continues the ContinueOpening procedure.
&AtClient
Procedure ContinueOpeningAfterSignData(Result, Context) Export
	
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
Procedure PerformSigning(ClientParameters, CompletionProcessing) Export
// CAC:78-on: to securely pass data between forms on the client without sending them to the server.
	
	DigitalSignatureInternalClient.RefreshFormBeforeSecondUse(ThisObject, ClientParameters);
	
	DataDetails             = ClientParameters.DataDetails;
	ObjectForm               = ClientParameters.Form;
	CurrentPresentationsList = ClientParameters.CurrentPresentationsList;
	
	ProcessingAfterWarning = CompletionProcessing;
	
	Context = New Structure("CompletionProcessing", CompletionProcessing);
	SignData(New NotifyDescription("ExecuteSigningCompletion", ThisObject, Context));
	
EndProcedure

// Continues the ExecuteSigning procedure.
&AtClient
Procedure ExecuteSigningCompletion(Result, Context) Export
	
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
	
	DigitalSignatureInternal.CertificateOnChangeAtServer(ThisObject, CertificatesThumbprintsAtClient);
	
EndProcedure

&AtClient
Procedure SignData(Notification)
	
	Context = New Structure;
	Context.Insert("Notification", Notification);
	Context.Insert("ErrorAtClient", New Structure);
	Context.Insert("ErrorAtServer", New Structure);
	
	If CertificateExpiresOn < CommonClient.SessionDate() Then
		Context.ErrorAtClient.Insert("ErrorDescription",
			NStr("ru = 'У выбранного сертификата истек срок действия.
			           |Выберите другой сертификат.'; 
			           |en = 'The selected certificate has expired.
			           |Select a different certificate.'; 
			           |pl = 'The selected certificate has expired.
			           |Select a different certificate.';
			           |de = 'The selected certificate has expired.
			           |Select a different certificate.';
			           |ro = 'The selected certificate has expired.
			           |Select a different certificate.';
			           |tr = 'The selected certificate has expired.
			           |Select a different certificate.'; 
			           |es_ES = 'The selected certificate has expired.
			           |Select a different certificate.'"));
		ShowError(Context.ErrorAtClient, Context.ErrorAtServer);
		ExecuteNotifyProcessing(Context.Notification, False);
		Return;
	EndIf;
	
	If Not ValueIsFilled(CertificateApplication) Then
		Context.ErrorAtClient.Insert("ErrorDescription",
			NStr("ru = 'У выбранного сертификата не указана программа для закрытого ключа.
			           |Выберите другой сертификат.'; 
			           |en = 'Application for the private key of the selected certificate is not specified.
			           |Select another certificate.'; 
			           |pl = 'Application for the private key of the selected certificate is not specified.
			           |Select another certificate.';
			           |de = 'Application for the private key of the selected certificate is not specified.
			           |Select another certificate.';
			           |ro = 'Application for the private key of the selected certificate is not specified.
			           |Select another certificate.';
			           |tr = 'Application for the private key of the selected certificate is not specified.
			           |Select another certificate.'; 
			           |es_ES = 'Application for the private key of the selected certificate is not specified.
			           |Select another certificate.'"));
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
			"SignDataAfterProcesssingBeforeExecute", ThisObject, Context));
		
		ExecuteNotifyProcessing(DataDetails.BeforeExecute, ExecutionParameters);
	Else
		SignDataAfterProcesssingBeforeExecute(New Structure, Context);
	EndIf;
	
EndProcedure

// Continues the SignData procedure.
&AtClient
Procedure SignDataAfterProcesssingBeforeExecute(Result, Context) Export
	
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
	
	DigitalSignatureInternalClient.CheckCertificate(New NotifyDescription(
			"SignDataAfterCertificateCheck", ThisObject, Context),
		CertificateAddress,,, False);
	
EndProcedure

// Continues the SignData procedure.
&AtClient
Procedure SignDataAfterCertificateCheck(Result, Context) Export
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("DataDetails",     DataDetails);
	ExecutionParameters.Insert("Form",              ThisObject);
	ExecutionParameters.Insert("FormID", Context.FormID);
	ExecutionParameters.Insert("PasswordValue",     PasswordProperties.Value);
	ExecutionParameters.Insert("CertificateValid",    ?(Result = Undefined, Result, Result = True));
	ExecutionParameters.Insert("CertificateAddress",    CertificateAddress);
	
	ExecutionParameters.Insert("FullDataPresentation",
		DigitalSignatureInternalClient.FullDataPresentation(ThisObject));
	
	ExecutionParameters.Insert("CurrentPresentationsList", CurrentPresentationsList);
	
	Context.Insert("ExecutionParameters", ExecutionParameters);
	
	If DigitalSignatureClient.GenerateDigitalSignaturesAtServer() Then
		If ValueIsFilled(CertificateAtServerErrorDescription) Then
			Result = New Structure("Error", CertificateAtServerErrorDescription);
			CertificateAtServerErrorDescription = New Structure;
			SignDataAfterExecutionAtServerSide(Result, Context);
		Else
			// An attempt to sign on the server.
			DigitalSignatureInternalClient.ExecuteAtSide(New NotifyDescription(
					"SignDataAfterExecutionAtServerSide", ThisObject, Context),
				"Signing", "AtServerSide", Context.ExecutionParameters);
		EndIf;
	Else
		SignDataAfterExecutionAtServerSide(Undefined, Context);
	EndIf;
	
EndProcedure

// Continues the SignData procedure.
&AtClient
Procedure SignDataAfterExecutionAtServerSide(Result, Context) Export
	
	If Result <> Undefined Then
		SignDataAfterExecute(Result);
	EndIf;
	
	If Result <> Undefined AND Not Result.Property("Error") Then
		SignDataAfterExecutionAtClientSide(New Structure, Context);
	Else
		If Result <> Undefined Then
			Context.ErrorAtServer = Result.Error;
		EndIf;
		
		// An attempt to sign on the client.
		DigitalSignatureInternalClient.ExecuteAtSide(New NotifyDescription(
				"SignDataAfterExecutionAtClientSide", ThisObject, Context),
			"Signing", "OnClientSide", Context.ExecutionParameters);
	EndIf;
	
EndProcedure

// Continues the SignData procedure.
&AtClient
Procedure SignDataAfterExecutionAtClientSide(Result, Context) Export
	
	SignDataAfterExecute(Result);
	
	If Result.Property("Error") Then
		Context.ErrorAtClient = Result.Error;
		UnsignedData = DigitalSignatureInternalClient.CurrentDataItemProperties(
			Context.ExecutionParameters);
		ShowError(Context.ErrorAtClient, Context.ErrorAtServer, UnsignedData);
		ExecuteNotifyProcessing(Context.Notification, False);
		Return;
	EndIf;
	
	If ValueIsFilled(DataPresentation)
	   AND (Not DataDetails.Property("NotifyOnCompletion")
	      Or DataDetails.NotifyOnCompletion <> False) Then
		
		DigitalSignatureClient.ObjectSigningInfo(
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

// Continues the SignData procedure.
&AtClient
Procedure SignDataAfterExecute(Result)
	
	If Result.Property("OperationStarted") Then
		DigitalSignatureInternalClient.ProcessPasswordInForm(ThisObject, InternalData,
			PasswordProperties, New Structure("OnOperationSuccess", True));
	EndIf;
	
	If Result.Property("HasProcessedDataItems") Then
		// You cannot change a certificate once signing starts, otherwise, the data set will be processed 
		// differently.
		Items.Certificate.ReadOnly = True;
		Items.Comment.ReadOnly = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure ShowError(ErrorAtClient, ErrorAtServer, UnsignedData = Undefined)
	
	If Not IsOpen() AND ProcessingAfterWarning = Undefined Then
		Open();
	EndIf;
	
	AdditionalParameters = New Structure;
	If UnsignedData <> Undefined Then
		AdditionalParameters.Insert("UnsignedData", UnsignedData);
	EndIf;
	
	DigitalSignatureInternalClient.ShowApplicationCallError(
		NStr("ru = 'Не удалось подписать данные'; en = 'Cannot sign data'; pl = 'Cannot sign data';de = 'Cannot sign data';ro = 'Cannot sign data';tr = 'Cannot sign data'; es_ES = 'Cannot sign data'"), "", 
		ErrorAtClient, ErrorAtServer, AdditionalParameters, ProcessingAfterWarning);
	
EndProcedure

#EndRegion
