///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var RecipientHistory;

#EndRegion

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SuccessResultColor = StyleColors.SuccessResultColor;
	
	AttachmentsForEmail = New Structure;
	
	If TypeOf(Parameters.Attachments) = Type("ValueList") Or TypeOf(Parameters.Attachments) = Type("Array") Then
		For Each Attachment In Parameters.Attachments Do
			DetermineEmailAttachmentPurpose(Attachment, AttachmentsForEmail);
		EndDo;
	EndIf;
	
	EmailSubject = Parameters.Subject;
	EmailBody.SetHTML(HTMLWrappedText(Parameters.Text), AttachmentsForEmail);
	ReplyToAddress = Parameters.ReplyToAddress;
	
	If NOT ValueIsFilled(Parameters.Sender) Then
		// Account is not passed. Selecting the first available account.
		AvailableEmailAccounts = EmailOperations.AvailableEmailAccounts(True);
		If AvailableEmailAccounts.Count() = 0 Then
			MessageText = NStr("ru = 'Не обнаружены доступные учетные записи электронной почты, обратитесь к администратору системы.'; en = 'There are no email accounts available. Please contact your system administrator.'; pl = 'Nie znaleziono dostępnych kont poczty elektronicznej, skontaktuj się z administratorem systemu.';de = 'Verfügbare E-Mail-Konten werden nicht gefunden, wenden Sie sich an den Systemadministrator.';ro = 'Conturile de e-mail disponibile nu au fost găsite, contactați administratorul de sistem.';tr = 'Kullanılabilir e-posta hesapları bulunamadı, sistem yöneticisine başvurun.'; es_ES = 'Cuentas de correo electrónico disponibles no se han encontrado, contactar el administrador del sistema.'");
			Common.MessageToUser(MessageText,,,,Cancel);
			Return;
		EndIf;
		
		Account = AvailableEmailAccounts[0].Ref;
		
	ElsIf TypeOf(Parameters.Sender) = Type("CatalogRef.EmailAccounts") Then
		Account = Parameters.Sender;
	ElsIf TypeOf(Parameters.Sender) = Type("ValueList") Then
		EmailAccountList = Parameters.Sender;
		
		If EmailAccountList.Count() = 0 Then
			MessageText = NStr("ru = 'Не указаны учетные записи для отправки сообщения, обратитесь к администратору системы.'; en = 'Accounts for sending mail are not specified. Please contact your system administrator.'; pl = 'Nie wskazano kont mailowych, skontaktuj się z administratorem systemu.';de = 'E-Mail-Konten sind nicht angegeben, wenden Sie sich an den Systemadministrator.';ro = 'Conturile de e-mail pentru trimitere nu sunt specificate, contactați administratorul de sistem.';tr = 'E-posta hesapları belirtilmedi, sistem yöneticisine başvurun.'; es_ES = 'Cuentas de correo electrónico no está especificadas, contactar el administrador del sistema.'");
			Common.MessageToUser(MessageText,,,, Cancel);
			Return;
		EndIf;
		
		For Each ItemAccount In EmailAccountList Do
			Items.Account.ChoiceList.Add(
										ItemAccount.Value,
										ItemAccount.Presentation);
			If ItemAccount.Value.UseForReceiving Then
				ReplyToAddressesByAccounts.Add(ItemAccount.Value,
														GetEmailAddressByAccount(ItemAccount.Value));
			EndIf;
		EndDo;
		
		Items.Account.ChoiceList.SortByPresentation();
		Account = EmailAccountList[0].Value;
		
		// Selecting accounts from the passed account list.
		Items.Account.DropListButton = True;
	EndIf;
	
	If TypeOf(Parameters.Recipient) = Type("ValueList") Then
		
		For Each ItemEmailAddress In Parameters.Recipient Do
			NewRecipient = RecipientsMailAddresses.Add();
			NewRecipient.SendingOption = NStr("ru='Кому:'; en = 'To:'; pl = 'Do:';de = 'An wen:';ro = 'Către:';tr = 'Kime:'; es_ES = 'Para:'");
			If ValueIsFilled(ItemEmailAddress.Presentation) Then
				NewRecipient.Presentation = ItemEmailAddress.Presentation
										+ " <"
										+ ItemEmailAddress.Value
										+ ">"
			Else
				NewRecipient.Presentation = ItemEmailAddress.Value;
			EndIf;
		EndDo;
		
	ElsIf TypeOf(Parameters.Recipient) = Type("String") Then
		NewRecipient                 = RecipientsMailAddresses.Add();
		NewRecipient.SendingOption = NStr("ru='Кому:'; en = 'To:'; pl = 'Do:';de = 'An wen:';ro = 'Către:';tr = 'Kime:'; es_ES = 'Para:'");
		NewRecipient.Presentation   = Parameters.Recipient;
	ElsIf TypeOf(Parameters.Recipient) = Type("Array") Then
		For Each RecipientStructure In Parameters.Recipient Do
			HasPropertySelected = RecipientStructure.Property("Selected");
			AddressesArray      = StrSplit(RecipientStructure.Address, ";");
			For Each Address In AddressesArray Do
				If IsBlankString(Address) Then
					Continue;
				EndIf;
				If (HasPropertySelected AND RecipientStructure.Selected) OR (NOT HasPropertySelected) Then
					NewRecipient                 = RecipientsMailAddresses.Add();
					NewRecipient.SendingOption = NStr("ru='Кому:'; en = 'To:'; pl = 'Do:';de = 'An wen:';ro = 'Către:';tr = 'Kime:'; es_ES = 'Para:'");
					NewRecipient.Presentation   = RecipientStructure.Presentation + " <" + TrimAll(Address) + ">";
				EndIf;
			EndDo;
		EndDo;
	EndIf;
	
	If TypeOf(Parameters.Recipient) = Type("Array") Then
		If TypeOf(Parameters.Recipient) = Type("String") Then
			FillRecipientsTableFromRow(Parameters.Recipient);
		ElsIf TypeOf(Parameters.Recipient) = Type("ValueList") Then
			MessageRecipients = (Parameters.Recipient);
		ElsIf TypeOf(Parameters.Recipient) = Type("Array") Then
			FillRecipientsTableFromStructuresArray(Parameters.Recipient);
		EndIf;
	EndIf;
	
	If RecipientsMailAddresses.Count() = 0 Then
		NewRow                 = RecipientsMailAddresses.Add();
		NewRow.SendingOption = NStr("ru='Кому:'; en = 'To:'; pl = 'Do:';de = 'An wen:';ro = 'Către:';tr = 'Kime:'; es_ES = 'Para:'");
		NewRow.Presentation   = "";
	EndIf;
	
	// Getting the list of addresses that the user previously used.
	ReplyToList = Common.CommonSettingsStorageLoad(
		"EditNewEmailMessage", "ReplyToList");
	
	If ReplyToList <> Undefined AND ReplyToList.Count() > 0 Then
		For Each ReplyToItem In ReplyToList Do
			Items.ReplyToAddress.ChoiceList.Add(ReplyToItem.Value, ReplyToItem.Presentation);
		EndDo;
		
		Items.ReplyToAddress.DropListButton = True;
	EndIf;
	
	If ValueIsFilled(ReplyToAddress) Then
		FillReplyToAddressAutomatically = False;
	Else
		If Account.UseForReceiving Then
			// Setting default email address
			If ValueIsFilled(Account.UserName) Then 
				ReplyToAddress = Account.UserName + " <" + Account.EmailAddress + ">";
			Else
				ReplyToAddress = Account.EmailAddress;
			EndIf;
		EndIf;
		
		FillReplyToAddressAutomatically = True;
	EndIf;
	
	// StandardSubsystems.MessagesTemplates
	
	Items.FormGenerateFromTemplate.Visible = False;
	Items.FormSaveAsTemplate.Visible    = False;
	
	If Common.SubsystemExists("StandardSubsystems.MessageTemplates")Then
		ModuleMessagesTemplatesInternal = Common.CommonModule("MessageTemplatesInternal");
		
		If ModuleMessagesTemplatesInternal.MessagesTemplatesUsed() Then
			Items.FormGenerateFromTemplate.Visible = ModuleMessagesTemplatesInternal.HasAvailableTemplates("Email");
			Items.FormSaveAsTemplate.Visible    = True;
		EndIf;
		
	EndIf;
	
	// End StandardSubsystems.MessagesTemplates
	
	If Common.IsMobileClient() Then
		Items.Attachment2.Visible = False;
		Items.EmailBodyMainGroup.ItemsAndTitlesAlign = ItemsAndTitlesAlignVariant.ItemsRightTitlesLeft;
		Items.EmailSubject.TitleLocation = FormItemTitleLocation.Top;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	ImportAttachmentsFromFiles();
	RefreshAttachmentPresentation();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	If Not FormClosingConfirmationRequired Then
		Return;
	EndIf;
	
	Cancel = True;
	If Exit Then
		Return;
	EndIf;
	
	AttachIdleHandler("ShowQueryBoxBeforeCloseForm", 0.1, True);
