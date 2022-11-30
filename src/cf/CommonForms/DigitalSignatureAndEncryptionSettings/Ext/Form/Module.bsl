///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var ApplicationsCheckPerformed;

#EndRegion

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	DigitalSignatureInternal.SetCertificateListConditionalAppearance(Certificates, True);
	
	URL = "e1cib/app/CommonForm.DigitalSignatureAndEncryptionSettings";
	
	If Not AccessRight("SaveUserData", Metadata) Then
		Items.SettingsPage.Visible = False;
		NoRightToSaveUserData = True;
	EndIf;
	
	IsFullUser = Users.IsFullUser();
	
	If Parameters.Property("ShowCertificatesPage") Then
		Items.Pages.CurrentPage = Items.CertificatesPage;
		
	ElsIf Parameters.Property("ShowSettingsPage") Then
		Items.Pages.CurrentPage = Items.SettingsPage;
		
	ElsIf Parameters.Property("ShowApplicationsPage") Then
		Items.Pages.CurrentPage = Items.ApplicationPage;
	EndIf;
	
	If Common.DataSeparationEnabled() Then
		SetSignatureCheckAtServer(False);
		Items.CheckSignaturesAtServer.Visible = False;
		Items.SignAtServer.Visible = False;
	Else
		CheckSignaturesAtServer = Constants.VerifyDigitalSignaturesOnTheServer.Get();
		SignAtServer      = Constants.GenerateDigitalSignaturesAtServer.Get();
	EndIf;
	
	If Users.IsFullUser() Then
		CertificatesShow = "AllCertificates";
	Else
		CertificatesShow = "MyCertificates";
		
		// Application page
		Items.Applications.ChangeRowSet = False;
		
		CommonClientServer.SetFormItemProperty(Items,
			"ApplicationsAdd", "Visible", False);
		
		CommonClientServer.SetFormItemProperty(Items,
			"ApplicationsChange", "Visible", False);
		
		Items.ApplicationsMarkForDeletion.Visible = False;
		
		CommonClientServer.SetFormItemProperty(Items,
			"ApplicationsContextMenuAdd", "Visible", False);
		
		CommonClientServer.SetFormItemProperty(Items,
			"ApplicationsContextMenuChange", "Visible", False);
		
		Items.ApplicationsContextMenuApplicationsMarkForDeletion.Visible = False;
		Items.CheckSignaturesAtServer.Visible = False;
		Items.SignAtServer.Visible = False;
		Items.Applications.Title =
			NStr("ru = 'Список программ, предусмотренных администратором, которые можно использовать на компьютере'; en = 'List of applications provided by administrator which can be used on your computer'; pl = 'List of applications provided by administrator which can be used on your computer';de = 'List of applications provided by administrator which can be used on your computer';ro = 'List of applications provided by administrator which can be used on your computer';tr = 'List of applications provided by administrator which can be used on your computer'; es_ES = 'List of applications provided by administrator which can be used on your computer'");
	EndIf;
	
	If Not DigitalSignature.CommonSettings().CertificateIssueRequestAvailable Then
		CommonClientServer.SetFormItemProperty(Items,
			"CertificatesCreate", "Visible", True);
		
		Items.CertificatesAdd.Visible           = False;
		Items.CertificatesShowRequests.Visible  = False;
		Items.Instruction.Visible                    = False;
	EndIf;
	
	CertificatesUpdateFilter(ThisObject, Users.CurrentUser());
	
	If Common.IsSubordinateDIBNode() Then
		// The components and settings of the provided applications cannot be changed.
		// You can only change application paths at Linux servers.
		Items.Applications.ChangeRowSet = False;
		Items.ApplicationsMarkForDeletion.Enabled = False;
		Items.ApplicationsContextMenuApplicationsMarkForDeletion.Enabled = False;
		CommonClientServer.SetFormItemProperty(Items,
			"ApplicationsChange", "OnlyInAllActions", False);
	EndIf;
	
	If Common.IsWindowsClient() Then
		Items.ApplicationsLinuxPathToApplicationGroup.Visible = False;
	EndIf;
	
	Items.WebClientExtentionNotInstalledGroup.Visible =
		  Common.IsWebClient()
		AND Parameters.Property("ExtensionNotAttached");
	
	FillApplicationsAndSettings();
	
	UpdateCurrentItemsVisibility();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	DefineInstalledApplications();
	
EndProcedure

