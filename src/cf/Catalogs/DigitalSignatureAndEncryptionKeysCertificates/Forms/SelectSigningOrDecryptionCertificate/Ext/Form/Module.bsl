///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var InternalData, PasswordProperties;

#EndRegion

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	DigitalSignatureInternal.SetPasswordEntryNote(ThisObject,
		Items.CertificatePrivateKeyAdvancedProtection.Name,
		Items.AdvancedPasswordNote.Name);
	
	CertificateAttributeParameters = New Structure;
	If Parameters.Property("Company") Then
		CertificateAttributeParameters.Insert("Company", Parameters.Company);
	EndIf;
	
	FilterByCompany = Parameters.FilterByCompany;
	
	If Parameters.AddToList Then
		AddToList = True;
		Items.Select.Title = NStr("ru = 'Добавить'; en = 'Add'; pl = 'Add';de = 'Add';ro = 'Add';tr = 'Add'; es_ES = 'Add'");
		
		Items.AdvancedPasswordNote.Title =
			NStr("ru = 'Нажмите Добавить, чтобы перейти к вводу пароля.'; en = 'Click Add to enter the password.'; pl = 'Click Add to enter the password.';de = 'Click Add to enter the password.';ro = 'Click Add to enter the password.';tr = 'Click Add to enter the password.'; es_ES = 'Click Add to enter the password.'");
		
		PersonalListOnAdd = Parameters.PersonalListOnAdd;
		Items.ShowAll.ToolTip =
			NStr("ru = 'Показать все сертификаты без отбора (например, включая добавленные и просроченные)'; en = 'Show all certificates without filter (for example, including added and overdue)'; pl = 'Show all certificates without filter (for example, including added and overdue)';de = 'Show all certificates without filter (for example, including added and overdue)';ro = 'Show all certificates without filter (for example, including added and overdue)';tr = 'Show all certificates without filter (for example, including added and overdue)'; es_ES = 'Show all certificates without filter (for example, including added and overdue)'");
	EndIf;
	
	ToEncryptAndDecrypt = Parameters.ToEncryptAndDecrypt;
	ReturnPassword = Parameters.ReturnPassword;
	
	If ToEncryptAndDecrypt = True Then
		If Parameters.AddToList Then
			Title = NStr("ru = 'Добавление сертификата для шифрования и расшифровки данных'; en = 'Add certificate to encrypt and decrypt data'; pl = 'Add certificate to encrypt and decrypt data';de = 'Add certificate to encrypt and decrypt data';ro = 'Add certificate to encrypt and decrypt data';tr = 'Add certificate to encrypt and decrypt data'; es_ES = 'Add certificate to encrypt and decrypt data'");
		Else
			Title = NStr("ru = 'Выбор сертификата для шифрования и расшифровки данных'; en = 'Select certificate to encrypt and decrypt data'; pl = 'Select certificate to encrypt and decrypt data';de = 'Select certificate to encrypt and decrypt data';ro = 'Select certificate to encrypt and decrypt data';tr = 'Select certificate to encrypt and decrypt data'; es_ES = 'Select certificate to encrypt and decrypt data'");
		EndIf;
	ElsIf ToEncryptAndDecrypt = False Then
		If Parameters.AddToList Then
			Title = NStr("ru = 'Добавление сертификата для подписания данных'; en = 'Add a certificate for signing data'; pl = 'Add a certificate for signing data';de = 'Add a certificate for signing data';ro = 'Add a certificate for signing data';tr = 'Add a certificate for signing data'; es_ES = 'Add a certificate for signing data'");
		EndIf;
	ElsIf DigitalSignature.UseEncryption() Then
		Title = NStr("ru = 'Добавление сертификата для подписания и шифрования данных'; en = 'Add a certificate for signing and encrypting data'; pl = 'Add a certificate for signing and encrypting data';de = 'Add a certificate for signing and encrypting data';ro = 'Add a certificate for signing and encrypting data';tr = 'Add a certificate for signing and encrypting data'; es_ES = 'Add a certificate for signing and encrypting data'");
	Else
		Title = NStr("ru = 'Добавление сертификата для подписания данных'; en = 'Add a certificate for signing data'; pl = 'Add a certificate for signing data';de = 'Add a certificate for signing data';ro = 'Add a certificate for signing data';tr = 'Add a certificate for signing data'; es_ES = 'Add a certificate for signing data'");
	EndIf;
	
	If DigitalSignature.GenerateDigitalSignaturesAtServer() Then
		Items.CertificatesGroup.Title =
			NStr("ru = 'Личные сертификаты на компьютере и сервере'; en = 'Personal certificates on computer and on server'; pl = 'Personal certificates on computer and on server';de = 'Personal certificates on computer and on server';ro = 'Personal certificates on computer and on server';tr = 'Personal certificates on computer and on server'; es_ES = 'Personal certificates on computer and on server'");
	EndIf;
	
	HasCompanies = Not Metadata.DefinedTypes.Company.Type.ContainsType(Type("String"));
	Items.CertificateCompany.Visible = HasCompanies;
	
	Items.CertificateUser.ToolTip =
		Metadata.Catalogs.DigitalSignatureAndEncryptionKeysCertificates.Attributes.User.ToolTip;
	
	Items.CertificateCompany.ToolTip =
		Metadata.Catalogs.DigitalSignatureAndEncryptionKeysCertificates.Attributes.Company.ToolTip;
	
	If ValueIsFilled(Parameters.SelectedCertificateThumbprint) Then
		SelectedCertificateThumbprintNotFound = False;
		SelectedCertificateThumbprint = Parameters.SelectedCertificateThumbprint;
	Else
		SelectedCertificateThumbprint = Common.ObjectAttributeValue(
			Parameters.SelectedCertificate, "Thumbprint");
	EndIf;
	
	ErrorOnGetCertificatesAtClient = Parameters.ErrorOnGetCertificatesAtClient;
	UpdateCertificatesListAtServer(Parameters.CertificatesPropertiesAtClient);
	
	If ValueIsFilled(Parameters.SelectedCertificateThumbprint)
	   AND Parameters.SelectedCertificateThumbprint <> SelectedCertificateThumbprint Then
		
		SelectedCertificateThumbprintNotFound = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If InternalData = Undefined Then
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If Upper(EventName) = Upper("Write_DigitalSignatureAndEncryptionSoftware")
	 Or Upper(EventName) = Upper("Write_PathToDigitalSignatureAndEncryptionSoftwareAtServer") Then
		
		RefreshReusableValues();
		UpdateCertificatesList();
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
		
	// Checking whether the company is filled.
	If Items.CertificateCompany.Visible
	   AND Not Items.CertificateCompany.ReadOnly
	   AND Items.CertificateCompany.AutoMarkIncomplete = True
	   AND Not ValueIsFilled(CertificateCompany) Then
		
		MessageText = NStr("ru = 'Поле Организация не заполнено.'; en = 'Company is not populated.'; pl = 'Company is not populated.';de = 'Company is not populated.';ro = 'Company is not populated.';tr = 'Company is not populated.'; es_ES = 'Company is not populated.'");
		Common.MessageToUser(MessageText,, "CertificateCompany",, Cancel);
	EndIf;
	
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

