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
	
	CertificateAttributeParameters = New Structure;
	If Parameters.Property("Company") Then
		CertificateAttributeParameters.Insert("Company", Parameters.Company);
	EndIf;
	
	If ValueIsFilled(Parameters.CertificateDataAddress) Then
		CertificateData = GetFromTempStorage(Parameters.CertificateDataAddress);
		
		CryptoCertificate = DigitalSignatureInternal.CertificateFromBinaryData(CertificateData);
		If CryptoCertificate = Undefined Then
			Cancel = True;
			Return;
		EndIf;
		
		ShowCertificatePropertiesAdjustmentPage(ThisObject,
			CryptoCertificate,
			CryptoCertificate.Unload(),
			DigitalSignature.CertificateProperties(CryptoCertificate));
		
		Items.Back.Visible = False;
	Else
		If DigitalSignature.GenerateDigitalSignaturesAtServer() Then
			Items.CertificatesGroup.Title =
				NStr("ru = 'Личные сертификаты на компьютере и сервере'; en = 'Personal certificates on computer and on server'; pl = 'Personal certificates on computer and on server';de = 'Personal certificates on computer and on server';ro = 'Personal certificates on computer and on server';tr = 'Personal certificates on computer and on server'; es_ES = 'Personal certificates on computer and on server'");
		EndIf;
		
		ErrorOnGetCertificatesAtClient = Parameters.ErrorOnGetCertificatesAtClient;
		UpdateCertificatesListAtServer(Parameters.CertificatesPropertiesAtClient);
	EndIf;
	
	If Metadata.DefinedTypes.Company.Type.ContainsType(Type("String")) Then
		Items.CertificateCompany.Visible = False;
	Else
		CompanyTypeToDefineConfigured = True;
	EndIf;
	
	Items.CertificateUser.ToolTip =
		Metadata.Catalogs.DigitalSignatureAndEncryptionKeysCertificates.Attributes.User.ToolTip;
	
	Items.CertificateCompany.ToolTip =
		Metadata.Catalogs.DigitalSignatureAndEncryptionKeysCertificates.Attributes.Company.ToolTip;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If ValueIsFilled(Certificate) Then
		Cancel = True;
		Return;
	EndIf;
	
	If ValueIsFilled(CertificateAddress) Then
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If Upper(EventName) = Upper("Write_DigitalSignatureAndEncryptionSoftware")
	 Or Upper(EventName) = Upper("Write_PathToDigitalSignatureAndEncryptionSoftwareAtServer") Then
		
		RefreshReusableValues();
		If Items.Back.Visible Then
			UpdateCertificatesList();
		EndIf;
		Return;
	EndIf;
	
	If Upper(EventName) = Upper("Write_DigitalSignatureAndEncryptionKeyCertificates") Then
		UpdateCertificatesList();
		Return;
	EndIf;
	
	If Upper(EventName) = Upper("Install_CryptoExtension") Then
		UpdateCertificatesList();
		Return;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// Checking description for uniqueness.
	DigitalSignatureInternal.CheckPresentationUniqueness(
		CertificateDescription, Certificate, "CertificateDescription", Cancel);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CertificatesUnavailableAtClientLabelClick(Item)
	
	DigitalSignatureInternalClient.ShowApplicationCallError(
		NStr("ru = 'Сертификаты на компьютере'; en = 'Certificates on computer'; pl = 'Certificates on computer';de = 'Certificates on computer';ro = 'Certificates on computer';tr = 'Certificates on computer'; es_ES = 'Certificates on computer'"), "", ErrorOnGetCertificatesAtClient, New Structure);
	
EndProcedure

&AtClient
Procedure CertificatesUnavailableAtServerLabelClick(Item)
	
	DigitalSignatureInternalClient.ShowApplicationCallError(
		NStr("ru = 'Сертификаты на сервере'; en = 'Certificates on server'; pl = 'Certificates on server';de = 'Certificates on server';ro = 'Certificates on server';tr = 'Certificates on server'; es_ES = 'Certificates on server'"), "", ErrorGettingCertificatesAtServer, New Structure);
	
EndProcedure