&AtClient
Procedure OnReopen()
	
	DefineInstalledApplications();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If Upper(EventName) = Upper("Write_DigitalSignatureAndEncryptionKeyCertificates")
	   AND Parameter.Property("IsNew") Then
		
		Items.Certificates.Refresh();
		Items.Certificates.CurrentRow = Source;
		Return;
	EndIf;
	
	// When changing application components or settings.
	If Upper(EventName) = Upper("Write_DigitalSignatureAndEncryptionSoftware")
	 Or Upper(EventName) = Upper("Write_PathToDigitalSignatureAndEncryptionSoftwareAtServer")
	 Or Upper(EventName) = Upper("Write_PersonalSettingsForDigitalSignatureAndEncryption") Then
		
		AttachIdleHandler("OnChangeApplicationsCompositionOrSettings", 0.1, True);
		Return;
	EndIf;
	
	If Upper(EventName) = Upper("Install_CryptoExtension") Then
		DefineInstalledApplications();
		Return;
	EndIf;
	
	// When changing usage settings.
	If Upper(EventName) <> Upper("Write_ConstantsSet") Then
		Return;
	EndIf;
	
	If Upper(Source) = Upper("UseDigitalSignature")
	 Or Upper(Source) = Upper("UseEncryption") Then
		
		AttachIdleHandler("OnChangeSigningOrEncryptionUsage", 0.1, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PageOnChangePage(Item, CurrentPage)
	
	If ApplicationsCheckPerformed <> True Then
		DefineInstalledApplications();
	EndIf;
	
EndProcedure

&AtClient
Procedure CertificatesShowOnChange(Item)
	
	CertificatesUpdateFilter(ThisObject, UsersClient.CurrentUser());
	
EndProcedure

&AtClient
Procedure CertificatesShowApplicationsOnChange(Item)
	
	CertificatesUpdateFilter(ThisObject, UsersClient.CurrentUser());
	
EndProcedure

&AtClient
Procedure ExtensionForEncryptedFilesOnChange(Item)
	
	If IsBlankString(EncryptedFilesExtension) Then
		EncryptedFilesExtension = "p7m";
	EndIf;
	
	SaveSettings();
	
EndProcedure

&AtClient
Procedure ExtensionForSignatureFilesOnChange(Item)
	
	If IsBlankString(SignatureFilesExtension) Then
		SignatureFilesExtension = "p7s";
	EndIf;
	
	SaveSettings();
	
EndProcedure

&AtClient
Procedure ActionsOnSaveDataWithDigitalSignatureOnChange(Item)
	
	SaveSettings();
	
EndProcedure

&AtClient
Procedure CheckSignaturesAtServerOnChange(Item)
	
	SetSignatureCheckAtServer(CheckSignaturesAtServer);
	
	Notify("Write_ConstantsSet", New Structure, "VerifyDigitalSignaturesOnTheServer");
	
EndProcedure

&AtClient
Procedure SignAtServerOnChange(Item)
	
	SetSigningAtServer(SignAtServer);
	
	Notify("Write_ConstantsSet", New Structure, "GenerateDigitalSignaturesAtServer");
	
EndProcedure

&AtClient
Procedure SaveCertificateWithSignatureOnChange(Item)
	SaveSettings();
EndProcedure

#EndRegion

#Region CertificatesFormTableItemsEventHandlers

&AtClient
Procedure CertificatesBeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)
	
	Cancel = True;
	If Not Clone Then
		CreationParameters = New Structure;
		CreationParameters.Insert("HideApplication", False);
		DigitalSignatureInternalClient.AddCertificate(CreationParameters);
	EndIf;
	
EndProcedure

#EndRegion

#Region ApplicationsFormTableItemsEventHandlers

&AtClient
Procedure ApplicationsOnActivateRow(Item)
	
	Items.ApplicationsMarkForDeletion.Enabled =
		Items.Applications.CurrentData <> Undefined;
	
	If Items.Applications.CurrentData <> Undefined Then
		LinuxPathToCurrentApplication = Items.Applications.CurrentData.LinuxPathToApplication;
	EndIf;
	
EndProcedure

&AtClient
Procedure ApplicationsBeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)
	
	Cancel = True;
	
	If Items.Applications.ChangeRowSet Then
		OpenForm("Catalog.DigitalSignatureAndEncryptionApplications.ObjectForm");
	EndIf;
	
EndProcedure

&AtClient
Procedure ApplicationsBeforeChangeRow(Item, Cancel)
	
	Cancel = True;
	
	If Items.Find("ApplicationsChange") <> Undefined
	   AND Items.ApplicationsChange.Visible Then
		
		ShowValue(, Items.Applications.CurrentData.Ref);
	EndIf;
	
EndProcedure

&AtClient
Procedure ApplicationsBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
	If Items.Find("ApplicationsChange") <> Undefined
	   AND Items.ApplicationsChange.Visible Then
		
		ApplicationsMarkForDeletion(Undefined);
	EndIf;
	
EndProcedure