&AtClient
Procedure CertificateStrongPrivateKeyProtectionOnchange(Item)
	
	DigitalSignatureInternalClient.ProcessPasswordInForm(ThisObject,
		InternalData, PasswordProperties, New Structure("OnChangeCertificateProperties", True));
	
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
	
	Items.Next.Enabled = False;
	
	GoToCurrentCertificateChoice(New NotifyDescription(
		"NextAfterGoToCurrentCertificateSelection", ThisObject));
	
EndProcedure

// Continues the Next procedure.
&AtClient
Procedure NextAfterGoToCurrentCertificateSelection(Result, Context) Export
	
	If Result = True Then
		Items.Next.Enabled = True;
		Return;
	EndIf;
	
	Context = Result;
	
	If Context.UpdateCertificatesList Then
		UpdateCertificatesList(New NotifyDescription(
			"NextAfterCertificatesListUpdate", ThisObject, Context));
	Else
		NextAfterCertificatesListUpdate(Undefined, Context);
	EndIf;
	
EndProcedure

// Continues the Next procedure.
&AtClient
Procedure NextAfterCertificatesListUpdate(Result, Context) Export
	
	ShowMessageBox(, Context.ErrorDescription);
	Items.Next.Enabled = True;
	
EndProcedure

&AtClient
Procedure Back(Command)
	
	Items.MainPages.CurrentPage = Items.CertificateSelectionPage;
	Items.Next.DefaultButton = True;
	
	UpdateCertificatesList();
	
EndProcedure

&AtClient
Procedure Select(Command)
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	Context = New Structure;
	Context.Insert("ErrorAtServer", New Structure);
	Context.Insert("ErrorAtClient", New Structure);
	
	If CertificateAtServer
	   AND CheckCertificateAndWriteToCatalog(PasswordProperties.Value, Context.ErrorAtServer) Then
		
		SelectAfterCertificateCheck(Context.ErrorAtClient, Context);
	Else
		If CertificateInCloudService Then
			Notification = New NotifyDescription("SelectAfterCertificateCheckInSaaSMode", ThisObject, Context);
		Else
			Notification = New NotifyDescription("SelectAfterCertificateCheck", ThisObject, Context);
		EndIf;
		CheckCertificate(Notification);
	EndIf;
	
EndProcedure

