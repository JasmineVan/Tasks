///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	DigitalSignatureInternal.SetPasswordEntryNote(ThisObject,
		Items.StrongPrivateKeyProtection.Name);
	
	If Not ValueIsFilled(Object.Ref) Then
		Return;
	EndIf;
	
	If Metadata.DataProcessors.Find("ApplicationForNewQualifiedCertificateIssue") <> Undefined Then
		ProcessingApplicationForNewQualifiedCertificateIssue =
			Common.ObjectManagerByFullName(
				"DataProcessor.ApplicationForNewQualifiedCertificateIssue");
		ProcessingApplicationForNewQualifiedCertificateIssue.OnCreateAtServer(
			Object, OpenRequest);
		RequestFormName = "DataProcessor.ApplicationForNewQualifiedCertificateIssue.Form.Form";
		CanOpenRequest = True;
	EndIf;
	
	HasCompanies = Not Metadata.DefinedTypes.Company.Type.ContainsType(Type("String"));
	OnCreateAtServerOnReadAtServer();
	
	If Items.FieldsAutoPopulatedFromCertificateData.Visible Then
		StandardSubsystemsServer.SetFormAssignmentKey(ThisObject, "CustomCertificate");
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Not ValueIsFilled(Object.Ref) Then
		Cancel = True;
		StandardSubsystemsClient.SetFormStorageOption(ThisObject, True);
		AttachIdleHandler("IdleHandlerAddCertificate", 0.1, True);
		Return;
		
	ElsIf OpenRequest Then
		Cancel = True;
		StandardSubsystemsClient.SetFormStorageOption(ThisObject, True);
		AttachIdleHandler("IdleHandlerOpenApplication", 0.1, True);
		Return;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	If CertificateAddress <> Undefined Then
		OnCreateAtServerOnReadAtServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	WriteParameters.Insert("IsNew", Not ValueIsFilled(Object.Ref));
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	AdditionalParameters = New Structure;
	If WriteParameters.IsNew Then
		AdditionalParameters.Insert("IsNew");
	EndIf;
	
	Notify("Write_DigitalSignatureAndEncryptionKeyCertificates", AdditionalParameters, Object.Ref);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// Checking description for uniqueness.
	If Not Items.Description.ReadOnly Then
		DigitalSignatureInternal.CheckPresentationUniqueness(
			Object.Description, Object.Ref, "Object.Description", Cancel);
	EndIf;
	
	If TypeOf(AttributesParameters) <> Type("Structure") Then
		Return;
	EndIf;
	
	For each KeyAndValue In AttributesParameters Do
		AttributeName = KeyAndValue.Key;
		Properties     = KeyAndValue.Value;
		
		If Not Properties.FillChecking
		 Or ValueIsFilled(Object[AttributeName]) Then
			
			Continue;
		EndIf;
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Поле %1 не заполнено.'; en = 'The ""%1"" field is not filled in.'; pl = 'The ""%1"" field is not filled in.';de = 'The ""%1"" field is not filled in.';ro = 'The ""%1"" field is not filled in.';tr = 'The ""%1"" field is not filled in.'; es_ES = 'The ""%1"" field is not filled in.'"),
			Items[AttributeName].Title);
		
		Common.MessageToUser(MessageText,, AttributeName,, Cancel);
	EndDo;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure ShowAutoPopulatedAttributes(Command)
	
	Show = Not Items.FormShowAutoPopulatedAttributes.Check;
	
	Items.FormShowAutoPopulatedAttributes.Check = Show;
	Items.FieldsAutoPopulatedFromCertificateData.Visible = Show;
	
	If HasCompanies Then
		Items.Company.Visible = Show;
	EndIf;
	
EndProcedure

&AtClient
Procedure ShowCertificateData(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("OpeningFromCertificateItemForm");
	FormParameters.Insert("CertificateAddress", CertificateAddress);
	
	OpenForm("CommonForm.Certificate", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure ShowCertificateApplication(Command)
	
	If CanOpenRequest Then
		FormParameters = New Structure;
		FormParameters.Insert("CertificateReference", Object.Ref);
		OpenForm(RequestFormName, FormParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckCertificate(Command)
	
	If Not ValueIsFilled(Object.Ref) Then
		ShowMessageBox(, NStr("ru = 'Сертификат еще не записан.'; en = 'Certificate has not been recorded yet.'; pl = 'Certificate has not been recorded yet.';de = 'Certificate has not been recorded yet.';ro = 'Certificate has not been recorded yet.';tr = 'Certificate has not been recorded yet.'; es_ES = 'Certificate has not been recorded yet.'"));
		Return;
	EndIf;
	
	If Modified AND Not Write() Then
		Return;
	EndIf;
	
	DigitalSignatureClient.CheckCatalogCertificate(Object.Ref,
		New Structure("NoConfirmation", True));
	
EndProcedure

&AtClient
Procedure SaveCertificateDataToFile(Command)
	
	DigitalSignatureInternalClient.SaveCertificate(Undefined, CertificateAddress);
	
EndProcedure

&AtClient
Procedure CertificateRevoked(Command)
	
	Object.Revoked = Not Object.Revoked;
	Items.FormCertificateRevoked.Check = Object.Revoked;
	
	If Object.Revoked Then
		ShowMessageBox(, NStr("ru = 'После записи отменить отзыв будет невозможно.'; en = 'After writing, callback cannot be canceled.'; pl = 'After writing, callback cannot be canceled.';de = 'After writing, callback cannot be canceled.';ro = 'After writing, callback cannot be canceled.';tr = 'After writing, callback cannot be canceled.'; es_ES = 'After writing, callback cannot be canceled.'"));
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure OnCreateAtServerOnReadAtServer()
	
	If Metadata.DataProcessors.Find("ApplicationForNewQualifiedCertificateIssue") <> Undefined Then
		ProcessingApplicationForNewQualifiedCertificateIssue =
			Common.ObjectManagerByFullName(
				"DataProcessor.ApplicationForNewQualifiedCertificateIssue");
		ProcessingApplicationForNewQualifiedCertificateIssue.OnCreateAtServerOnReadAtServer(
			Object, Items);
	EndIf;
	
	CertificateBinaryData = Common.ObjectAttributeValue(
		Object.Ref, "CertificateData").Get();
	
	If TypeOf(CertificateBinaryData) = Type("BinaryData") Then
		Certificate = New CryptoCertificate(CertificateBinaryData);
		If ValueIsFilled(CertificateAddress) Then
			PutToTempStorage(CertificateBinaryData, CertificateAddress);
		Else
			CertificateAddress = PutToTempStorage(CertificateBinaryData, UUID);
		EndIf;
		DigitalSignatureInternalClientServer.FillCertificateDataDetails(CertificateDataDetails,
			DigitalSignature.CertificateProperties(Certificate));
	Else
		CertificateAddress = "";
		Items.ShowCertificateData.Enabled  = False;
		Items.FormCheckCertificate.Enabled = ValueIsFilled(CertificateBinaryData);
		Items.FormSaveCertificateDataToFile.Enabled = False;
		Items.FieldsAutoPopulatedFromCertificateData.Visible = True;
		Items.FormShowAutoPopulatedAttributes.Check = True;
		If ValueIsFilled(CertificateBinaryData) Then
			// Supporting display of main properties of non-standard certificates (iBank2 system).
			DigitalSignatureInternalClientServer.FillCertificateDataDetails(CertificateDataDetails, Object);
		EndIf;
	EndIf;
	
	Items.FormCertificateRevoked.Check = Object.Revoked;
	If Object.Revoked Then
		Items.FormCertificateRevoked.Enabled = False;
	EndIf;
	
	If Not Users.IsFullUser() Then
		If Object.Added      <> Users.CurrentUser()
		   AND Object.User <> Users.CurrentUser() Then
			// Standard users can change only their own certificates.
			ReadOnly = True;
		Else
			// Standard users cannot change access rights.
			Items.Added.ReadOnly = True;
			If Object.Added <> Users.CurrentUser() Then
				// Standard users cannot change the User attribute if they did not add the certificate.
				// 
				Items.User.ReadOnly = True;
			EndIf;
		EndIf;
	EndIf;
	
	HasCompanies = Not Metadata.DefinedTypes.Company.Type.ContainsType(Type("String"));
	Items.Company.Visible = HasCompanies;
	
	If Not ValueIsFilled(CertificateAddress) Then
		Return; // Certificate = Undefined.
	EndIf;
	
	SubjectProperties = DigitalSignature.CertificateSubjectProperties(Certificate);
	If SubjectProperties.LastName <> Undefined Then
		Items.LastName.ReadOnly = True;
	EndIf;
	If SubjectProperties.Name <> Undefined Then
		Items.Name.ReadOnly = True;
	EndIf;
	If SubjectProperties.Property("MiddleName") AND SubjectProperties.MiddleName <> Undefined Then
		Items.MiddleName.ReadOnly = True;
	EndIf;
	If SubjectProperties.Company <> Undefined Then
		Items.Firm.ReadOnly = True;
	EndIf;
	If SubjectProperties.Property("JobPosition") AND SubjectProperties.JobPosition <> Undefined Then
		Items.JobPosition.ReadOnly = True;
	EndIf;
	
	AttributesParameters = Undefined;
	DigitalSignatureInternal.BeforeStartEditKeyCertificate(
		Object.Ref, Certificate, AttributesParameters);
	
	For each KeyAndValue In AttributesParameters Do
		AttributeName = KeyAndValue.Key;
		Properties     = KeyAndValue.Value;
		
		If Not Properties.Visible Then
			Items[AttributeName].Visible = False;
			
		ElsIf Properties.ReadOnly Then
			Items[AttributeName].ReadOnly = True
		EndIf;
		If Properties.FillChecking Then
			Items[AttributeName].AutoMarkIncomplete = True;
		EndIf;
	EndDo;
	
	Items.FieldsAutoPopulatedFromCertificateData.Visible =
		    Not Items.LastName.ReadOnly   AND Not ValueIsFilled(Object.LastName)
		Or Not Items.Name.ReadOnly       AND Not ValueIsFilled(Object.Name)
		Or Not Items.MiddleName.ReadOnly  AND Not ValueIsFilled(Object.MiddleName);
	
	Items.FormShowAutoPopulatedAttributes.Check =
		Items.FieldsAutoPopulatedFromCertificateData.Visible;
	
EndProcedure

&AtClient
Procedure IdleHandlerAddCertificate()
	
	StandardSubsystemsClient.SetFormStorageOption(ThisObject, False);
	
	CreationParameters = New Structure;
	CreationParameters.Insert("ToPersonalList", True);
	CreationParameters.Insert("Company", Object.Company);
	CreationParameters.Insert("HideApplication", False);
	
	DigitalSignatureInternalClient.AddCertificate(CreationParameters);
	
EndProcedure

&AtClient
Procedure IdleHandlerOpenApplication()
	
	StandardSubsystemsClient.SetFormStorageOption(ThisObject, False);
	
	If CanOpenRequest Then
		FormParameters = New Structure;
		FormParameters.Insert("CertificateReference", Object.Ref);
		OpenForm(RequestFormName, FormParameters);
	EndIf;
	
EndProcedure

#EndRegion
