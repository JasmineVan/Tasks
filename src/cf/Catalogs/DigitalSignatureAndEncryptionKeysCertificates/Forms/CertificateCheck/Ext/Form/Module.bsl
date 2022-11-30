///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var InternalData, ClientParameters, PasswordProperties;

#EndRegion

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	DigitalSignatureInternal.SetPasswordEntryNote(ThisObject, ,
		Items.AdvancedPasswordNote.Name);
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.AtServerPicture.Height = 2;
	EndIf;
	
	Certificate        = Parameters.Certificate;
	CheckOnSelection = Parameters.CheckOnSelection;
	
	If ValueIsFilled(Parameters.FormCaption) Then
		AutoTitle = False;
		Title = Parameters.FormCaption;
	EndIf;
	
	If CheckOnSelection Then
		Items.FormCheck.Title = NStr("ru = 'Проверить и продолжить'; en = 'Check and continue'; pl = 'Check and continue';de = 'Check and continue';ro = 'Check and continue';tr = 'Check and continue'; es_ES = 'Check and continue'");
		Items.FormClose.Title   = NStr("ru = 'Отмена'; en = 'Cancel'; pl = 'Cancel';de = 'Cancel';ro = 'Cancel';tr = 'Cancel'; es_ES = 'Cancel'");
	EndIf;
	
	StandardChecks = True;
	
	Checks = New ValueTable;
	Checks.Columns.Add("Name",           New TypeDescription("String"));
	Checks.Columns.Add("Presentation", New TypeDescription("String"));
	Checks.Columns.Add("ToolTip",     New TypeDescription("String"));
	
	EnterPassword = True;
	
	DigitalSignatureOverridable.OnCreateFormCertificateCheck(Parameters.Certificate,
		Checks, Parameters.AdditionalChecksParameters, StandardChecks, EnterPassword);
	
	For each CheckSSL In Checks Do
		Folder = Items.Add("Group" + CheckSSL.Name, Type("FormGroup"), Items.AdditionalChecksGroup);
		Folder.Type = FormGroupType.UsualGroup;
		Folder.Group = ChildFormItemsGroup.AlwaysHorizontal;
		Folder.ShowTitle = False;
		Folder.Representation = UsualGroupRepresentation.None;
		
		Picture = Items.Add(CheckSSL.Name + "AtClientPicture", Type("FormDecoration"), Folder);
		Picture.Type = FormDecorationType.Picture;
		Picture.Picture = New Picture;
		Picture.PictureSize = PictureSize.AutoSize;
		Picture.Width = 3;
		Picture.Height = 1;
		Picture.Hyperlink = True;
		Picture.SetAction("Click", "Attachable_PictureClick");
		
		Picture = Items.Add(CheckSSL.Name + "AtServerPicture", Type("FormDecoration"), Folder);
		Picture.Type = FormDecorationType.Picture;
		Picture.Picture = New Picture;
		Picture.PictureSize = PictureSize.AutoSize;
		Picture.Width = 3;
		Picture.Height = 1;
		Picture.Hyperlink = True;
		Picture.SetAction("Click", "Attachable_PictureClick");
		
		Label = Items.Add(CheckSSL.Name + "Label", Type("FormDecoration"), Folder);
		Label.Title = CheckSSL.Presentation;
		Label.ToolTipRepresentation = ToolTipRepresentation.Button;
		Label.ExtendedTooltip.Title = CheckSSL.ToolTip;
		
		AdditionalChecks.Add(CheckSSL.Name);
	EndDo;
	
	If Not StandardChecks Then
		If AdditionalChecks.Count() = 0 Then
			Raise
				NStr("ru = 'Для проверки сертификата отключены стандартные проверки,
				           |при этом дополнительных проверок не указано.'; 
				           |en = 'Standard checks for checking the certificate are disabled,
				           |at that additional checks are not specified.'; 
				           |pl = 'Standard checks for checking the certificate are disabled,
				           |at that additional checks are not specified.';
				           |de = 'Standard checks for checking the certificate are disabled,
				           |at that additional checks are not specified.';
				           |ro = 'Standard checks for checking the certificate are disabled,
				           |at that additional checks are not specified.';
				           |tr = 'Standard checks for checking the certificate are disabled,
				           |at that additional checks are not specified.'; 
				           |es_ES = 'Standard checks for checking the certificate are disabled,
				           |at that additional checks are not specified.'");
		EndIf;
		Items.GeneralChecksGroup.Visible = False;
		Items.OperationsCheckGroup.Visible = False;
		StandardSubsystemsServer.SetFormAssignmentKey(ThisObject, "CustomChecks");
	EndIf;
	
	CertificateProperties = Common.ObjectAttributesValues(Certificate,
		"CertificateData, Application, StrongPrivateKeyProtection");
	
	Application = CertificateProperties.Application;
	CertificateAddress = PutToTempStorage(CertificateProperties.CertificateData.Get(), UUID);
	CertificatePrivateKeyAdvancedProtection = CertificateProperties.StrongPrivateKeyProtection;
	
	If Application.IsCloudServiceApplication Then
		IsCloudServiceApplication = True;
		Items.PasswordEntryGroup.Visible = False;
	ElsIf Not StandardChecks AND Not EnterPassword Then
		Items.PasswordEntryGroup.Visible = False;
	EndIf;
	
	RefreshVisibilityAtServer();
	
	If StandardChecks Then
		If Items.LegalCertificateGroup.Visible Then
			FirstCheckName = "LegalCertificate";
		Else
			FirstCheckName = "CertificateExists";
		EndIf;
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
	
	// When changing usage settings.
	If Upper(EventName) <> Upper("Write_ConstantsSet") Then
		Return;
	EndIf;
	
	If Upper(Source) = Upper("VerifyDigitalSignaturesOnTheServer")
	 Or Upper(Source) = Upper("GenerateDigitalSignaturesAtServer") Then
		
		AttachIdleHandler("OnChangeSigningOrEncryptionUsage", 0.1, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure Attachable_PictureClick(Item)
	
	WarningParameters = New Structure;
	WarningParameters.Insert("WarningText", Item.ToolTip);
	
	If StrEndsWith(Item.Name, "AtClientPicture") Then
		CheckName = Left(Item.Name, StrLen(Item.Name) - StrLen("AtClientPicture"));
		
	ElsIf StrEndsWith(Item.Name, "AtServerPicture") Then
		CheckName = Left(Item.Name, StrLen(Item.Name) - StrLen("AtServerPicture"));
	Else
		CheckName = Undefined;
	EndIf;
	
	If ValueIsFilled(CheckName) Then
		WarningParameters.Insert("WarningTitle",
			Items[CheckName + "Label"].Title);
	EndIf;
	
	OpenForm("CommonForm.CheckResult", WarningParameters);
	
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

&AtClient
Procedure InstructionClick(Item)
	
	DigitalSignatureClient.OpenInstructionOnTypicalProblemsOnWorkWithApplications();
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure CheckSSL(Command)
	
	Items.FormCheck.Enabled = False;
	
	CheckCertificate(New NotifyDescription("CheckCompletion", ThisObject));
	
EndProcedure

// Continues the Check procedure.
&AtClient
Procedure CheckCompletion(NotDefined, Context) Export
	
	Items.FormCheck.Enabled = True;
	
	If Not CheckOnSelection Then
		Return;
	EndIf;
	
	If ClientParameters.Result.ChecksPassed Then
		Close(True);
	Else
		ShowCannotContinueWarning();
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// CAC:78-off: to securely pass data between forms on the client without sending them to the server.
&AtClient
Procedure ContinueOpening(Notification, CommonInternalData, IncomingClientParameters) Export
// CAC:78-on: to securely pass data between forms on the client without sending them to the server.
	
	InternalData = CommonInternalData;
	ClientParameters = IncomingClientParameters;
	ClientParameters.Insert("Result");
	
	AdditionalParameters = New Structure;
	DigitalSignatureInternalClient.ProcessPasswordInForm(ThisObject,
		InternalData, PasswordProperties, AdditionalParameters);
	
	If Not Items.Password.Enabled Then
		CurrentItem = Items.FormCheck;
	EndIf;
	
	If ClientParameters.Property("NoConfirmation")
	   AND ClientParameters.NoConfirmation
	   AND (    AdditionalParameters.PasswordSpecified
	      Or AdditionalParameters.StrongPrivateKeyProtection) Then
	
		
		If Not ClientParameters.Property("ResultProcessing")
		 Or TypeOf(ClientParameters.ResultProcessing) <> Type("NotifyDescription") Then
			Open();
		EndIf;
		
		Context = New Structure("Notification", Notification);
		CheckCertificate(New NotifyDescription("ContinueOpeningAfterCertificateCheck", ThisObject, Context));
		Return;
	EndIf;
	
	Open();
	
	ExecuteNotifyProcessing(Notification);
	
EndProcedure

// Continues the ContinueOpening procedure.
&AtClient
Procedure ContinueOpeningAfterCertificateCheck(Result, Context) Export
	
	If ClientParameters.Result.ChecksPassed Then
		ExecuteNotifyProcessing(Context.Notification, True);
		Return;
	EndIf;
	
	If Not IsOpen() Then
		Open();
	EndIf;
	
	If CheckOnSelection Then
		ShowCannotContinueWarning();
	EndIf;
	
	ExecuteNotifyProcessing(Context.Notification);
	
EndProcedure

&AtClient
Procedure OnChangeSigningOrEncryptionUsage()
	
	RefreshVisibilityAtServer()
	
EndProcedure

&AtServer
Procedure RefreshVisibilityAtServer()
	
	OperationsAtServer = DigitalSignature.VerifyDigitalSignaturesOnTheServer()
	                Or DigitalSignature.GenerateDigitalSignaturesAtServer();
	
	Items.AtServerPicture.Visible                   = OperationsAtServer;
	Items.LegalCertificateAtServerPicture.Visible = OperationsAtServer;
	Items.CertificateAvailableAtServerPicture.Visible = OperationsAtServer;
	Items.CertificateDataAtServerPicture.Visible  = OperationsAtServer;
	Items.ApplicationAvailableAtServerPicture.Visible   = OperationsAtServer;
	Items.SignedAtServerPicture.Visible         = OperationsAtServer;
	Items.CheckSignatureAtServerPicture.Visible    = OperationsAtServer;
	Items.EncryptionAtServerPicture.Visible         = OperationsAtServer;
	Items.DecryptionAtServerPicture.Visible        = OperationsAtServer;
	
	For each ListItem In AdditionalChecks Do
		Items[ListItem.Value + "AtServerPicture"].Visible = OperationsAtServer;
	EndDo;
	
EndProcedure

&AtClient
Procedure ShowCannotContinueWarning()
	
	ShowMessageBox(,
		NStr("ru = 'Не удалось продолжить, т.к. пройдены не все требуемые проверки.'; en = 'Cannot continue as not all required checks are passed.'; pl = 'Cannot continue as not all required checks are passed.';de = 'Cannot continue as not all required checks are passed.';ro = 'Cannot continue as not all required checks are passed.';tr = 'Cannot continue as not all required checks are passed.'; es_ES = 'Cannot continue as not all required checks are passed.'"));
	
EndProcedure

&AtClient
Procedure CheckCertificate(Notification)
	
	PasswordAccepted = False;
	ChecksAtClient = New Structure;
	ChecksAtServer = New Structure;
	
	// Clearing the previous check results.
	If StandardChecks Then
		BasicChecks = New Structure(
			"LegalCertificate, CertificateExists, CertificateData,
			|Signing, SignatureCheck, Encryption, Details");
			
		If Not IsCloudServiceApplication Then
			BasicChecks.Insert("ProgramExists");
		EndIf;
		
		For each KeyAndValue In BasicChecks Do
			SetItem(ThisObject, KeyAndValue.Key, False);
			SetItem(ThisObject, KeyAndValue.Key, True);
		EndDo;
	EndIf;
	
	For each ListItem In AdditionalChecks Do
		SetItem(ThisObject, ListItem.Value, False);
		SetItem(ThisObject, ListItem.Value, True);
	EndDo;
	
	Context = New Structure("Notification", Notification);
	
	CheckAtClientSide(New NotifyDescription(
		"CheckCertificateAfterCheckAtClient", ThisObject, Context));
	
EndProcedure

// Continues the CheckCertificate procedure.
&AtClient
Procedure CheckCertificateAfterCheckAtClient(Result, Context) Export
	
	If OperationsAtServer Then
		If StandardChecks Then
			CheckAtServerSide(PasswordProperties.Value);
		Else
			CheckAtServerSideAdditionalChecks(PasswordProperties.Value);
		EndIf;
	Else
		ChecksAtServer = Undefined;
	EndIf;
	
	If PasswordAccepted Then
		DigitalSignatureInternalClient.ProcessPasswordInForm(ThisObject,
			InternalData, PasswordProperties, New Structure("OnOperationSuccess", True));
	EndIf;
	
	Result = New Structure;
	Result.Insert("ChecksPassed", False);
	Result.Insert("ChecksAtClient", ChecksAtClient);
	Result.Insert("ChecksAtServer", ChecksAtServer);
	
	ClientParameters.Insert("Result", Result);
	
	If ClientParameters.Property("ResultProcessing")
	   AND TypeOf(ClientParameters.ResultProcessing) = Type("NotifyDescription") Then
		
		ExecuteNotifyProcessing(ClientParameters.ResultProcessing, Result.ChecksPassed);
	EndIf;
	
	ExecuteNotifyProcessing(Context.Notification);
	
EndProcedure


&AtClient
Procedure CheckAtClientSide(Notification)
	
	Context = New Structure("Notification", Notification);
	
	If StandardChecks Then
		BeginAttachingCryptoExtension(New NotifyDescription(
			"CheckAtClientSideAfterAttachCryptoExtension", ThisObject, Context));
	Else
		Context.Insert("CryptoManager", Undefined);
		CheckAtClientSideAdditionalChecks(Context);
	EndIf;
	
EndProcedure

// Continues the CheckAtClientSide procedure.
&AtClient
Procedure CheckAtClientSideAfterAttachCryptoExtension(Attached, Context) Export
	
	If Not Attached Then
		DigitalSignatureInternalClient.CreateCryptoManager(New NotifyDescription(
				"CheckAtClientSideAfterAttemptToCreateCryptoManager", ThisObject, Context),
			"CertificateCheck", False);
		Return;
	EndIf;
	
	// Checking certificate data.
	Context.Insert("CertificateData", GetFromTempStorage(CertificateAddress));
	
	CryptoCertificate = New CryptoCertificate;
	CryptoCertificate.BeginInitialization(New NotifyDescription(
			"CheckAtClientSideAfterInitializeCertificate", ThisObject, Context,
			"CheckAtClientSideAfterCertificateInitializationError", ThisObject),
		Context.CertificateData);
	
EndProcedure

// Continues the CheckAtClientSide procedure.
&AtClient
Procedure CheckAtClientSideAfterAttemptToCreateCryptoManager(Result, Context) Export
	
	SetItem(ThisObject, FirstCheckName, False, Result, False);
	ExecuteNotifyProcessing(Context.Notification);
	
EndProcedure

// Continues the CheckAtClientSide procedure.
&AtClient
Procedure CheckAtClientSideAfterCertificateInitializationError(ErrorInformation, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	ErrorDescription = BriefErrorDescription(ErrorInformation);
	SetItem(ThisObject, FirstCheckName, False, ErrorDescription, True);
	
	ExecuteNotifyProcessing(Context.Notification);
	
EndProcedure

// Continues the CheckAtClientSide procedure.
&AtClient
Procedure CheckAtClientSideAfterInitializeCertificate(CryptoCertificate, Context) Export
	
	Context.Insert("CryptoCertificate", CryptoCertificate);
	
	// Legitimate certificate
	If Not Items.LegalCertificateGroup.Visible
	 Or Context.CryptoCertificate.Subject.Property("SN") Then
		
		ErrorDescription = "";
	Else
		ErrorDescription = NStr("ru = 'В описании субъекта сертификата не найдено поле ""SN"".'; en = 'The ""SN"" field is not found in the certificate subject description.'; pl = 'The ""SN"" field is not found in the certificate subject description.';de = 'The ""SN"" field is not found in the certificate subject description.';ro = 'The ""SN"" field is not found in the certificate subject description.';tr = 'The ""SN"" field is not found in the certificate subject description.'; es_ES = 'The ""SN"" field is not found in the certificate subject description.'");
	EndIf;
	SetItem(ThisObject, "LegalCertificate", False, ErrorDescription);
	
	// Availability of a certificate in the personal list.
	If IsCloudServiceApplication Then
		SearchStructure = New Structure;
		SearchStructure.Insert("Thumbprint", Context.CryptoCertificate.Thumbprint);
		ModuleCertificateStoreClient = CommonClient.CommonModule("CertificatesStorageClient");
		ModuleCertificateStoreClient.FindCertificate(New NotifyDescription(
			"CheckAtClientSideAfterCertificateSearchInSaaSMode", ThisObject, Context), SearchStructure);
	Else
		DigitalSignatureInternalClient.GetCertificateByThumbprint(New NotifyDescription(
			"CheckAtClientSideAfterCertificateSearch", ThisObject, Context),
			Base64String(Context.CryptoCertificate.Thumbprint), True, Undefined);
	EndIf;
	
EndProcedure

// Continues the CheckAtClientSide procedure.
&AtClient
Procedure CheckAtClientSideAfterCertificateSearch(Result, Context) Export
	
	If TypeOf(Result) <> Type("CryptoCertificate") Then
		ErrorDescription = Result.ErrorDescription + Chars.LF + Chars.LF
			+ NStr("ru = 'Проверка подписания, созданной подписи и расшифровки не могут быть выполнены.'; en = 'Cannot check signing, created signature and decryption.'; pl = 'Cannot check signing, created signature and decryption.';de = 'Cannot check signing, created signature and decryption.';ro = 'Cannot check signing, created signature and decryption.';tr = 'Cannot check signing, created signature and decryption.'; es_ES = 'Cannot check signing, created signature and decryption.'");
	Else
		ErrorDescription = "";
	EndIf;
	SetItem(ThisObject, "CertificateExists", False, ErrorDescription);
	
	// Checking certificate data.
	DigitalSignatureInternalClient.CreateCryptoManager(New NotifyDescription(
			"CheckAtClientSideAfterCreateAnyCryptoManager", ThisObject, Context),
		"CertificateCheck", False);
	
EndProcedure

// Continues the CheckAtClientSide procedure.
&AtClient
Procedure CheckAtClientSideAfterCertificateSearchInSaaSMode(Result, Context) Export
	
	If TypeOf(Result) = Type("Structure") AND Not Result.Completed Then
		ErrorDescription = BriefErrorDescription(Result.ErrorInfo) + Chars.LF + Chars.LF
			+ NStr("ru = 'Проверка подписания, созданной подписи и расшифровки не могут быть выполнены.'; en = 'Cannot check signing, created signature and decryption.'; pl = 'Cannot check signing, created signature and decryption.';de = 'Cannot check signing, created signature and decryption.';ro = 'Cannot check signing, created signature and decryption.';tr = 'Cannot check signing, created signature and decryption.'; es_ES = 'Cannot check signing, created signature and decryption.'");
	ElsIf TypeOf(Result) <> Type("Structure") Then
		ErrorDescription = Result.ErrorDescription.Details + Chars.LF + Chars.LF
			+ NStr("ru = 'Проверка подписания, созданной подписи и расшифровки не могут быть выполнены.'; en = 'Cannot check signing, created signature and decryption.'; pl = 'Cannot check signing, created signature and decryption.';de = 'Cannot check signing, created signature and decryption.';ro = 'Cannot check signing, created signature and decryption.';tr = 'Cannot check signing, created signature and decryption.'; es_ES = 'Cannot check signing, created signature and decryption.'");
	ElsIf Result.Certificate = Undefined Then
		ErrorDescription = NStr("ru = 'Сертификат не найден в хранилище сертификатов.'; en = 'Certificate is not found in the certificate storage.'; pl = 'Certificate is not found in the certificate storage.';de = 'Certificate is not found in the certificate storage.';ro = 'Certificate is not found in the certificate storage.';tr = 'Certificate is not found in the certificate storage.'; es_ES = 'Certificate is not found in the certificate storage.'") + Chars.LF
			+ NStr("ru = 'Проверка подписания, созданной подписи и расшифровки не могут быть выполнены.'; en = 'Cannot check signing, created signature and decryption.'; pl = 'Cannot check signing, created signature and decryption.';de = 'Cannot check signing, created signature and decryption.';ro = 'Cannot check signing, created signature and decryption.';tr = 'Cannot check signing, created signature and decryption.'; es_ES = 'Cannot check signing, created signature and decryption.'");
	Else
		ErrorDescription = "";
	EndIf;
	SetItem(ThisObject, "CertificateExists", False, ErrorDescription);
	
	// If the certificate is not found in the certificate storage, checks stop.
	If Not IsBlankString(ErrorDescription) Then
		Return;
	EndIf;
	
	// Checking certificate data.
	ModuleCryptoServiceClient = CommonClient.CommonModule("CryptographyServiceClient");
	ModuleCryptoServiceClient.CheckCertificate(New NotifyDescription(
			"CheckAtClientSideAfterCertificateCheckInSaaSMode", ThisObject, Context),
			Result.Certificate.Certificate);
	
EndProcedure

// Continues the CheckAtClientSide procedure.
&AtClient
Procedure CheckAtClientSideAfterCreateAnyCryptoManager(Result, Context) Export
	
	If TypeOf(Result) = Type("CryptoManager") Then
		DigitalSignatureClient.CheckCertificate(New NotifyDescription(
				"CheckAtClientSideAfterCertificateCheck", ThisObject, Context),
			Context.CryptoCertificate, Result);
	Else
		CheckAtClientSideAfterCertificateCheck(Result, Context)
	EndIf;
	
EndProcedure

// Continues the CheckAtClientSide procedure.
&AtClient
Procedure CheckAtClientSideAfterCertificateCheck(Result, Context) Export
	
	If Result = True Then
		ErrorDescription = "";
	Else
		ErrorDescription = Result;
	EndIf;
	SetItem(ThisObject, "CertificateData", False, ErrorDescription, True);
	
	// Application availability
	If ValueIsFilled(Application) Then
		DigitalSignatureInternalClient.CreateCryptoManager(New NotifyDescription(
				"CheckAtClientSideAfterCreateCryptoManager", ThisObject, Context),
			"CertificateCheck", False, Application, CertificatePrivateKeyAdvancedProtection);
	Else
		ErrorDescription = NStr("ru = 'Программа для использования закрытого ключа не указана в сертификате.'; en = 'Application for private key was not specified in the certificate.'; pl = 'Application for private key was not specified in the certificate.';de = 'Application for private key was not specified in the certificate.';ro = 'Application for private key was not specified in the certificate.';tr = 'Application for private key was not specified in the certificate.'; es_ES = 'Application for private key was not specified in the certificate.'");
		CheckAtClientSideAfterCreateCryptoManager(ErrorDescription, Context);
	EndIf;
	
EndProcedure

// Continues the CheckAtClientSide procedure.
&AtClient
Procedure CheckAtClientSideAfterCertificateCheckInSaaSMode(Result, Context) Export
	
	If Result.Completed AND Result.Valid Then
		ErrorDescription = "";
	Else
		ErrorDescription = Result.ErrorInfo.Details;
	EndIf;
	SetItem(ThisObject, "CertificateData", False, ErrorDescription, True);
	
	// Application availability
	If ValueIsFilled(Application) Then
		CheckAtClientSideInSaaSMode("CryptographyService", Context);
	Else
		ErrorDescription = NStr("ru = 'Программа для использования закрытого ключа не указана в сертификате.'; en = 'Application for private key was not specified in the certificate.'; pl = 'Application for private key was not specified in the certificate.';de = 'Application for private key was not specified in the certificate.';ro = 'Application for private key was not specified in the certificate.';tr = 'Application for private key was not specified in the certificate.'; es_ES = 'Application for private key was not specified in the certificate.'");
		CheckAtClientSideAfterCreateCryptoManager(ErrorDescription, Context);
	EndIf;
	
EndProcedure

// Continues the CheckAtClientSide procedure.
&AtClient
Procedure CheckAtClientSideAfterCreateCryptoManager(Result, Context) Export
	
	Context.Insert("CryptoManager", Undefined);
	
	If TypeOf(Result) = Type("CryptoManager") Then
		Context.CryptoManager = Result;
		ErrorDescription = "";
	Else
		ErrorDescription = Result + Chars.LF + Chars.LF
			+ NStr("ru = 'Проверка подписания, созданной подписи, шифрования и
			             |расшифровки не могут быть выполнены.'; 
			             |en = 'Cannot verify signing, signature, 
			             |decryption and encryption.'; 
			             |pl = 'Cannot verify signing, signature, 
			             |decryption and encryption.';
			             |de = 'Cannot verify signing, signature, 
			             |decryption and encryption.';
			             |ro = 'Cannot verify signing, signature, 
			             |decryption and encryption.';
			             |tr = 'Cannot verify signing, signature, 
			             |decryption and encryption.'; 
			             |es_ES = 'Cannot verify signing, signature, 
			             |decryption and encryption.'");
	EndIf;
	SetItem(ThisObject, "ProgramExists", False, ErrorDescription, True);
	
	If Context.CryptoManager = Undefined Then
		ExecuteNotifyProcessing(Context.Notification);
		Return;
	EndIf;
	
	If Not DigitalSignatureInternalClient.InteractiveCryptographyModeUsed(Context.CryptoManager) Then
		Context.CryptoManager.PrivateKeyAccessPassword = PasswordProperties.Value;
	EndIf;
	
	// Signing.
	If ChecksAtClient.CertificateExists Then
		Context.CryptoManager.BeginSigning(New NotifyDescription(
				"CheckAtClientSideAfterSigning", ThisObject, Context,
				"CheckAtClientSideAfterSigningError", ThisObject),
			Context.CertificateData, Context.CryptoCertificate);
	Else
		CheckAtClientSideAfterSigning(Null, Context);
	EndIf;
	
EndProcedure

// Continues the CheckAtClientSide procedure.
&AtClient
Procedure CheckAtClientSideInSaaSMode(Result, Context) Export
	
	Context.Insert("CryptoManager", Undefined);
	
	If TypeOf(Result) = Type("String") AND Result = "CryptographyService" Then
		Context.CryptoManager = Result;
		ErrorDescription = "";
	Else
		ErrorDescription = Result + Chars.LF + Chars.LF
			+ NStr("ru = 'Проверка подписания, созданной подписи, шифрования и
			             |расшифровки не могут быть выполнены.'; 
			             |en = 'Cannot verify signing, signature, 
			             |decryption and encryption.'; 
			             |pl = 'Cannot verify signing, signature, 
			             |decryption and encryption.';
			             |de = 'Cannot verify signing, signature, 
			             |decryption and encryption.';
			             |ro = 'Cannot verify signing, signature, 
			             |decryption and encryption.';
			             |tr = 'Cannot verify signing, signature, 
			             |decryption and encryption.'; 
			             |es_ES = 'Cannot verify signing, signature, 
			             |decryption and encryption.'");
	EndIf;
	SetItem(ThisObject, "ProgramExists", False, ErrorDescription, True);
	
	If Context.CryptoManager = Undefined Then
		ExecuteNotifyProcessing(Context.Notification);
		Return;
	EndIf;
	
	// Signing.
	If ChecksAtClient.CertificateExists Then
		ModuleCryptoServiceClient = CommonClient.CommonModule("CryptographyServiceClient");
		ModuleCryptoServiceClient.Sign(New NotifyDescription(
				"CheckAtClientSideAfterSigningSaaS", ThisObject, Context,
				"CheckAtClientSideAfterSigningError", ThisObject),
			Context.CertificateData, Context.CertificateData);
	Else
		CheckAtClientSideAfterSigning(Null, Context);
	EndIf;
	
EndProcedure

// Continues the CheckAtClientSide procedure.
&AtClient
Procedure CheckAtClientSideAfterSigningError(ErrorInformation, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	CheckAtClientSideAfterSigning(BriefErrorDescription(ErrorInformation), Context);
	
EndProcedure

// Continues the CheckAtClientSide procedure.
&AtClient
Procedure CheckAtClientSideAfterSigning(SignatureData, Context) Export
	
	If SignatureData <> Null Then
		If TypeOf(SignatureData) = Type("String") Then
			ErrorDescription = SignatureData;
		Else
			ErrorDescription = "";
			DigitalSignatureInternalClientServer.BlankSignatureData(SignatureData, ErrorDescription);
		EndIf;
		If Not ValueIsFilled(ErrorDescription) Then
			PasswordAccepted = True;
		EndIf;
		SetItem(ThisObject, "Signing", False, ErrorDescription, True);
	EndIf;
	
	// Checking the signature.
	If ChecksAtClient.CertificateExists AND Not ValueIsFilled(ErrorDescription) Then
		Context.CryptoManager.BeginVerifyingSignature(New NotifyDescription(
				"CheckAtClientSideAfterSignatureCheck", ThisObject, Context,
				"CheckAtClientSideAfterSignatureCheckError", ThisObject),
			Context.CertificateData, SignatureData);
	Else
		CheckAtClientSideAfterSignatureCheck(Null, Context);
	EndIf;
	
EndProcedure

// Continues the CheckAtClientSide procedure.
&AtClient
Procedure CheckAtClientSideAfterSigningSaaS(SignatureData, Context) Export
	
	If TypeOf(SignatureData) = Type("Structure") Then
		If Not SignatureData.Completed Then
			ErrorDescription = SignatureData.ErrorInfo.Details;
		Else
			ErrorDescription = "";
			SignatureData = SignatureData.Signature;
			DigitalSignatureInternalClientServer.BlankSignatureData(SignatureData, ErrorDescription);
		EndIf;
		If Not ValueIsFilled(ErrorDescription) Then
			PasswordAccepted = True;
		EndIf;
		SetItem(ThisObject, "Signing", False, ErrorDescription, True);
	EndIf;
	
	// Checking the signature.
	If ChecksAtClient.CertificateExists AND Not ValueIsFilled(ErrorDescription) Then
		ModuleCryptoServiceClient = CommonClient.CommonModule("CryptographyServiceClient");
		ModuleCryptoServiceClient.VerifySignature(New NotifyDescription(
					"CheckAtClientSideAfterSignatureCheckInSaaSMode", ThisObject, Context,
					"CheckAtClientSideAfterSignatureCheckError", ThisObject),
				SignatureData, Context.CertificateData);
	Else
		CheckAtClientSideAfterSignatureCheckInSaaSMode(Null, Context);
	EndIf;
	
EndProcedure

// Continues the CheckAtClientSide procedure.
&AtClient
Procedure CheckAtClientSideAfterSignatureCheckError(ErrorInformation, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	CheckAtClientSideAfterSignatureCheck(BriefErrorDescription(ErrorInformation), Context);
	
EndProcedure

// Continues the CheckAtClientSide procedure.
&AtClient
Procedure CheckAtClientSideAfterSignatureCheck(Certificate, Context) Export
	
	If Certificate <> Null Then
		If TypeOf(Certificate) = Type("String") Then
			ErrorDescription = Certificate;
		Else
			ErrorDescription = "";
		EndIf;
		SetItem(ThisObject, "SignatureCheck", False, ErrorDescription, True);
	EndIf;
	
	// Encryption.
	Context.CryptoManager.BeginEncrypting(New NotifyDescription(
			"CheckAtClientSideAfterEncryption", ThisObject, Context,
			"CheckAtClientSideAfterEncryptionError", ThisObject),
		Context.CertificateData, Context.CryptoCertificate);
	
EndProcedure
	
// Continues the CheckAtClientSide procedure.
&AtClient
Procedure CheckAtClientSideAfterSignatureCheckInSaaSMode(Result, Context) Export
	
	If TypeOf(Result) = Type("Structure") Then
		If Not Result.Completed Then
			ErrorDescription = Result.ErrorInfo.Details;
		Else
			ErrorDescription = "";
		EndIf;
		SetItem(ThisObject, "SignatureCheck", False, ErrorDescription, True);
	EndIf;
	
	// Encryption.
	ModuleCryptoServiceClient = CommonClient.CommonModule("CryptographyServiceClient");
	ModuleCryptoServiceClient.Encrypt(New NotifyDescription(
			"CheckAtClientSideAfterEncryptionInSaaSMode", ThisObject, Context,
			"CheckAtClientSideAfterEncryptionError", ThisObject),
			Context.CertificateData, Context.CertificateData);
	
EndProcedure

// Continues the CheckAtClientSide procedure.
&AtClient
Procedure CheckAtClientSideAfterEncryptionError(ErrorInformation, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	CheckAtClientSideAfterEncryption(BriefErrorDescription(ErrorInformation), Context);
	
EndProcedure

// Continues the CheckAtClientSide procedure.
&AtClient
Procedure CheckAtClientSideAfterEncryption(EncryptedData, Context) Export
	
	If TypeOf(EncryptedData) = Type("String") Then
		ErrorDescription = EncryptedData;
	Else
		ErrorDescription = "";
	EndIf;
	SetItem(ThisObject, "Encryption", False, ErrorDescription, True);
	
	// Decryption.
	If ChecksAtClient.CertificateExists AND Not ValueIsFilled(ErrorDescription) Then
		Context.CryptoManager.BeginDecrypting(New NotifyDescription(
				"CheckAtClientSideAfterDecryption", ThisObject, Context,
				"CheckAtClientSideAfterDecryptionError", ThisObject),
			EncryptedData);
	Else
		CheckAtClientSideAfterDecryption(Null, Context);
	EndIf;
	
EndProcedure

// Continues the CheckAtClientSide procedure.
&AtClient
Procedure CheckAtClientSideAfterEncryptionInSaaSMode(Result, Context) Export
	
	If TypeOf(Result) = Type("Structure") Then
		If Not Result.Completed Then
			ErrorDescription = Result.ErrorInfo.Details;
		Else
			ErrorDescription = "";
		EndIf;
	EndIf;
	SetItem(ThisObject, "Encryption", False, ErrorDescription, True);
	
	// Decryption.
	If ChecksAtClient.CertificateExists AND Not ValueIsFilled(ErrorDescription) Then
		ModuleCryptoServiceClient = CommonClient.CommonModule("CryptographyServiceClient");
		ModuleCryptoServiceClient.Decrypt(New NotifyDescription(
				"CheckAtClientSideAfterDecryptionInSaaSMode", ThisObject, Context,
				"CheckAtClientSideAfterDecryptionError", ThisObject),
			Result.EncryptedData);
	Else
		CheckAtClientSideAfterDecryptionInSaaSMode(Null, Context);
	EndIf;
	
EndProcedure

// Continues the CheckAtClientSide procedure.
&AtClient
Procedure CheckAtClientSideAfterDecryptionError(ErrorInformation, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	CheckAtClientSideAfterDecryption(BriefErrorDescription(ErrorInformation), Context);
	
EndProcedure

// Continues the CheckAtClientSide procedure.
&AtClient
Procedure CheckAtClientSideAfterDecryption(DecryptedData, Context) Export
	
	If DecryptedData <> Null Then
		If TypeOf(DecryptedData) = Type("String") Then
			ErrorDescription = DecryptedData;
		Else
			ErrorDescription = "";
		EndIf;
		DigitalSignatureInternalClientServer.BlankDecryptedData(DecryptedData, ErrorDescription);
		SetItem(ThisObject, "Details", False, ErrorDescription, True);
	EndIf;
	
	CheckAtClientSideAdditionalChecks(Context);
	
EndProcedure

// Continues the CheckAtClientSide procedure.
&AtClient
Procedure CheckAtClientSideAfterDecryptionInSaaSMode(Result, Context) Export
	
	If TypeOf(Result) = Type("Structure") Then
		If Not Result.Completed Then
			ErrorDescription = Result.ErrorInfo.Details;
		Else
			ErrorDescription = "";
			DigitalSignatureInternalClientServer.BlankDecryptedData(Result.DecryptedData, ErrorDescription);
		EndIf;
		SetItem(ThisObject, "Details", False, ErrorDescription, True);
	EndIf;
	
	CheckAtClientSideAdditionalChecks(Context);
	
EndProcedure

// Continues the CheckAtClientSide procedure.
&AtClient
Procedure CheckAtClientSideAdditionalChecks(Context)
	
	// Additional checks.
	Context.Insert("IndexOf", -1);
	
	CheckAtClientSideLoopStart(Context);
	
EndProcedure

// Continues the CheckAtClientSide procedure.
&AtClient
Procedure CheckAtClientSideLoopStart(Context)
	
	If AdditionalChecks.Count() <= Context.IndexOf + 1 Then
		ExecuteNotifyProcessing(Context.Notification);
		Return;
	EndIf;
	Context.IndexOf = Context.IndexOf + 1;
	Context.Insert("ListItem", AdditionalChecks[Context.IndexOf]);
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("Certificate",           Certificate);
	ExecutionParameters.Insert("CheckSSL",             Context.ListItem.Value);
	ExecutionParameters.Insert("CryptoManager", Context.CryptoManager);
	ExecutionParameters.Insert("ErrorDescription",       "");
	ExecutionParameters.Insert("IsWarning",    False);
	ExecutionParameters.Insert("WaitForContinue",   False);
	ExecutionParameters.Insert("Password",               ?(EnterPassword, PasswordProperties.Value, Undefined));
	ExecutionParameters.Insert("ChecksResults",   ChecksAtClient);
	ExecutionParameters.Insert("Notification",           New NotifyDescription(
		"CheckAtClientSideAfterAdditionalCheck", ThisObject, Context));
	
	Context.Insert("ExecutionParameters", ExecutionParameters);
	
	Try
		DigitalSignatureClientOverridable.OnAdditionalCertificateCheck(ExecutionParameters);
	Except
		ErrorInformation = ErrorInfo();
		ExecutionParameters.WaitForContinue = False;
		ExecutionParameters.ErrorDescription = BriefErrorDescription(ErrorInformation);
	EndTry;
	
	If ExecutionParameters.WaitForContinue <> True Then
		CheckAtClientSideAfterAdditionalCheck(Undefined, Context);
	EndIf;
	
EndProcedure

// Continues the CheckAtClientSide procedure.
&AtClient
Procedure CheckAtClientSideAfterAdditionalCheck(NotDefined, Context) Export
	
	SetItem(ThisObject, Context.ListItem.Value, False,
		Context.ExecutionParameters.ErrorDescription,
		Context.ExecutionParameters.IsWarning <> True);
	
	CheckAtClientSideLoopStart(Context);
	
EndProcedure


&AtServer
Procedure CheckAtServerSide(Val PasswordValue)
	
	CertificateData = GetFromTempStorage(CertificateAddress);
	
	Try
		CryptoCertificate = New CryptoCertificate(CertificateData);
		ErrorDescription = "";
	Except
		ErrorInformation = ErrorInfo();
		ErrorDescription = BriefErrorDescription(ErrorInformation);
	EndTry;
	
	If ValueIsFilled(ErrorDescription) Then
		SetItem(ThisObject, FirstCheckName, True, ErrorDescription, True);
		Return;
	EndIf;
	
	// Legitimate certificate
	If Not Items.LegalCertificateGroup.Visible
	 Or CryptoCertificate.Subject.Property("SN") Then
		ErrorDescription = "";
	Else
		ErrorDescription = NStr("ru = 'В описании субъекта сертификата не найдено поле ""SN"".'; en = 'The ""SN"" field is not found in the certificate subject description.'; pl = 'The ""SN"" field is not found in the certificate subject description.';de = 'The ""SN"" field is not found in the certificate subject description.';ro = 'The ""SN"" field is not found in the certificate subject description.';tr = 'The ""SN"" field is not found in the certificate subject description.'; es_ES = 'The ""SN"" field is not found in the certificate subject description.'");
	EndIf;
	SetItem(ThisObject, "LegalCertificate", True, ErrorDescription);
	
	// Availability of a certificate in the personal list.
	Result = New Structure;
	DigitalSignatureInternal.GetCertificateByThumbprint(Base64String(CryptoCertificate.Thumbprint),
		True, False, , Result);
	If ValueIsFilled(Result) Then
		ErrorDescription = Result.ErrorDescription + Chars.LF + Chars.LF
			+ NStr("ru = 'Проверка подписания, созданной подписи и расшифровки не могут быть выполнены.'; en = 'Cannot check signing, created signature and decryption.'; pl = 'Cannot check signing, created signature and decryption.';de = 'Cannot check signing, created signature and decryption.';ro = 'Cannot check signing, created signature and decryption.';tr = 'Cannot check signing, created signature and decryption.'; es_ES = 'Cannot check signing, created signature and decryption.'");
	Else
		ErrorDescription = "";
	EndIf;
	SetItem(ThisObject, "CertificateExists", True, ErrorDescription);
	
	// Checking certificate data.
	ErrorDescription = "";
	CryptoManager = DigitalSignatureInternal.CryptoManager("CertificateCheck",
		False, ErrorDescription);
	
	If Not ValueIsFilled(ErrorDescription) Then
		DigitalSignature.CheckCertificate(CryptoManager, CryptoCertificate, ErrorDescription);
	EndIf;
	SetItem(ThisObject, "CertificateData", True, ErrorDescription, True);
	
	// Application availability
	If ValueIsFilled(Application) Then
		ErrorDescription = "";
		CryptoManager = DigitalSignatureInternal.CryptoManager("",
			False, ErrorDescription, Application);
	Else
		CryptoManager = Undefined;
		ErrorDescription = NStr("ru = 'Программа для использования закрытого ключа не указана в сертификате.'; en = 'Application for private key was not specified in the certificate.'; pl = 'Application for private key was not specified in the certificate.';de = 'Application for private key was not specified in the certificate.';ro = 'Application for private key was not specified in the certificate.';tr = 'Application for private key was not specified in the certificate.'; es_ES = 'Application for private key was not specified in the certificate.'");
	EndIf;
	If ValueIsFilled(ErrorDescription) Then
		ErrorDescription = ErrorDescription + Chars.LF + Chars.LF
			+ NStr("ru = 'Проверка подписания, созданной подписи, шифрования и
			             |расшифровки не могут быть выполнены.'; 
			             |en = 'Cannot verify signing, signature, 
			             |decryption and encryption.'; 
			             |pl = 'Cannot verify signing, signature, 
			             |decryption and encryption.';
			             |de = 'Cannot verify signing, signature, 
			             |decryption and encryption.';
			             |ro = 'Cannot verify signing, signature, 
			             |decryption and encryption.';
			             |tr = 'Cannot verify signing, signature, 
			             |decryption and encryption.'; 
			             |es_ES = 'Cannot verify signing, signature, 
			             |decryption and encryption.'");
	EndIf;
	SetItem(ThisObject, "ProgramExists", True, ErrorDescription, True);
	
	If CryptoManager = Undefined Then
		Return;
	EndIf;
	
	CryptoManager.PrivateKeyAccessPassword = PasswordValue;
	
	// Signing.
	If ChecksAtServer.CertificateExists Then
		ErrorDescription = "";
		Try
			SignatureData = CryptoManager.Sign(CertificateData, CryptoCertificate);
			DigitalSignatureInternalClientServer.BlankSignatureData(SignatureData, ErrorDescription);
		Except
			ErrorInformation = ErrorInfo();
			ErrorDescription = BriefErrorDescription(ErrorInformation);
		EndTry;
		If Not ValueIsFilled(ErrorDescription) Then
			PasswordAccepted = True;
		EndIf;
		SetItem(ThisObject, "Signing", True, ErrorDescription, True);
	EndIf;
	
	// Checking the signature.
	If ChecksAtServer.CertificateExists AND Not ValueIsFilled(ErrorDescription) Then
		ErrorDescription = "";
		Try
			CryptoManager.VerifySignature(CertificateData, SignatureData);
		Except
			ErrorInformation = ErrorInfo();
			ErrorDescription = BriefErrorDescription(ErrorInformation);
		EndTry;
		SetItem(ThisObject, "SignatureCheck", True, ErrorDescription, True);
	EndIf;
	
	// Encryption.
	ErrorDescription = "";
	Try
		EncryptedData = CryptoManager.Encrypt(CertificateData, CryptoCertificate);
	Except
		ErrorInformation = ErrorInfo();
		ErrorDescription = BriefErrorDescription(ErrorInformation);
	EndTry;
	SetItem(ThisObject, "Encryption", True, ErrorDescription, True);
	
	// Decryption.
	If ChecksAtServer.CertificateExists AND Not ValueIsFilled(ErrorDescription) Then
		ErrorDescription = "";
		Try
			DecryptedData = CryptoManager.Decrypt(EncryptedData);
			DigitalSignatureInternalClientServer.BlankDecryptedData(DecryptedData, ErrorDescription);
		Except
			ErrorInformation = ErrorInfo();
			ErrorDescription = BriefErrorDescription(ErrorInformation);
		EndTry;
		SetItem(ThisObject, "Details", True, ErrorDescription, True);
	EndIf;
	
	CheckAtServerSideAdditionalChecks(PasswordValue, CryptoManager);
	
EndProcedure

&AtServer
Procedure CheckAtServerSideAdditionalChecks(PasswordValue, CryptoManager = Undefined)
	
	// Additional checks.
	For Each ListItem In AdditionalChecks Do
		ErrorDescription = "";
		IsWarning = False;
		Try
			ExecutionParameters = New Structure;
			ExecutionParameters.Insert("Certificate",           Certificate);
			ExecutionParameters.Insert("CheckSSL",             ListItem.Value);
			ExecutionParameters.Insert("CryptoManager", CryptoManager);
			ExecutionParameters.Insert("ErrorDescription",       ErrorDescription);
			ExecutionParameters.Insert("IsWarning",    IsWarning);
			ExecutionParameters.Insert("Password",               ?(EnterPassword, PasswordValue, Undefined));
			ExecutionParameters.Insert("ChecksResults",   ChecksAtServer);
			DigitalSignatureOverridable.OnAdditionalCertificateCheck(ExecutionParameters);
		Except
			ErrorInformation = ErrorInfo();
			ErrorDescription = BriefErrorDescription(ErrorInformation);
		EndTry;
		SetItem(ThisObject, ListItem.Value, True, ErrorDescription, IsWarning <> True);
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetItem(Form, BeginItem, AtServer, ErrorDescription = Undefined, IsError = False)
	
	ItemPicture = Form.Items[BeginItem + ?(AtServer, "AtServer", "AtClient") + "Picture"];
	Checks = Form["Validation" + ?(AtServer, "AtServer", "AtClient")];
	
	If ErrorDescription = Undefined Then
		ItemPicture.Picture    = New Picture;
		ItemPicture.ToolTip   = NStr("ru = 'Проверка не выполнялась.'; en = 'No check was performed.'; pl = 'No check was performed.';de = 'No check was performed.';ro = 'No check was performed.';tr = 'No check was performed.'; es_ES = 'No check was performed.'");
		Checks.Insert(BeginItem, Undefined);
		
	ElsIf ValueIsFilled(ErrorDescription) Then
		ItemPicture.Picture    = ?(IsError, PictureLib.Error32, PictureLib.Warning32);
		ItemPicture.ToolTip   = ErrorDescription;
		Checks.Insert(BeginItem, False);
	Else
		ItemPicture.Picture    = PictureLib.Done32;
		ItemPicture.ToolTip   = NStr("ru = 'Проверка выполнена успешно.'; en = 'Check succeeded.'; pl = 'Check succeeded.';de = 'Check succeeded.';ro = 'Check succeeded.';tr = 'Check succeeded.'; es_ES = 'Check succeeded.'");;
		Checks.Insert(BeginItem, True);
	EndIf;
	
EndProcedure

#EndRegion