// Continues the Select procedure.
&AtClient
Procedure SelectAfterCertificateCheck(Result, Context) Export
	
	AdditionalParameters = New Structure;
	If Result.Property("Application") Then
		
		If Not ValueIsFilled(Certificate) Then
			AdditionalParameters.Insert("IsNew");
		EndIf;
		
		WriteCertificateToCatalog(Result.Application);
		
	EndIf;
	
	If Result.Property("ErrorDescription") Then
		ErrorAtClient = Result;
		
		If ToEncryptAndDecrypt = True Then
			FormHeader = NStr("ru = 'Проверка шифрования и расшифровки'; en = 'Encryption and decryption check'; pl = 'Encryption and decryption check';de = 'Encryption and decryption check';ro = 'Encryption and decryption check';tr = 'Encryption and decryption check'; es_ES = 'Encryption and decryption check'");
		Else
			FormHeader = NStr("ru = 'Проверка установки электронной подписи'; en = 'Digital signature verification'; pl = 'Digital signature verification';de = 'Digital signature verification';ro = 'Digital signature verification';tr = 'Digital signature verification'; es_ES = 'Digital signature verification'");
		EndIf;
		DigitalSignatureInternalClient.ShowApplicationCallError(
			FormHeader, "", ErrorAtClient, Context.ErrorAtServer);
		
		Return;
	EndIf;
	
	DigitalSignatureInternalClient.ProcessPasswordInForm(ThisObject,
		InternalData, PasswordProperties, New Structure("OnOperationSuccess", True));
	
	NotifyChanged(Certificate);
	Notify("Write_DigitalSignatureAndEncryptionKeyCertificates",
		AdditionalParameters, Certificate);
		
	If ReturnPassword Then
		InternalData.Insert("SelectedCertificate", Certificate);
		If Not RememberPassword Then
			InternalData.Insert("SelectedCertificatePassword", PasswordProperties.Value);
		EndIf;
		NotifyChoice(True);
	Else
		NotifyChoice(Certificate);
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectAfterCertificateCheckInSaaSMode(Result, Context) Export
	
	AdditionalParameters = New Structure;
	If Result.Property("Valid") AND Result.Valid Then
		
		If Not ValueIsFilled(Certificate) Then
			AdditionalParameters.Insert("IsNew");
		EndIf;
		
		WriteCertificateToCatalogSaaS();
		
	EndIf;
	
	If Result.Property("ErrorInfo") Then
		ErrorAtClient = Result.ErrorInfo.Details;
		
		If ToEncryptAndDecrypt = True Then
			FormHeader = NStr("ru = 'Проверка шифрования и расшифровки'; en = 'Encryption and decryption check'; pl = 'Encryption and decryption check';de = 'Encryption and decryption check';ro = 'Encryption and decryption check';tr = 'Encryption and decryption check'; es_ES = 'Encryption and decryption check'");
		Else
			FormHeader = NStr("ru = 'Проверка установки электронной подписи'; en = 'Digital signature verification'; pl = 'Digital signature verification';de = 'Digital signature verification';ro = 'Digital signature verification';tr = 'Digital signature verification'; es_ES = 'Digital signature verification'");
		EndIf;
		DigitalSignatureInternalClient.ShowApplicationCallError(
			FormHeader, "", ErrorAtClient, Context.ErrorAtServer);
		Return;
	EndIf;
	
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

// CAC:78-off: to securely pass data between forms on the client without sending them to the server.
&AtClient
Procedure ContinueOpening(Notification, CommonInternalData) Export
// CAC:78-on: to securely pass data between forms on the client without sending them to the server.
	
	InternalData = CommonInternalData;
	DigitalSignatureInternalClient.ProcessPasswordInForm(ThisObject, InternalData, PasswordProperties);
	
	Context = New Structure;
	Context.Insert("Notification", Notification);
	
	If SelectedCertificateThumbprintNotFound = Undefined
	 Or SelectedCertificateThumbprintNotFound = True Then
		
		ContinueOpeningAfterGoToChooseCurrentCertificate(Undefined, Context);
	Else
		GoToCurrentCertificateChoice(New NotifyDescription(
			"ContinueOpeningAfterGoToChooseCurrentCertificate", ThisObject, Context));
	EndIf;
	
EndProcedure

// Continues the ContinueOpening procedure.
&AtClient
Procedure ContinueOpeningAfterGoToChooseCurrentCertificate(Result, Context) Export
	
	If TypeOf(Result) = Type("Structure") Then
		NotifyChoice(False);
	Else
		Open();
	EndIf;
	
	ExecuteNotifyProcessing(Context.Notification);
	
EndProcedure

&AtServer
Function FillCurrentCertificatePropertiesAtServer(Val Thumbprint, SavedProperties);
	
	CryptoCertificate = DigitalSignatureInternal.GetCertificateByThumbprint(Thumbprint, False);
	If CryptoCertificate = Undefined Then
		Return False;
	EndIf;
	
	CertificateAddress = PutToTempStorage(CryptoCertificate.Unload(),
		UUID);
	
	CertificateThumbprint = Thumbprint;
	
	DigitalSignatureInternalClientServer.FillCertificateDataDetails(CertificateDataDetails,
		DigitalSignature.CertificateProperties(CryptoCertificate));
	
	SavedProperties = SavedCertificateProperties(Thumbprint,
		CertificateAddress, CertificateAttributeParameters);
	
	Return True;
	
EndFunction

&AtServerNoContext
Function SavedCertificateProperties(Val Thumbprint, Val Address, AttributesParameters)
	
	Return DigitalSignatureInternal.SavedCertificateProperties(Thumbprint, Address, AttributesParameters);
	
EndFunction