&AtClient
Procedure LinuxApplicationsApplicationPathOnChange(Item)
	
	CurrentData = Items.Applications.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If NoRightToSaveUserData Then
		CurrentData.LinuxPathToApplication = LinuxPathToCurrentApplication;
		ShowMessageBox(,
			NStr("ru = 'Невозможно сохранить путь к программе. Отсутствует право сохранения данных.
			           |Обратитесь к администратору.'; 
			           |en = 'Cannot save path to the application. You do not have sufficient rights to save data.
			           |Contact your administrator.'; 
			           |pl = 'Cannot save path to the application. You do not have sufficient rights to save data.
			           |Contact your administrator.';
			           |de = 'Cannot save path to the application. You do not have sufficient rights to save data.
			           |Contact your administrator.';
			           |ro = 'Cannot save path to the application. You do not have sufficient rights to save data.
			           |Contact your administrator.';
			           |tr = 'Cannot save path to the application. You do not have sufficient rights to save data.
			           |Contact your administrator.'; 
			           |es_ES = 'Cannot save path to the application. You do not have sufficient rights to save data.
			           |Contact your administrator.'"));
	Else
		SaveLinuxPathAtServer(CurrentData.Ref, CurrentData.LinuxPathToApplication);
		DefineInstalledApplications();
	EndIf;
	
EndProcedure

&AtClient
Procedure InstructionClick(Item)
	
	DigitalSignatureInternalClient.OpenInstructionOfWorkWithApplications();
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Update(Command)
	
	FillApplicationsAndSettings(True);
	
	DefineInstalledApplications();
	
EndProcedure

&AtClient
Procedure AddCertificateIssueRequest(Command)
	
	CreationParameters = New Structure;
	CreationParameters.Insert("CreateRequest", True);
	
	DigitalSignatureInternalClient.AddCertificate(CreationParameters);
	
EndProcedure

&AtClient
Procedure AddFromCertificatesInstalledOnComputer(Command)
	
	DigitalSignatureInternalClient.AddCertificate();
	
EndProcedure

&AtClient
Procedure InstallExtension(Command)
	
	DigitalSignatureClient.InstallExtension(True);
	
EndProcedure

&AtClient
Procedure ApplicationsMarkForDeletion(Command)
	
	CurrentData = Items.Applications.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.DeletionMark Then
		QuestionText = NStr("ru = 'Снять с ""%1"" пометку на удаление?'; en = 'Do you want to clear a deletion mark for ""%1""?'; pl = 'Do you want to clear a deletion mark for ""%1""?';de = 'Do you want to clear a deletion mark for ""%1""?';ro = 'Do you want to clear a deletion mark for ""%1""?';tr = 'Do you want to clear a deletion mark for ""%1""?'; es_ES = 'Do you want to clear a deletion mark for ""%1""?'");
	Else
		QuestionText = NStr("ru = 'Пометить ""%1"" на удаление?'; en = 'Do you want to mark %1 for deletion?'; pl = 'Do you want to mark %1 for deletion?';de = 'Do you want to mark %1 for deletion?';ro = 'Do you want to mark %1 for deletion?';tr = 'Do you want to mark %1 for deletion?'; es_ES = 'Do you want to mark %1 for deletion?'");
	EndIf;
	
	QuestionContent = New Array;
	QuestionContent.Add(PictureLib.Question32);
	QuestionContent.Add(StringFunctionsClientServer.SubstituteParametersToString(QuestionText, CurrentData.Description));
	
	ShowQueryBox(
		New NotifyDescription("ApplicationsSetDeletionMarkContinue", ThisObject, CurrentData.Ref),
		New FormattedString(QuestionContent),
		QuestionDialogMode.YesNo);
	
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	// Managing the appearance for successful application installation message.
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("TextColor");
	AppearanceColorItem.Value = Metadata.StyleItems.NoteText.Value;
	AppearanceColorItem.Use = True;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue  = New DataCompositionField("Applications.Use");
	DataFilterItem.ComparisonType   = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = True;
	DataFilterItem.Use  = True;
	
	AppearanceFieldItem = ConditionalAppearanceItem.Fields.Items.Add();
	AppearanceFieldItem.Field = New DataCompositionField("ApplicationsCheckResult");
	AppearanceFieldItem.Use = True;
	
	// Managing the appearance for application installation error message.
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("TextColor");
	AppearanceColorItem.Value = Metadata.StyleItems.ErrorNoteText.Value;
	AppearanceColorItem.Use = True;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue  = New DataCompositionField("Applications.Use");
	DataFilterItem.ComparisonType   = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = False;
	DataFilterItem.Use  = True;
	
	AppearanceFieldItem = ConditionalAppearanceItem.Fields.Items.Add();
	AppearanceFieldItem.Field = New DataCompositionField("ApplicationsCheckResult");
	AppearanceFieldItem.Use = True;
	
EndProcedure

&AtClientAtServerNoContext
Procedure CertificatesUpdateFilter(Form, CurrentUser)
	
	Items = Form.Items;
	
	// Filtering certificates All/My.
	ShowOwnCertificates = Form.CertificatesShow <> "AllCertificates";
	
	CommonClientServer.SetDynamicListFilterItem(
		Form.Certificates, "User", CurrentUser,,, ShowOwnCertificates);
	
	Items.CertificatesUser.Visible = Not ShowOwnCertificates;
	
	If Items.CertificatesShowRequests.Visible Then
		// Filtering certificates by the application state.
		FilterByApplicationState = ValueIsFilled(Form.CertificatesShowRequests);
		CommonClientServer.SetDynamicListFilterItem(Form.Certificates,
			"ApplicationState", Form.CertificatesShowRequests, , , FilterByApplicationState);
	EndIf;
	
EndProcedure

&AtClient
Procedure ApplicationsSetDeletionMarkContinue(Response, CurrentApplication) Export
	
	If Response = DialogReturnCode.Yes Then
		ChangeApplicationDeletionMark(CurrentApplication);
		NotifyChanged(CurrentApplication);
		Notify("Write_DigitalSignatureAndEncryptionSoftware", New Structure, CurrentApplication);
		DefineInstalledApplications();
	EndIf;
	
EndProcedure

&AtServer
Procedure ChangeApplicationDeletionMark(Application)
	
	LockDataForEdit(Application, , UUID);
	
	Try
		Object = Application.GetObject();
		Object.DeletionMark = Not Object.DeletionMark;
		Object.Write();
	Except
		UnlockDataForEdit(Application, UUID);
		Raise;
	EndTry;
	
	UnlockDataForEdit(Application, UUID);
	
	FillApplicationsAndSettings(True);
	
EndProcedure

&AtClient
Procedure OnChangeSigningOrEncryptionUsage()
	
	UpdateCurrentItemsVisibility();
	
EndProcedure

&AtServer
Procedure UpdateCurrentItemsVisibility()
	
	If Constants.UseEncryption.Get()
	 Or DigitalSignature.CommonSettings().CertificateIssueRequestAvailable Then
		
		CommonClientServer.SetFormItemProperty(Items,
			"CertificatesCreate", "Title", NStr("ru = 'Добавить...'; en = 'Add...'; pl = 'Add...';de = 'Add...';ro = 'Add...';tr = 'Add...'; es_ES = 'Add...'"));
		
		CommonClientServer.SetFormItemProperty(Items,
			"CertificatesContextMenuCreate", "Title", NStr("ru = 'Добавить...'; en = 'Add...'; pl = 'Add...';de = 'Add...';ro = 'Add...';tr = 'Add...'; es_ES = 'Add...'"));
		
		Items.EncryptedFilesExtension.Visible = True;
	Else
		CommonClientServer.SetFormItemProperty(Items,
			"CertificatesCreate", "Title", NStr("ru = 'Добавить'; en = 'Add'; pl = 'Add';de = 'Add';ro = 'Add';tr = 'Add'; es_ES = 'Add'"));
		
		CommonClientServer.SetFormItemProperty(Items,
			"CertificatesContextMenuCreate", "Title", NStr("ru = 'Добавить'; en = 'Add'; pl = 'Add';de = 'Add';ro = 'Add';tr = 'Add'; es_ES = 'Add'"));
		
		Items.EncryptedFilesExtension.Visible = False;
	EndIf;
	
	If Constants.UseEncryption.Get() Then
		If DigitalSignatureInternal.UseDigitalSignatureSaaS() Then
			Items.AddFromCertificatesInstalledOnComputer.Title =
				NStr("ru = 'Из установленных в облачном сервисе и на компьютере...'; en = 'From the ones installed in cloud service and computer...'; pl = 'From the ones installed in cloud service and computer...';de = 'From the ones installed in cloud service and computer...';ro = 'From the ones installed in cloud service and computer...';tr = 'From the ones installed in cloud service and computer...'; es_ES = 'From the ones installed in cloud service and computer...'");
		Else
			Items.AddFromCertificatesInstalledOnComputer.Title =
				NStr("ru = 'Из установленных на компьютере...'; en = 'From the ones installed on computer...'; pl = 'From the ones installed on computer...';de = 'From the ones installed on computer...';ro = 'From the ones installed on computer...';tr = 'From the ones installed on computer...'; es_ES = 'From the ones installed on computer...'");
		EndIf;
	Else
		If DigitalSignatureInternal.UseDigitalSignatureSaaS() Then
			Items.AddFromCertificatesInstalledOnComputer.Title =
				NStr("ru = 'Из установленных в облачном сервисе и на компьютере'; en = 'From ones installed in the cloud service and computer'; pl = 'From ones installed in the cloud service and computer';de = 'From ones installed in the cloud service and computer';ro = 'From ones installed in the cloud service and computer';tr = 'From ones installed in the cloud service and computer'; es_ES = 'From ones installed in the cloud service and computer'");
		Else
			Items.AddFromCertificatesInstalledOnComputer.Title =
				NStr("ru = 'Из установленных на компьютере'; en = 'From the ones installed on computer'; pl = 'From the ones installed on computer';de = 'From the ones installed on computer';ro = 'From the ones installed on computer';tr = 'From the ones installed on computer'; es_ES = 'From the ones installed on computer'");
		EndIf;
	EndIf;
	
	If Constants.UseDigitalSignature.Get() Then
		CheckBoxTitle = NStr("ru = 'Проверять подписи и сертификаты на сервере'; en = 'Check signatures and certificates on server'; pl = 'Check signatures and certificates on server';de = 'Check signatures and certificates on server';ro = 'Check signatures and certificates on server';tr = 'Check signatures and certificates on server'; es_ES = 'Check signatures and certificates on server'");
		CheckBoxTooltip =
			NStr("ru = 'Позволяет не устанавливать программу на компьютер пользователя
			           |для проверки электронных подписей и сертификатов.
			           |
			           |Важно: на каждый компьютер, где работает сервер 1С:Предприятия
			           |или веб-сервер, использующий файловую информационную базу,
			           |должна быть установлена хотя бы одна из программ в списке.'; 
			           |en = 'Allows you not to install the application on user computer 
			           |to check digital signatures and certificates.
			           |
			           |Important: at least one application from the list 
			           |must be installed on each computer which has 1C:Enterprise server 
			           |or web server using file infobase.'; 
			           |pl = 'Allows you not to install the application on user computer 
			           |to check digital signatures and certificates.
			           |
			           |Important: at least one application from the list 
			           |must be installed on each computer which has 1C:Enterprise server 
			           |or web server using file infobase.';
			           |de = 'Allows you not to install the application on user computer 
			           |to check digital signatures and certificates.
			           |
			           |Important: at least one application from the list 
			           |must be installed on each computer which has 1C:Enterprise server 
			           |or web server using file infobase.';
			           |ro = 'Allows you not to install the application on user computer 
			           |to check digital signatures and certificates.
			           |
			           |Important: at least one application from the list 
			           |must be installed on each computer which has 1C:Enterprise server 
			           |or web server using file infobase.';
			           |tr = 'Allows you not to install the application on user computer 
			           |to check digital signatures and certificates.
			           |
			           |Important: at least one application from the list 
			           |must be installed on each computer which has 1C:Enterprise server 
			           |or web server using file infobase.'; 
			           |es_ES = 'Allows you not to install the application on user computer 
			           |to check digital signatures and certificates.
			           |
			           |Important: at least one application from the list 
			           |must be installed on each computer which has 1C:Enterprise server 
			           |or web server using file infobase.'");
		Items.SignatureFilesExtension.Visible = True;
		Items.ActionsOnSaveSignedData.Visible = True;
	Else
		CheckBoxTitle = NStr("ru = 'Проверять сертификаты на сервере'; en = 'Verify certificates on server'; pl = 'Verify certificates on server';de = 'Verify certificates on server';ro = 'Verify certificates on server';tr = 'Verify certificates on server'; es_ES = 'Verify certificates on server'");
		CheckBoxTooltip =
			NStr("ru = 'Позволяет не устанавливать программу на компьютер пользователя
			           |для проверки сертификатов.
			           |
			           |Важно: на каждый компьютер, где работает сервер 1С:Предприятия
			           |или веб-сервер, использующий файловую информационную базу,
			           |должна быть установлена хотя бы одна из программ в списке.'; 
			           |en = 'Allows you not to install the application and certificate 
			           |for checking certificates on a user computer.
			           |
			           |Important: Application and certificate with a private key must be installed 
			           |on each computer with 1C:Enterprise server 
			           |or web server using file infobase on it.'; 
			           |pl = 'Allows you not to install the application and certificate 
			           |for checking certificates on a user computer.
			           |
			           |Important: Application and certificate with a private key must be installed 
			           |on each computer with 1C:Enterprise server 
			           |or web server using file infobase on it.';
			           |de = 'Allows you not to install the application and certificate 
			           |for checking certificates on a user computer.
			           |
			           |Important: Application and certificate with a private key must be installed 
			           |on each computer with 1C:Enterprise server 
			           |or web server using file infobase on it.';
			           |ro = 'Allows you not to install the application and certificate 
			           |for checking certificates on a user computer.
			           |
			           |Important: Application and certificate with a private key must be installed 
			           |on each computer with 1C:Enterprise server 
			           |or web server using file infobase on it.';
			           |tr = 'Allows you not to install the application and certificate 
			           |for checking certificates on a user computer.
			           |
			           |Important: Application and certificate with a private key must be installed 
			           |on each computer with 1C:Enterprise server 
			           |or web server using file infobase on it.'; 
			           |es_ES = 'Allows you not to install the application and certificate 
			           |for checking certificates on a user computer.
			           |
			           |Important: Application and certificate with a private key must be installed 
			           |on each computer with 1C:Enterprise server 
			           |or web server using file infobase on it.'");
		Items.SignatureFilesExtension.Visible = False;
		Items.ActionsOnSaveSignedData.Visible = False;
	EndIf;
	Items.CheckSignaturesAtServer.Title = CheckBoxTitle;
	Items.CheckSignaturesAtServer.ExtendedTooltip.Title = CheckBoxTooltip;
	
	If Not Constants.UseDigitalSignature.Get() Then
		CheckBoxTitle = NStr("ru = 'Шифровать и расшифровывать на сервере'; en = 'Encrypt and decrypt on server'; pl = 'Encrypt and decrypt on server';de = 'Encrypt and decrypt on server';ro = 'Encrypt and decrypt on server';tr = 'Encrypt and decrypt on server'; es_ES = 'Encrypt and decrypt on server'");
		CheckBoxTooltip =
			NStr("ru = 'Позволяет не устанавливать программу и сертификат
			           |на компьютер пользователя для шифрования и расшифровки.
			           |
			           |Важно: на каждый компьютер, где работает сервер 1С:Предприятия
			           |или веб-сервер, использующий файловую информационную базу,
			           |должна быть установлена программа и сертификат с закрытым ключом.'; 
			           |en = 'Allows you not to install the application and certificate 
			           |for encryption and decryption on a user computer.
			           |
			           |Important: Application and certificate with a private key must be installed 
			           |on each computer with running 1C:Enterprise server 
			           |or web server using file infobase on it.'; 
			           |pl = 'Allows you not to install the application and certificate 
			           |for encryption and decryption on a user computer.
			           |
			           |Important: Application and certificate with a private key must be installed 
			           |on each computer with running 1C:Enterprise server 
			           |or web server using file infobase on it.';
			           |de = 'Allows you not to install the application and certificate 
			           |for encryption and decryption on a user computer.
			           |
			           |Important: Application and certificate with a private key must be installed 
			           |on each computer with running 1C:Enterprise server 
			           |or web server using file infobase on it.';
			           |ro = 'Allows you not to install the application and certificate 
			           |for encryption and decryption on a user computer.
			           |
			           |Important: Application and certificate with a private key must be installed 
			           |on each computer with running 1C:Enterprise server 
			           |or web server using file infobase on it.';
			           |tr = 'Allows you not to install the application and certificate 
			           |for encryption and decryption on a user computer.
			           |
			           |Important: Application and certificate with a private key must be installed 
			           |on each computer with running 1C:Enterprise server 
			           |or web server using file infobase on it.'; 
			           |es_ES = 'Allows you not to install the application and certificate 
			           |for encryption and decryption on a user computer.
			           |
			           |Important: Application and certificate with a private key must be installed 
			           |on each computer with running 1C:Enterprise server 
			           |or web server using file infobase on it.'");
	ElsIf Not Constants.UseEncryption.Get() Then
		CheckBoxTitle = NStr("ru = 'Подписывать на сервере'; en = 'Sign on server'; pl = 'Sign on server';de = 'Sign on server';ro = 'Sign on server';tr = 'Sign on server'; es_ES = 'Sign on server'");
		CheckBoxTooltip =
			NStr("ru = 'Позволяет не устанавливать программу и сертификат
			           |на компьютер пользователя для подписания.
			           |
			           |Важно: на каждый компьютер, где работает сервер 1С:Предприятия
			           |или веб-сервер, использующий файловую информационную базу,
			           |должна быть установлена программа и сертификат с закрытым ключом.'; 
			           |en = 'Allows you not to install the application and signing certificate 
			           |on a user computer.
			           |
			           |Important: Application and certificate with a private key must be installed 
			           |on each computer with running 1C:Enterprise server 
			           |or web server using file infobase on it.'; 
			           |pl = 'Allows you not to install the application and signing certificate 
			           |on a user computer.
			           |
			           |Important: Application and certificate with a private key must be installed 
			           |on each computer with running 1C:Enterprise server 
			           |or web server using file infobase on it.';
			           |de = 'Allows you not to install the application and signing certificate 
			           |on a user computer.
			           |
			           |Important: Application and certificate with a private key must be installed 
			           |on each computer with running 1C:Enterprise server 
			           |or web server using file infobase on it.';
			           |ro = 'Allows you not to install the application and signing certificate 
			           |on a user computer.
			           |
			           |Important: Application and certificate with a private key must be installed 
			           |on each computer with running 1C:Enterprise server 
			           |or web server using file infobase on it.';
			           |tr = 'Allows you not to install the application and signing certificate 
			           |on a user computer.
			           |
			           |Important: Application and certificate with a private key must be installed 
			           |on each computer with running 1C:Enterprise server 
			           |or web server using file infobase on it.'; 
			           |es_ES = 'Allows you not to install the application and signing certificate 
			           |on a user computer.
			           |
			           |Important: Application and certificate with a private key must be installed 
			           |on each computer with running 1C:Enterprise server 
			           |or web server using file infobase on it.'");
	Else
		CheckBoxTitle = NStr("ru = 'Подписывать и шифровать на сервере'; en = 'Sign and decrypt on server'; pl = 'Sign and decrypt on server';de = 'Sign and decrypt on server';ro = 'Sign and decrypt on server';tr = 'Sign and decrypt on server'; es_ES = 'Sign and decrypt on server'");
		CheckBoxTooltip =
			NStr("ru = 'Позволяет не устанавливать программу и сертификат
			           |на компьютер пользователя для подписания, шифрования и расшифровки.
			           |
			           |Важно: на каждый компьютер, где работает сервер 1С:Предприятия
			           |или веб-сервер, использующий файловую информационную базу,
			           |должна быть установлена программа и сертификат с закрытым ключом.'; 
			           |en = 'Allows not to install the application and certificate 
			           |on user computer for signing, encryption and decryption.
			           |
			           |Important: application and certificate with the private key must be installed 
			           |on each computer which has 1C:Enterprise server or web server 
			           |using file infobase.'; 
			           |pl = 'Allows not to install the application and certificate 
			           |on user computer for signing, encryption and decryption.
			           |
			           |Important: application and certificate with the private key must be installed 
			           |on each computer which has 1C:Enterprise server or web server 
			           |using file infobase.';
			           |de = 'Allows not to install the application and certificate 
			           |on user computer for signing, encryption and decryption.
			           |
			           |Important: application and certificate with the private key must be installed 
			           |on each computer which has 1C:Enterprise server or web server 
			           |using file infobase.';
			           |ro = 'Allows not to install the application and certificate 
			           |on user computer for signing, encryption and decryption.
			           |
			           |Important: application and certificate with the private key must be installed 
			           |on each computer which has 1C:Enterprise server or web server 
			           |using file infobase.';
			           |tr = 'Allows not to install the application and certificate 
			           |on user computer for signing, encryption and decryption.
			           |
			           |Important: application and certificate with the private key must be installed 
			           |on each computer which has 1C:Enterprise server or web server 
			           |using file infobase.'; 
			           |es_ES = 'Allows not to install the application and certificate 
			           |on user computer for signing, encryption and decryption.
			           |
			           |Important: application and certificate with the private key must be installed 
			           |on each computer which has 1C:Enterprise server or web server 
			           |using file infobase.'");
	EndIf;
	Items.SignAtServer.Title = CheckBoxTitle;
	Items.SignAtServer.ExtendedTooltip.Title = CheckBoxTooltip;
	
EndProcedure

&AtClient
Procedure DefineInstalledApplications()
	
	If Items.Pages.CurrentPage = Items.ApplicationPage Then
		ApplicationsCheckPerformed = True;
		BeginAttachingCryptoExtension(New NotifyDescription(
			"DetermineApplicationsInstalledAfterAttachExtension", ThisObject));
	Else
		ApplicationsCheckPerformed = Undefined;
	EndIf;
	
EndProcedure

// Continues the DefineInstalledApplications procedure.
&AtClient
Procedure DetermineApplicationsInstalledAfterAttachExtension(Attached, Context) Export
	
	If Attached Then
		Items.ApplicationsAndRefreshPages.CurrentPage = Items.ApplicationsRefreshPage;
	EndIf;
	
	#If WebClient Then
		AttachIdleHandler("IdleHandlerDefineInstalledApplications", 0.3, True);
	#Else
		AttachIdleHandler("IdleHandlerDefineInstalledApplications", 0.1, True);
	#EndIf
	
EndProcedure

&AtClient
Procedure IdleHandlerToContinue()
	
	Return;
	
EndProcedure

&AtClient
Procedure IdleHandlerDefineInstalledApplications()
	
	BeginAttachingCryptoExtension(New NotifyDescription(
		"DefineInstalledApplicationsOnAttachExtension", ThisObject));
	
	#If WebClient Then
		AttachIdleHandler("IdleHandlerToContinue", 0.3, True);
	#Else
		AttachIdleHandler("IdleHandlerToContinue", 0.1, True);
	#EndIf
	
EndProcedure

// Continues the IdleHandlerDefineInstalledApplications procedure.
&AtClient
Procedure DefineInstalledApplicationsOnAttachExtension(Attached, Context) Export
	
	If Not Attached Then
		If Not Items.WebClientExtentionNotInstalledGroup.Visible Then
			SetVisibilityGroupWebClientExtensionNotInstalled(True);
		EndIf;
		AttachIdleHandler("IdleHandlerDefineInstalledApplications", 3, True);
		Return;
	EndIf;
	
	If Items.WebClientExtentionNotInstalledGroup.Visible Then
		SetVisibilityGroupWebClientExtensionNotInstalled(False);
	EndIf;
	
	Context = New Structure;
	Context.Insert("IndexOf", -1);
	
	IdleHandlerDefineInstalledApplicationsLoopStart(Context);
	
EndProcedure

// Continues the IdleHandlerDefineInstalledApplications procedure.
&AtClient
Procedure IdleHandlerDefineInstalledApplicationsLoopStart(Context)
	
	If Applications.Count() <= Context.IndexOf + 1 Then
		// After loop.
		Items.ApplicationsAndRefreshPages.CurrentPage = Items.ApplicationsListPage;
		CurrentItem = Items.Applications;
		Return;
	EndIf;
	Context.IndexOf = Context.IndexOf + 1;
	ApplicationDetails = Applications.Get(Context.IndexOf);
	
	Context.Insert("ApplicationDetails", ApplicationDetails);
	
	If ApplicationDetails.DeletionMark Then
		UpdateValue(ApplicationDetails.CheckResult, "");
		UpdateValue(ApplicationDetails.Use, "");
		IdleHandlerDefineInstalledApplicationsLoopStart(Context);
		Return;
	ElsIf ApplicationDetails.IsCloudServiceApplication Then
		UpdateValue(ApplicationDetails.CheckResult, NStr("ru = 'Доступен.'; en = 'Available.'; pl = 'Available.';de = 'Available.';ro = 'Available.';tr = 'Available.'; es_ES = 'Available.'"));
		UpdateValue(ApplicationDetails.Use, True);
		IdleHandlerDefineInstalledApplicationsLoopStart(Context);
		Return;
	EndIf;
	
	ApplicationsDetailsCollection = New Array;
	ApplicationsDetailsCollection.Add(Context.ApplicationDetails);
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("ApplicationsDetailsCollection",  ApplicationsDetailsCollection);
	ExecutionParameters.Insert("IndexOf",            -1);
	ExecutionParameters.Insert("ShowError",    Undefined);
	ExecutionParameters.Insert("ErrorProperties",    New Structure("Errors", New Array));
	ExecutionParameters.Insert("InteractiveMode", False);
	ExecutionParameters.Insert("IsLinux",   Not CommonClient.IsWindowsClient());
	ExecutionParameters.Insert("Manager",   Undefined);
	ExecutionParameters.Insert("Notification", New NotifyDescription(
		"IdleHandlerDefineInstalledApplicationsLoopFollowUp", ThisObject, Context));
	
	Context.Insert("ExecutionParameters", ExecutionParameters);
	DigitalSignatureInternalClient.CreateCryptoManagerLoopStart(ExecutionParameters);
	
EndProcedure

// Continues the IdleHandlerDefineInstalledApplications procedure.
&AtClient
Procedure IdleHandlerDefineInstalledApplicationsLoopFollowUp(Manager, Context) Export
	
	ApplicationDetails = Context.ApplicationDetails;
	Errors            = Context.ExecutionParameters.ErrorProperties.Errors;
	
	If Manager <> Undefined Then
		UpdateValue(ApplicationDetails.CheckResult, NStr("ru = 'Установлена на компьютере.'; en = 'Installed on the computer.'; pl = 'Installed on the computer.';de = 'Installed on the computer.';ro = 'Installed on the computer.';tr = 'Installed on the computer.'; es_ES = 'Installed on the computer.'"));
		UpdateValue(ApplicationDetails.Use, True);
		IdleHandlerDefineInstalledApplicationsLoopStart(Context);
		Return;
	EndIf;
	
	For each Error In Errors Do
		Break;
	EndDo;
	
	If Error.PathNotSpecified Then
		UpdateValue(ApplicationDetails.CheckResult, NStr("ru = 'Не указан путь к программе.'; en = 'Path to the application is not specified.'; pl = 'Path to the application is not specified.';de = 'Path to the application is not specified.';ro = 'Path to the application is not specified.';tr = 'Path to the application is not specified.'; es_ES = 'Path to the application is not specified.'"));
		UpdateValue(ApplicationDetails.Use, "");
	Else
		ErrorText = NStr("ru = 'Не установлена на компьютере.'; en = 'It is not installed on the computer.'; pl = 'It is not installed on the computer.';de = 'It is not installed on the computer.';ro = 'It is not installed on the computer.';tr = 'It is not installed on the computer.'; es_ES = 'It is not installed on the computer.'") + " " + Error.Details;
		If Error.ToAdministrator AND Not IsFullUser Then
			ErrorText = ErrorText + " " + NStr("ru = 'Обратитесь к администратору.'; en = 'Please contact the application administrator.'; pl = 'Please contact the application administrator.';de = 'Please contact the application administrator.';ro = 'Please contact the application administrator.';tr = 'Please contact the application administrator.'; es_ES = 'Please contact the application administrator.'");
		EndIf;
		UpdateValue(ApplicationDetails.CheckResult, ErrorText);
		UpdateValue(ApplicationDetails.Use, False);
	EndIf;
	
	IdleHandlerDefineInstalledApplicationsLoopStart(Context);
	
EndProcedure

&AtServer
Procedure SetVisibilityGroupWebClientExtensionNotInstalled(Val ItemVisibility)
	
	Items.WebClientExtentionNotInstalledGroup.Visible = ItemVisibility;
	
EndProcedure

&AtClient
Procedure OnChangeApplicationsCompositionOrSettings()
	
	FillApplicationsAndSettings();
	
	DefineInstalledApplications();
	
EndProcedure

&AtServer
Procedure FillApplicationsAndSettings(UpdateCached = False)
	
	Items.Certificates.Refresh();
	
	If UpdateCached Then
		RefreshReusableValues();
	EndIf;
	
	PersonalSettings = DigitalSignature.PersonalSettings();
	
	ActionsOnSavingWithDS                   = PersonalSettings.ActionsOnSavingWithDS;
	EncryptedFilesExtension           = PersonalSettings.EncryptedFilesExtension;
	SignatureFilesExtension                 = PersonalSettings.SignatureFilesExtension;
	ApplicationsPaths                            = PersonalSettings.PathsToDigitalSignatureAndEncryptionApplications;
	SaveCertificateWithSignature         = PersonalSettings.SaveCertificateWithSignature;
	Query = New Query;
	Query.Text =
	"SELECT
	|	Applications.Ref,
	|	Applications.Description AS Description,
	|	Applications.ApplicationName,
	|	Applications.ApplicationType,
	|	Applications.SignAlgorithm,
	|	Applications.HashAlgorithm,
	|	Applications.EncryptAlgorithm,
	|	Applications.DeletionMark AS DeletionMark,
	|	Applications.IsCloudServiceApplication
	|FROM
	|	Catalog.DigitalSignatureAndEncryptionApplications AS Applications
	|WHERE
	|	NOT Applications.IsCloudServiceApplication
	|
	|UNION ALL
	|
	|SELECT
	|	Applications.Ref,
	|	Applications.Description,
	|	Applications.ApplicationName,
	|	Applications.ApplicationType,
	|	Applications.SignAlgorithm,
	|	Applications.HashAlgorithm,
	|	Applications.EncryptAlgorithm,
	|	Applications.DeletionMark,
	|	Applications.IsCloudServiceApplication
	|FROM
	|	Catalog.DigitalSignatureAndEncryptionApplications AS Applications
	|WHERE
	|	Applications.IsCloudServiceApplication
	|	AND &UseDigitalSignatureSaaS
	|
	|ORDER BY
	|	Description";
	
	Query.SetParameter("UseDigitalSignatureSaaS", 
		DigitalSignatureInternal.UseDigitalSignatureSaaS());
	
	Selection = Query.Execute().Select();
	
	ProcessedRows = New Map;
	Index = 0;
	
	While Selection.Next() Do
		If Not Users.IsFullUser() AND Selection.DeletionMark Then
			Continue;
		EndIf;
		Rows = Applications.FindRows(New Structure("Ref", Selection.Ref));
		If Rows.Count() = 0 Then
			If Applications.Count()-1 < Index Then
				Row = Applications.Add();
			Else
				Row = Applications.Insert(Index);
			EndIf;
		Else
			Row = Rows[0];
			RowIndex = Applications.IndexOf(Row);
			If RowIndex <> Index Then
				Applications.Move(RowIndex, Index - RowIndex);
			EndIf;
		EndIf;
		// Updating only changed values not to update the form table once again.
		UpdateValue(Row.Ref,              Selection.Ref);
		UpdateValue(Row.DeletionMark,     Selection.DeletionMark);
		UpdateValue(Row.Description,        Selection.Description);
		UpdateValue(Row.ApplicationName,        Selection.ApplicationName);
		UpdateValue(Row.ApplicationType,        Selection.ApplicationType);
		UpdateValue(Row.SignAlgorithm,     Selection.SignAlgorithm);
		UpdateValue(Row.HashAlgorithm, Selection.HashAlgorithm);
		UpdateValue(Row.EncryptAlgorithm,  Selection.EncryptAlgorithm);
		UpdateValue(Row.LinuxPathToApplication, ApplicationsPaths.Get(Selection.Ref));
		UpdateValue(Row.PictureNumber,       ?(Selection.DeletionMark, 4, 3));
		UpdateValue(Row.IsCloudServiceApplication, Selection.IsCloudServiceApplication);
		If Row.IsCloudServiceApplication AND Not Row.DeletionMark Then
			UpdateValue(Row.CheckResult, NStr("ru = 'Доступен.'; en = 'Available.'; pl = 'Available.';de = 'Available.';ro = 'Available.';tr = 'Available.'; es_ES = 'Available.'"));
			UpdateValue(Row.Use, True);
		EndIf;
		
		ProcessedRows.Insert(Row, True);
		Index = Index + 1;
	EndDo;
	
	Index = Applications.Count()-1;
	While Index >=0 Do
		Row = Applications.Get(Index);
		If ProcessedRows.Get(Row) = Undefined Then
			Applications.Delete(Index);
		EndIf;
		Index = Index-1;
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateValue(PreviousValue, NewValue)
	
	If PreviousValue <> NewValue Then
		PreviousValue = NewValue;
	EndIf;
	
EndProcedure

&AtClient
Procedure SaveSettings()
	
	SettingsToSave = New Structure;
	SettingsToSave.Insert("ActionsOnSavingWithDS",                   ActionsOnSavingWithDS);
	SettingsToSave.Insert("EncryptedFilesExtension",           EncryptedFilesExtension);
	SettingsToSave.Insert("SignatureFilesExtension",                 SignatureFilesExtension);
	SettingsToSave.Insert("SaveCertificateWithSignature",         SaveCertificateWithSignature);
	SaveSettingsAtServer(SettingsToSave);
	
EndProcedure

&AtServerNoContext
Procedure SaveSettingsAtServer(SettingsToSave)
	
	PersonalSettings = DigitalSignature.PersonalSettings();
	FillPropertyValues(PersonalSettings, SettingsToSave);
	DigitalSignatureInternal.SavePersonalSettings(PersonalSettings);
	
	// It is required to update personal settings on the client.
	RefreshReusableValues();
	
EndProcedure

&AtServerNoContext
Procedure SaveLinuxPathAtServer(Application, LinuxPath)
	
	PersonalSettings = DigitalSignature.PersonalSettings();
	PersonalSettings.PathsToDigitalSignatureAndEncryptionApplications.Insert(Application, LinuxPath);
	DigitalSignatureInternal.SavePersonalSettings(PersonalSettings);
	
	// It is required to update personal settings on the client.
	RefreshReusableValues();
	
EndProcedure

&AtServerNoContext
Procedure SetSignatureCheckAtServer(CheckSignaturesAtServer)
	
	If Not AccessRight("Update", Metadata.Constants.VerifyDigitalSignaturesOnTheServer)
	 Or Constants.VerifyDigitalSignaturesOnTheServer.Get() = CheckSignaturesAtServer Then
		
		Return;
	EndIf;
	
	Constants.VerifyDigitalSignaturesOnTheServer.Set(CheckSignaturesAtServer);
	
	// It is required to update common settings both on the server and on the client.
	RefreshReusableValues();
	
EndProcedure

&AtServerNoContext
Procedure SetSigningAtServer(SignAtServer)
	
	If Not AccessRight("Update", Metadata.Constants.GenerateDigitalSignaturesAtServer)
	 Or Constants.GenerateDigitalSignaturesAtServer.Get() = SignAtServer Then
		
		Return;
	EndIf;
	
	Constants.GenerateDigitalSignaturesAtServer.Set(SignAtServer);
	
	// It is required to update common settings both on the server and on the client.
	RefreshReusableValues();
	
EndProcedure

#EndRegion