EndProcedure

&AtClient
Procedure OnClose(Exit)
	If Not Exit Then
		AttachmentAddresses = New Array;
		For Each Attachment In Attachments Do
			AttachmentAddresses.Add(Attachment.AddressInTempStorage);
		EndDo;
		ClearAttachments(AttachmentAddresses);
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// Populating the reply address if the flag of automatic reply address substitution is set.
//
&AtClient
Procedure AccountChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If IsBlankString(ReplyToAddress) Then
		FillReplyToAddressAutomatically = True;
	EndIf;
	
	If FillReplyToAddressAutomatically Then
		If ReplyToAddressesByAccounts.FindByValue(ValueSelected) <> Undefined Then
			ReplyToAddress = ReplyToAddressesByAccounts.FindByValue(ValueSelected).Presentation;
		Else
			ReplyToAddress = GetEmailAddressByAccount(ValueSelected);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure SetFormModificationFlag(Item)
	FormClosingConfirmationRequired = True;
EndProcedure

#EndRegion

#Region EventHandlersOfTableItemsOfRecipientPostalAddressesForm

&AtClient
Procedure RecipientPostalAddressesBeforeDelete(Item, Cancel)
	
	If RecipientsMailAddresses.Count() = 1 Then
		Cancel = True;
		RecipientsMailAddresses[0].Presentation = "";
	EndIf;
	
EndProcedure