&AtClient
Procedure UpdateCertificatesList(Notification = Undefined)
	
	Context = New Structure;
	Context.Insert("Notification", Notification);
	
	DigitalSignatureInternalClient.GetCertificatesPropertiesAtClient(New NotifyDescription(
		"UpdateCertificatesListFollowUp", ThisObject, Context), True, ShowAll);
	
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
		AddToList, True, ErrorGettingCertificatesAtServer, ShowAll, FilterByCompany);
	
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
	
	If Items.Certificates.CurrentRow = Undefined Then
		SelectedCertificateThumbprint = "";
	Else
		Row = Certificates.FindByID(Items.Certificates.CurrentRow);
		SelectedCertificateThumbprint = ?(Row = Undefined, "", Row.Thumbprint);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoToCurrentCertificateChoice(Notification)
	
	Result = New Structure;
	Result.Insert("ErrorDescription", "");
	Result.Insert("UpdateCertificatesList", False);
	
	If Items.Certificates.CurrentData = Undefined Then
		Result.ErrorDescription = NStr("ru = 'Выделите сертификат, который будет использоваться.'; en = 'Select a certificate to be used.'; pl = 'Select a certificate to be used.';de = 'Select a certificate to be used.';ro = 'Select a certificate to be used.';tr = 'Select a certificate to be used.'; es_ES = 'Select a certificate to be used.'");
		ExecuteNotifyProcessing(Notification, Result);
		Return;
	EndIf;
	
	CurrentData = Items.Certificates.CurrentData;
	
	If CurrentData.IsRequest Then
		Result.UpdateCertificatesList = True;
		Result.ErrorDescription =
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
			           |Open the application for certificate issue and perform the required steps.'");
		ExecuteNotifyProcessing(Notification, Result);
		Return;
	EndIf;
	
	CertificateAtClient = CurrentData.AtClient;
	CertificateAtServer = CurrentData.AtServer;
	CertificateInCloudService = CurrentData.InCloudService;
	
	Context = New Structure;
	Context.Insert("Notification",          Notification);
	Context.Insert("Result",           Result);
	Context.Insert("CurrentData",       CurrentData);
	Context.Insert("SavedProperties", Undefined);
	
	If CertificateAtServer Then
		If FillCurrentCertificatePropertiesAtServer(CurrentData.Thumbprint, Context.SavedProperties) Then
			GoToCurrentCertificateChoiceAfterFillCertificateProperties(Context);
		Else
			Result.ErrorDescription = NStr("ru = 'Сертификат не найден на сервере (возможно удален).'; en = 'Certificate is not found on the server (it might have been deleted).'; pl = 'Certificate is not found on the server (it might have been deleted).';de = 'Certificate is not found on the server (it might have been deleted).';ro = 'Certificate is not found on the server (it might have been deleted).';tr = 'Certificate is not found on the server (it might have been deleted).'; es_ES = 'Certificate is not found on the server (it might have been deleted).'");
			Result.UpdateCertificatesList = True;
			ExecuteNotifyProcessing(Notification, Result);
		EndIf;
		Return;
	EndIf;
	
	If CurrentData.InCloudService Then
		SearchStructure = New Structure;
		SearchStructure.Insert("Thumbprint", Base64Value(CurrentData.Thumbprint));
		ModuleCertificateStoreClient = CommonClient.CommonModule("CertificatesStorageClient");
		ModuleCertificateStoreClient.FindCertificate(New NotifyDescription(
			"GoToCurrentCertificateChoiceAfterCertificateSearchInCloudService", ThisObject, Context), SearchStructure);
	Else
		// CertificateAtClient.
		DigitalSignatureInternalClient.GetCertificateByThumbprint(
			New NotifyDescription("GoToCurrentCertificateChoiceAfterCertificateSearch", ThisObject, Context),
			CurrentData.Thumbprint, False, Undefined);
	EndIf;
	
EndProcedure

// Continues the GoToCurrentCertificateChoice procedure.
&AtClient
Procedure GoToCurrentCertificateChoiceAfterCertificateSearch(SearchResult, Context) Export
	
	If TypeOf(SearchResult) <> Type("CryptoCertificate") Then
		If SearchResult.Property("CertificateNotFound") Then
			Context.Result.ErrorDescription = NStr("ru = 'Сертификат не найден на компьютере (возможно удален).'; en = 'Certificate is not found on the computer (it might have been deleted).'; pl = 'Certificate is not found on the computer (it might have been deleted).';de = 'Certificate is not found on the computer (it might have been deleted).';ro = 'Certificate is not found on the computer (it might have been deleted).';tr = 'Certificate is not found on the computer (it might have been deleted).'; es_ES = 'Certificate is not found on the computer (it might have been deleted).'");
		Else
			Context.Result.ErrorDescription = SearchResult.ErrorDescription;
		EndIf;
		Context.Result.UpdateCertificatesList = True;
		ExecuteNotifyProcessing(Context.Notification, Context.Result);
		Return;
	EndIf;
	
	Context.Insert("CryptoCertificate", SearchResult);
	
	Context.CryptoCertificate.BeginUnloading(New NotifyDescription(
		"GoToCurrentCertificateChoiceAfterCertificateExport", ThisObject, Context));
	
EndProcedure

// Continues the GoToCurrentCertificateChoice procedure.
&AtClient
Procedure GoToCurrentCertificateChoiceAfterCertificateSearchInCloudService(SearchResult, Context) Export
	
	If Not SearchResult.Completed Then
		Context.Insert("ErrorDescription", SearchResult.ErrorDescription.Details);
	EndIf;
	
	Context.Insert("CryptoCertificate", SearchResult.Certificate);
	
	GoToCurrentCertificateChoiceAfterCertificateExport(SearchResult.Certificate.Certificate, Context);
	
EndProcedure

