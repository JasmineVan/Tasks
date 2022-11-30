///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Opens a message creation form.
//
// Parameters:
//  EmailSendOptions  - Structure          - see EmailOperationsClient.EmailSendOptions. 
//  FormClosingNotification - NotifyDescription - procedure to be executed after closing the message 
//                                                  sending form.
//
Procedure CreateNewEmailMessage(EmailSendOptions = Undefined, FormClosingNotification = Undefined) Export
	
	SendOptions = EmailSendOptions();
	If EmailSendOptions <> Undefined Then
		CommonClientServer.SupplementStructure(SendOptions, EmailSendOptions, True);
	EndIf;
	
	InfoForSending = EmailServerCall.InfoForSending(SendOptions);
	SendOptions.Insert("ShowAttachmentSaveFormatSelectionDialog", InfoForSending.ShowAttachmentSaveFormatSelectionDialog);
	SendOptions.Insert("FormClosingNotification", FormClosingNotification);
	
	If InfoForSending.HasAvailableAccountsForSending Then
		CreateNewEmailMessageAccountChecked(True, SendOptions);
	Else
		ResultHandler = New NotifyDescription("CreateNewEmailMessageAccountChecked", ThisObject, SendOptions);
		If InfoForSending.CanAddNewAccounts Then
			OpenForm("Catalog.EmailAccounts.Form.AccountSetupWizard", 
				New Structure("ContextMode", True), , , , , ResultHandler);
		Else
			MessageText = NStr("ru = 'Для отправки письма требуется настройка учетной записи электронной почты.
				|Обратитесь к администратору.'; 
				|en = 'Cannot send mail because the account is not configured.
				|Please contact the administrator.'; 
				|pl = 'Aby wysłać wiadomość e-mail, musisz skonfigurować konto użytkownika e-mail.
				|Skontaktuj się z administratorem.';
				|de = 'Um eine E-Mail zu senden, müssen Sie das E-Mail-Konto konfigurieren. 
				|Kontaktieren Sie Ihren Administrator.';
				|ro = 'Pentru a trimite un e-mail trebuie să configurați contul poștei electronice.
				|Adresați-vă administratorului.';
				|tr = 'Bir e-posta göndermek için e-posta hesabını yapılandırmanız gerekir. 
				|Yöneticinize başvurun.'; 
				|es_ES = 'Para enviar un correo electrónico, usted necesita configurar la cuenta de correo electrónico.
				|Contactar su administrador.'");
			NotifyDescription = New NotifyDescription("CheckAccountForSendingEmailExistsEnd", ThisObject, ResultHandler);
			ShowMessageBox(NotifyDescription, MessageText);
		EndIf;
	EndIf;
	
EndProcedure

// Returns an empty structure with email sending parameters.
//
// Returns:
//  Structure - parameters for filling the sending form for the new message (all optional):
//   * Sender - CatalogRef.EmailAccounts - account used to send the email message.
//                   
//                 - ValueList - list of accounts available for selection in the following format:
//                     ** Presentation - String - an account description.
//                     ** Value - CatalogRef.EmailAccounts - account.
//    
//   * Recipient - String - list of addresses in the following format:
//                           [RecipientPresentation1] <Address1>; [[RecipientPresentation2] <Address2>;...]
//                - ValueList - a list of addresses.
//                   ** Presentation - String - recipient presentation.
//                   ** Value      - String - email address.
//                - Array - array of structures describing recipients:
//                   ** Address                        - String - recipient email address.
//                   ** Presentation               - String - addressee presentation.
//                   ** ContactInformationSource - CatalogRef - contact information owner.
//   
//   * Cc - ValueList, String - see the "Recipient" field description.
//   * BCC - ValueList, String - see the "Recipient" field description.
//   * MailSubject - String - email subject.
//   * Text - String - email body.
//
//   * Attachments - Array - attached files (described as structures):
//     ** Presentation - String - attachment file name.
//     ** AddressInTempStorage - String - address of binary data or spreadsheet document in temporary storage.
//     ** Encoding - String - an attachment encoding (used if it differs from the message encoding).
//     ** ID - String - (optional) used to store images displayed in the message body.
//   
//   * DeleteFilesAfterSending - Boolean - delete temporary files after sending the message.
//   * SubjectSSL - AnyRef - email subject.
Function EmailSendOptions() Export
	EmailParameters = New Structure;
	
	EmailParameters.Insert("From", Undefined);
	EmailParameters.Insert("Recipient", Undefined);
	EmailParameters.Insert("Cc", Undefined);
	EmailParameters.Insert("BCC", Undefined);
	EmailParameters.Insert("Subject", Undefined);
	EmailParameters.Insert("Text", Undefined);
	EmailParameters.Insert("Attachments", Undefined);
	EmailParameters.Insert("DeleteFilesAfterSending", Undefined);
	EmailParameters.Insert("Topic", Undefined);
	
	Return EmailParameters;
EndFunction

// If a user has no account configured for sending emails, does one of the following depending on 
// the access rights: starts the account setup wizard, or displays a message that email cannot be sent.
// The procedure is intended for scenarios that require account setup before requesting additional 
// sending parameters.
//
// Parameters:
//  ResultHandler - NotifyDescription - procedure to be executed after the check is completed.
//                                              True returns if there is an available account for 
//                                              sending emails. Otherwise, False returns.
Procedure CheckAccountForSendingEmailExists(ResultHandler) Export
	If EmailServerCall.HasAvailableAccountsForSending() Then
		ExecuteNotifyProcessing(ResultHandler, True);
	Else
		If EmailServerCall.CanAddNewAccounts() Then
			OpenForm("Catalog.EmailAccounts.Form.AccountSetupWizard", 
				New Structure("ContextMode", True), , , , , ResultHandler);
		Else	
			MessageText = NStr("ru = 'Для отправки письма требуется настройка учетной записи электронной почты.
				|Обратитесь к администратору.'; 
				|en = 'Cannot send mail because the account is not configured.
				|Please contact the administrator.'; 
				|pl = 'Aby wysłać wiadomość e-mail, musisz skonfigurować konto użytkownika e-mail.
				|Skontaktuj się z administratorem.';
				|de = 'Um eine E-Mail zu senden, müssen Sie das E-Mail-Konto konfigurieren. 
				|Kontaktieren Sie Ihren Administrator.';
				|ro = 'Pentru a trimite un e-mail trebuie să configurați contul poștei electronice.
				|Adresați-vă administratorului.';
				|tr = 'Bir e-posta göndermek için e-posta hesabını yapılandırmanız gerekir. 
				|Yöneticinize başvurun.'; 
				|es_ES = 'Para enviar un correo electrónico, usted necesita configurar la cuenta de correo electrónico.
				|Contactar su administrador.'");
			NotifyDescription = New NotifyDescription("CheckAccountForSendingEmailExistsEnd", ThisObject, ResultHandler);
			ShowMessageBox(NotifyDescription, MessageText);
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region Private

// Continues the CreateNewEmailMessage procedure.
Procedure CreateNewEmailMessageAccountChecked(AccountSetUp, SendOptions) Export
	
	If AccountSetUp <> True Then
		Return;
	EndIf;
	
	If SendOptions.ShowAttachmentSaveFormatSelectionDialog Then
		NotifyDescription = New NotifyDescription("CreateNewEmailMessagePrepareAttachments", ThisObject, SendOptions);
		OpenForm("CommonForm.SelectAttachmentFormat", , , , , , NotifyDescription);
		Return;
	EndIf;
	
	CreateNewEmailMessageAttachmentsPrepared(True, SendOptions);
	
EndProcedure

Procedure CreateNewEmailMessagePrepareAttachments(SettingsForSaving, SendOptions) Export
	If TypeOf(SettingsForSaving) <> Type("Structure") Then
		Return;
	EndIf;
	
	EmailServerCall.PrepareAttachments(SendOptions.Attachments, SettingsForSaving);
	
	CreateNewEmailMessageAttachmentsPrepared(True, SendOptions);
EndProcedure

// Continues the CreateNewEmailMessage procedure.
Procedure CreateNewEmailMessageAttachmentsPrepared(AttachmentsPrepared, SendOptions)

	If AttachmentsPrepared <> True Then
		Return;
	EndIf;
	
	FormClosingNotification = SendOptions.FormClosingNotification;
	SendOptions.Delete("FormClosingNotification");
	
	StandardProcessing = True;
	EmailClientOverridable.BeforeOpenEmailSendingForm(SendOptions, FormClosingNotification, StandardProcessing);
	
	If Not StandardProcessing Then
		Return;
	EndIf;
	
	If CommonClient.SubsystemExists("StandardSubsystems.Interactions") 
		AND StandardSubsystemsClient.ClientRunParameters().OutgoingEmailsCreationAvailable Then
		ModuleClientInteractions = CommonClient.CommonModule("InteractionsClient");
		ModuleClientInteractions.OpenEmailSendingForm(SendOptions, FormClosingNotification);
	Else
		OpenSimpleSendEmailMessageForm(SendOptions, FormClosingNotification);
	EndIf;
	
EndProcedure

// Client interface function supporting simplified call of simple form for editing new message.
//  Messages sent using simple form are not saved to the infobase.
// 
//
// For parameters, see the CreateNewEmailMessage function description.
//
Procedure OpenSimpleSendEmailMessageForm(EmailParameters, OnCloseNotifyDescription)
	OpenForm("CommonForm.SendMessage", EmailParameters, , , , , OnCloseNotifyDescription);
EndProcedure

// Performs account check.
//
// Parameters:
//   Account - CatalogRef.EmailAccounts - account to be checked.
//					
//
Procedure CheckAccount(Val Account) Export
	ClearMessages();
	CheckCanSendReceiveEmail(Undefined, Account);
EndProcedure

// Validating email account.
//
// See procedure EmailOperationsInternal.CheckCanSendReceiveEmail.
//
Procedure CheckCanSendReceiveEmail(ResultHandler, Account)
	
	ErrorMessage = "";
	AdditionalMessage = "";
	EmailServerCall.CheckSendReceiveEmailAvailability(Account, ErrorMessage, AdditionalMessage);
	
	If ValueIsFilled(ErrorMessage) Then
		ShowMessageBox(ResultHandler, StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Проверка параметров учетной записи завершилась с ошибками:
					   |%1'; 
					   |en = 'Account parameters validation completed with errors:
					   |%1'; 
					   |pl = 'Weryfikacja parametrów konta została zakończona z błędami:
					   |%1';
					   |de = 'Die Überprüfung der Kontenparameter ist fehlerhaft verlaufen:
					   |%1';
					   |ro = 'Verificarea parametrilor contului este finalizată cu erori:
					   |%1';
					   |tr = 'Hesap parametreleri hatalarla 
					   |kontrol edildi:%1'; 
					   |es_ES = 'Revisión de parámetros de la cuenta se ha finalizado con errores:
					   |%1'"), ErrorMessage ),,
			NStr("ru = 'Проверка учетной записи'; en = 'Validate account'; pl = 'Sprawdź konto';de = 'Benutzerkonto prüfen';ro = 'Verificarea contului';tr = 'Hesabı kontrol et'; es_ES = 'Revisar la cuenta'"));
	Else
		ShowMessageBox(ResultHandler, StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Проверка параметров учетной записи завершилась успешно. %1'; en = 'Account parameters validation is completed. %1'; pl = 'Sprawdzenie parametrów konta zakończyło się pomyślnie. %1';de = 'Die Überprüfung der Kontoparameter wurde erfolgreich abgeschlossen. %1';ro = 'Verificarea parametrilor de cont a fost încheiată cu succes. %1';tr = 'Hesap parametresi kontrolü başarıyla tamamlandı.%1'; es_ES = 'Revisión de los parámetros de la cuenta se ha finalizado con éxito. %1'"),
			AdditionalMessage),,
			NStr("ru = 'Проверка учетной записи'; en = 'Validate account'; pl = 'Sprawdź konto';de = 'Benutzerkonto prüfen';ro = 'Verificarea contului';tr = 'Hesabı kontrol et'; es_ES = 'Revisar la cuenta'"));
	EndIf;
	
EndProcedure

Procedure CheckAccountForSendingEmailExistsEnd(ResultHandler) Export
	ExecuteNotifyProcessing(ResultHandler, False);
EndProcedure

Procedure GoToEmailAccountInputDocumentation() Export
	
	FileSystemClient.OpenURL("https://its.1c.ru/db/translate?db=bspdoc&path=src/5.48 processing with postal messages.htm&anchor=issogl1_enter_email_account");
	
EndProcedure

#EndRegion