&AtClient
Procedure RecipientPostalAddressesOnStartEdit(Item, NewRow, Clone)
	If NewRow Then
		Item.CurrentData.SendingOption = Items.RecipientsEmailAddressSendingOption.ChoiceList.FindByValue("SendTo:");
		Item.CurrentItem                = Items.RecipientsEmailAddressPresentation;
	EndIf;
EndProcedure

&AtClient
Procedure RecipientsPostalAddressPresentationAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If MessageRecipients.Count() = 0 Then
		ChoiceData = SimilarRecipientsFromHistory(Text);
	Else
		ChoiceData = SimilarRecipientsFromPassedRecipients(Text);
	EndIf;
	
	StandardProcessing = ChoiceData.Count() = 0;
	
EndProcedure

&AtClient
Procedure RecipientPostalAddressesBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	
	If CancelEdit Then
		Return;
	EndIf;
	
	RowData = Item.CurrentData;
	If RowData = Undefined Then
		Return;
	EndIf;
	
	Address = EmailAddressFromPresentation(RowData.Presentation);
	
	If IsBlankString(Address) Then
		Address = RowData.Presentation;
	EndIf;
	
	If IsBlankString(Address) Then
		Return;
	EndIf;
	
	If StrFind(Address, "@") = 0 OR StrFind(Address, ".") = 0 Then
		ShowMessageBox(, NStr("ru = 'Необходимо ввести адрес электронной почты'; en = 'Please enter an email address.'; pl = 'Należy podać adres poczty elektronicznej';de = 'Sie müssen eine E-Mail-Adresse eingeben';ro = 'Introduceți adresa de e-mail';tr = 'E-posta adresi girilmelidir'; es_ES = 'Es necesario introducir la dirección de correo electrónico'"));
		Cancel = True;
		Return;
	EndIf;
	
	Duplicates = New Map;
	For each EmailRecipient In RecipientsMailAddresses Do
		MailAddr = EmailAddressFromPresentation(EmailRecipient.Presentation);
		If Duplicates[Upper(MailAddr)] = Undefined Then
			Duplicates.Insert(Upper(MailAddr), True);
		Else
			ShowMessageBox(, NStr("ru = 'Такой адрес электронной почты уже есть в списке.'; en = 'This email address already exists.'; pl = 'Ten adres poczty elektronicznej już jest na liście';de = 'Diese E-Mail-Adresse ist bereits in der Liste enthalten.';ro = 'Acest e-mail deja există în listă.';tr = 'Bu e-posta adresi listede zaten mevcut.'; es_ES = 'Esta dirección del correo electrónico ya existe en la lista.'"));
			Cancel = True;
			Return;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion


#Region AttachmentsFormTableItemsEventHandlers

// Removes an attachment from the list and also calls the function that updates the table of 
// attachment presentations.
//
&AtClient
Procedure AttachmentsBeforeDeleteRow(Item, Cancel)
	
	AttachmentDescription = Item.CurrentData[Item.CurrentItem.Name];
	
	For Each Attachment In Attachments Do
		If Attachment.Presentation = AttachmentDescription Then
			Attachments.Delete(Attachment);
		EndIf;
	EndDo;
	
	RefreshAttachmentPresentation();
	
EndProcedure

&AtClient
Procedure AttachmentsBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
	
	Cancel = True;
	AddFileToAttachments();
	
EndProcedure