// Continues the GoToCurrentCertificateChoice procedure.
&AtClient
Procedure GoToCurrentCertificateChoiceAfterCertificateExport(ExportedData, Context) Export
	
	CertificateAddress = PutToTempStorage(ExportedData, UUID);
	
	CertificateThumbprint = Context.CurrentData.Thumbprint;
	
	DigitalSignatureInternalClientServer.FillCertificateDataDetails(CertificateDataDetails,
		DigitalSignatureClient.CertificateProperties(Context.CryptoCertificate));
	
	Context.SavedProperties = SavedCertificateProperties(Context.CurrentData.Thumbprint,
		CertificateAddress, CertificateAttributeParameters);
		
	If ValueIsFilled(FilterByCompany) Then
		Context.SavedProperties.Insert("Company", FilterByCompany);
	EndIf;
	
	GoToCurrentCertificateChoiceAfterFillCertificateProperties(Context);
	
EndProcedure

// Continues the GoToCurrentCertificateChoice procedure.
&AtClient
Procedure GoToCurrentCertificateChoiceAfterFillCertificateProperties(Context)
	
	If CertificateAttributeParameters.Property("Description") Then
		If CertificateAttributeParameters.Description.ReadOnly Then
			Items.CertificateDescription.ReadOnly = True;
		EndIf;
	EndIf;
	
	If HasCompanies Then
		If CertificateAttributeParameters.Property("Company") Then
			If Not CertificateAttributeParameters.Company.Visible Then
				Items.CertificateCompany.Visible = False;
			ElsIf CertificateAttributeParameters.Company.ReadOnly Then
				Items.CertificateCompany.ReadOnly = True;
			ElsIf CertificateAttributeParameters.Company.FillChecking Then
				Items.CertificateCompany.AutoMarkIncomplete = True;
			EndIf;
		EndIf;
	EndIf;
	
	If CertificateAttributeParameters.Property("StrongPrivateKeyProtection") Then
		If Not CertificateAttributeParameters.StrongPrivateKeyProtection.Visible Then
			Items.CertificatePrivateKeyAdvancedProtection.Visible = False;
		ElsIf CertificateAttributeParameters.StrongPrivateKeyProtection.ReadOnly Then
			Items.CertificatePrivateKeyAdvancedProtection.ReadOnly = True;
		EndIf;
	EndIf;
	
	Certificate             = Context.SavedProperties.Ref;
	CertificateUser = Context.SavedProperties.User;
	CertificateCompany  = Context.SavedProperties.Company;
	CertificateDescription = Context.SavedProperties.Description;
	CertificatePrivateKeyAdvancedProtection = Context.SavedProperties.StrongPrivateKeyProtection;
	
	DigitalSignatureInternalClient.ProcessPasswordInForm(ThisObject, InternalData, PasswordProperties);
	
	Items.MainPages.CurrentPage = Items.PromptForCertificatePropertiesPage;
	Items.Select.DefaultButton = True;
	
	If AddToList Then
		Row = ?(ValueIsFilled(Certificate), NStr("ru = 'Обновить'; en = 'Update'; pl = 'Update';de = 'Update';ro = 'Update';tr = 'Update'; es_ES = 'Update'"), NStr("ru = 'Добавить'; en = 'Add'; pl = 'Add';de = 'Add';ro = 'Add';tr = 'Add'; es_ES = 'Add'"));
		If Items.Select.Title <> Row Then
			Items.Select.Title = Row;
		EndIf;
	EndIf;
	
	If CertificateInCloudService Then
		Items.PrivateKeyAdvancedProtectionGroup.Visible = False;
	Else
		Items.PrivateKeyAdvancedProtectionGroup.Visible = True;
		AttachIdleHandler("IdleHandlerActivateItemPassword", 0.1, True);
	EndIf;
	
	ExecuteNotifyProcessing(Context.Notification, True);
	
EndProcedure

&AtClient
Procedure IdleHandlerActivateItemPassword()
	
	CurrentItem = Items.Password;
	
EndProcedure


&AtClient
Procedure CheckCertificate(Notification)
	
	Context = New Structure;
	Context.Insert("Notification", Notification);
	
	If CertificateInCloudService Then
		ModuleCryptoServiceClient = CommonClient.CommonModule("CryptographyServiceClient");
		ModuleCryptoServiceClient.CheckCertificate(Notification, GetFromTempStorage(CertificateAddress));
	Else
	     DigitalSignatureInternalClient.CreateCryptoManager(New NotifyDescription(
			"CheckCertificateAfterCreateCryptoManager", ThisObject, Context), "", Undefined);
	EndIf;
	
EndProcedure

// Continues the CheckCertificate procedure.
&AtClient
Procedure CheckCertificateAfterCreateCryptoManager(Result, Context) Export
	
	If TypeOf(Result) <> Type("CryptoManager")
		AND Result.Total Then
		
		If ToEncryptAndDecrypt = True Then
			Result.Insert("ErrorTitle", NStr("ru = 'Не удалось пройти проверку шифрования по причине:'; en = 'Cannot pass the encryption check due to:'; pl = 'Cannot pass the encryption check due to:';de = 'Cannot pass the encryption check due to:';ro = 'Cannot pass the encryption check due to:';tr = 'Cannot pass the encryption check due to:'; es_ES = 'Cannot pass the encryption check due to:'"));
		Else
			Result.Insert("ErrorTitle", NStr("ru = 'Не удалось пройти проверку подписания по причине:'; en = 'Cannot pass the signing check due to:'; pl = 'Cannot pass the signing check due to:';de = 'Cannot pass the signing check due to:';ro = 'Cannot pass the signing check due to:';tr = 'Cannot pass the signing check due to:'; es_ES = 'Cannot pass the signing check due to:'"));
		EndIf;
		ExecuteNotifyProcessing(Context.Notification, Result);
		Return;
	EndIf;
	
	Context.Insert("CertificateBinaryData", GetFromTempStorage(CertificateAddress));
	
	CryptoCertificate = New CryptoCertificate;
	CryptoCertificate.BeginInitialization(New NotifyDescription(
			"CheckCertificateAfterInitializeCertificate", ThisObject, Context),
		Context.CertificateBinaryData);
	
EndProcedure

// Continues the CheckCertificate procedure.
&AtClient
Procedure CheckCertificateAfterInitializeCertificate(CryptoCertificate, Context) Export
	
	Context.Insert("CryptoCertificate", CryptoCertificate);
	
	Context.Insert("ErrorDescription", "");
	Context.Insert("ErrorAtClient", New Structure);
	
	Context.ErrorAtClient.Insert("ErrorDescription", "");
	Context.ErrorAtClient.Insert("Errors", New Array);
	
	Context.Insert("ApplicationsDetailsCollection", DigitalSignatureClient.CommonSettings().ApplicationsDetailsCollection);
	Context.Insert("IndexOf", -1);
	
	CheckCertificateLoopStart(Context);
	
EndProcedure

// Continues the CheckCertificate procedure.
&AtClient
Procedure CheckCertificateLoopStart(Context)
	
	If Context.ApplicationsDetailsCollection.Count() <= Context.IndexOf + 1 Then
		Context.ErrorAtClient.Insert("ErrorDescription", TrimAll(Context.ErrorDescription));
		ExecuteNotifyProcessing(Context.Notification, Context.ErrorAtClient);
		Return;
	EndIf;
	Context.IndexOf = Context.IndexOf + 1;
	Context.Insert("ApplicationDetails", Context.ApplicationsDetailsCollection[Context.IndexOf]);
	
	DigitalSignatureInternalClient.CreateCryptoManager(New NotifyDescription(
			"CheckCertificateLoopAfterCreateCryptoManager", ThisObject, Context),
		"", Undefined, Context.ApplicationDetails.Ref, CertificatePrivateKeyAdvancedProtection);
	
EndProcedure

// Continues the CheckCertificate procedure.
&AtClient
Procedure CheckCertificateLoopAfterCreateCryptoManager(Result, Context) Export
	
	If TypeOf(Result) <> Type("CryptoManager") Then
		If Result.Errors.Count() > 0 Then
			Context.ErrorAtClient.Errors.Add(Result.Errors[0]);
		EndIf;
		CheckCertificateLoopStart(Context);
		Return;
	EndIf;
	Context.Insert("CryptoManager", Result);
	
	If Not DigitalSignatureInternalClient.InteractiveCryptographyModeUsed(Context.CryptoManager) Then
		Context.CryptoManager.PrivateKeyAccessPassword = PasswordProperties.Value;
	EndIf;
	
	If ToEncryptAndDecrypt = True Then
		Context.CryptoManager.BeginEncrypting(New NotifyDescription(
				"CheckCertificateLoopAfterEncryption", ThisObject, Context,
				"CheckCertificateLoopAfterEncryptionError", ThisObject),
			Context.CertificateBinaryData, Context.CryptoCertificate);
	Else
		Context.CryptoManager.BeginSigning(New NotifyDescription(
				"CheckCertificateLoopAfterSigning", ThisObject, Context,
				"CheckCertificateLoopAfterSigningError", ThisObject),
			Context.CertificateBinaryData, Context.CryptoCertificate);
	EndIf;
	
EndProcedure

// Continues the CheckCertificate procedure.
&AtClient
Procedure CheckCertificateLoopAfterSigningError(ErrorInformation, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	FillSigningError(Context.ErrorAtClient, Context.ErrorDescription, Context.ApplicationDetails,
		BriefErrorDescription(ErrorInformation), False);
	
	CheckCertificateLoopStart(Context);
	
EndProcedure

// Continues the CheckCertificate procedure.
&AtClient
Procedure CheckCertificateLoopAfterSigning(SignatureData, Context) Export
	
	ErrorPresentation = "";
	Try
		DigitalSignatureInternalClientServer.BlankSignatureData(SignatureData, ErrorPresentation);
	Except
		ErrorInformation = ErrorInfo();
		ErrorPresentation = BriefErrorDescription(ErrorInformation);
	EndTry;
	
	If ValueIsFilled(ErrorPresentation) Then
		FillSigningError(Context.ErrorAtClient, Context.ErrorDescription, Context.ApplicationDetails,
			ErrorPresentation, ErrorInformation = Undefined);
		CheckCertificateLoopStart(Context);
		Return;
	EndIf;
	
	Result = New Structure("Application", Context.ApplicationDetails.Ref);
	ExecuteNotifyProcessing(Context.Notification, Result);
	
EndProcedure

// Continues the CheckCertificate procedure.
&AtClient
Procedure CheckCertificateLoopAfterEncryptionError(ErrorInformation, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	FillEncryptionError(Context.ErrorAtClient, Context.ErrorDescription, Context.ApplicationDetails,
		BriefErrorDescription(ErrorInformation));
	
	CheckCertificateLoopStart(Context);
	
EndProcedure

// Continues the CheckCertificate procedure.
&AtClient
Procedure CheckCertificateLoopAfterEncryption(EncryptedData, Context) Export
	
	Context.CryptoManager.BeginDecrypting(New NotifyDescription(
			"CheckCertificateLoopAfterDecryption", ThisObject, Context,
			"CheckCertificateLoopAfterDecryptionError", ThisObject),
		EncryptedData);
	
EndProcedure

// Continues the CheckCertificate procedure.
&AtClient
Procedure CheckCertificateLoopAfterDecryptionError(ErrorInformation, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	FillDecryptionError(Context.ErrorAtClient, Context.ErrorDescription, Context.ApplicationDetails,
		BriefErrorDescription(ErrorInformation));
	
	CheckCertificateLoopStart(Context);
	
EndProcedure

// Continues the CheckCertificate procedure.
&AtClient
Procedure CheckCertificateLoopAfterDecryption(DecryptedData, Context) Export
	
	ErrorPresentation = "";
	Try
		DigitalSignatureInternalClientServer.BlankDecryptedData(DecryptedData, ErrorPresentation);
	Except
		ErrorInformation = ErrorInfo();
		ErrorPresentation = BriefErrorDescription(ErrorInformation);
	EndTry;
	
	If ValueIsFilled(ErrorPresentation) Then
		FillDecryptionError(Context.ErrorAtClient, Context.ErrorDescription, Context.ApplicationDetails,
			ErrorPresentation);
		CheckCertificateLoopStart(Context);
		Return;
	EndIf;
	
	Result = New Structure("Application", Context.ApplicationDetails.Ref);
	ExecuteNotifyProcessing(Context.Notification, Result);
	
EndProcedure


&AtServer
Function CheckCertificateAndWriteToCatalog(Val PasswordValue, ErrorAtServer)
	
	If DigitalSignatureInternal.CryptoManager("", False, ErrorAtServer) = Undefined
	   AND ErrorAtServer.Total Then
		
		If ToEncryptAndDecrypt = True Then
			ErrorAtServer.Insert("ErrorTitle", NStr("ru = 'Не удалось пройти проверку шифрования по причине:'; en = 'Cannot pass the encryption check due to:'; pl = 'Cannot pass the encryption check due to:';de = 'Cannot pass the encryption check due to:';ro = 'Cannot pass the encryption check due to:';tr = 'Cannot pass the encryption check due to:'; es_ES = 'Cannot pass the encryption check due to:'"));
		Else
			ErrorAtServer.Insert("ErrorTitle", NStr("ru = 'Не удалось пройти проверку подписания по причине:'; en = 'Cannot pass the signing check due to:'; pl = 'Cannot pass the signing check due to:';de = 'Cannot pass the signing check due to:';ro = 'Cannot pass the signing check due to:';tr = 'Cannot pass the signing check due to:'; es_ES = 'Cannot pass the signing check due to:'"));
		EndIf;
		Return False;
	EndIf;
	
	CertificateBinaryData = GetFromTempStorage(CertificateAddress);
	CryptoCertificate = New CryptoCertificate(CertificateBinaryData);
	
	ErrorAtServer = New Structure;
	ErrorAtServer.Insert("ErrorDescription", "");
	ErrorAtServer.Insert("Errors", New Array);
	
	ErrorDescription = "";
	
	ApplicationsDetailsCollection = DigitalSignature.CommonSettings().ApplicationsDetailsCollection;
	For each ApplicationDetails In ApplicationsDetailsCollection Do
		ManagerError = New Structure;
		
		CryptoManager = DigitalSignatureInternal.CryptoManager("",
			False, ManagerError, ApplicationDetails.Ref);
		
		If CryptoManager = Undefined Then
			If ManagerError.Errors.Count() > 0 Then
				ErrorAtServer.Errors.Add(ManagerError.Errors[0]);
			EndIf;
			Continue;
		EndIf;
		
		CryptoManager.PrivateKeyAccessPassword = PasswordValue;
		
		If ToEncryptAndDecrypt = True Then
			Success = CheckEncryptionAndDecryptionAtServer(CryptoManager, CertificateBinaryData,
				CryptoCertificate, ApplicationDetails, ErrorAtServer, ErrorDescription);
		Else
			Success = CheckSigningAtServer(CryptoManager, CertificateBinaryData,
				CryptoCertificate, ApplicationDetails, ErrorAtServer, ErrorDescription);
		EndIf;
		
		If Success Then
			WriteCertificateToCatalog(ApplicationDetails.Ref);
			Return True;
		EndIf;
	EndDo;
	
	ErrorAtServer.Insert("ErrorDescription", TrimAll(ErrorDescription));
	
	Return False;
	
EndFunction

&AtServer
Function CheckEncryptionAndDecryptionAtServer(CryptoManager, CertificateBinaryData,
			CryptoCertificate, ApplicationDetails, ErrorAtServer, ErrorDescription)
	
	ErrorPresentation = "";
	Try
		EncryptedData = CryptoManager.Encrypt(CertificateBinaryData, CryptoCertificate);
	Except
		ErrorInformation = ErrorInfo();
		ErrorPresentation = BriefErrorDescription(ErrorInformation);
	EndTry;
	
	If ValueIsFilled(ErrorPresentation) Then
		FillEncryptionError(ErrorAtServer, ErrorDescription, ApplicationDetails, ErrorPresentation);
		Return False;
	EndIf;
	
	ErrorPresentation = "";
	Try
		DecryptedData = CryptoManager.Decrypt(EncryptedData);
		DigitalSignatureInternalClientServer.BlankDecryptedData(DecryptedData, ErrorPresentation);
	Except
		ErrorInformation = ErrorInfo();
		ErrorPresentation = BriefErrorDescription(ErrorInformation);
	EndTry;
	
	If ValueIsFilled(ErrorPresentation) Then
		FillDecryptionError(ErrorAtServer, ErrorDescription, ApplicationDetails, ErrorPresentation);
		Return False;
	EndIf;
		
	Return True;
	
EndFunction

&AtServer
Function CheckSigningAtServer(CryptoManager, CertificateBinaryData,
			CryptoCertificate, ApplicationDetails, ErrorAtServer, ErrorDescription)
	
	ErrorPresentation = "";
	Try
		SignatureData = CryptoManager.Sign(CertificateBinaryData, CryptoCertificate);
		DigitalSignatureInternalClientServer.BlankSignatureData(SignatureData, ErrorPresentation);
	Except
		ErrorInformation = ErrorInfo();
		ErrorPresentation = BriefErrorDescription(ErrorInformation);
	EndTry;
	If ValueIsFilled(ErrorPresentation) Then
		FillSigningError(ErrorAtServer, ErrorDescription, ApplicationDetails,
			ErrorPresentation, ErrorInformation <> Undefined);
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

&AtServer
Procedure WriteCertificateToCatalog(Application)
	
	DigitalSignatureInternal.WriteCertificateToCatalog(ThisObject, Application);
	
EndProcedure

&AtServer
Procedure WriteCertificateToCatalogSaaS()
	
	DigitalSignatureInternal.WriteCertificateToCatalog(ThisObject, , True);
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillEncryptionError(Error, ErrorDescription, ApplicationDetails, ErrorPresentation)
	
	CurrentError = New Structure;
	CurrentError.Insert("Details", ErrorPresentation);
	CurrentError.Insert("Instruction", True);
	CurrentError.Insert("ApplicationsSetUp", True);
	
	Error.Errors.Add(CurrentError);
	
	ErrorDescription = ErrorDescription + Chars.LF + Chars.LF + StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Не удалось пройти проверку шифрования с помощью программы %1 по причине:
		           |%2'; 
		           |en = 'Cannot pass the encryption check with application %1 due to:
		           |%2'; 
		           |pl = 'Cannot pass the encryption check with application %1 due to:
		           |%2';
		           |de = 'Cannot pass the encryption check with application %1 due to:
		           |%2';
		           |ro = 'Cannot pass the encryption check with application %1 due to:
		           |%2';
		           |tr = 'Cannot pass the encryption check with application %1 due to:
		           |%2'; 
		           |es_ES = 'Cannot pass the encryption check with application %1 due to:
		           |%2'"),
		ApplicationDetails.Description,
		ErrorPresentation);
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillDecryptionError(Error, ErrorDescription, ApplicationDetails, ErrorPresentation)
	
	CurrentError = New Structure;
	CurrentError.Insert("Details", ErrorPresentation);
	CurrentError.Insert("Instruction", True);
	CurrentError.Insert("ApplicationsSetUp", True);
	
	Error.Errors.Add(CurrentError);
	
	ErrorDescription = ErrorDescription + Chars.LF + Chars.LF + StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Не удалось пройти проверку расшифровки с помощью программы %1 по причине:
		           |%2'; 
		           |en = 'Cannot pass the encryption check with application %1 due to:
		           |%2'; 
		           |pl = 'Cannot pass the encryption check with application %1 due to:
		           |%2';
		           |de = 'Cannot pass the encryption check with application %1 due to:
		           |%2';
		           |ro = 'Cannot pass the encryption check with application %1 due to:
		           |%2';
		           |tr = 'Cannot pass the encryption check with application %1 due to:
		           |%2'; 
		           |es_ES = 'Cannot pass the encryption check with application %1 due to:
		           |%2'"),
		ApplicationDetails.Description,
		ErrorPresentation);
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillSigningError(Error, ErrorDescription, ApplicationDetails, ErrorPresentation, BlankData)
	
	CurrentError = New Structure;
	CurrentError.Insert("Details", ErrorPresentation);
	
	If Not BlankData Then
		CurrentError.Insert("ApplicationsSetUp", True);
		CurrentError.Insert("Instruction", True);
	EndIf;
	
	Error.Errors.Add(CurrentError);
	
	ErrorDescription = ErrorDescription + Chars.LF + Chars.LF + StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Не удалось пройти проверку подписания с помощью программы %1 по причине:
		           |%2'; 
		           |en = 'Cannot pass the signing check using application %1 due to:
		           |%2'; 
		           |pl = 'Cannot pass the signing check using application %1 due to:
		           |%2';
		           |de = 'Cannot pass the signing check using application %1 due to:
		           |%2';
		           |ro = 'Cannot pass the signing check using application %1 due to:
		           |%2';
		           |tr = 'Cannot pass the signing check using application %1 due to:
		           |%2'; 
		           |es_ES = 'Cannot pass the signing check using application %1 due to:
		           |%2'"),
		ApplicationDetails.Description,
		ErrorPresentation);
	
EndProcedure

#EndRegion