&AtClient
Procedure ShowAllOnChange(Item)
	
	UpdateCertificatesList();
	
EndProcedure

&AtClient
Procedure InstructionClick(Item)
	
	DigitalSignatureInternalClient.OpenInstructionOfWorkWithApplications();
	
EndProcedure

#EndRegion

#Region CertificatesFormTableItemsEventHandlers

&AtClient
Procedure CertificatesChoice(Item, RowSelected, Field, StandardProcessing)
	
	Next(Undefined);
	
EndProcedure

&AtClient
Procedure CertificatesOnActivateRow(Item)
	
	If Items.Certificates.CurrentData = Undefined Then
		SelectedCertificateThumbprint = "";
	Else
		SelectedCertificateThumbprint = Items.Certificates.CurrentData.Thumbprint;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Update(Command)
	
	UpdateCertificatesList();
	
EndProcedure

&AtClient
Procedure ShowCurrentCertificateData(Command)
	
	CurrentData = Items.Certificates.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	DigitalSignatureClient.OpenCertificate(CurrentData.Thumbprint, Not CurrentData.IsRequest);
	
EndProcedure

&AtClient
Procedure Next(Command)
	
	If Items.Certificates.CurrentData = Undefined Then
		ShowMessageBox(, NStr("ru = 'Выделите сертификаты, которые требуется добавить.'; en = 'Select certificates that you want to add.'; pl = 'Select certificates that you want to add.';de = 'Select certificates that you want to add.';ro = 'Select certificates that you want to add.';tr = 'Select certificates that you want to add.'; es_ES = 'Select certificates that you want to add.'"));
		Return;
	EndIf;
	
	CurrentData = Items.Certificates.CurrentData;
	
	If CurrentData.IsRequest Then
		ShowMessageBox(,
			NStr("ru = 'Для этого сертификата заявление на выпуск еще не исполнено.
			           |Откройте заявление на выпуск сертификата и выполните требуемые шаги.'; 
			           |en = 'The application for issue for this certificate has not been processed yet.
			           |Open the application for certificate issue and perform the required steps.'; 
			           |pl = 'The application for issue for this certificate has not been processed yet.
			           |Open the application for certificate issue and perform the required steps.';
			           |de = 'The application for issue for this certificate has not been processed yet.
			           |Open the application for certificate issue and perform the required steps.';
			           |ro = 'The application for issue for this certificate has not been processed yet.
			           |Open the application for certificate issue and perform the required steps.';
			           |tr = 'The application for issue for this certificate has not been processed yet.
			           |Open the application for certificate issue and perform the required steps.'; 
			           |es_ES = 'The application for issue for this certificate has not been processed yet.
			           |Open the application for certificate issue and perform the required steps.'"));
		UpdateCertificatesList();
		Return;
	EndIf;
	
	Items.Next.Enabled = False;
	
	If DigitalSignatureInternalClient.UseDigitalSignatureSaaS() AND CurrentData.InCloudService Then
		SearchStructure = New Structure;
		SearchStructure.Insert("Thumbprint", Base64Value(CurrentData.Thumbprint));
		ModuleCertificateStoreClient = CommonClient.CommonModule("CertificatesStorageClient");
		ModuleCertificateStoreClient.FindCertificate(New NotifyDescription(
			"NextAfterCertificateSearchInCloudService", ThisObject), SearchStructure);
	Else
		DigitalSignatureInternalClient.GetCertificateByThumbprint(New NotifyDescription(
			"NextAfterCertificateSearch", ThisObject), CurrentData.Thumbprint, False, Undefined);
	EndIf;
	
EndProcedure

// Continues the Next procedure.
&AtClient
Procedure NextAfterCertificateSearch(Result, Context) Export
	
	If TypeOf(Result) = Type("CryptoCertificate") Then
		Result.BeginUnloading(New NotifyDescription(
			"NextAfterCertificateExport", ThisObject, Result));
		Return;
	EndIf;
	
	Context = New Structure;
	
	If Result.Property("CertificateNotFound") Then
		Context.Insert("ErrorDescription", NStr("ru = 'Сертификат не найден на компьютере (возможно удален).'; en = 'Certificate is not found on the computer (it might have been deleted).'; pl = 'Certificate is not found on the computer (it might have been deleted).';de = 'Certificate is not found on the computer (it might have been deleted).';ro = 'Certificate is not found on the computer (it might have been deleted).';tr = 'Certificate is not found on the computer (it might have been deleted).'; es_ES = 'Certificate is not found on the computer (it might have been deleted).'"));
	Else
		Context.Insert("ErrorDescription", Result.ErrorDescription);
	EndIf;
	
	UpdateCertificatesList(New NotifyDescription(
		"NextAfterCertificatesListUpdate", ThisObject, Context));
	
EndProcedure

// Continues the Next procedure.
&AtClient
Procedure NextAfterCertificateExport(ExportedData, CryptoCertificate) Export
	
	ShowCertificatePropertiesAdjustmentPage(ThisObject,
		CryptoCertificate,
		ExportedData,
		DigitalSignatureClient.CertificateProperties(CryptoCertificate));
	
EndProcedure

// Continues the Next procedure.
&AtClient
Procedure NextAfterCertificatesListUpdate(Result, Context) Export
	
	ShowMessageBox(, Context.ErrorDescription);
	Items.Next.Enabled = True;
	
EndProcedure

// Continues the Next procedure.
&AtClient
Procedure NextAfterCertificateSearchInCloudService(Result, Context) Export
	
	If TypeOf(Result) = Type("Structure") Then
		If Result.Completed Then
			NextAfterCertificateExport(Result.Certificate.Certificate, Result.Certificate);
		EndIf;
		Return;
	EndIf;
	
	Context = New Structure;
	
	If Not Result.Completed Then
		Context.Insert("ErrorDescription", NStr("ru = 'Сертификат не найден в облачном сервисе (возможно удален).'; en = 'Certificate was not found in the cloud service (may have been deleted).'; pl = 'Certificate was not found in the cloud service (may have been deleted).';de = 'Certificate was not found in the cloud service (may have been deleted).';ro = 'Certificate was not found in the cloud service (may have been deleted).';tr = 'Certificate was not found in the cloud service (may have been deleted).'; es_ES = 'Certificate was not found in the cloud service (may have been deleted).'"));
	Else
		Context.Insert("ErrorDescription", Result.ErrorDescription);
	EndIf;
	
	UpdateCertificatesList(New NotifyDescription(
		"NextAfterCertificatesListUpdate", ThisObject, Context));
	
EndProcedure

&AtClient
Procedure Back(Command)
	
	Items.Pages.CurrentPage = Items.CertificateSelectionPage;
	Items.Next.DefaultButton = True;
	
	UpdateCertificatesList();
	
EndProcedure

&AtClient
Procedure Add(Command)
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	AdditionalParameters = New Structure;
	If Not ValueIsFilled(Certificate) Then
		AdditionalParameters.Insert("IsNew");
	EndIf;
	
	WriteCertificateToCatalog();
	
	NotifyChanged(Certificate);
	Notify("Write_DigitalSignatureAndEncryptionKeyCertificates",
		AdditionalParameters, Certificate);
	
	NotifyChoice(Certificate);
	
EndProcedure

&AtClient
Procedure ShowCertificateData(Command)
	
	If ValueIsFilled(CertificateAddress) Then
		DigitalSignatureClient.OpenCertificate(CertificateAddress, True);
	Else
		DigitalSignatureClient.OpenCertificate(CertificateThumbprint, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure ShowCertificatePropertiesAdjustmentPage(Form, CryptoCertificate, CertificateData, CertificateProperties)
	
	Items = Form.Items;
	
	Form.CertificateAddress = PutToTempStorage(CertificateData, Form.UUID);
	
	Form.CertificateThumbprint = Base64String(CryptoCertificate.Thumbprint);
	
	DigitalSignatureInternalClientServer.FillCertificateDataDetails(
		Form.CertificateDataDetails, CertificateProperties);
	
	SavedProperties = SavedCertificateProperties(
		Form.CertificateThumbprint,
		Form.CertificateAddress,
		Form.CertificateAttributeParameters);
	
	If Form.CertificateAttributeParameters.Property("Description") Then
		If Form.CertificateAttributeParameters.Description.ReadOnly Then
			Items.CertificateDescription.ReadOnly = True;
		EndIf;
	EndIf;
	
	If Form.CompanyTypeToDefineConfigured Then
		If Form.CertificateAttributeParameters.Property("Company") Then
			If Not Form.CertificateAttributeParameters.Company.Visible Then
				Items.CertificateCompany.Visible = False;
			ElsIf Form.CertificateAttributeParameters.Company.ReadOnly Then
				Items.CertificateCompany.ReadOnly = True;
			EndIf;
		EndIf;
	EndIf;
	
	Form.Certificate             = SavedProperties.Ref;
	Form.CertificateDescription = SavedProperties.Description;
	Form.CertificateUser = SavedProperties.User;
	Form.CertificateCompany  = SavedProperties.Company;
	
	Items.Pages.CurrentPage   = Items.PromptForCertificatePropertiesPage;
	Items.Add.DefaultButton = True;
	Items.Next.Enabled          = True;
	
	Row = ?(ValueIsFilled(Form.Certificate), NStr("ru = 'Обновить'; en = 'Update'; pl = 'Update';de = 'Update';ro = 'Update';tr = 'Update'; es_ES = 'Update'"), NStr("ru = 'Добавить'; en = 'Add'; pl = 'Add';de = 'Add';ro = 'Add';tr = 'Add'; es_ES = 'Add'"));
	If Items.Add.Title <> Row Then
		Items.Add.Title = Row;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function SavedCertificateProperties(Val Thumbprint, Address, AttributesParameters)
	
	Return DigitalSignatureInternal.SavedCertificateProperties(Thumbprint, Address, AttributesParameters, True);
	
EndFunction

&AtClient
Procedure UpdateCertificatesList(Notification = Undefined)
	
	Context = New Structure;
	Context.Insert("Notification", Notification);
	
	DigitalSignatureInternalClient.GetCertificatesPropertiesAtClient(New NotifyDescription(
		"UpdateCertificatesListFollowUp", ThisObject, Context), False, ShowAll);
	
EndProcedure

// Continues the UpdateCertificatesList procedure.
&AtClient
Procedure UpdateCertificatesListFollowUp(Result, Context) Export
	
	ErrorOnGetCertificatesAtClient = Result.ErrorOnGetCertificatesAtClient;
	
	UpdateCertificatesListAtServer(Result.CertificatesPropertiesAtClient);
	
	If Context.Notification <> Undefined Then
		ExecuteNotifyProcessing(Context.Notification);
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateCertificatesListAtServer(Val CertificatesPropertiesAtClient)
	
	ErrorGettingCertificatesAtServer = New Structure;
	
	DigitalSignatureInternal.UpdateCertificatesList(Certificates, CertificatesPropertiesAtClient,
		True, False, ErrorGettingCertificatesAtServer, ShowAll);
	
	If ValueIsFilled(SelectedCertificateThumbprint)
	   AND (    Items.Certificates.CurrentRow = Undefined
	      Or Certificates.FindByID(Items.Certificates.CurrentRow) = Undefined
	      Or Certificates.FindByID(Items.Certificates.CurrentRow).Thumbprint
	              <> SelectedCertificateThumbprint) Then
		
		Filter = New Structure("Thumbprint", SelectedCertificateThumbprint);
		Rows = Certificates.FindRows(Filter);
		If Rows.Count() > 0 Then
			Items.Certificates.CurrentRow = Rows[0].GetID();
		EndIf;
	EndIf;
	
	Items.CertificatesUnavailableAtClientGroup.Visible =
		ValueIsFilled(ErrorOnGetCertificatesAtClient);
	
	Items.CertificatesUnavailableAtServerGroup.Visible =
		ValueIsFilled(ErrorGettingCertificatesAtServer);
	
EndProcedure

&AtServer
Procedure WriteCertificateToCatalog()
	
	DigitalSignatureInternal.WriteCertificateToCatalog(ThisObject, , True);
	
EndProcedure

#EndRegion