&AtClient
Procedure AttachmentsChoice(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	OpenAttachment();
	
EndProcedure

&AtClient
Procedure AttachmentsDragCheck(Item, DragParameters, StandardProcessing, Row, Field)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure AttachmentsDrag(Item, DragParameters, StandardProcessing, Row, Field)
	
	StandardProcessing = False;
	
	If TypeOf(DragParameters.Value) = Type("File") Then
		NotifyDescription = New NotifyDescription("AttachmentsDragCompletion", ThisObject, New Structure("Name", DragParameters.Value.Name));
		BeginPutFile(NotifyDescription, , DragParameters.Value.FullName, False);
	EndIf;
	
EndProcedure

&AtClient
Procedure ReplyToTextEditEnd(Item, Text, ChoiceData, StandardProcessing)
	
	FillReplyToAddressAutomatically = False;
	ReplyToAddress = GetNormalizedEmailInFormat(Text);
	
EndProcedure

&AtClient
Procedure ReplyToChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	FillReplyToAddressAutomatically = False;
	
EndProcedure

&AtClient
Procedure ReplyToClearing(Item, StandardProcessing)

	StandardProcessing = False;
	SaveReplyTo(ReplyToAddress, False);
	
	For Each ReplyToItem In Items.ReplyToAddress.ChoiceList Do
		If ReplyToItem.Value = ReplyToAddress
		   AND ReplyToItem.Presentation = ReplyToAddress Then
			Items.ReplyToAddress.ChoiceList.Delete(ReplyToItem);
		EndIf;
	EndDo;
	
	ReplyToAddress = "";
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure OpenFile(Command)
	OpenAttachment();
EndProcedure

&AtClient
Procedure SendEmail()
	
	ClearMessages();
	
	If FieldsFilledCorrectly() AND SendEmailMessage() Then
		SaveReplyTo(ReplyToAddress);
		FormClosingConfirmationRequired = False;
		
		ShowUserNotification(NStr("ru = 'Сообщение отправлено:'; en = 'Message sent:'; pl = 'Wiadomość została wysłana:';de = 'Nachricht gesendet:';ro = 'Mesajul este trimis:';tr = 'Mesaj gönderildi:'; es_ES = 'Mensaje enviado:'"), ,
			?(IsBlankString(EmailSubject), NStr("ru = '<Без темы>'; en = '<No subject>'; pl = '<Bez tematu>';de = '<Kein Thema>';ro = '<Fără temă>';tr = '<Konu yok>'; es_ES = '<Sin tema>'"), EmailSubject), PictureLib.Information32);
			
		Close();
	EndIf;
	
EndProcedure

&AtClient
Function FieldsFilledCorrectly()
	Result = True;
	
	If RecipientsMailAddresses.Count() = 0 Then
		CommonClient.MessageToUser(
			NStr("ru = 'Необходимо заполнить получателя письма'; en = 'Please enter the email recipient.'; pl = 'Należy wypełnić adresata wiadomości';de = 'Sie müssen den Empfänger ausfüllen';ro = 'Trebuie să completați destinatarul scrisorii';tr = 'E-posta alıcısını belirtin'; es_ES = 'Es necesario rellenar el destinatario del correo'"), , "RecipientsMailAddresses");
		Result = False;
	EndIf;
	For each EmailRecipient In RecipientsMailAddresses Do
		Address = EmailAddressFromPresentation(EmailRecipient.Presentation);
		If IsBlankString(Address) Then
			CommonClient.MessageToUser(
				NStr("ru = 'Необходимо заполнить получателя письма'; en = 'Please enter the email recipient.'; pl = 'Należy wypełnić adresata wiadomości';de = 'Sie müssen den Empfänger ausfüllen';ro = 'Trebuie să completați destinatarul scrisorii';tr = 'E-posta alıcısını belirtin'; es_ES = 'Es necesario rellenar el destinatario del correo'"),, "RecipientsMailAddresses[" + Format(RecipientsMailAddresses.IndexOf(EmailRecipient), "NG=0") + "].Presentation");
			Result = False;
		ElsIf StrFind(Address, "@") = 0 Then
			CommonClient.MessageToUser(
				NStr("ru = 'Неверный адрес электронной почты'; en = 'Invalid email address.'; pl = 'Nieprawidłowy adres poczty elektronicznej';de = 'Ungültige E-Mail-Adresse';ro = 'Adresa e-mail incorectă';tr = 'Yalnış e-posta adresi'; es_ES = 'Dirección incorrecta del correo electrónico'"),, "RecipientsMailAddresses[" + Format(RecipientsMailAddresses.IndexOf(EmailRecipient), "NG=0") + "].Presentation");
			Result = False;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

&AtClient
Procedure AttachFileExecute()
	
	AddFileToAttachments();
	
EndProcedure

// StandardSubsystems.MessagesTemplates

&AtClient
Procedure GenerateFromTemplate(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.MessageTemplates") Then
		ModuleMessagesTemplatesClient = CommonClient.CommonModule("MessageTemplatesClient");
		Notification = New NotifyDescription("FillByTemplateAfterTemplateChoice", ThisObject);
		ModuleMessagesTemplatesClient.PrepareMessageFromTemplate("Common", "Email", Notification);
	EndIf
	
EndProcedure

// End StandardSubsystems.MessagesTemplates

#EndRegion

#Region Private

&AtServer
Function SendEmailMessage()
	EmailParameters = GenerateEmailParameters();
	If EmailParameters = Undefined Then
		Return False;
	EndIf;
	EmailOperations.SendEmailMessage(Account, EmailParameters);
	AddRecipientsToHistory(EmailParameters.SendTo);
	Return True;
EndFunction

&AtServerNoContext
Function GetEmailAddressByAccount(Val Account)
	
	Return TrimAll(Account.UserName)
			+ ? (IsBlankString(TrimAll(Account.UserName)),
					Account.EmailAddress,
					" <" + Account.EmailAddress + ">");
	
EndFunction

&AtClient
Procedure OpenAttachment()
	
	SelectedAttachment = SelectedAttachment();
	If SelectedAttachment = Undefined Then
		Return;
	EndIf;
	
	#If WebClient Then
		GetFile(SelectedAttachment.AddressInTempStorage, SelectedAttachment.Presentation, True);
	#Else
		TempFolderName = GetTempFileName();
		CreateDirectory(TempFolderName);
		
		TempFileName = CommonClientServer.AddLastPathSeparator(TempFolderName) + SelectedAttachment.Presentation;
		
		BinaryData = GetFromTempStorage(SelectedAttachment.AddressInTempStorage);
		BinaryData.Write(TempFileName);
		
		File = New File(TempFileName);
		File.SetReadOnly(True);
		If File.Extension = ".mxl" Then
			SpreadsheetDocument = GetSpreadsheetDocumentByBinaryData(SelectedAttachment.AddressInTempStorage);
			OpeningParameters = New Structure;
			OpeningParameters.Insert("DocumentName", SelectedAttachment.Presentation);
			OpeningParameters.Insert("SpreadsheetDocument", SpreadsheetDocument);
			OpeningParameters.Insert("PathToFile", TempFileName);
			OpenForm("CommonForm.EditSpreadsheetDocument", OpeningParameters, ThisObject);
		Else
			FileSystemClient.OpenFile(TempFileName);
		EndIf;
	#EndIf
	
EndProcedure

&AtClient
Function SelectedAttachment()
	
	Result = Undefined;
	If Items.Attachments.CurrentData <> Undefined Then
		AttachmentDescription = Items.Attachments.CurrentData[Items.Attachments.CurrentItem.Name];
		For Each Attachment In Attachments Do
			If Attachment.Presentation = AttachmentDescription Then
				Result = Attachment;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	Return Result;
	
EndFunction

&AtServerNoContext
Function GetSpreadsheetDocumentByBinaryData(Val BinaryData)
	
	If TypeOf(BinaryData) = Type("String") Then
		// Transferring binary data address to temporary storage.
		BinaryData = GetFromTempStorage(BinaryData);
	EndIf;
	
	FileName = GetTempFileName("mxl");
	BinaryData.Write(FileName);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.Read(FileName);
	
	Try
		DeleteFiles(FileName);
	Except
		WriteLogEvent(NStr("ru = 'Получение табличного документа'; en = 'Get spreadsheet document'; pl = 'Uzyskać dokument tabelaryczny';de = 'Kalkulationstabellen-Dokument erhalten';ro = 'Primirea documentului tabelar';tr = 'Elektronik çizelge belgesini al'; es_ES = 'Recibir el documento de la hoja de cálculo'", Common.DefaultLanguageCode()), EventLogLevel.Error, , , 
			DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return SpreadsheetDocument;
	
EndFunction

&AtClient
Procedure AddFileToAttachments()
	
	NotifyDescription = New NotifyDescription("AddFileToAttachmentsOnPutFiles", ThisObject);
	
	ImportParameters = FileSystemClient.FileImportParameters();
	ImportParameters.FormID = UUID;
	FileSystemClient.ImportFiles(NotifyDescription, ImportParameters);
	
EndProcedure

&AtClient
Procedure AddFileToAttachmentsOnPutFiles(FilesThatWerePut, AdditionalParameters) Export
	If FilesThatWerePut = Undefined Or FilesThatWerePut.Count() = 0 Then
		Return;
	EndIf;
	AddFilesToList(FilesThatWerePut);
	RefreshAttachmentPresentation();
	FormClosingConfirmationRequired = True;
EndProcedure

&AtServer
Procedure AddFilesToList(FilesThatWerePut)
	
	For Each FileDetails In FilesThatWerePut Do
		File = New File(FileDetails.Name);
		Attachment = Attachments.Add();
		Attachment.Presentation = File.Name;
		Attachment.AddressInTempStorage = PutToTempStorage(GetFromTempStorage(FileDetails.Location), UUID);
	EndDo;
	
EndProcedure

&AtClient
Procedure RefreshAttachmentPresentation()
	
	AttachmentsPresentation.Clear();
	
	Index = 0;
	
	For Each Attachment In Attachments Do
		If Index = 0 Then
			PresentationRow = AttachmentsPresentation.Add();
		EndIf;
		
		PresentationRow["Attachment" + String(Index + 1)] = Attachment.Presentation;
		
		If Items.Attachment2.Visible Then // For mobile client.
			Index = Index + 1;
			If Index = 2 Then 
				Index = 0;
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

// Checks whether it is possible to send the email. If it is possible, sending parameters are 
// generated.
//
&AtServer
Function GenerateEmailParameters()
	
	EmailParameters = New Structure;
	SendTo = New Array;
	Cc = New Array;
	BCC = New Array;
	
	For each Recipient In RecipientsMailAddresses Do
		RecipientsEmailAddr = CommonClientServer.EmailsFromString(Recipient.Presentation);
		For each RecipientEmailAddr In RecipientsEmailAddr Do
			If Recipient.SendingOption = NStr("ru = 'Скрытая копия:'; en = 'Bcc:'; pl = 'Ukryta kopia:';de = 'Eine versteckte Kopie:';ro = 'Copia ascunsă:';tr = 'Gizli:'; es_ES = 'Copia oculta:'") Then
				BCC.Add(New Structure("Address, Presentation", RecipientEmailAddr.Address, RecipientEmailAddr.Alias));
			ElsIf Recipient.SendingOption = NStr("ru = 'Копия:'; en = 'Cc:'; pl = 'Kopia:';de = 'Kopie:';ro = 'Copia:';tr = 'Kopya:'; es_ES = 'Copia:'") Then
				Cc.Add(New Structure("Address, Presentation", RecipientEmailAddr.Address, RecipientEmailAddr.Alias));
			Else
				SendTo.Add(New Structure("Address, Presentation", RecipientEmailAddr.Address, RecipientEmailAddr.Alias));
			EndIf;
		EndDo;
	EndDo;
	
	If SendTo.Count() > 0 Then
		EmailParameters.Insert("SendTo", SendTo);
	EndIf;
	If Cc.Count() > 0 Then
		EmailParameters.Insert("Cc", Cc);
	EndIf;
	If BCC.Count() > 0 Then
		EmailParameters.Insert("BCC", BCC);
	EndIf;
	
	RecipientsList = CommonClientServer.EmailsFromString(ReplyToAddress);
	SendTo = New Array;
	For Each Recipient In RecipientsList Do
		If Not IsBlankString(Recipient.ErrorDescription) Then
			Common.MessageToUser(
				Recipient.ErrorDescription, , "ReplyToAddress");
			Return Undefined;
		EndIf;
		SendTo.Add(New Structure("Address, Presentation", Recipient.Address, Recipient.Alias));
	EndDo;
	
	If ValueIsFilled(ReplyToAddress) Then
		EmailParameters.Insert("ReplyToAddress", ReplyToAddress);
	EndIf;
	
	If ValueIsFilled(EmailSubject) Then
		EmailParameters.Insert("Subject", EmailSubject);
	EndIf;
	
	EmailParameters.Insert("Body", EmailBody);
	EmailParameters.Insert("Attachments", Attachments());
	
	Return EmailParameters;
	
EndFunction

&AtServer
Function HTMLWrappedText(Text)
	
	If StrFind(Lower(Text), "</html>", SearchDirection.FromEnd) > 0 Then
		Return Text;
	EndIf;
	
	DocumentHTML = New HTMLDocument;
	
	ItemBody = DocumentHTML.CreateElement("body");
	DocumentHTML.Body = ItemBody;
	
	For RowNumber = 1 To StrLineCount(Text) Do
		Row = StrGetLine(Text, RowNumber);
		
		ItemBlock = DocumentHTML.CreateElement("p");
		ItemBody.AppendChild(ItemBlock);
		
		ItemText = DocumentHTML.CreateTextNode(Row);
		ItemBlock.AppendChild(ItemText);
	EndDo;
	
	DOMWriter = New DOMWriter;
	HTMLWriter = New HTMLWriter;
	HTMLWriter.SetString();
	DOMWriter.Write(DocumentHTML, HTMLWriter);
	Result = HTMLWriter.Close();
	
	Return Result;
	
EndFunction

&AtServer
Function Attachments()
	
	Result = New Array;
	For Each Attachment In Attachments Do
		AttachmentDetails = New Structure;
		AttachmentDetails.Insert("Presentation", Attachment.Presentation);
		AttachmentDetails.Insert("AddressInTempStorage", Attachment.AddressInTempStorage);
		AttachmentDetails.Insert("Encoding", Attachment.Encoding);
		AttachmentDetails.Insert("ID", Attachment.ID);
		Result.Add(AttachmentDetails);
	EndDo;
	
	Return Result;
	
EndFunction

&AtServer
Procedure DetermineEmailAttachmentPurpose(Attachment, AttachmentsForEmail)
	
	If Attachment.Property("ID") AND ValueIsFilled(Attachment.ID) Then
		PictureAttachment = New Picture(GetFromTempStorage(Attachment.AddressInTempStorage));
		AttachmentsForEmail.Insert(Attachment.Presentation, PictureAttachment);
	Else
		AttachmentDetails = Attachments.Add();
		FillPropertyValues(AttachmentDetails, Attachment);
		If Not IsBlankString(AttachmentDetails.AddressInTempStorage) Then
			AttachmentDetails.AddressInTempStorage = PutToTempStorage(
			GetFromTempStorage(AttachmentDetails.AddressInTempStorage), UUID);
		EndIf;
	EndIf;

EndProcedure

&AtServerNoContext
Procedure SaveReplyTo(Val ReplyToAddress, Val AddAddressToList = True)
	
	// Getting the list of addresses that the user previously used.
	ReplyToList = Common.CommonSettingsStorageLoad(
		"EditNewEmailMessage",
		"ReplyToList");
	
	If ReplyToList = Undefined Then
		ReplyToList = New ValueList();
	EndIf;
	
	For Each ItemReplyTo In ReplyToList Do
		If ItemReplyTo.Value = ReplyToAddress
		   AND ItemReplyTo.Presentation = ReplyToAddress Then
			ReplyToList.Delete(ItemReplyTo);
		EndIf;
	EndDo;
	
	If AddAddressToList
	   AND ValueIsFilled(ReplyToAddress) Then
		ReplyToList.Insert(0, ReplyToAddress, ReplyToAddress);
	EndIf;
	
	Common.CommonSettingsStorageSave(
		"EditNewEmailMessage",
		"ReplyToList",
		ReplyToList);
	
EndProcedure

&AtClient
Function GetNormalizedEmailInFormat(Text)
	AddressesAsString = "";
	Addresses = CommonClientServer.EmailsFromString(Text);
	
	If Addresses.Count() > 1 Then
		CommonClient.MessageToUser(
			NStr("ru = 'Можно указывать только один адрес для ответа.'; en = 'Please specify a single reply-to address.'; pl = 'Można określać tylko jeden adres do odpowiedzi.';de = 'Es kann nur eine Adresse für die Antwort angegeben werden.';ro = 'Puteți indica o singură adresă pentru răspuns.';tr = 'Cevap için sadece bir adres belirtilebilir.'; es_ES = 'Se puede indicar solo una dirección para responder.'"), , "ReplyToAddress");
		Return Text;
	EndIf;
	
	For Each AddrDetails In Addresses Do
		If Not IsBlankString(AddrDetails.ErrorDescription) Then
			CommonClient.MessageToUser(AddrDetails.ErrorDescription, , "ReplyToAddress");
		EndIf;
		
		If Not IsBlankString(AddressesAsString) Then
			AddressesAsString = AddressesAsString + "; ";
		EndIf;
		AddressesAsString = AddressesAsString + AddressAsString(AddrDetails);
	EndDo;
	
	Return AddressesAsString;
EndFunction

&AtClient
Function AddressAsString(AddrDetails)
	Result = "";
	If IsBlankString(AddrDetails.Alias) Then
		Result = AddrDetails.Address;
	Else
		If IsBlankString(AddrDetails.Address) Then
			Result = AddrDetails.Alias;
		Else
			Result = StringFunctionsClientServer.SubstituteParametersToString(
				"%1 <%2>", AddrDetails.Alias, AddrDetails.Address);
		EndIf;
	EndIf;
	
	Return Result;
EndFunction

&AtClient
Procedure AttachmentsDragCompletion(Result, TempStorageAddress, SelectedFileName, AdditionalParameters) Export
	Files = New Array;
	FileToPass = New TransferableFileDescription(AdditionalParameters.Name, TempStorageAddress);
	Files.Add(FileToPass);
	AddFilesToList(Files);
	RefreshAttachmentPresentation();
	FormClosingConfirmationRequired = True;
EndProcedure

&AtClient
Procedure ImportAttachmentsFromFiles()
	
	For Each Attachment In Attachments Do
		If Not IsBlankString(Attachment.PathToFile) Then
			BinaryData = New BinaryData(Attachment.PathToFile);
			Attachment.AddressInTempStorage = PutToTempStorage(BinaryData, UUID);
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure ShowQueryBoxBeforeCloseForm()
	QuestionText = NStr("ru = 'Сообщение еще не отправлено. Закрыть форму?'; en = 'The message is not yet sent. Do you want to close the window?'; pl = 'Wiadomość nie została jeszcze wysłana. Zamknąć formularz?';de = 'Die Nachricht wurde noch nicht gesendet. Das Formular schließen?';ro = 'Mesajul încă nu este trimis. Închideți forma?';tr = 'Mesaj henüz gönderilmedi. Formu kapat?'; es_ES = 'Mensaje no se ha enviado. ¿Cerrar el formulario?'");
	NotifyDescription = New NotifyDescription("CloseFormConfirmed", ThisObject);
	Buttons = New ValueList;
	Buttons.Add("Close", NStr("ru = 'Закрыть'; en = 'Close'; pl = 'Zamknij';de = 'Schließen';ro = 'Închideți';tr = 'Kapat'; es_ES = 'Cerrar'"));
	Buttons.Add(DialogReturnCode.Cancel, NStr("ru = 'Не закрывать'; en = 'Do not close'; pl = 'Zostaw otwarte';de = 'Offen halten';ro = 'Nu închide';tr = 'Kapatmayın'; es_ES = 'Dejar abierto'"));
	ShowQueryBox(NotifyDescription, QuestionText, Buttons,,
		DialogReturnCode.Cancel, NStr("ru = 'Отправка сообщения'; en = 'Send message'; pl = 'Wiadomość e-mail';de = 'Nachricht senden';ro = 'Expediere mesajul';tr = 'Mesaj gönder'; es_ES = 'Mensaje de correo electrónico'"));
EndProcedure

&AtClient
Procedure CloseFormConfirmed(QuestionResult, AdditionalParameters = Undefined) Export
	
	If QuestionResult = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	
	FormClosingConfirmationRequired = False;
	Close();
	
EndProcedure

&AtClient
Procedure SaveAsTemplate(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.MessageTemplates") Then
		ModuleMessagesTemplatesClientServer = CommonClient.CommonModule("MessageTemplatesClientServer");
		TemplateParameters = ModuleMessagesTemplatesClientServer.TemplateParametersDetails();
		ModuleMessagesTemplatesClient = CommonClient.CommonModule("MessageTemplatesClient");
		TemplateParameters.Subject = EmailSubject;
		TemplateParameters.Text = EmailBody.GetText();
		TemplateParameters.TemplateType = "Email";
		ModuleMessagesTemplatesClient.ShowTemplateForm(TemplateParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillByTemplateAfterTemplateChoice(Result, AdditionalParameters) Export
	If Result <> Undefined Then
		EmailSubject = Result.Subject;
		SetEmailTextAndAttachments(Result.Text, Result.Attachments);
		RefreshAttachmentPresentation();
		
		If TypeOf(Result.Recipient) = Type("ValueList") Then
			For Each Recipient In Result.Recipient Do
				RecipientAddress                 = RecipientsMailAddresses.Add();
				RecipientAddress.SendingOption = NStr("ru='Кому:'; en = 'To:'; pl = 'Do:';de = 'An wen:';ro = 'Către:';tr = 'Kime:'; es_ES = 'Para:'");
				RecipientAddress.Presentation   = Recipient.Presentation;
			EndDo;
		EndIf;
	EndIf;
EndProcedure

&AtServer
Procedure SetEmailTextAndAttachments(Text, AttachmentsStructure)
	
	HTMLAttachments = New Structure();
	If TypeOf(AttachmentsStructure) = Type("Array") Then
		For each Attachment In AttachmentsStructure Do
			DetermineEmailAttachmentPurpose(Attachment, HTMLAttachments);
		EndDo;
	EndIf;
		
	EmailBody.SetHTML(Text, HTMLAttachments);
	
EndProcedure

&AtClient
Function EmailAddressFromPresentation(Val Presentation)
	
	Address = Presentation;
	PositionStart = StrFind(Presentation, "<");
	If PositionStart > 0 Then
		PositionEnd = StrFind(Presentation, ">", SearchDirection.FromBegin, PositionStart);
		If PositionEnd > 0 Then
			Address = Mid(Presentation, PositionStart + 1, PositionEnd - PositionStart - 1);
		EndIf;
	EndIf;
	
	Return TrimAll(Address);

EndFunction

&AtServer
Procedure FillRecipientsTableFromStructuresArray(MessageRecipientParameters)
	
	For Each RecipientParameters In MessageRecipientParameters Do
		If ValueIsFilled(RecipientParameters.Address) Then
			Address = StrReplace(RecipientParameters.Presentation, ",", " ") + " < "+ RecipientParameters.Address + ">";
			
			If RecipientParameters.Property("EmailAddressKind") 
				AND ValueIsFilled(RecipientParameters.EmailAddressKind) Then
				Presentation = Address + " (" + RecipientParameters.EmailAddressKind + ")";
			ElsIf RecipientParameters.Property("ContactInformationSource")
				AND ValueIsFilled(RecipientParameters.ContactInformationSource) Then
				Presentation = Address + " (" + String(RecipientParameters.ContactInformationSource) + ")";
			Else
				Presentation = Address;
			EndIf;
			MessageRecipients.Add(Address, Presentation);
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure FillRecipientsTableFromRow(Val MessageRecipientParameters)
	
	MessageRecipientParameters = CommonClientServer.EmailsFromString(MessageRecipientParameters);
	
	For Each RecipientParameters In MessageRecipientParameters Do
		If ValueIsFilled(RecipientParameters.Address) Then
			MessageRecipients.Add(RecipientParameters.Address, RecipientParameters.Alias);
		EndIf;
	EndDo;
	
EndProcedure

&AtServerNoContext
Procedure ClearAttachments(AttachmentAddresses)
	For Each AttachmentAddress In AttachmentAddresses Do
		DeleteFromTempStorage(AttachmentAddress);
	EndDo;
EndProcedure

&AtServerNoContext
Procedure AddRecipientsToHistory(EmailRecipients)
	
	RecipientHistory = RecipientHistory();
	For Each Recipient In EmailRecipients Do
		RecipientHistory.Insert(Recipient.Address, Recipient.Presentation);
	EndDo;
	
	Common.CommonSettingsStorageSave("EditNewEmailMessage", "RecipientsHistory", RecipientHistory);
	
EndProcedure

&AtServerNoContext
Function RecipientHistory()
	
	Return Common.CommonSettingsStorageLoad("EditNewEmailMessage", "RecipientsHistory", New Map);
	
EndFunction

&AtClient
Function AddressPresentation(Address, RecipientPresentation)
	Result = Address;
	If Not IsBlankString(RecipientPresentation) Then
		Result = StringFunctionsClientServer.SubstituteParametersToString("%1 <%2>", RecipientPresentation, Address);
	EndIf;
	Return Result;
EndFunction

&AtClient
Function SimilarRecipientsFromHistory(Row)
	
	Result = New ValueList;
	If StrLen(Row) = 0 Then
		Return Result;
	EndIf;
	
	If RecipientHistory = Undefined Then
		RecipientHistory = RecipientHistory();
	EndIf;
	
	For Each Recipient In RecipientHistory Do
		AddressPresentation = AddressPresentation(Recipient.Key, Recipient.Value);
		Position = StrFind(Lower(AddressPresentation), Lower(Row));
		If Position > 0 Then
			SubstringBeforeOccurence = Left(AddressPresentation, Position - 1);
			OccurenceSubstring = Mid(AddressPresentation, Position, StrLen(Row));
			SubstringAfterOccurence = Mid(AddressPresentation, Position + StrLen(Row));
			HighlightedString = New FormattedString(
				SubstringBeforeOccurence,
				New FormattedString(OccurenceSubstring, New Font( , , True), SuccessResultColor),
				SubstringAfterOccurence);
			Result.Add(AddressPresentation, HighlightedString);
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

&AtClient
Function SimilarRecipientsFromPassedRecipients(Val Text)
	
	Result = New ValueList;
	
	AddressesList = New Array;
	For each TableRow In RecipientsMailAddresses Do
		Address = EmailAddressFromPresentation(TableRow.Presentation);
		If ValueIsFilled(Address) Then
			AddressesList.Add(Upper(Address));
		EndIf;
	EndDo;
	
	PresentationSelect = New FormattedString(Text, New Font(,, True), SuccessResultColor);
	TextLength = StrLen(Text);
	For Each Mail In MessageRecipients Do
		Address = EmailAddressFromPresentation(Mail.Value);
		If AddressesList.Find(Upper(Address)) = Undefined Then
			Position = StrFind(Mail.Value, Text);
			If Position > 0 Then
				Presentation= New FormattedString(Left(Mail.Presentation, Position - 1), PresentationSelect, Mid(Mail.Presentation, Position + TextLength));
				Result.Add(Mail.Value, Presentation);
			EndIf;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion
